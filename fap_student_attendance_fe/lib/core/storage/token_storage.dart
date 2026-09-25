import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý lưu trữ cục bộ cho JWT Token và thông tin phiên đăng nhập
class TokenStorage {
  static const String _keyToken = 'auth_jwt_token';
  static const String _keyUser = 'auth_user_data';
  static const String _keyDeviceId = 'app_device_id';

  // Singleton instance
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  /// Lấy hoặc sinh mã định danh thiết bị duy nhất (UUID v4) lưu trong SharedPreferences
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_keyDeviceId);
    if (deviceId == null || deviceId.trim().isEmpty) {
      deviceId = _generateUuidV4();
      await prefs.setString(_keyDeviceId, deviceId);
    }
    return deviceId;
  }

  /// Sinh UUID v4 theo chuẩn RFC-4122
  static String _generateUuidV4() {
    final random = DateTime.now().microsecondsSinceEpoch;
    final randExtra = (random ^ 0x5DEECE66D).abs();
    // Tạo 32 ký tự hex
    final hexChars = '0123456789abcdef';
    final sb = StringBuffer();
    for (int i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        sb.write('-');
      }
      if (i == 12) {
        sb.write('4'); // UUID version 4
      } else if (i == 16) {
        // Variant: 8, 9, a, or b
        final r = (randExtra >> (i % 16)) & 0x03 | 0x08;
        sb.write(hexChars[r]);
      } else {
        final r = ((random >> ((i * 3) % 24)) ^ (randExtra >> ((i * 5) % 24))) & 0x0f;
        sb.write(hexChars[r]);
      }
    }
    return sb.toString();
  }

  /// Lưu JWT Token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  /// Lấy JWT Token đã lưu
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Lưu thông tin User
  Future<void> saveUser(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(userJson));
  }

  /// Lấy thông tin User đã lưu
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Kiểm tra xem người dùng đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Xóa sạch dữ liệu phiên (Đăng xuất)
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
