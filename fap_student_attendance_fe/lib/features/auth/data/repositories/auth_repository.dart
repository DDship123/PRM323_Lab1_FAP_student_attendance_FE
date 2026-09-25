import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';

/// Repository xử lý nghiệp vụ xác thực (Login, Register, Logout)
class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  /// Đăng nhập tài khoản
  Future<AuthResponseModel> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: request.toJson(),
      requiresAuth: false,
    );

    if (response.data == null) {
      throw ApiException(
        statusCode: 500,
        message: 'Dữ liệu phản hồi từ máy chủ không hợp lệ.',
      );
    }

    final authResponse = AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );

    // Lưu token và thông tin user vào bộ nhớ cục bộ
    await _tokenStorage.saveToken(authResponse.token);
    await _tokenStorage.saveUser(authResponse.user.toJson());

    return authResponse;
  }

  /// Đăng ký tài khoản mới
  Future<UserModel> register(RegisterRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      body: request.toJson(),
      requiresAuth: false,
    );

    if (response.data == null) {
      throw ApiException(
        statusCode: 500,
        message: 'Dữ liệu phản hồi từ máy chủ không hợp lệ.',
      );
    }

    return UserModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Lấy thông tin người dùng đang đăng nhập
  Future<UserModel?> getCurrentUser() async {
    final userJson = await _tokenStorage.getUser();
    if (userJson == null) return null;
    return UserModel.fromJson(userJson);
  }

  /// Cập nhật thông tin cá nhân: PUT /api/users/profile
  Future<UserModel> updateProfile({
    String? fullName,
    String? email,
    String? username,
  }) async {
    final body = <String, dynamic>{};
    if (username != null && username.trim().isNotEmpty) {
      body['username'] = username.trim();
    }
    if (fullName != null && fullName.trim().isNotEmpty) {
      body['fullName'] = fullName.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }

    final response = await _apiClient.put(
      ApiEndpoints.userProfile,
      body: body,
      requiresAuth: true,
    );

    if (response.data == null) {
      throw ApiException(
        statusCode: 500,
        message: 'Không nhận được dữ liệu phản hồi sau khi cập nhật thông tin.',
      );
    }

    final updated = UserModel.fromJson(response.data as Map<String, dynamic>);
    await _tokenStorage.saveUser(updated.toJson());
    return updated;
  }

  /// Đổi mật khẩu tài khoản: PUT /api/users/change-password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.put(
      ApiEndpoints.changePassword,
      body: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
      requiresAuth: true,
    );
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> logout() async {
    await _tokenStorage.clear();
  }
}
