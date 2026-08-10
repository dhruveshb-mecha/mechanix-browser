import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/features/browser/bloc/download/browser_download.dart';
import 'package:mechanix_browser/features/browser/bloc/download/download_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/download_entity.dart';
import 'package:mechanix_browser/features/browser/data/repositories/download_repository.dart';
import 'package:mechanix_browser/features/browser/data/repositories/download_repository_impl.dart';
import 'package:mechanix_browser/objectbox.g.dart';
import 'package:webview_cef/webview_cef.dart';

class MockWebViewController extends Fake implements WebViewController {
  @override
  bool get value => true;

  @override
  Future<void> continueDownload(
    int downloadId,
    String downloadPath, {
    bool showDialog = false,
  }) async {}

  @override
  Future<void> pauseDownload(int downloadId) async {}

  @override
  Future<void> resumeDownload(int downloadId) async {}

  @override
  Future<void> cancelDownload(int downloadId) async {}

  @override
  Future<void> loadUrl(String url) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Download History & ObjectBox Lifecycle Tests', () {
    late DownloadRepositoryImpl repository;
    late MockWebViewController mockController;
    late Directory tempDir;

    late Directory testDbDir;
    late Store testStore;

    setUpAll(() async {
      testDbDir = Directory.systemTemp.createTempSync('objectbox_test_db_');
      testStore = Store(getObjectBoxModel(), directory: testDbDir.path);
      repository = DownloadRepositoryImpl(store: testStore);
      mockController = MockWebViewController();
    });

