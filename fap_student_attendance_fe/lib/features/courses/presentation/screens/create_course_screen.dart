import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/course_controller.dart';

/// Màn hình tạo môn học và lớp học dành cho Giảng viên
class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCodeController = TextEditingController(text: 'PRM392');
  final _classNameController = TextEditingController(text: 'SE1701');
  final _semesterController = TextEditingController(text: 'Spring2026');
  final _passwordController = TextEditingController();
  final _descriptionController = TextEditingController(
    text: 'Lập trình di động và ứng dụng đa nền tảng Flutter/Spring Boot.',
  );

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _subjectCodeController.dispose();
    _classNameController.dispose();
    _semesterController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final courseController = CourseController();
    final newCourse = await courseController.createCourse(
      subjectCode: _subjectCodeController.text.trim(),
      className: _classNameController.text.trim(),
      semester: _semesterController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (newCourse != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tạo lớp học ${newCourse.className} (${newCourse.subjectCode}) thành công!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/courses');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            courseController.errorMessage ?? 'Không thể tạo khóa học. Vui lòng kiểm tra kết nối Ứng dụng.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      selectedIndex: 1, // Môn học
      role: UserRole.lecturer,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──
            _buildHeader(),
            const SizedBox(height: 32),
            // ── Content Row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Form ──
                Expanded(
                  flex: 3,
                  child: _buildForm(context),
                ),
                const SizedBox(width: 24),
                // ── Quick Guide ──
                SizedBox(
                  width: 280,
                  child: _buildQuickGuide(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MÔN HỌC VÀ LỚP HỌC MỚI',
                style: AppTextStyles.breadcrumb,
              ),
              const SizedBox(height: 8),
              Text(
                'Tạo môn học và lớp học',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 4),
              Text(
                'Thiết lập thông tin môn học và lớp học để bắt đầu quản lý sinh viên và điểm danh.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final fieldErrors = CourseController().fieldErrors;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thông tin môn học và lớp học', style: AppTextStyles.h3),
            const SizedBox(height: 24),
            // ── Row: Mã môn học + Tên lớp ──
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Mã môn học *',
                    hintText: 'Ví dụ: PRM392',
                    controller: _subjectCodeController,
                    errorText: fieldErrors['subjectCode'],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mã môn học' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'Tên lớp học phần *',
                    hintText: 'Ví dụ: SE1701',
                    controller: _classNameController,
                    errorText: fieldErrors['className'],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên lớp' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // ── Row: Học kỳ ──
            CustomTextField(
              label: 'Học kỳ *',
              hintText: 'Ví dụ: Spring2026, FA24',
              controller: _semesterController,
              errorText: fieldErrors['semester'],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập học kỳ' : null,
            ),
            const SizedBox(height: 20),
            // ── Mật khẩu khóa học (Optional) ──
            CustomTextField(
              label: 'Mật khẩu khóa học (Tùy chọn)',
              hintText: 'Để trống nếu không yêu cầu mật khẩu...',
              helperText: 'Nếu cài đặt, sinh viên cần nhập mật khẩu này để tự đăng ký vào lớp',
              controller: _passwordController,
              obscureText: _obscurePassword,
              errorText: fieldErrors['password'],
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 20),
            // ── Mô tả ──
            CustomTextField(
              label: 'Mô tả lớp học',
              hintText: 'Nhập thông tin giới thiệu về môn học...',
              controller: _descriptionController,
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            // ── Buttons ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  text: 'Hủy bỏ',
                  onPressed: () => context.go('/courses'),
                ),
                const SizedBox(width: 16),
                PrimaryButton(
                  text: 'Tạo môn học & lớp học',
                  icon: Icons.check,
                  isLoading: _isLoading,
                  onPressed: _handleCreateCourse,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGuide() {
    final steps = [
      'Tạo thông tin môn học và lớp học',
      'Đăng ký sinh viên vào môn',
      'Lên lịch và tạo phiên điểm danh',
      'Mở mã QR trực tiếp cho sinh viên quét',
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quy trình nhanh', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: AppTextStyles.body.copyWith(
                        color: index == 0 ? AppColors.accent : AppColors.textSecondary,
                        fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
