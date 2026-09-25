import 'user_model.dart';

/// Request body cho API đăng nhập POST /api/auth/login
class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username.trim(),
      'password': password,
    };
  }
}

/// Request body cho API đăng ký POST /api/auth/register
class RegisterRequest {
  final String username;
  final String password;
  final String email;
  final String fullName;
  final String roleId;
  final String? fapCode;

  const RegisterRequest({
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
    required this.roleId,
    this.fapCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'username': username.trim(),
      'password': password,
      'email': email.trim(),
      'fullName': fullName.trim(),
      'roleId': roleId,
    };
    if (fapCode != null && fapCode!.trim().isNotEmpty) {
      map['fapCode'] = fapCode!.trim().toUpperCase();
    }
    return map;
  }
}

/// Response data từ API đăng nhập thành công
class AuthResponseModel {
  final String token;
  final String tokenType;
  final UserModel user;

  const AuthResponseModel({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}
