import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/auth_desktop.dart';
import '../features/courses/presentation/screens/create_course_screen.dart';
import '../features/courses/presentation/screens/import_students_screen.dart';
import '../features/courses/presentation/screens/lecturer_dashboard_screen.dart';
import '../features/courses/presentation/screens/lecturer_courses_screen.dart';
import '../features/schedule/presentation/screens/create_session_screen.dart';
import '../features/attendance/presentation/screens/attendance_live_screen.dart';
import '../features/attendance/presentation/screens/lecturer_attendance_management_screen.dart';
import '../features/attendance/presentation/screens/attendance_results_screen.dart';
import '../features/attendance/presentation/screens/qr_scanner_screen.dart';
import '../features/attendance/presentation/screens/student_check_in_screen.dart';
import '../features/attendance/presentation/screens/attendance_result_screen.dart';
import '../features/student/presentation/screens/student_dashboard_screen.dart';
import '../features/student/presentation/screens/student_courses_search_screen.dart';
import '../features/student/presentation/screens/student_attendance_history_screen.dart';

/// Router cấu hình cho Attendly — hỗ trợ cả Giảng viên và Sinh viên
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // ── Auth ──
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthDesktopScreen(),
    ),

    // ── Giảng viên: Tổng quan & Môn học ──
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const LecturerDashboardScreen(),
    ),
    GoRoute(
      path: '/courses',
      builder: (context, state) => const LecturerCoursesScreen(),
    ),
    GoRoute(
      path: '/courses/create',
      builder: (context, state) => const CreateCourseScreen(),
    ),
    GoRoute(
      path: '/courses/import',
      builder: (context, state) => const ImportStudentsScreen(),
    ),

    // ── Giảng viên: Lịch học & Điểm danh ──
    GoRoute(
      path: '/schedule/create',
      builder: (context, state) => const CreateSessionScreen(),
    ),
    GoRoute(
      path: '/attendance/manage',
      builder: (context, state) => const LecturerAttendanceManagementScreen(),
    ),
    GoRoute(
      path: '/attendance/live',
      builder: (context, state) => const AttendanceLiveScreen(),
    ),
    GoRoute(
      path: '/attendance/results',
      builder: (context, state) => const AttendanceResultsScreen(),
    ),

    // ── Sinh viên ──
    GoRoute(
      path: '/student/dashboard',
      builder: (context, state) => const StudentDashboardScreen(),
    ),
    GoRoute(
      path: '/student/courses',
      builder: (context, state) => const StudentCoursesSearchScreen(),
    ),
    GoRoute(
      path: '/student/check-in',
      builder: (context, state) => const StudentCheckInScreen(),
    ),
    GoRoute(
      path: '/student/result',
      builder: (context, state) => const AttendanceResultScreen(),
    ),
    GoRoute(
      path: '/student/scan',
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/student/history',
      builder: (context, state) => const StudentAttendanceHistoryScreen(),
    ),
    GoRoute(
      path: '/student/success',
      builder: (context, state) => const AttendanceResultScreen(),
    ),
  ],
);

