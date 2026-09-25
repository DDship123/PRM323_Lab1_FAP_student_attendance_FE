/// Danh sách các endpoint REST API của hệ thống Backend FAP Attendance
class ApiEndpoints {
  ApiEndpoints._();

  /// Base URL backend Spring Boot (tự động nhận diện host từ trình duyệt)
  static String get baseUrl {
    final host = Uri.base.host;
    if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
      return 'http://$host:8080';
    }
    return 'http://localhost:8080';
  }

  // ── Authentication ──
  static String get login => '$baseUrl/api/auth/login';
  static String get register => '$baseUrl/api/auth/register';

  // ── Users & Profile ──
  static String get userProfile => '$baseUrl/api/users/profile';
  static String get changePassword => '$baseUrl/api/users/change-password';
  static String get importUsersExcel => '$baseUrl/api/users/import-excel';

  // ── Lecturer Analytics / Stats ──
  static String get lecturerDashboardStats => '$baseUrl/api/lecturer/dashboard-stats';
  static String get lecturerStatsAlias => '$baseUrl/api/lecturer/stats';

  // ── Courses ──
  static String get courses => '$baseUrl/api/courses';
  static String get searchCourses => '$baseUrl/api/courses/search';
  static String get registerCourse => '$baseUrl/api/courses/register';
  static String get enrollCourseAlias => '$baseUrl/api/courses/enroll';
  static String get coursesMyCourses => '$baseUrl/api/courses/my-courses';
  static String courseDetail(String id) => '$baseUrl/api/courses/$id';
  static String importCourseStudents(String courseId) =>
      '$baseUrl/api/courses/$courseId/import-students';

  // ── Enrollments ──
  static String get enrollments => '$baseUrl/api/enrollments';
  static String get myCourses => '$baseUrl/api/enrollments/my-courses';
  static String studentsByCourse(String courseId) =>
      '$baseUrl/api/enrollments/course/$courseId';

  // ── Attendance Sessions ──
  static String get sessions => '$baseUrl/api/sessions';
  static String sessionDetail(String sessionId) =>
      '$baseUrl/api/sessions/$sessionId';
  static String sessionsByCourse(String courseId) =>
      '$baseUrl/api/sessions/course/$courseId';
  static String closeSession(String sessionId) =>
      '$baseUrl/api/sessions/$sessionId/close';
  static String currentToken(String sessionId) =>
      '$baseUrl/api/sessions/$sessionId/current-token';
  static String qrStream(String sessionId) =>
      '$baseUrl/api/sessions/$sessionId/qr-stream';

  // ── Attendance Records ──
  static String get checkIn => '$baseUrl/api/attendance/check-in';
  static String sessionAttendance(String sessionId) =>
      '$baseUrl/api/attendance/session/$sessionId';
  static String get myAttendanceHistory => '$baseUrl/api/attendance/my-history';
  static String exportCsv(String sessionId) =>
      '$baseUrl/api/attendance/export/$sessionId';
  static String exportExcel(String sessionId) =>
      '$baseUrl/api/attendance/export-excel/$sessionId';
}
