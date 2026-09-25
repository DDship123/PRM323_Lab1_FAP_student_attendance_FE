/// Model thống kê tổng quan dành cho Giảng viên: GET /api/lecturer/dashboard-stats
class LecturerDashboardStatsModel {
  final String lecturerId;
  final int totalCourses;
  final int totalRegisteredStudents;
  final int activeSemestersCount;
  final List<String> activeSemesters;
  final int totalSessions;
  final List<LecturerRecentCourseModel> recentCourses;

  const LecturerDashboardStatsModel({
    required this.lecturerId,
    required this.totalCourses,
    required this.totalRegisteredStudents,
    required this.activeSemestersCount,
    this.activeSemesters = const [],
    this.totalSessions = 0,
    this.recentCourses = const [],
  });

  factory LecturerDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final recentRaw = json['recentCourses'];
    List<LecturerRecentCourseModel> recentList = [];
    if (recentRaw is List) {
      recentList = recentRaw
          .map((e) => LecturerRecentCourseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final semestersRaw = json['activeSemesters'];
    List<String> semList = [];
    if (semestersRaw is List) {
      semList = semestersRaw.map((e) => e.toString()).toList();
    }

    return LecturerDashboardStatsModel(
      lecturerId: json['lecturerId']?.toString() ?? '',
      totalCourses: (json['totalCourses'] as num?)?.toInt() ?? 0,
      totalRegisteredStudents: (json['totalRegisteredStudents'] as num?)?.toInt() ?? 0,
      activeSemestersCount: (json['activeSemestersCount'] as num?)?.toInt() ?? semList.length,
      activeSemesters: semList,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      recentCourses: recentList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lecturerId': lecturerId,
      'totalCourses': totalCourses,
      'totalRegisteredStudents': totalRegisteredStudents,
      'activeSemestersCount': activeSemestersCount,
      'activeSemesters': activeSemesters,
      'totalSessions': totalSessions,
      'recentCourses': recentCourses.map((e) => e.toJson()).toList(),
    };
  }
}

/// Khóa học gần đây trong thống kê giảng viên
class LecturerRecentCourseModel {
  final String courseId;
  final String subjectCode;
  final String className;
  final String semester;
  final int studentCount;

  const LecturerRecentCourseModel({
    required this.courseId,
    required this.subjectCode,
    required this.className,
    required this.semester,
    this.studentCount = 0,
  });

  factory LecturerRecentCourseModel.fromJson(Map<String, dynamic> json) {
    return LecturerRecentCourseModel(
      courseId: json['courseId']?.toString() ?? '',
      subjectCode: json['subjectCode']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'subjectCode': subjectCode,
      'className': className,
      'semester': semester,
      'studentCount': studentCount,
    };
  }
}
