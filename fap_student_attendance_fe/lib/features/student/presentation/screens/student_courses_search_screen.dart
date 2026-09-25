import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../attendance/presentation/controllers/student_attendance_controller.dart';
import '../../../courses/data/models/course_model.dart';

/// Màn hình Tìm kiếm & Đăng ký khóa học dành cho Sinh viên (Mục 2.6 & 2.7)
class StudentCoursesSearchScreen extends StatefulWidget {
  const StudentCoursesSearchScreen({super.key});

  @override
  State<StudentCoursesSearchScreen> createState() =>
      _StudentCoursesSearchScreenState();
}

class _StudentCoursesSearchScreenState
    extends State<StudentCoursesSearchScreen> {
  final StudentAttendanceController _controller = StudentAttendanceController();

  final _searchKeywordController = TextEditingController();
  final _semesterController = TextEditingController();
  final _lecturerController = TextEditingController();

  String? _registeringCourseId;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // Tải danh sách môn đã ghi danh để đối chiếu
    await _controller.loadEnrollments();
    // Tải danh sách khóa học ban đầu
    _handleSearch();
  }

  @override
  void dispose() {
    _searchKeywordController.dispose();
    _semesterController.dispose();
    _lecturerController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    final keyword = _searchKeywordController.text.trim();
    final semester = _semesterController.text.trim();
    final lecturer = _lecturerController.text.trim();

    await _controller.searchCourses(
      subjectCode: keyword.isNotEmpty ? keyword : null,
      className: keyword.isNotEmpty ? keyword : null,
      semester: semester.isNotEmpty ? semester : null,
      lecturerName: lecturer.isNotEmpty ? lecturer : null,
    );
  }

  void _clearFilters() {
    _searchKeywordController.clear();
    _semesterController.clear();
    _lecturerController.clear();
    _handleSearch();
  }

  Future<void> _showRegisterDialog(CourseModel course) async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Đăng ký lớp ${course.className}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Môn học: ${course.subjectCode} · Học kỳ: ${course.semester}',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              Text(
                'Giảng viên: ${course.lecturerDisplay}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Mật khẩu khóa học (nếu có)',
                hintText: 'Nhập mã bảo mật do giảng viên cung cấp...',
                controller: passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Nếu môn học không yêu cầu mật khẩu bảo vệ, bạn có thể để trống trường này.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          PrimaryButton(
            text: 'Xác nhận đăng ký',
            icon: Icons.check,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _registeringCourseId = course.id);

      final success = await _controller.registerCourseForStudent(
        courseId: course.id,
        coursePassword: passwordController.text.trim().isNotEmpty
            ? passwordController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() => _registeringCourseId = null);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký lớp ${course.className} (${course.subjectCode}) thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _controller.errorMessage ?? 'Không thể đăng ký môn học. Vui lòng thử lại.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return DesktopScaffold(
      selectedIndex: 1, // Tìm & Đăng ký môn
      role: UserRole.student,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile: isMobile),
                SizedBox(height: isMobile ? 18 : 28),
                _buildSearchBar(isMobile: isMobile),
                SizedBox(height: isMobile ? 20 : 28),
                _buildCourseList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CỔNG SINH VIÊN · ĐĂNG KÝ HỌC PHẦN',
            style: AppTextStyles.breadcrumb.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            'Tìm kiếm & Đăng ký môn',
            style: AppTextStyles.h2.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            'Tìm kiếm các lớp học phần đang mở và đăng ký trực tiếp.',
            style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CỔNG THÔNG TIN SINH VIÊN · ĐĂNG KÝ HỌC PHẦN',
                style: AppTextStyles.breadcrumb,
              ),
              const SizedBox(height: 8),
              Text(
                'Tìm kiếm & Đăng ký môn học',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 4),
              Text(
                'Tìm kiếm các lớp học phần đang mở theo mã môn, tên lớp hoặc giảng viên và đăng ký trực tiếp.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        SecondaryButton(
          text: 'Về danh sách buổi học',
          icon: Icons.arrow_back,
          onPressed: () => context.go('/student/dashboard'),
        ),
      ],
    );
  }

  Widget _buildSearchBar({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            CustomTextField(
              label: 'Mã môn / Tên lớp học',
              hintText: 'Ví dụ: PRM392, SE1701...',
              controller: _searchKeywordController,
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
              onSubmitted: (_) => _handleSearch(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Học kỳ',
                    hintText: 'VD: Spring2026',
                    controller: _semesterController,
                    prefixIcon: const Icon(Icons.calendar_month, size: 18, color: AppColors.textSecondary),
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    label: 'Giảng viên',
                    hintText: 'Tên GV...',
                    controller: _lecturerController,
                    prefixIcon: const Icon(Icons.person_search, size: 18, color: AppColors.textSecondary),
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Tìm kiếm',
                    icon: Icons.search,
                    isLoading: _controller.isSearching,
                    onPressed: _handleSearch,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    side: const BorderSide(color: AppColors.inputBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Xóa lọc', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'Mã môn / Tên lớp học',
                    hintText: 'Ví dụ: PRM392, SE1701...',
                    controller: _searchKeywordController,
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'Học kỳ',
                    hintText: 'Ví dụ: Spring2026, FA24...',
                    controller: _semesterController,
                    prefixIcon: const Icon(Icons.calendar_month, size: 20, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'Giảng viên',
                    hintText: 'Tên giảng viên...',
                    controller: _lecturerController,
                    prefixIcon: const Icon(Icons.person_search, size: 20, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Xóa bộ lọc'),
                  onPressed: _clearFilters,
                ),
                const SizedBox(width: 12),
                PrimaryButton(
                  text: 'Tìm kiếm môn học',
                  icon: Icons.search,
                  isLoading: _controller.isSearching,
                  onPressed: _handleSearch,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    final results = _controller.searchResults;

    if (_controller.isSearching && results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off_outlined, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('Không tìm thấy môn học phù hợp', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                'Hãy thử thay đổi từ khóa tìm kiếm hoặc học kỳ để tìm kiếm các khóa học đang mở.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              SecondaryButton(
                text: 'Xóa bộ lọc và tải lại tất cả',
                icon: Icons.refresh,
                onPressed: _clearFilters,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kết quả tìm kiếm (${results.length} môn học)',
              style: AppTextStyles.h4,
            ),
            Text(
              'Đã đăng ký ${_controller.enrollments.length} môn',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 950 ? 3 : (constraints.maxWidth > 650 ? 2 : 1);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 220,
              ),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final course = results[index];
                final isEnrolled = _controller.isCourseEnrolled(course.id);
                final isRegisteringThis = _registeringCourseId == course.id;

                return _buildCourseCard(course, isEnrolled, isRegisteringThis);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourseCard(CourseModel course, bool isEnrolled, bool isRegistering) {
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFF06B6D4),
      const Color(0xFF059669),
      const Color(0xFFEA580C),
    ];
    final color = colors[course.subjectCode.hashCode.abs() % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnrolled ? AppColors.success.withValues(alpha: 0.5) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        course.subjectCode.length > 2
                            ? course.subjectCode.substring(0, 2)
                            : course.subjectCode,
                        style: AppTextStyles.label.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEnrolled ? AppColors.successBg : AppColors.infoBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isEnrolled ? '✓ Đã đăng ký' : course.semester,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isEnrolled ? AppColors.success : AppColors.info,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${course.subjectCode} · ${course.className}',
                  style: AppTextStyles.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'GV: ${course.lecturerDisplay}',
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: isEnrolled
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Đã có trong danh sách học',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : TextButton.icon(
                    icon: isRegistering
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle_outline, size: 16),
                    label: Text(isRegistering ? 'Đang đăng ký...' : 'Đăng ký môn học'),
                    onPressed: isRegistering ? null : () => _showRegisterDialog(course),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
