import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Configures Web options natively so flutter_secure_storage works in browsers without crashing
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'boro_secure_store',
      publicKey: 'boro_public_key',
    ),
  );

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'access_token');
  }
}