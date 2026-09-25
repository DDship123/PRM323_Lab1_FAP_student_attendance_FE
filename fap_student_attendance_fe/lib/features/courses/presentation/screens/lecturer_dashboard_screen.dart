import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../attendance/data/models/attendance_models.dart';
import '../../../attendance/data/repositories/attendance_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository.dart';
import '../widgets/course_students_dialog.dart';
import '../widgets/edit_course_dialog.dart';

/// Trang tổng quát (Dashboard) dành cho Giảng viên
class LecturerDashboardScreen extends StatefulWidget {
  const LecturerDashboardScreen({super.key});

  @override
  State<LecturerDashboardScreen> createState() => _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends State<LecturerDashboardScreen> {
  final CourseRepository _courseRepo = CourseRepository();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final AuthController _authController = AuthController();

  LecturerDashboardStatsModel? _stats;
  List<CourseModel> _courses = [];
  final Map<String, int> _courseStudentCounts = {};
  int _totalRegisteredStudents = 0;
  int _uniqueStudentsCount = 0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _authController.currentUser;

      // 1. Tải số liệu thống kê tổng hợp từ GET /api/lecturer/dashboard-stats
      LecturerDashboardStatsModel? stats;
      try {
        stats = await _courseRepo.getLecturerDashboardStats(
          lecturerId: user?.isLecturer == true ? null : user?.userId,
        );
      } catch (e) {
        debugPrint('getLecturerDashboardStats error: $e');
      }

      // 2. Tải danh sách khóa học của giảng viên (ưu tiên GET /api/courses/my-courses nay đã mở cho LECTURER)
      List<CourseModel> courses = [];
      try {
        courses = await _courseRepo.getMyCourses();
      } catch (_) {
        try {
          if (user != null && user.userId.isNotEmpty) {
            courses = await _courseRepo.getCourses(lecturerId: user.userId);
          }
        } catch (_) {}
      }

      if (courses.isEmpty) {
        final allCourses = await _courseRepo.getCourses();
        if (user != null && (user.userId.isNotEmpty || user.fullName.isNotEmpty)) {
          final filtered = allCourses.where((c) {
            final matchId = user.userId.isNotEmpty && c.lecturerId == user.userId;
            final matchName = user.fullName.isNotEmpty && (c.lecturerName?.toLowerCase() == user.fullName.toLowerCase());
            final matchUsername = user.username.isNotEmpty && (c.lecturerName?.toLowerCase().contains(user.username.toLowerCase()) ?? false);
            return matchId || matchName || matchUsername;
          }).toList();
          courses = filtered.isNotEmpty ? filtered : allCourses;
        } else {
          courses = allCourses;
        }
      }

      int totalCount = stats?.totalRegisteredStudents ?? 0;
      final Set<String> uniqueStudentIds = {};
      final Map<String, int> counts = {};

      // Ánh xạ trước studentCount từ recentCourses trong stats (nếu backend trả về)
      if (stats != null && stats.recentCourses.isNotEmpty) {
        for (final rc in stats.recentCourses) {
          counts[rc.courseId] = rc.studentCount;
        }
      }

      // Với các khóa học chưa có sĩ số từ stats, gọi an toàn getStudentsByCourse
      for (final course in courses) {
        if (!counts.containsKey(course.courseId)) {
          try {
            final List<EnrollmentModel> students = await _attendanceRepo.getStudentsByCourse(course.courseId);
            counts[course.courseId] = students.length;
            if (stats == null) {
              totalCount += students.length;
            }
            for (final s in students) {
              final key = s.fapCode ?? s.studentId;
              if (key.isNotEmpty) {
                uniqueStudentIds.add(key);
              }
            }
          } catch (_) {
            counts[course.courseId] = 0;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _courses = courses;
        _courseStudentCounts.addAll(counts);
        _totalRegisteredStudents = stats?.totalRegisteredStudents ?? totalCount;
        _uniqueStudentsCount = uniqueStudentIds.isNotEmpty ? uniqueStudentIds.length : _totalRegisteredStudents;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu tổng quan: ${e.toString().replaceFirst("Exception: ", "")}';
      });
    }
  }

