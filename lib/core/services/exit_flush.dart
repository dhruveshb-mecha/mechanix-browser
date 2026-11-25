import 'package:flutter/services.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';

/// Channel on which the elinux runner can announce that the window has
/// closed, by sending 'exit' and waiting for the reply.
const exitChannel = BasicMessageChannel<Object?>(
  'com.mechanix.browser/lifecycle',
  StandardMessageCodec(),
);

/// Runs [flushers] when the runner announces exit, and replies once they
/// have finished, so writes still in progress aren't cut off.
///
/// The embedder sends no lifecycle event on exit, hence this channel. The
/// current runner doesn't send `exit` yet, so this is a no-op until it does;
/// nothing depends on it (bookmarks are saved right away).
void flushOnExit(List<Future<void> Function()> flushers) {
  exitChannel.setMessageHandler((message) async {
    if (message != 'exit') return null;
    await Future.wait([
      for (final flush in flushers)
        flush().catchError((Object e, StackTrace stack) {
          AppLogger.e('Error saving before exit', error: e, stack: stack);
        }),
    ]);
    AppLogger.i('Saved pending data before exit');
    return null;
  });
}
