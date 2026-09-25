import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

/// Modal dialog cập nhật thông tin cá nhân và đổi mật khẩu
class UserProfileDialog extends StatefulWidget {
  const UserProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const UserProfileDialog(),
    );
  }

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  final AuthController _authController = AuthController();
  int _tabIndex = 0; // 0 = Thông tin cá nhân, 1 = Đổi mật khẩu

  // Form Thông tin
  final _profileFormKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;

  // Form Đổi mật khẩu
  final _passwordFormKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = _authController.currentUser;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _authController.clearMessages();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    final success = await _authController.updateProfile(
      username: _usernameController.text.trim(),
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin cá nhân thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _authController.errorMessage ?? 'Cập nhật thất bại. Vui lòng thử lại.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final oldPwd = _oldPasswordController.text;
    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;

    if (newPwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không khớp!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await _authController.changePassword(
      oldPassword: oldPwd,
      newPassword: newPwd,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _authController.errorMessage ?? 'Đổi mật khẩu thất bại. Vui lòng kiểm tra lại.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.currentUser;
    final fieldErrors = _authController.fieldErrors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header & User Avatar ──
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                    child: Text(
                      user != null && user.fullName.isNotEmpty
                          ? user.fullName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: AppTextStyles.h3.copyWith(color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Người dùng',
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user?.roleDisplay ?? 'Tài khoản',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (user?.fapCode != null && user!.fapCode!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                'MSSV: ${user.fapCode}',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Tab selector ──
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _tabIndex = 0),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0 ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _tabIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 18,
                                color: _tabIndex == 0 ? AppColors.accent : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Thông tin tài khoản',
                                style: AppTextStyles.label.copyWith(
                                  color: _tabIndex == 0 ? AppColors.accent : AppColors.textSecondary,
                                  fontWeight: _tabIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _tabIndex = 1),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1 ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _tabIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 18,
                                color: _tabIndex == 1 ? AppColors.accent : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Đổi mật khẩu',
                                style: AppTextStyles.label.copyWith(
                                  color: _tabIndex == 1 ? AppColors.accent : AppColors.textSecondary,
                                  fontWeight: _tabIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Tab Content ──
              if (_tabIndex == 0)
                _buildProfileTab(user, fieldErrors)
              else
                _buildPasswordTab(fieldErrors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(dynamic user, Map<String, String> fieldErrors) {
    return Form(
      key: _profileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Tên đăng nhập (Username) *',
                  controller: _usernameController,
                  hintText: 'Nhập tên đăng nhập',
                  prefixIcon: const Icon(Icons.account_circle_outlined, size: 20),
                  errorText: fieldErrors['username'],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên đăng nhập';
                    if (v.trim().length < 3) return 'Tối thiểu 3 ký tự';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Vai trò hệ thống',
                  initialValue: user?.roleDisplay ?? '',
                  readOnly: true,
                  prefixIcon: const Icon(Icons.shield_outlined, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Họ và tên *',
            controller: _fullNameController,
            hintText: 'Nhập họ và tên đầy đủ',
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            errorText: fieldErrors['fullName'],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Địa chỉ Email *',
            controller: _emailController,
            hintText: 'example@fpt.edu.vn',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            errorText: fieldErrors['email'],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập địa chỉ email';
              if (!v.contains('@')) return 'Email không đúng định dạng';
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                text: 'Lưu thay đổi',
                icon: Icons.check,
                isLoading: _authController.isLoading,
                onPressed: _handleUpdateProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTab(Map<String, String> fieldErrors) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'Mật khẩu hiện tại *',
            controller: _oldPasswordController,
            obscureText: _obscureOld,
            hintText: 'Nhập mật khẩu đang sử dụng',
            prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
            errorText: fieldErrors['oldPassword'],
            suffixIcon: IconButton(
              icon: Icon(
                _obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureOld = !_obscureOld),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu hiện tại';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Mật khẩu mới *',
            controller: _newPasswordController,
            obscureText: _obscureNew,
            hintText: 'Tối thiểu 6 ký tự',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            errorText: fieldErrors['newPassword'],
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
              if (v.length < 6) return 'Mật khẩu mới phải có tối thiểu 6 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Xác nhận mật khẩu mới *',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            hintText: 'Nhập lại mật khẩu mới',
            prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu mới';
              if (v != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                text: 'Cập nhật mật khẩu',
                icon: Icons.key,
                isLoading: _authController.isLoading,
                onPressed: _handleChangePassword,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