  int get _activeSemestersCount {
    if (_stats != null && _stats!.activeSemestersCount > 0) {
      return _stats!.activeSemestersCount;
    }
    final set = _courses
        .map((c) => c.semester.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    return set.length;
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.currentUser;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return DesktopScaffold(
      selectedIndex: 0, // Tổng quan
      role: UserRole.lecturer,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, user, isMobile),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              _buildErrorBanner()
            else ...[
              _buildStatsRow(isMobile),
              const SizedBox(height: 28),
              _buildQuickActions(context, isMobile),
              const SizedBox(height: 28),
              _buildCourseSummarySection(context, isMobile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CỔNG GIẢNG VIÊN · TRANG TỔNG QUAN',
                style: AppTextStyles.breadcrumb,
              ),
              const SizedBox(height: 8),
              Text(
                'Tổng quan đào tạo & giảng dạy',
                style: isMobile ? AppTextStyles.h2 : AppTextStyles.h1,
              ),
              const SizedBox(height: 4),
              Text(
                'Xin chào, ${user?.fullName ?? "Giảng viên"}! Dưới đây là thống kê tổng quát về các môn học và số sinh viên đã đăng ký.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại dữ liệu',
              onPressed: _loadDashboardData,
            ),
            const SizedBox(width: 8),
            PrimaryButton(
              text: 'Tạo môn học',
              icon: Icons.add,
              onPressed: () => context.go('/courses/create'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: _loadDashboardData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // ── Thẻ thống kê: Lớp học phần phụ trách, Tổng sinh viên đã đăng ký, Học kỳ hoạt động ──
  Widget _buildStatsRow(bool isMobile) {
    final displayCoursesCount = _stats?.totalCourses ?? _courses.length;
    final displaySemesterSubtitle = (_stats != null && _stats!.activeSemesters.isNotEmpty)
        ? _stats!.activeSemesters.join(' · ')
        : 'Các kỳ học có lịch giảng dạy';

    final cards = [
      _buildStatCard(
        value: '$displayCoursesCount',
        label: 'Lớp học phần phụ trách',
        subtitle: 'Các lớp đang phân công giảng dạy',
        icon: Icons.menu_book_outlined,
        color: AppColors.accent,
      ),
      _buildStatCard(
        value: '$_totalRegisteredStudents',
        label: 'Tổng sinh viên đã đăng ký',
        subtitle: '$_uniqueStudentsCount sinh viên trong các lớp',
        icon: Icons.groups_outlined,
        color: const Color(0xFF06B6D4),
      ),
      _buildStatCard(
        value: '$_activeSemestersCount',
        label: 'Học kỳ hoạt động',
        subtitle: displaySemesterSubtitle,
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFF059669),
      ),
      if (_stats != null && _stats!.totalSessions > 0)
        _buildStatCard(
          value: '${_stats!.totalSessions}',
          label: 'Buổi điểm danh',
          subtitle: 'Tổng số phiên đã thiết lập',
          icon: Icons.qr_code_2_outlined,
          color: const Color(0xFF8B5CF6),
        ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.statNumber.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Lối tắt tác vụ nhanh ──
  Widget _buildQuickActions(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thao tác nhanh', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'Truy cập nhanh các chức năng cốt lõi của giảng viên',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                icon: Icons.menu_book,
                label: 'Xem tất cả môn học',
                onPressed: () => context.go('/courses'),
              ),
              _buildActionButton(
                icon: Icons.qr_code_scanner,
                label: 'Tạo phiên điểm danh QR',
                onPressed: () => context.go('/schedule/create'),
              ),
              _buildActionButton(
                icon: Icons.how_to_reg,
                label: 'Quản lý kết quả điểm danh',
                onPressed: () => context.go('/attendance/manage'),
              ),
              _buildActionButton(
                icon: Icons.add_circle_outline,
                label: 'Tạo môn học mới',
                onPressed: () => context.go('/courses/create'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18, color: AppColors.accent),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: AppColors.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
    );
  }

  // ── Danh sách tóm tắt lớp học phần và số sinh viên đã đăng ký ──
  Widget _buildCourseSummarySection(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Danh sách lớp học phần phụ trách', style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                    'Số lượng sinh viên thực tế đã đăng ký vào từng lớp học',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Xem chi tiết'),
                onPressed: () => context.go('/courses'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_courses.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.school_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('Bạn chưa tạo môn học nào', style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text('Hãy tạo môn học đầu tiên để bắt đầu ghi danh sinh viên và điểm danh.', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Tạo môn học ngay',
                    icon: Icons.add,
                    onPressed: () => context.go('/courses/create'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _courses.length,
              separatorBuilder: (context, index) => const Divider(height: 16, color: AppColors.divider),
              itemBuilder: (context, index) {
                final course = _courses[index];
                final studentCount = _courseStudentCounts[course.courseId] ?? 0;

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => CourseStudentsDialog.show(context, course),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.class_outlined, color: AppColors.accent, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    course.subjectCode,
                                    style: AppTextStyles.label.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Lớp ${course.className}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Học kỳ: ${course.semester} · ID: ${course.courseId}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: studentCount > 0 ? AppColors.successBg : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: studentCount > 0
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: studentCount > 0 ? AppColors.success : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$studentCount sinh viên',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: studentCount > 0 ? AppColors.success : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                          tooltip: 'Sửa môn học',
                          onPressed: () async {
                            final updated = await EditCourseDialog.show(context, course);
                            if (updated != null) {
                              _loadDashboardData();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
