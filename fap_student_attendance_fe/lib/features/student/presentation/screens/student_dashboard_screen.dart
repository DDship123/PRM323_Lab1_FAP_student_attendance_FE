import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../attendance/presentation/controllers/student_attendance_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../courses/data/models/course_model.dart';

/// Màn hình Dashboard sinh viên — Theo dõi môn học đã đăng ký, điểm danh và tìm kiếm
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final StudentAttendanceController _controller = StudentAttendanceController();
  final AuthController _authController = AuthController();

  final _searchCourseController = TextEditingController();
  final _searchLecturerController = TextEditingController();
  String? _selectedSemester;

  final List<String> _semesters = ['Tất cả học kỳ', 'Spring 2026', 'Fall 2025', 'Summer 2025', 'Spring 2025'];

  @override
  void initState() {
    super.initState();
    _controller.loadEnrollments();
  }

  @override
  void dispose() {
    _searchCourseController.dispose();
    _searchLecturerController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final courseKeyword = _searchCourseController.text.trim();
    final lecturerKeyword = _searchLecturerController.text.trim();
    final semester = (_selectedSemester == null || _selectedSemester == 'Tất cả học kỳ')
        ? null
        : _selectedSemester;

    _controller.loadEnrollments(
      subjectCode: courseKeyword.isNotEmpty ? courseKeyword : null,
      lecturerName: lecturerKeyword.isNotEmpty ? lecturerKeyword : null,
      semester: semester,
    );
  }

  void _clearFilter() {
    _searchCourseController.clear();
    _searchLecturerController.clear();
    setState(() => _selectedSemester = 'Tất cả học kỳ');
    _controller.loadEnrollments();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.currentUser;
    final displayName = user?.fullName ?? user?.username ?? 'Sinh viên';
    final isMobile = MediaQuery.of(context).size.width < 800;

    return DesktopScaffold(
      selectedIndex: 0,
      role: UserRole.student,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(displayName, isMobile: isMobile),
                SizedBox(height: isMobile ? 16 : 24),
                _buildCheckInBanner(context, isMobile: isMobile),
                SizedBox(height: isMobile ? 20 : 28),
                _buildStatsOverview(isMobile: isMobile),
                SizedBox(height: isMobile ? 20 : 28),
                _buildEnrolledCoursesSection(isMobile: isMobile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String displayName, {required bool isMobile}) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final user = _authController.currentUser;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NGÀY $dateStr',
                  style: AppTextStyles.breadcrumb.copyWith(fontSize: 11),
                ),
                if (user?.fapCode != null && user!.fapCode!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      user.fapCode!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Xin chào, $displayName 👋',
              style: AppTextStyles.h2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              'Theo dõi môn học, tra cứu lịch sử và xác nhận điểm danh.',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
            ),
          ],
        ),
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
                'CỔNG THÔNG TIN SINH VIÊN · NGÀY $dateStr',
                style: AppTextStyles.breadcrumb,
              ),
              const SizedBox(height: 8),
              Text(
                'Xin chào, $displayName',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 4),
              Text(
                'Theo dõi danh sách môn học đã đăng ký, tra cứu lịch sử điểm danh và xác nhận có mặt trong buổi học.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại dữ liệu',
          onPressed: _controller.loadEnrollments,
        ),
      ],
    );
  }

  Widget _buildCheckInBanner(BuildContext context, {required bool isMobile}) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ĐIỂM DANH TRỰC TIẾP',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Điểm danh buổi học',
                        style: AppTextStyles.h3.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Quét mã QR từ máy chiếu giảng viên hoặc nhập mã PIN 6 số. Yêu cầu kết nối Wi-Fi phòng học.',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.pin, size: 16),
                    label: const Text('Nhập PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.inputBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => context.go('/student/scan'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    text: 'Quét QR',
                    icon: Icons.qr_code,
                    onPressed: () => context.go('/student/scan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_scanner, color: AppColors.accent, size: 36),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ĐIỂM DANH TRỰC TIẾP',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'HỖ TRỢ MÃ QR & MÃ PIN 6 SỐ',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Xác nhận điểm danh phiên học hôm nay',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 4),
                Text(
                  'Quét mã QR từ màn hình giảng viên hoặc nhập mã số PIN 6 số. Lưu ý kết nối Wi-Fi phòng học theo yêu cầu.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              SecondaryButton(
                text: 'Nhập mã PIN',
                icon: Icons.pin,
                onPressed: () => context.go('/student/scan'),
              ),
              PrimaryButton(
                text: 'Quét mã QR',
                icon: Icons.qr_code,
                onPressed: () => context.go('/student/scan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview({required bool isMobile}) {
    final count = _controller.myCourses.isNotEmpty
        ? _controller.myCourses.length
        : _controller.enrollments.length;

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Môn học',
                  value: '$count',
                  subText: 'Học kỳ này',
                  icon: Icons.class_outlined,
                  color: AppColors.accent,
                  isMobile: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  title: 'Trạng thái',
                  value: 'Sẵn sàng',
                  subText: 'Wi-Fi phòng',
                  icon: Icons.wifi,
                  color: const Color(0xFF10B981),
                  isMobile: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatCard(
            title: 'Lịch sử điểm danh',
            value: 'Tra cứu chuyên cần',
            subText: 'Xem chi tiết các buổi học có mặt / vắng',
            icon: Icons.history,
            color: const Color(0xFFF59E0B),
            onTap: () => context.go('/student/history'),
            isMobile: true,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Môn học đã đăng ký',
            value: '$count',
            subText: 'Học kỳ hiện tại',
            icon: Icons.class_outlined,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Trạng thái điểm danh',
            value: 'Sẵn sàng',
            subText: 'Kiểm tra Wi-Fi phòng học trước khi check-in',
            icon: Icons.wifi,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Lịch sử điểm danh',
            value: 'Tra cứu',
            subText: 'Xem chi tiết các buổi đã có mặt / vắng',
            icon: Icons.history,
            color: const Color(0xFFF59E0B),
            onTap: () => context.go('/student/history'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isMobile = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isMobile ? 20 : 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.h2.copyWith(
                      color: color,
                      fontSize: isMobile ? 18 : 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subText,
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledCoursesSection({required bool isMobile}) {
    final courses = _controller.myCourses;
    final enrollments = _controller.enrollments;

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
            Text('Môn học của tôi', style: AppTextStyles.h3.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'Danh sách các môn học bạn đã ghi danh trong kỳ',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: 'Tìm & Đăng ký môn mới',
                icon: Icons.search,
                onPressed: () => context.go('/student/courses'),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danh sách môn học đã đăng ký', style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    Text(
                      'Lọc và tìm kiếm các môn học bạn đang tham gia trong học kỳ',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                PrimaryButton(
                  text: 'Tìm & Đăng ký môn mới',
                  icon: Icons.search,
                  onPressed: () => context.go('/student/courses'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Bộ lọc tìm kiếm
          if (isMobile) ...[
            CustomTextField(
              hintText: 'Mã môn hoặc tên lớp (vd: PRM392)...',
              controller: _searchCourseController,
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
              onSubmitted: (_) => _applyFilter(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    hintText: 'Giảng viên...',
                    controller: _searchLecturerController,
                    prefixIcon: const Icon(Icons.person, size: 18, color: AppColors.textSecondary),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSemester ?? 'Tất cả học kỳ',
                    dropdownColor: Colors.white,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                    ),
                    items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedSemester = val);
                      _applyFilter();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Lọc kết quả',
                    icon: Icons.filter_list,
                    onPressed: _applyFilter,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.clear, size: 16, color: AppColors.textSecondary),
                  label: const Text('Xóa lọc', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    side: const BorderSide(color: AppColors.inputBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _clearFilter,
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    hintText: 'Tìm theo mã môn hoặc tên lớp (vd: PRM392)...',
                    controller: _searchCourseController,
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    hintText: 'Tên giảng viên...',
                    controller: _searchLecturerController,
                    prefixIcon: const Icon(Icons.person, size: 18, color: AppColors.textSecondary),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSemester ?? 'Tất cả học kỳ',
                    dropdownColor: Colors.white,
                    style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                    ),
                    items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedSemester = val);
                      _applyFilter();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                PrimaryButton(
                  text: 'Lọc',
                  icon: Icons.filter_list,
                  onPressed: _applyFilter,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  tooltip: 'Xóa bộ lọc',
                  onPressed: _clearFilter,
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          if (_controller.isLoading && courses.isEmpty && enrollments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (courses.isEmpty && enrollments.isEmpty)
            _buildEmptyCoursesState()
          else
            _buildCoursesGrid(courses, enrollments, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildEmptyCoursesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.school_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Không tìm thấy môn học nào phù hợp', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              'Thử thay đổi từ khóa lọc hoặc đăng ký thêm các học phần đang mở.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Tìm kiếm & Đăng ký môn học',
              icon: Icons.search,
              onPressed: () => context.go('/student/courses'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesGrid(List<CourseModel> courses, List<dynamic> fallbackEnrollments, {required bool isMobile}) {
    final count = courses.isNotEmpty ? courses.length : fallbackEnrollments.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 14,
        mainAxisExtent: isMobile ? 160 : 180,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        if (courses.isNotEmpty) {
          final course = courses[index];
          return _buildCourseCard(
            courseId: course.id,
            subjectCode: course.subjectCode,
            className: course.className,
            semester: course.semester,
            lecturerName: course.lecturerDisplay,
            isMobile: isMobile,
          );
        } else {
          final item = fallbackEnrollments[index];
          return _buildCourseCard(
            courseId: item.courseId,
            subjectCode: item.courseId,
            className: 'Lớp học phần',
            semester: 'Học kỳ hiện tại',
            lecturerName: 'Giảng viên phụ trách',
            isMobile: isMobile,
          );
        }
      },
    );
  }

  Widget _buildCourseCard({
    required String courseId,
    required String subjectCode,
    required String className,
    required String semester,
    required String lecturerName,
    bool isMobile = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subjectCode,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Đã ghi danh',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            className,
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
                  lecturerName,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(semester, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
              InkWell(
                onTap: () => context.go('/student/history'),
                child: Text(
                  'Xem điểm danh →',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
