import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/models/course_model.dart';
import '../controllers/course_controller.dart';

/// Modal dialog cập nhật thông tin khóa học / lớp học phần
class EditCourseDialog extends StatefulWidget {
  final CourseModel course;

  const EditCourseDialog({super.key, required this.course});

  static Future<CourseModel?> show(BuildContext context, CourseModel course) {
    return showDialog<CourseModel>(
      context: context,
      builder: (ctx) => EditCourseDialog(course: course),
    );
  }

  @override
  State<EditCourseDialog> createState() => _EditCourseDialogState();
}

class _EditCourseDialogState extends State<EditCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final CourseController _controller = CourseController();

  late TextEditingController _subjectCodeController;
  late TextEditingController _classNameController;
  late TextEditingController _semesterController;
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _subjectCodeController = TextEditingController(text: widget.course.subjectCode);
    _classNameController = TextEditingController(text: widget.course.className);
    _semesterController = TextEditingController(text: widget.course.semester);
  }

  @override
  void dispose() {
    _subjectCodeController.dispose();
    _classNameController.dispose();
    _semesterController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updated = await _controller.updateCourse(
      courseId: widget.course.courseId,
      subjectCode: _subjectCodeController.text.trim(),
      className: _classNameController.text.trim(),
      semester: _semesterController.text.trim(),
      password: _passwordController.text.trim().isNotEmpty
          ? _passwordController.text.trim()
          : null,
      lecturerId: widget.course.lecturerId,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cập nhật môn học ${updated.subjectCode} - ${updated.className} thành công!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Cập nhật thất bại. Vui lòng thử lại.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldErrors = _controller.fieldErrors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_outlined, color: AppColors.accent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cập nhật môn học', style: AppTextStyles.h3),
                          const SizedBox(height: 2),
                          Text(
                            'Chỉnh sửa thông tin mã môn, lớp học phần và học kỳ.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form inputs
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Mã môn học *',
                        controller: _subjectCodeController,
                        hintText: 'VD: PRM392',
                        errorText: fieldErrors['subjectCode'],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mã môn';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        label: 'Tên lớp học phần *',
                        controller: _classNameController,
                        hintText: 'VD: SE1701',
                        errorText: fieldErrors['className'],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên lớp';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Học kỳ *',
                  controller: _semesterController,
                  hintText: 'VD: Spring2026, FA24',
                  errorText: fieldErrors['semester'],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập học kỳ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Mật khẩu khóa học (tùy chọn)',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  hintText: 'Để trống nếu giữ nguyên mật khẩu cũ',
                  helperText: 'Nếu nhập, sinh viên sẽ cần mật khẩu này để đăng ký vào lớp',
                  errorText: fieldErrors['password'],
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 28),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.inputBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    PrimaryButton(
                      text: 'Lưu thay đổi',
                      icon: Icons.check,
                      isLoading: _isLoading,
                      onPressed: _handleUpdate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
