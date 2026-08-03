import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  
  // Fallback in-memory token for macOS debug when keychain fails
  static String? _memoryToken;

  static Future<void> saveToken(String token) async {
    _memoryToken = token;
    try {
      await _storage.write(key: 'jwt_token', value: token);
    } catch (e) {
      debugPrint('Secure storage write error (using memory fallback): $e');
    }
  }

  static Future<String?> getToken() async {
    if (_memoryToken != null && _memoryToken!.isNotEmpty) {
      return _memoryToken;
    }
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) _memoryToken = token;
      return token;
    } catch (e) {
      debugPrint('Secure storage read error: $e');
      return _memoryToken;
    }
  }

  static Future<void> clearToken() async {
    _memoryToken = null;
    try {
      await _storage.delete(key: 'jwt_token');
    } catch (e) {
      debugPrint('Secure storage delete error: $e');
    }
  }

  static Future<void> deleteToken() async {
    await clearToken();
  }
}