import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/models/auth_models.dart';
import '../controllers/auth_controller.dart';

/// Màn hình đăng nhập & đăng ký desktop — layout 2 cột hiện đại
class AuthDesktopScreen extends StatefulWidget {
  const AuthDesktopScreen({super.key});

  @override
  State<AuthDesktopScreen> createState() => _AuthDesktopScreenState();
}

class _AuthDesktopScreenState extends State<AuthDesktopScreen> {
  final AuthController _authController = AuthController();

  // Mode: 0 = Đăng nhập, 1 = Đăng ký
  int _authMode = 0;

  // Login form controllers & key
  final _loginFormKey = GlobalKey<FormState>();
  final _loginUsernameController = TextEditingController(text: 'datnht');
  final _loginPasswordController = TextEditingController(text: '123456');

  // Register form controllers & key
  final _registerFormKey = GlobalKey<FormState>();
  final _regFullNameController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  final _regFapCodeController = TextEditingController();

  // Vai trò đăng ký: 0 = Sinh viên (STUDENT), 1 = Giảng viên (LECTURER)
  int _selectedRegisterRole = 0;

  // Trạng thái ẩn/hiện mật khẩu
  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;
  bool _obscureRegConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _authController.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regFullNameController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _regFapCodeController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) setState(() {});
  }

  // ── Xử lý Đăng nhập ──
  Future<void> _handleLogin() async {
    _authController.clearMessages();
    if (!_loginFormKey.currentState!.validate()) return;

    final user = await _authController.login(
      username: _loginUsernameController.text.trim(),
      password: _loginPasswordController.text,
    );

    if (user != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xin chào, ${user.fullName} (${user.roleDisplay})!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Kiểm tra nếu có redirect URL (ví dụ từ deep link quét QR)
      final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
      if (redirect != null && redirect.isNotEmpty) {
        final target = redirect.contains('%') ? Uri.decodeComponent(redirect) : redirect;
        context.go(target);
        return;
      }

      // Điều hướng theo phân quyền từ Backend
      if (user.isLecturer || user.isAdmin) {
        context.go('/dashboard');
      } else {
        context.go('/student/dashboard');
      }
    }
  }

  // ── Xử lý Đăng ký ──
  Future<void> _handleRegister() async {
    _authController.clearMessages();
    if (!_registerFormKey.currentState!.validate()) return;

    final roleId = _selectedRegisterRole == 0 ? 'STUDENT' : 'LECTURER';

    final request = RegisterRequest(
      username: _regUsernameController.text.trim(),
      password: _regPasswordController.text,
      email: _regEmailController.text.trim(),
      fullName: _regFullNameController.text.trim(),
      roleId: roleId,
      fapCode: _selectedRegisterRole == 0 ? _regFapCodeController.text.trim() : null,
    );

    final newUser = await _authController.register(request);

    if (newUser != null && mounted) {
      // Tự động điền username vào form đăng nhập và chuyển sang tab Đăng nhập
      _loginUsernameController.text = newUser.username;
      _loginPasswordController.text = _regPasswordController.text;

      setState(() {
        _authMode = 0; // Chuyển sang form đăng nhập
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng ký tài khoản ${newUser.username} thành công! Vui lòng đăng nhập.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _buildMobileAuth(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left Panel: Branding ──
          Expanded(
            flex: 4,
            child: _buildBrandingPanel(),
          ),
          // ── Right Panel: Login / Register Form ──
          Expanded(
            flex: 5,
            child: _buildFormPanel(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // GIAO DIỆN MOBILE CHO ĐĂNG NHẬP & ĐĂNG KÝ
  // ══════════════════════════════════════════════════════════
  Widget _buildMobileAuth(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              children: [
                // Header thương hiệu mobile
                _buildMobileHeader(),

                // Card form tương tác
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tab switcher (Đăng nhập / Đăng ký)
                        _buildModeSwitchTabs(),
                        const SizedBox(height: 20),

                        // Banner thông báo lỗi
                        if (_authController.errorMessage != null) ...[
                          _buildMessageBanner(
                            message: _authController.errorMessage!,
                            isError: true,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Banner thông báo thành công
                        if (_authController.successMessage != null) ...[
                          _buildMessageBanner(
                            message: _authController.successMessage!,
                            isError: false,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Form nội dung
                        if (_authMode == 0) _buildLoginForm() else _buildRegisterForm(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // FPT Education Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 1.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('F', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.fptOrange)),
                    Text('P', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.fptGreen)),
                    Text('T', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.fptBlue)),
                    const SizedBox(width: 4),
                    Text('Edu', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textWhite)),
                  ],
                ),
              ),
              // App pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 14, color: AppColors.accentLight),
                    const SizedBox(width: 4),
                    Text(
                      'FAP ATTENDANCE',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendly',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textWhite,
                      ),
                    ),
                    Text(
                      'Hệ thống Điểm danh Thông minh FAP',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.sidebarText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      color: AppColors.primary,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final verticalPad = constraints.maxHeight > 700 ? 44.0 : 28.0;
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 44, vertical: verticalPad),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (verticalPad * 2),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── FPT Education Logo ──
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24, width: 1.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('F', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.fptOrange)),
                              Text('P', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.fptGreen)),
                              Text('T', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.fptBlue)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Education',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppConstants.universityName,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textWhite,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // ── Badge ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'ĐIỂM DANH THÔNG MINH',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentLight,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ── Main Slogan ──
                    Text(
                      AppConstants.brandSlogan,
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textWhite,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // ── Features ──
                    ...AppConstants.brandFeatures.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              feature,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.sidebarText,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const Spacer(),
                    const SizedBox(height: 24),
                    // ── Footer ──
                    Text(
                      AppConstants.brandFooter,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.sidebarText.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormPanel() {
    return Container(
      color: AppColors.background,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final verticalPadding = constraints.maxHeight > 750 ? 32.0 : 16.0;
          final minCardHeight = constraints.maxHeight - (verticalPadding * 2);

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minCardHeight > 0 ? minCardHeight : 0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: minCardHeight > 0 ? minCardHeight : 0,
                    maxWidth: 480,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Mode Switcher Tab (Đăng nhập / Đăng ký) ──
                        _buildModeSwitchTabs(),
                        const SizedBox(height: 24),

                        // ── Error Banner ──
                        if (_authController.errorMessage != null) ...[
                          _buildMessageBanner(
                            message: _authController.errorMessage!,
                            isError: true,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Success Banner ──
                        if (_authController.successMessage != null) ...[
                          _buildMessageBanner(
                            message: _authController.successMessage!,
                            isError: false,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Active Form ──
                        if (_authMode == 0) _buildLoginForm() else _buildRegisterForm(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeSwitchTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildModeTab('Đăng nhập', 0),
          _buildModeTab('Tạo tài khoản mới', 1),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, int index) {
    final isSelected = _authMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _authMode = index;
            _authController.clearMessages();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? AppColors.accent : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBanner({required String message, required bool isError}) {
    final bgColor = isError ? AppColors.errorBg : AppColors.successBg;
    final textColor = isError ? AppColors.error : AppColors.success;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: () => _authController.clearMessages(),
            child: Icon(Icons.close, color: textColor, size: 16),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FORM ĐĂNG NHẬP
  // ══════════════════════════════════════════════════════════
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Đăng nhập', style: AppTextStyles.h1),
          const SizedBox(height: 6),
          Text(
            'Nhập tên tài khoản hoặc email để truy cập hệ thống Attendly.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),

          // Tên đăng nhập
          CustomTextField(
            label: 'Tên đăng nhập / Username',
            hintText: 'Nhập username (VD: datnht)',
            controller: _loginUsernameController,
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            errorText: _authController.fieldErrors['username'],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên đăng nhập';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Mật khẩu
          CustomTextField(
            label: 'Mật khẩu',
            hintText: 'Nhập mật khẩu',
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            ),
            errorText: _authController.fieldErrors['password'],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Nút Đăng nhập
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: _authController.isLoading ? 'Đang xác thực...' : 'Đăng nhập',
              icon: _authController.isLoading ? null : Icons.login,
              onPressed: _authController.isLoading ? null : _handleLogin,
            ),
          ),
          const SizedBox(height: 20),

          // Footer switch
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Chưa có tài khoản? ', style: AppTextStyles.bodySmall),
                InkWell(
                  onTap: () {
                    setState(() {
                      _authMode = 1;
                      _authController.clearMessages();
                    });
                  },
                  child: Text(
                    'Đăng ký ngay',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FORM ĐĂNG KÝ
  // ══════════════════════════════════════════════════════════
  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tạo tài khoản', style: AppTextStyles.h1),
          const SizedBox(height: 6),
          Text(
            'Đăng ký tài khoản để bắt đầu điểm danh hoặc quản lý lớp học.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 20),

          // ── Chọn vai trò (Role: Sinh viên / Giảng viên) ──
          Text('Vai trò của bạn', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  title: 'Sinh viên',
                  subtitle: 'Điểm danh qua QR',
                  icon: Icons.school_outlined,
                  isSelected: _selectedRegisterRole == 0,
                  onTap: () => setState(() => _selectedRegisterRole = 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoleCard(
                  title: 'Giảng viên',
                  subtitle: 'Tạo mã & quản lý',
                  icon: Icons.co_present_outlined,
                  isSelected: _selectedRegisterRole == 1,
                  onTap: () => setState(() => _selectedRegisterRole = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Họ và tên
          CustomTextField(
            label: 'Họ và tên',
            hintText: 'VD: Ngô Hoàng Trường Đạt',
            controller: _regFullNameController,
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            errorText: _authController.fieldErrors['fullName'],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Họ và tên không được để trống';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Tên đăng nhập (username)
          CustomTextField(
            label: 'Tên đăng nhập (Username)',
            hintText: '3–50 ký tự (VD: datnht)',
            controller: _regUsernameController,
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            errorText: _authController.fieldErrors['username'],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên đăng nhập';
              }
              if (value.trim().length < 3 || value.trim().length > 50) {
                return 'Tên đăng nhập phải từ 3 đến 50 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Mã sinh viên (FAP Code) - Bắt buộc nếu là Sinh viên
          if (_selectedRegisterRole == 0) ...[
            CustomTextField(
              label: 'Mã số sinh viên (FAP Code)',
              hintText: 'Định dạng 2 chữ cái + 6 số (VD: SE192964)',
              controller: _regFapCodeController,
              prefixIcon: const Icon(Icons.numbers_outlined, size: 20),
              errorText: _authController.fieldErrors['fapCode'],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mã sinh viên là bắt buộc đối với Sinh viên';
                }
                final reg = RegExp(r'^[A-Z]{2}\d{6}$');
                if (!reg.hasMatch(value.trim().toUpperCase())) {
                  return 'Sai định dạng FAP Code (VD hợp lệ: SE192964, IA180123)';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],

          // Email trường
          CustomTextField(
            label: 'Email',
            hintText: 'VD: datnhse192964@fpt.edu.vn',
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            errorText: _authController.fieldErrors['email'],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Email không đúng định dạng';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Mật khẩu
          CustomTextField(
            label: 'Mật khẩu',
            hintText: 'Tối thiểu 6 ký tự',
            controller: _regPasswordController,
            obscureText: _obscureRegPassword,
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
            ),
            errorText: _authController.fieldErrors['password'],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              if (value.length < 6) {
                return 'Mật khẩu phải có ít nhất 6 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Nhập lại mật khẩu
          CustomTextField(
            label: 'Xác nhận mật khẩu',
            hintText: 'Nhập lại mật khẩu vừa đặt',
            controller: _regConfirmPasswordController,
            obscureText: _obscureRegConfirmPassword,
            prefixIcon: const Icon(Icons.lock_reset, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscureRegConfirmPassword = !_obscureRegConfirmPassword),
            ),
            validator: (value) {
              if (value != _regPasswordController.text) {
                return 'Mật khẩu xác nhận không trùng khớp';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Nút Đăng ký
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: _authController.isLoading ? 'Đang tạo tài khoản...' : 'Đăng ký tài khoản',
              icon: _authController.isLoading ? null : Icons.person_add_alt_1,
              onPressed: _authController.isLoading ? null : _handleRegister,
            ),
          ),
          const SizedBox(height: 20),

          // Footer switch
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Đã có tài khoản? ', style: AppTextStyles.bodySmall),
                InkWell(
                  onTap: () {
                    setState(() {
                      _authMode = 0;
                      _authController.clearMessages();
                    });
                  },
                  child: Text(
                    'Đăng nhập tại đây',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? AppColors.accent : AppColors.cardBorder;
    final bgColor = isSelected ? AppColors.accent.withValues(alpha: 0.05) : AppColors.surface;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      color: isSelected ? AppColors.accent : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