    tearDownAll(() {
      repository.close();
      testStore.close();
      if (testDbDir.existsSync()) {
        try {
          testDbDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    setUp(() {
      repository.clearHistory();
      tempDir = Directory.systemTemp.createTempSync('download_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test(
      'Test 1: Download -> complete -> Remove from history -> ObjectBox record removed -> physical file remains',
      () async {
        final bloc = DownloadBloc(repository: repository);
        final filePath = '${tempDir.path}/test_file_1.zip';
        final file = File(filePath)..writeAsStringSync('dummy content');

        // Start download
        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 1,
            url: 'https://example.com/file1.zip',
            suggestedName: 'test_file_1.zip',
            contentDisposition: '',
            mimeType: 'application/zip',
            totalBytes: 100,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // Complete download
        bloc.add(
          DownloadUpdatedEvent(
            controller: mockController,
            downloadId: 1,
            url: 'https://example.com/file1.zip',
            fullPath: filePath,
            receivedBytes: 100,
            totalBytes: 100,
            currentSpeed: 1000,
            percentComplete: 100,
            isInProgress: false,
            isComplete: true,
            isCanceled: false,
            isInterrupted: false,
            interruptReason: 0,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final initialRecords = repository.getAllDownloads();
        expect(initialRecords.length, 1);
        final recordId = initialRecords.first.id;

        // Remove from history (deleteFile: false)
        bloc.add(DownloadRemoveRequested(recordId, deleteFile: false));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(repository.getAllDownloads().isEmpty, isTrue);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Physical file must remain on disk',
        );

        await bloc.close();
      },
    );

    test(
      'Test 2: Download -> complete -> Delete download & remove history -> file removed -> ObjectBox record removed',
      () async {
        final bloc = DownloadBloc(repository: repository);
        final filePath = '${tempDir.path}/test_file_2.zip';
        final file = File(filePath)..writeAsStringSync('dummy content');

        // Start download
        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 2,
            url: 'https://example.com/file2.zip',
            suggestedName: 'test_file_2.zip',
            contentDisposition: '',
            mimeType: 'application/zip',
            totalBytes: 100,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // Complete download
        bloc.add(
          DownloadUpdatedEvent(
            controller: mockController,
            downloadId: 2,
            url: 'https://example.com/file2.zip',
            fullPath: filePath,
            receivedBytes: 100,
            totalBytes: 100,
            currentSpeed: 1000,
            percentComplete: 100,
            isInProgress: false,
            isComplete: true,
            isCanceled: false,
            isInterrupted: false,
            interruptReason: 0,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final initialRecords = repository.getAllDownloads();
        expect(initialRecords.length, 1);
        final recordId = initialRecords.first.id;

        // Delete file & remove history (deleteFile: true)
        bloc.add(DownloadRemoveRequested(recordId, deleteFile: true));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(repository.getAllDownloads().isEmpty, isTrue);
        expect(
          file.existsSync(),
          isFalse,
          reason: 'Physical file must be deleted from disk',
        );

        await bloc.close();
      },
    );

    test(
      'Test 3: Download -> fail -> Retry -> same ObjectBox ID -> only one record exists',
      () async {
        final bloc = DownloadBloc(repository: repository);

        // 1. Initial download start
        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 10,
            url: 'https://example.com/file3.zip',
            suggestedName: 'file3.zip',
            contentDisposition: '',
            mimeType: 'application/zip',
            totalBytes: 200,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final initialRecords = repository.getAllDownloads();
        expect(initialRecords.length, 1);
        final originalId = initialRecords.first.id;

        // 2. Download fails
        bloc.add(
          DownloadUpdatedEvent(
            controller: mockController,
            downloadId: 10,
            url: 'https://example.com/file3.zip',
            fullPath: '${tempDir.path}/file3.zip',
            receivedBytes: 50,
            totalBytes: 200,
            currentSpeed: 0,
            percentComplete: 25,
            isInProgress: false,
            isComplete: false,
            isCanceled: false,
            isInterrupted: true,
            interruptReason: 20,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final failedDownload = bloc.state.downloads.first;
        expect(failedDownload.status, DownloadStatus.failed);

        // 3. User retries download
        bloc.add(
          DownloadRetryRequested(failedDownload, controller: mockController),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // CEF assigns new downloadId 11
        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 11,
            url: 'https://example.com/file3.zip',
            suggestedName: 'file3.zip',
            contentDisposition: '',
            mimeType: 'application/zip',
            totalBytes: 200,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final currentRecords = repository.getAllDownloads();
        expect(
          currentRecords.length,
          1,
          reason: 'Exactly ONE ObjectBox record must exist after retry',
        );
        expect(
          currentRecords.first.id,
          originalId,
          reason: 'Must reuse original ObjectBox primary key',
        );

        await bloc.close();
      },
    );

    test(
      'Test 4: Download -> fail -> Retry -> fail -> Retry -> complete -> exactly ONE ObjectBox record',
      () async {
        final bloc = DownloadBloc(repository: repository);
        final url = 'https://example.com/file4.zip';

        // 1. Initial download start
        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 20,
            url: url,
            suggestedName: 'file4.zip',
            contentDisposition: '',
            mimeType: 'application/zip',
            totalBytes: 500,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final originalId = repository.getAllDownloads().first.id;

        // 2. Fail 1
        bloc.add(
          DownloadUpdatedEvent(
            controller: mockController,
            downloadId: 20,
            url: url,
            fullPath: '${tempDir.path}/file4.zip',
            receivedBytes: 100,
            totalBytes: 500,
            currentSpeed: 0,
            percentComplete: 20,
            isInProgress: false,
            isComplete: false,
            isCanceled: false,
            isInterrupted: true,
            interruptReason: 20,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // 3. Retry 1
        bloc.add(
          DownloadRetryRequested(
            bloc.state.downloads.first,
            controller: mockController,
          ),
        );
        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 21,
            url: url,
            suggestedName: 'file4.zip',
            contentDisposition: '',
            mimeType: 'application/zip',
            totalBytes: 500,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // 4. Fail 2
        bloc.add(
          DownloadUpdatedEvent(
            controller: mockController,
            downloadId: 21,
            url: url,
            fullPath: '${tempDir.path}/file4.zip',
            receivedBytes: 250,
            totalBytes: 500,
            currentSpeed: 0,
            percentComplete: 50,
            isInProgress: false,
            isComplete: false,
            isCanceled: false,
            isInterrupted: true,
            interruptReason: 20,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // 5. Retry 2
        bloc.add(
          DownloadRetryRequested(
            bloc.state.downloads.first,
            controller: mockController,
          ),
        );
        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 22,
            url: url,
            suggestedName: 'file4.zip',
            contentDisposition: '',
            mimeType: 'application/zip',
            totalBytes: 500,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // 6. Complete
        bloc.add(
          DownloadUpdatedEvent(
            controller: mockController,
            downloadId: 22,
            url: url,
            fullPath: '${tempDir.path}/file4.zip',
            receivedBytes: 500,
            totalBytes: 500,
            currentSpeed: 1000,
            percentComplete: 100,
            isInProgress: false,
            isComplete: true,
            isCanceled: false,
            isInterrupted: false,
            interruptReason: 0,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final allRecords = repository.getAllDownloads();
        expect(
          allRecords.length,
          1,
          reason:
              'Must have exactly ONE ObjectBox record across full retry cycle',
        );
        expect(allRecords.first.id, originalId);
        expect(allRecords.first.statusIndex, DownloadStatus.completed.index);

        await bloc.close();
      },
    );

    test(
      'Test 5: Download -> interrupted -> Resume -> same ObjectBox ID',
      () async {
        final bloc = DownloadBloc(repository: repository);
        final url = 'https://example.com/file5.zip';

        // 1. Initial download
        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 30,
            url: url,
            suggestedName: 'file5.zip',
            contentDisposition: '',
            mimeType: 'application/zip',
            totalBytes: 300,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final originalId = repository.getAllDownloads().first.id;

        // 2. Interrupt
        bloc.add(
          DownloadUpdatedEvent(
            controller: mockController,
            downloadId: 30,
            url: url,
            fullPath: '${tempDir.path}/file5.zip',
            receivedBytes: 150,
            totalBytes: 300,
            currentSpeed: 0,
            percentComplete: 50,
            isInProgress: false,
            isComplete: false,
            isCanceled: false,
            isInterrupted: true,
            interruptReason: 10,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // 3. Resume
        bloc.add(
          DownloadResumeRequested(originalId, controller: mockController),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 31,
            url: url,
            suggestedName: 'file5.zip',
            contentDisposition: '',
            mimeType: 'application/zip',
            totalBytes: 300,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final allRecords = repository.getAllDownloads();
        expect(allRecords.length, 1);
        expect(
          allRecords.first.id,
          originalId,
          reason: 'Resume must reuse same ObjectBox ID',
        );

        await bloc.close();
      },
    );

    test(
      'Test 6: Download -> browser killed -> browser reopened -> existing downloading record becomes interrupted using SAME ID',
      () async {
        // Save an entity that was downloading when browser closed
        final entity = repository.downloadBox.put(
          BrowserDownload(
            downloadId: 40,
            url: 'https://example.com/file6.zip',
            filename: 'file6.zip',
            destinationPath: '${tempDir.path}/file6.zip',
            receivedBytes: 200,
            totalBytes: 1000,
            status: DownloadStatus.downloading,
            startTimestamp: DateTime.now(),
          ).toEntity(),
        );

        final originalId = entity;

        // Reopen browser -> Initialize DownloadBloc
        final bloc = DownloadBloc(repository: repository);
        bloc.add(const DownloadInitializeRequested());
        await Future.delayed(const Duration(milliseconds: 50));

        final allRecords = repository.getAllDownloads();
        expect(allRecords.length, 1);
        expect(
          allRecords.first.id,
          originalId,
          reason: 'Must preserve same ObjectBox ID upon browser restart',
        );
        expect(allRecords.first.statusIndex, DownloadStatus.interrupted.index);

        await bloc.close();
      },
    );

    test(
      'Test 7: Download same URL intentionally twice -> creates two separate history records',
      () async {
        final bloc = DownloadBloc(repository: repository);
        final url = 'https://example.com/file7.pdf';

        // Download 1
        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 50,
            url: url,
            suggestedName: 'file7.pdf',
            contentDisposition: '',
            mimeType: 'application/pdf',
            totalBytes: 400,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(
          DownloadUpdatedEvent(
            controller: mockController,
            downloadId: 50,
            url: url,
            fullPath: '${tempDir.path}/file7.pdf',
            receivedBytes: 400,
            totalBytes: 400,
            currentSpeed: 1000,
            percentComplete: 100,
            isInProgress: false,
            isComplete: true,
            isCanceled: false,
            isInterrupted: false,
            interruptReason: 0,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // User clicks download link a second time intentionally
        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 51,
            url: url,
            suggestedName: 'file7.pdf',
            contentDisposition: '',
            mimeType: 'application/pdf',
            totalBytes: 400,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final allRecords = repository.getAllDownloads();
        expect(
          allRecords.length,
          2,
          reason:
              'Two intentional downloads of the same URL should create two records',
        );
        expect(allRecords[0].id, isNot(equals(allRecords[1].id)));

        await bloc.close();
      },
    );

    test(
      'Test 8: File is manually deleted outside browser -> user removes history -> ObjectBox record should still be removed successfully',
      () async {
        final bloc = DownloadBloc(repository: repository);
        final filePath = '${tempDir.path}/file8.zip';

        // Start & complete download
        bloc.add(
          DownloadBeforeStarted(
            controller: mockController,
            downloadId: 60,
            url: 'https://example.com/file8.zip',
            suggestedName: 'file8.zip',
            contentDisposition: '',
            mimeType: 'application/zip',
            totalBytes: 100,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(
          DownloadUpdatedEvent(
            controller: mockController,
            downloadId: 60,
            url: 'https://example.com/file8.zip',
            fullPath: filePath,
            receivedBytes: 100,
            totalBytes: 100,
            currentSpeed: 1000,
            percentComplete: 100,
            isInProgress: false,
            isComplete: true,
            isCanceled: false,
            isInterrupted: false,
            interruptReason: 0,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final initialRecords = repository.getAllDownloads();
        expect(initialRecords.length, 1);
        final recordId = initialRecords.first.id;

        // Ensure physical file does NOT exist (e.g. manually deleted outside browser)
        final file = File(filePath);
        if (file.existsSync()) {
          file.deleteSync();
        }

        // Remove history & delete file
        bloc.add(DownloadRemoveRequested(recordId, deleteFile: true));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(
          repository.getAllDownloads().isEmpty,
          isTrue,
          reason:
              'ObjectBox history record must be removed even if physical file was missing',
        );

        await bloc.close();
      },
    );

    test(
      'Test 9: Initialization failure emits error state with descriptive errorType',
      () async {
        final failingRepo = FailingDownloadRepository();
        final bloc = DownloadBloc(repository: failingRepo);

        expect(bloc.state.hasError, isFalse);

        bloc.add(const DownloadInitializeRequested());
        await Future.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.hasError, isTrue);
        expect(bloc.state.errorType, DownloadErrorType.initializationFailed);

        await bloc.close();
      },
    );
  });
}

class FailingDownloadRepository extends Fake implements DownloadRepository {
  @override
  List<DownloadEntity> getAllDownloads() {
    throw Exception('Database corrupt or unreadable');
  }
}
