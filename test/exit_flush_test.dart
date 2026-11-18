import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/core/services/exit_flush.dart';
import 'package:mechanix_browser/features/browser/data/bookmarks/bookmark_model.dart';

/// Sends [message] on the exit channel as the runner does, and completes
/// when the app replies.
Future<void> sendFromRunner(Object? message) {
  final replied = Completer<void>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        exitChannel.name,
        exitChannel.codec.encodeMessage(message),
        (_) => replied.complete(),
      );
  return replied.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => exitChannel.setMessageHandler(null));

  test('replies only after every flusher has finished', () async {
    final done = <String>[];
    flushOnExit([
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        done.add('slow');
      },
      () async => done.add('fast'),
      () async => throw StateError('one failing flusher'),
    ]);

    await sendFromRunner('exit');
    expect(done, unorderedEquals(['slow', 'fast']));
  });

  test('other messages are answered without flushing', () async {
    var flushed = false;
    flushOnExit([() async => flushed = true]);
    await sendFromRunner('something else');
    expect(flushed, isFalse);
  });

  test('a bookmark added just before exit reaches the file', () async {
    final dir = Directory.systemTemp.createTempSync('exit_flush_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/Bookmarks');
    final model = await BookmarkModel.load(file); // 2.5 s save delay

    flushOnExit([model.flush]);
    model.addUrl(model.bookmarkBar, title: 'Fav', url: 'https://fav/');
    expect(file.existsSync(), isFalse);

    await sendFromRunner('exit');
    expect(file.readAsStringSync(), contains('https://fav/'));
  });
}
