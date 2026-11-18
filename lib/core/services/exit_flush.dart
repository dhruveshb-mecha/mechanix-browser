import 'package:flutter/services.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';

/// Channel the elinux runner uses to announce that the window has closed
/// (see `FlushDartBeforeExit` in elinux/runner/main.cc).
const exitChannel = BasicMessageChannel<Object?>(
  'com.mechanix.browser/lifecycle',
  StandardMessageCodec(),
);

/// Runs [flushers] when the runner announces exit, and replies once they
/// have finished. The runner keeps the engine alive until the reply (for at
/// most a few seconds), so data saved after a delay, like bookmarks, isn't
/// lost when the app closes.
///
/// The embedder sends no lifecycle event on exit, hence this channel.
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
