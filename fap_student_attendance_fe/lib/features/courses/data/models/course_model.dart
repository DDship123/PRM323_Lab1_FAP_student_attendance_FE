export 'lecturer_dashboard_stats_model.dart';

/// Model đại diện cho một khóa học / lớp học phần từ Backend
class CourseModel {
  final String courseId;
  final String subjectCode;
  final String className;
  final String semester;
  final String? lecturerId;
  final String? lecturerName;
  final String? createdAt;

  const CourseModel({
    required this.courseId,
    required this.subjectCode,
    required this.className,
    required this.semester,
    this.lecturerId,
    this.lecturerName,
    this.createdAt,
  });

  String get id => courseId;
  String get displayName => '$subjectCode · $className';
  String get lecturerDisplay => lecturerName ?? lecturerId ?? 'Chưa phân công';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseModel && other.courseId == courseId;

  @override
  int get hashCode => courseId.hashCode;

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      courseId: json['courseId'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      className: json['className'] as String? ?? '',
      semester: json['semester'] as String? ?? '',
      lecturerId: json['lecturerId'] as String?,
      lecturerName: json['lecturerName'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'subjectCode': subjectCode,
      'className': className,
      'semester': semester,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'createdAt': createdAt,
    };
  }
}

/// DTO gửi lên để tạo khóa học mới: POST /api/courses
class CourseCreateRequest {
  final String subjectCode;
  final String className;
  final String semester;
  final String? lecturerId;
  final String password;

  const CourseCreateRequest({
    required this.subjectCode,
    required this.className,
    required this.semester,
    this.lecturerId,
    this.password = '',
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'subjectCode': subjectCode.trim(),
      'className': className.trim(),
      'semester': semester.trim(),
      'password': password.trim(),
      'coursePassword': password.trim(),
    };
    if (lecturerId != null && lecturerId!.isNotEmpty) {
      map['lecturerId'] = lecturerId;
    }
    return map;
  }
}

/// DTO gửi lên để học sinh đăng ký khóa học: POST /api/courses/register (Mục 2.7)
class CourseRegisterRequest {
  final String courseId;
  final String userId;
  final String? coursePassword;

  const CourseRegisterRequest({
    required this.courseId,
    required this.userId,
    this.coursePassword,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'courseId': courseId.trim(),
      'userId': userId.trim(),
      // Bổ sung studentId alias cho tính tương thích tối đa với backend
      'studentId': userId.trim(),
    };
    if (coursePassword != null && coursePassword!.trim().isNotEmpty) {
      map['coursePassword'] = coursePassword!.trim();
      map['password'] = coursePassword!.trim();
    }
    return map;
  }
}

/// DTO gửi lên để cập nhật khóa học: PUT /api/courses/{id} (Mục 2.4)
class CourseUpdateRequest {
  final String subjectCode;
  final String className;
  final String semester;
  final String? lecturerId;
  final String? password;

  const CourseUpdateRequest({
    required this.subjectCode,
    required this.className,
    required this.semester,
    this.lecturerId,
    this.password,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'subjectCode': subjectCode.trim(),
      'className': className.trim(),
      'semester': semester.trim(),
    };
    if (password != null && password!.trim().isNotEmpty) {
      map['password'] = password!.trim();
      map['coursePassword'] = password!.trim();
    }
    if (lecturerId != null && lecturerId!.isNotEmpty) {
      map['lecturerId'] = lecturerId;
    }
    return map;
  }
}
