import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/models/attendance_models.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../courses/data/repositories/course_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Controller quản lý nghiệp vụ điểm danh và lớp học dành cho Sinh viên
class StudentAttendanceController extends ChangeNotifier {
  final AttendanceRepository _repository = AttendanceRepository();
  final CourseRepository _courseRepository = CourseRepository();

  static final StudentAttendanceController _instance =
      StudentAttendanceController._internal();
  factory StudentAttendanceController() => _instance;
  StudentAttendanceController._internal();

  List<EnrollmentModel> _enrollments = [];
  bool _isLoading = false;
  String? _errorMessage;
  AttendanceRecordModel? _lastCheckInRecord;

  // ── Tìm kiếm khóa học ──
  List<CourseModel> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  List<AttendanceHistoryItemModel> _attendanceHistory = [];
  List<CourseModel> _myCourses = [];

  int? _lastStatusCode;

  List<EnrollmentModel> get enrollments => _enrollments;
  List<AttendanceHistoryItemModel> get attendanceHistory => _attendanceHistory;
  List<CourseModel> get myCourses => _myCourses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get lastStatusCode => _lastStatusCode;
  AttendanceRecordModel? get lastCheckInRecord => _lastCheckInRecord;

  List<CourseModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;

  /// Kiểm tra xem sinh viên đã ghi danh vào môn học này chưa
  bool isCourseEnrolled(String courseId) {
    return _enrollments.any((e) => e.courseId == courseId) ||
        _myCourses.any((c) => c.courseId == courseId);
  }

  /// Tải danh sách các khóa học sinh viên đã tham gia: GET /api/courses/my-courses
  Future<void> loadEnrollments({
    String? subjectCode,
    String? semester,
    String? lecturerName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final courses = await _courseRepository.getMyCourses(
        subjectCode: subjectCode,
        semester: semester,
        lecturerName: lecturerName,
      );
      _myCourses = courses;

      _enrollments = await _repository.getMyEnrollments();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải lịch sử điểm danh của sinh viên: GET /api/attendance/my-history
  Future<void> loadAttendanceHistory({String? courseId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _attendanceHistory = await _repository.getMyAttendanceHistory(courseId: courseId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sinh viên điểm danh qua Dynamic QR Token (TOTP), QR Code hoặc mã PIN (sessionCode)
  Future<AttendanceRecordModel?> checkIn({
    String? sessionId,
    String? qrToken,
    String? qrCodeSecret,
    String? sessionCode,
    String? bssid,
    String? deviceId,
    String? clientIp,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _lastStatusCode = null;
    notifyListeners();

    try {
      // Tự động lấy Device ID phần cứng duy nhất đã lưu trong SharedPreferences nếu chưa có
      final effectiveDeviceId = (deviceId != null && deviceId.trim().isNotEmpty)
          ? deviceId.trim()
          : await TokenStorage().getDeviceId();

      final record = await _repository.checkIn(
        CheckInRequest(
          sessionId: sessionId,
          qrToken: qrToken,
          qrCodeSecret: qrCodeSecret,
          sessionCode: sessionCode,
          bssid: bssid,
          deviceId: effectiveDeviceId,
          clientIp: clientIp,
          latitude: latitude,
          longitude: longitude,
        ),
      );

      _lastCheckInRecord = record;
      _isLoading = false;
      notifyListeners();
      return record;
    } catch (e) {
      if (e is ApiException) {
        _errorMessage = e.message;
        _lastStatusCode = e.statusCode;
      } else {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Điểm danh bằng mã PIN 6 số của phiên điểm danh
  Future<AttendanceRecordModel?> checkInByPin({
    required String sessionCode,
    String? bssid,
    String? deviceId,
    String? clientIp,
    double? latitude,
    double? longitude,
  }) async {
    return checkIn(
      sessionCode: sessionCode.trim(),
      bssid: bssid,
      deviceId: deviceId,
      clientIp: clientIp,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Tìm kiếm môn học: GET /api/courses/search (Mục 2.6)
  Future<List<CourseModel>> searchCourses({
    String? className,
    String? subjectCode,
    String? semester,
    String? lecturerName,
  }) async {
    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      _searchResults = await _courseRepository.searchCourses(
        className: className,
        subjectCode: subjectCode,
        semester: semester,
        lecturerName: lecturerName,
      );
      _isSearching = false;
      notifyListeners();
      return _searchResults;
    } catch (e) {
      _searchError = e.toString();
      _isSearching = false;
      notifyListeners();
      return [];
    }
  }

  /// Học sinh đăng ký khóa học: POST /api/courses/register (Mục 2.7)
  Future<bool> registerCourseForStudent({
    required String courseId,
    String? coursePassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = AuthController().currentUser;
    final userId = user?.userId.isNotEmpty == true
        ? user!.userId
        : (user?.username.isNotEmpty == true ? user!.username : 'STUDENT');

    try {
      await _courseRepository.registerCourse(
        CourseRegisterRequest(
          courseId: courseId,
          userId: userId,
          coursePassword: coursePassword,
        ),
      );

      // Tải lại danh sách môn học ngay sau khi đăng ký thành công
      await loadEnrollments();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đăng ký vào môn học qua enrollment controller: POST /api/enrollments
  Future<bool> enrollCourse(String courseId) async {
    return registerCourseForStudent(courseId: courseId);
  }

  void clearLastCheckIn() {
    _lastCheckInRecord = null;
    notifyListeners();
  }
}
