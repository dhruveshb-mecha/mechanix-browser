import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/core/database/app_database.dart';
import 'package:mechanix_browser/features/browser/bloc/download/browser_download.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/download_entity.dart';
import 'package:mechanix_browser/features/browser/data/repositories/download_repository_impl.dart';
import 'package:webview_cef/webview_cef.dart';

class _Controller extends Fake implements WebViewController {
  @override
  bool get value => true;

  @override
  Future<void> continueDownload(
    int downloadId,
    String downloadPath, {
    bool showDialog = false,
  }) async {}
}

DownloadEntity entity(int cefId, {int createdAt = 0, int id = 0}) =>
    DownloadEntity(
      id: id,
      cefDownloadId: cefId,
      url: 'https://example.com/$cefId',
      fileName: 'f$cefId',
      filePath: '/tmp/f$cefId',
      statusIndex: DownloadStatus.downloading.index,
      createdAt: createdAt,
    );

void main() {
  late AppDatabase db;
  late DownloadRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DownloadRepositoryImpl(db: db);
  });
  tearDown(() => db.close());

  test('save inserts, sets the id, then updates in place', () async {
    final e = entity(1);
    final id = await repository.saveDownload(e);
    expect(id, greaterThan(0));
    expect(e.id, id, reason: 'the id is stored on the entity, like put()');

    e
      ..downloadedBytes = 50
      ..statusIndex = DownloadStatus.completed.index;
    expect(await repository.saveDownload(e), id);

    final stored = await repository.getDownloadById(id);
    expect(stored!.downloadedBytes, 50);
    expect(stored.statusIndex, DownloadStatus.completed.index);
    expect(await repository.getAllDownloads(), hasLength(1));
  });

  test('lists newest first and finds by CEF id', () async {
    await repository.saveAllDownloads([
      entity(1, createdAt: 10),
      entity(2, createdAt: 30),
      entity(1, createdAt: 20),
    ]);
    expect((await repository.getAllDownloads()).map((d) => d.createdAt), [
      30,
      20,
      10,
    ]);
    expect((await repository.getDownloadByCefId(1))!.createdAt, 20);
    expect(await repository.getDownloadByCefId(99), isNull);
  });

  test(
    'delete reports whether the record existed; clear removes all',
    () async {
      final id = await repository.saveDownload(entity(1));
      await repository.saveDownload(entity(2));

      expect(await repository.deleteDownload(id), isTrue);
      expect(await repository.deleteDownload(id), isFalse);
      expect(await repository.getAllDownloads(), hasLength(1));

      await repository.clearHistory();
      expect(await repository.getAllDownloads(), isEmpty);
    },
  );

  test('a burst of progress updates ends with the final state saved', () async {
    final controller = _Controller();
    final bloc = DownloadBloc(repository: repository);
    bloc.add(
      DownloadBeforeStarted(
        controller: controller,
        downloadId: 7,
        url: 'https://example.com/big.iso',
        suggestedName: 'big.iso',
        contentDisposition: '',
        mimeType: 'application/octet-stream',
        totalBytes: 1000,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state.downloads.single.id, greaterThan(0));

    for (var received = 100; received <= 1000; received += 100) {
      bloc.add(
        DownloadUpdatedEvent(
          controller: controller,
          downloadId: 7,
          url: 'https://example.com/big.iso',
          fullPath: '/tmp/big.iso',
          receivedBytes: received,
          totalBytes: 1000,
          currentSpeed: 1000,
          percentComplete: received ~/ 10,
          isInProgress: received < 1000,
          isComplete: received == 1000,
          isCanceled: false,
          isInterrupted: false,
          interruptReason: 0,
        ),
      );
    }
    // Let the bloc process every update, then close: close() waits for the
    // queued background saves.
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (bloc.state.downloads.single.status != DownloadStatus.completed) {
      if (DateTime.now().isAfter(deadline)) fail('timed out');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await bloc.close();

    final [stored] = await repository.getAllDownloads();
    expect(stored.downloadedBytes, 1000);
    expect(stored.statusIndex, DownloadStatus.completed.index);
  });
}
