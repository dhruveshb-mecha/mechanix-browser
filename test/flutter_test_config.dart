import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef _DlopenC = Pointer<Void> Function(Pointer<Utf8>, Int32);
typedef _DlopenDart = Pointer<Void> Function(Pointer<Utf8>, int);

const _rtldNow = 0x2;
const _rtldGlobal = 0x100;

/// Runs before every test file in this directory.
///
/// The app resolves SQLite symbols from the process (sqlite3 `source: process`
/// in pubspec.yaml; the elinux runner links libsqlite3.so.0). flutter_tester
/// doesn't link SQLite, so load the system library into the global symbol
/// scope here, or drift fails with "undefined symbol: sqlite3_initialize".
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final dlopen = DynamicLibrary.process().lookupFunction<_DlopenC, _DlopenDart>(
    'dlopen',
  );
  final name = 'libsqlite3.so.0'.toNativeUtf8();
  try {
    if (dlopen(name, _rtldNow | _rtldGlobal) == nullptr) {
      throw StateError(
        'libsqlite3.so.0 not found; install libsqlite3-0 (or sqlite-libs).',
      );
    }
  } finally {
    malloc.free(name);
  }
  await testMain();
}
