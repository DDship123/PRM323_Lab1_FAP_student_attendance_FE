import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/widgets/user_profile_dialog.dart';

/// Vai trò người dùng cho sidebar
enum UserRole { lecturer, student }

/// Sidebar navigation item
class NavItem {
  final IconData icon;
  final String label;
  final String route;

  const NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// Nav items cho Giảng viên
const List<NavItem> lecturerNavItems = [
  NavItem(icon: Icons.dashboard_outlined, label: 'Tổng quan', route: '/dashboard'),
  NavItem(icon: Icons.menu_book_outlined, label: 'Môn học', route: '/courses'),
  NavItem(icon: Icons.calendar_today_outlined, label: 'Lịch học', route: '/schedule/create'),
  NavItem(icon: Icons.qr_code_scanner_outlined, label: 'Điểm danh', route: '/attendance/manage'),
];

/// Nav items cho Sinh viên
const List<NavItem> studentNavItems = [
  NavItem(icon: Icons.school_outlined, label: 'Buổi học', route: '/student/dashboard'),
  NavItem(icon: Icons.search_outlined, label: 'Tìm & Đăng ký môn', route: '/student/courses'),
  NavItem(icon: Icons.qr_code_scanner_outlined, label: 'Quét QR / PIN', route: '/student/scan'),
  NavItem(icon: Icons.history_outlined, label: 'Lịch sử điểm danh', route: '/student/history'),
];

/// Desktop layout chính: sidebar + content area
class DesktopScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int>? onNavChanged;
  final UserRole? role;

  const DesktopScaffold({
    super.key,
    required this.body,
    this.selectedIndex = 0,
    this.onNavChanged,
    this.role,
  });

  UserRole get effectiveRole {
    final user = AuthController().currentUser;
    if (user != null) {
      if (user.isLecturer || user.isAdmin) return UserRole.lecturer;
      if (user.isStudent) return UserRole.student;
    }
    return role ?? UserRole.lecturer;
  }

  List<NavItem> get _navItems =>
      effectiveRole == UserRole.lecturer ? lecturerNavItems : studentNavItems;

  String get _userName {
    final user = AuthController().currentUser;
    if (user != null && user.fullName.isNotEmpty) {
      return user.fullName;
    }
    return effectiveRole == UserRole.lecturer ? 'Nguyễn Minh Anh' : 'Trần Gia Hân';
  }

  String get _userRole {
    final user = AuthController().currentUser;
    if (user != null) {
      if (user.isStudent && user.fapCode != null && user.fapCode!.isNotEmpty) {
        return '${user.roleDisplay} · ${user.fapCode}';
      }
      return user.roleDisplay;
    }
    return effectiveRole == UserRole.lecturer ? 'Giảng viên' : 'Sinh viên';
  }

  Color get _avatarColor =>
      effectiveRole == UserRole.lecturer ? AppColors.accent : const Color(0xFF26C6DA);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBg,
          elevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textWhite),
              tooltip: 'Menu điều hướng',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Attendly',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
          actions: [
            if (effectiveRole == UserRole.student && _userRole.contains('·')) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _userRole.split('·').last.trim(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => UserProfileDialog.show(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: _avatarColor,
                  child: const Icon(Icons.person, color: AppColors.textWhite, size: 18),
                ),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: AppColors.sidebarBg,
          child: SafeArea(
            child: _buildSidebarContent(context, isDrawer: true),
          ),
        ),
        bottomNavigationBar: effectiveRole == UserRole.student
            ? NavigationBar(
                selectedIndex: selectedIndex.clamp(0, 3),
                backgroundColor: AppColors.surface,
                elevation: 8,
                indicatorColor: AppColors.accent.withValues(alpha: 0.15),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.school_outlined),
                    selectedIcon: Icon(Icons.school, color: AppColors.accent),
                    label: 'Buổi học',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search_outlined),
                    selectedIcon: Icon(Icons.search, color: AppColors.accent),
                    label: 'Tìm môn',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.qr_code_scanner_outlined),
                    selectedIcon: Icon(Icons.qr_code_scanner, color: AppColors.accent),
                    label: 'Quét QR',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(Icons.history, color: AppColors.accent),
                    label: 'Lịch sử',
                  ),
                ],
                onDestinationSelected: (idx) {
                  if (idx >= 0 && idx < studentNavItems.length) {
                    context.go(studentNavItems[idx].route);
                  }
                },
              )
            : null,
        body: SafeArea(
          child: body,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ──
          _buildSidebar(context),
          // ── Main Content ──
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: _buildSidebarContent(context, isDrawer: false),
    );
  }

  Widget _buildSidebarContent(BuildContext context, {required bool isDrawer}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // ── App Logo ──
                  _buildLogo(context, isDrawer: isDrawer),
                  const SizedBox(height: 8),
                  // ── Navigation Items ──
                  ...List.generate(_navItems.length, (index) {
                    return _buildNavItem(context, index, isDrawer: isDrawer);
                  }),
                  const Spacer(),
                  // ── User Profile ──
                  _buildUserProfile(context, isDrawer: isDrawer),
                  const SizedBox(height: 16),
                  // ── FPT Branding ──
                  _buildBranding(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo(BuildContext context, {bool isDrawer = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (isDrawer) Navigator.of(context).pop();
          context.go('/login');
        },
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'A',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Attendly',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, {bool isDrawer = false}) {
    final item = _navItems[index];
    final isSelected = index == selectedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (isDrawer) {
              Navigator.of(context).pop();
            }
            if (onNavChanged != null) {
              onNavChanged!(index);
            } else {
              context.go(item.route);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected ? AppColors.sidebarTextActive : AppColors.sidebarText,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    item.label,
                    style: AppTextStyles.body.copyWith(
                      color: isSelected ? AppColors.sidebarTextActive : AppColors.sidebarText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, {bool isDrawer = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (isDrawer) Navigator.of(context).pop();
              UserProfileDialog.show(context);
            },
            child: Tooltip(
              message: 'Cập nhật tài khoản / Đổi mật khẩu',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _avatarColor,
                child: const Icon(Icons.person, color: AppColors.textWhite, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                if (isDrawer) Navigator.of(context).pop();
                UserProfileDialog.show(context);
              },
              child: Tooltip(
                message: 'Cập nhật tài khoản / Đổi mật khẩu',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _userRole,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.sidebarText,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.sidebarText, size: 18),
            tooltip: 'Cài đặt tài khoản',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              if (isDrawer) Navigator.of(context).pop();
              UserProfileDialog.show(context);
            },
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.sidebarText, size: 18),
            tooltip: 'Đăng xuất',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              if (isDrawer) Navigator.of(context).pop();
              await AuthController().logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FPT Logo text
          Row(
            children: [
              Text('F', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.fptOrange)),
              Text('P', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.fptGreen)),
              Text('T', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.fptBlue)),
              Text(' Education', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.sidebarText)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'FPT UNIVERSITY',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.fptOrange,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
