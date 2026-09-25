/// Model đại diện cho thông tin người dùng từ Backend Spring Boot
class UserModel {
  final String userId;
  final String username;
  final String? fapCode;
  final String fullName;
  final String email;
  final String roleId;
  final String? createdAt;
  final String? memberCode;

  const UserModel({
    required this.userId,
    required this.username,
    this.fapCode,
    required this.fullName,
    required this.email,
    required this.roleId,
    this.createdAt,
    this.memberCode,
  });

  bool get isLecturer {
    final r = roleId.toUpperCase();
    return r == 'LECTURER' || r == 'ROLE_LECTURER' || r.contains('LECTURER');
  }

  bool get isStudent {
    final r = roleId.toUpperCase();
    return r == 'STUDENT' || r == 'ROLE_STUDENT' || r.contains('STUDENT');
  }

  bool get isAdmin {
    final r = roleId.toUpperCase();
    return r == 'ADMIN' || r == 'ROLE_ADMIN' || r.contains('ADMIN');
  }

  String get roleDisplay {
    if (isAdmin) return 'Quản trị viên';
    if (isLecturer) return 'Giảng viên';
    if (isStudent) return 'Sinh viên';
    return roleId;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Backend có thể trả roleId, role, hoặc roleName
    final roleRaw = json['roleId'] ?? json['role'] ?? json['roleName'] ?? 'STUDENT';
    return UserModel(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fapCode: json['fapCode'] as String?,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roleId: roleRaw.toString(),
      createdAt: json['createdAt'] as String?,
      memberCode: json['memberCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'fapCode': fapCode,
      'fullName': fullName,
      'email': email,
      'roleId': roleId,
      'createdAt': createdAt,
      'memberCode': memberCode,
    };
  }
}
