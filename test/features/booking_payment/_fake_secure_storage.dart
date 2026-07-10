// In-memory implementation của FlutterSecureStorage cho unit test.
//
// API của `flutter_secure_storage` phiên bản 10.x gộp iOS/MacOS
// dưới tên `AppleOptions` nhưng vẫn giữ 2 tên tham số `iOptions` và
// `mOptions` để tương thích ngược. Fake này chỉ cần ký đúng tên tham số
// — không cần gọi platform channel.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
