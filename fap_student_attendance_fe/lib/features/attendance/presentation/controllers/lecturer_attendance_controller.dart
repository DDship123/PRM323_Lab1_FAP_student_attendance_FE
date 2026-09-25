import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../courses/data/repositories/course_repository.dart';
import '../../../schedule/data/models/session_model.dart';
import '../../../schedule/data/repositories/session_repository.dart';
import '../../data/models/attendance_models.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Trạng thái tổng hợp điểm danh của sinh viên (kết hợp enrollment + record)
class StudentAttendanceStatus {
  final String studentId;
  final String? studentName;
  final String? fapCode;
  final bool isPresent;
  final String? checkedAt;

  const StudentAttendanceStatus({
    required this.studentId,
    this.studentName,
    this.fapCode,
    required this.isPresent,
    this.checkedAt,
  });
}

/// Controller quản lý flow: Courses → Sessions → Attendance Records
class LecturerAttendanceController extends ChangeNotifier {
  final CourseRepository _courseRepo = CourseRepository();
  final SessionRepository _sessionRepo = SessionRepository();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();

  // ── State ──
  bool _isLoading = false;
  String? _error;

  List<CourseModel> _courses = [];
  CourseModel? _selectedCourse;

  List<AttendanceSessionModel> _sessions = [];
  AttendanceSessionModel? _selectedSession;

  List<StudentAttendanceStatus> _studentStatuses = [];
  int _presentCount = 0;
  int _absentCount = 0;

  // ── Getters ──
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CourseModel> get courses => _courses;
  CourseModel? get selectedCourse => _selectedCourse;

  List<AttendanceSessionModel> get sessions => _sessions;
  AttendanceSessionModel? get selectedSession => _selectedSession;

  List<StudentAttendanceStatus> get studentStatuses => _studentStatuses;
  int get presentCount => _presentCount;
  int get absentCount => _absentCount;
  int get totalStudents => _studentStatuses.length;

  // ── Step 1: Load courses of current lecturer ──
  Future<void> loadLecturerCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = AuthController().currentUser;
      final lecturerId = user?.userId;
      _courses = await _courseRepo.getCourses(lecturerId: lecturerId);
      _selectedCourse = null;
      _sessions = [];
      _selectedSession = null;
      _studentStatuses = [];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Không thể tải danh sách khóa học: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Step 2: Select a course and load its sessions ──
  Future<void> selectCourse(CourseModel course) async {
    _selectedCourse = course;
    _selectedSession = null;
    _studentStatuses = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _sessionRepo.getSessionsByCourse(course.courseId);
      // Sort by createdAt descending (newest first)
      _sessions.sort((a, b) {
        final aDate = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(2000);
        final bDate = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Không thể tải danh sách phiên điểm danh: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Step 3: Select a session and load attendance detail ──
  Future<void> selectSession(AttendanceSessionModel session) async {
    _selectedSession = session;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch attendance records (students who checked in)
      final records = await _attendanceRepo.getSessionRecords(session.sessionId);

      // Fetch all enrolled students for this course
      List<EnrollmentModel> enrollments = [];
      try {
        enrollments = await _attendanceRepo.getStudentsByCourse(
          _selectedCourse?.courseId ?? session.courseId,
        );
      } catch (_) {
        // If enrollment endpoint fails, just show records only
      }

      // Build combined status list
      final recordMap = <String, AttendanceRecordModel>{};
      for (final r in records) {
        recordMap[r.studentId] = r;
      }

      final statuses = <StudentAttendanceStatus>[];
      final processedIds = <String>{};

      // First: add all enrolled students
      for (final e in enrollments) {
        processedIds.add(e.studentId);
        final record = recordMap[e.studentId];
        statuses.add(StudentAttendanceStatus(
          studentId: e.studentId,
          studentName: record?.studentName ?? e.studentName,
          fapCode: record?.studentFapCode ?? e.fapCode,
          isPresent: record != null,
          checkedAt: record?.checkedAt,
        ));
      }

      // Then: add any records not in enrollment (edge case)
      for (final r in records) {
        if (!processedIds.contains(r.studentId)) {
          statuses.add(StudentAttendanceStatus(
            studentId: r.studentId,
            studentName: r.studentName,
            fapCode: r.studentFapCode,
            isPresent: true,
            checkedAt: r.checkedAt,
          ));
        }
      }

      // Sort: Present first, then by name
      statuses.sort((a, b) {
        if (a.isPresent != b.isPresent) return a.isPresent ? -1 : 1;
        return (a.studentName ?? '').compareTo(b.studentName ?? '');
      });

      _studentStatuses = statuses;
      _presentCount = statuses.where((s) => s.isPresent).length;
      _absentCount = statuses.where((s) => !s.isPresent).length;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Không thể tải danh sách điểm danh: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Navigation helpers ──
  void goBackToCourses() {
    _selectedCourse = null;
    _selectedSession = null;
    _sessions = [];
    _studentStatuses = [];
    _error = null;
    notifyListeners();
  }

  void goBackToSessions() {
    _selectedSession = null;
    _studentStatuses = [];
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
