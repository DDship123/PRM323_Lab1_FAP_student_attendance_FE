import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/student_attendance_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Màn hình xác nhận điểm danh: Quét mã QR hoặc Nhập mã PIN phiên học
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  final StudentAttendanceController _controller = StudentAttendanceController();
  final AuthController _authController = AuthController();

  late TabController _tabController;
  final _qrInputController = TextEditingController();
  final _sessionInputController = TextEditingController();
  final _pinInputController = TextEditingController();

  bool _isLoading = false;
  String? _resultMessage;
  bool _isSuccess = false;
  bool _needsLogin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRouteParameters();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrInputController.dispose();
    _sessionInputController.dispose();
    _pinInputController.dispose();
    super.dispose();
  }

  /// Tự động lấy tham số từ URL nếu sinh viên mở link từ trình duyệt
  void _checkRouteParameters() {
    try {
      final uri = GoRouterState.of(context).uri;
      final sessionId = uri.queryParameters['sessionId'];
      final qrToken = uri.queryParameters['qrToken'];
      final secret = uri.queryParameters['qrCodeSecret'];
      final sessionCode = uri.queryParameters['code'];

      if (sessionId != null && sessionId.isNotEmpty) {
        _sessionInputController.text = sessionId;
      }

      if (sessionCode != null && sessionCode.trim().isNotEmpty) {
        _tabController.animateTo(1);
        _pinInputController.text = sessionCode.trim();
        _handlePinCheckIn();
        return;
      }

      if (sessionId != null && (qrToken != null || secret != null) && sessionId.isNotEmpty) {
        final queryParams = <String, String>{'sessionId': sessionId};
        if (qrToken != null && qrToken.isNotEmpty) queryParams['qrToken'] = qrToken;
        if (secret != null && secret.isNotEmpty) queryParams['qrCodeSecret'] = secret;
        final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
        context.go('/student/check-in?$queryString');
        return;
      }
    } catch (_) {}
  }

  /// Phân tích chuỗi QR (chuỗi Hex 8 ký tự, JSON hoặc URL)
  Map<String, String>? _parseQrData(String rawText) {
    final text = rawText.trim();

    // 1. JSON format
    if (text.startsWith('{')) {
      try {
        final map = jsonDecode(text) as Map<String, dynamic>;
        final sessionId = map['sessionId']?.toString();
        final qrToken = map['qrToken']?.toString() ?? map['token']?.toString();
        final secret = map['qrCodeSecret']?.toString();

        final result = <String, String>{};
        if (sessionId != null && sessionId.isNotEmpty) result['sessionId'] = sessionId;
        if (qrToken != null && qrToken.isNotEmpty) result['qrToken'] = qrToken;
        if (secret != null && secret.isNotEmpty) result['qrCodeSecret'] = secret;

        if (result.isNotEmpty) {
          return result;
        }
      } catch (_) {}
    }

    // 2. URL format (http/https hoặc link nội bộ)
    if (text.startsWith('http://') || text.startsWith('https://') || text.contains('check-in')) {
      try {
        final uri = Uri.parse(text);
        final sessionId = uri.queryParameters['sessionId'];
        final qrToken = uri.queryParameters['qrToken'];
        final secret = uri.queryParameters['qrCodeSecret'];

        final result = <String, String>{};
        if (sessionId != null && sessionId.isNotEmpty) result['sessionId'] = sessionId;
        if (qrToken != null && qrToken.isNotEmpty) result['qrToken'] = qrToken;
        if (secret != null && secret.isNotEmpty) result['qrCodeSecret'] = secret;

        if (result.isNotEmpty) {
          return result;
        }
      } catch (_) {}
    }

    // 3. Chuỗi Hex 8 ký tự từ TOTP dynamic QR
    final hex8Regex = RegExp(r'^[0-9A-Fa-f]{8}$');
    if (hex8Regex.hasMatch(text)) {
      return {'qrToken': text.toUpperCase()};
    }

    return null;
  }

  /// Hiển thị dialog hỏi Session ID nếu chỉ quét được chuỗi 8 ký tự hex mà chưa có Session ID
  Future<void> _showSessionIdPromptDialog({String? qrToken, String? secret}) async {
    final textCtrl = TextEditingController(text: _sessionInputController.text);
    final confirmedId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.qr_code, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('Nhập mã phiên học (Session ID)', style: AppTextStyles.h4),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đã nhận diện mã Token: ${qrToken ?? secret ?? ""}\nVui lòng nhập mã Session ID của phòng học để tiếp tục:',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(
                hintText: 'VD: sess_xxx hoặc UUID phiên học',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.pop(ctx, textCtrl.text.trim()),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );

    if (confirmedId != null && confirmedId.isNotEmpty) {
      _sessionInputController.text = confirmedId;
      final queryParams = <String, String>{'sessionId': confirmedId};
      if (qrToken != null && qrToken.isNotEmpty) queryParams['qrToken'] = qrToken;
      if (secret != null && secret.isNotEmpty) queryParams['qrCodeSecret'] = secret;
      final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      if (mounted) {
        context.go('/student/check-in?$queryString');
      }
    }
  }

  /// Check-in bằng QR Code: Điều hướng sang trang xác nhận phiên điểm danh & môn học
  Future<void> _handleAutoCheckIn(String rawQrData) async {
    final parsed = _parseQrData(rawQrData);

    if (parsed == null) {
      setState(() {
        _resultMessage = 'Mã QR không đúng định dạng. Vui lòng quét hoặc dán mã Hex 8 ký tự, JSON hoặc URL hợp lệ.';
        _isSuccess = false;
      });
      return;
    }

    final sId = parsed['sessionId'] ?? _sessionInputController.text.trim();
    final qrToken = parsed['qrToken'];
    final sSecret = parsed['qrCodeSecret'];

    if (sId.isEmpty) {
      await _showSessionIdPromptDialog(qrToken: qrToken, secret: sSecret);
      return;
    }

    final queryParams = <String, String>{'sessionId': sId};
    if (qrToken != null && qrToken.isNotEmpty) queryParams['qrToken'] = qrToken;
    if (sSecret != null && sSecret.isNotEmpty) queryParams['qrCodeSecret'] = sSecret;

    final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    context.go('/student/check-in?$queryString');
  }

  /// Check-in bằng mã PIN 6 số
  Future<void> _handlePinCheckIn() async {
    final pin = _pinInputController.text.trim();
    if (pin.isEmpty || pin.length < 4) {
      setState(() {
        _resultMessage = 'Vui lòng nhập đầy đủ mã PIN phiên học (thường là 6 chữ số).';
        _isSuccess = false;
      });
      return;
    }

    if (!_authController.isAuthenticated) {
      setState(() {
        _needsLogin = true;
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      });
      final currentUri = GoRouterState.of(context).uri.toString();
      context.go('/login?redirect=${Uri.encodeComponent(currentUri)}');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    final record = await _controller.checkInByPin(
      sessionCode: pin,
      latitude: 10.8412,
      longitude: 106.8099,
    );

    if (!mounted) return;

    if (record != null) {
      context.go(
        '/student/result?status=success'
        '&sessionId=${Uri.encodeComponent(record.sessionId)}'
        '&studentName=${Uri.encodeComponent(record.studentName ?? _authController.currentUser?.fullName ?? "Sinh viên")}'
        '&fapCode=${Uri.encodeComponent(record.studentFapCode ?? _authController.currentUser?.fapCode ?? "")}'
        '&checkedAt=${Uri.encodeComponent(record.checkedAt ?? "")}'
        '&slot=1'
        '&subject=Môn học',
      );
    } else {
      final err = _controller.errorMessage ??
          'Mã PIN không đúng, đã hết hạn hoặc bạn không kết nối đúng mạng Wi-Fi phòng học.';
      context.go('/student/result?status=failure&message=${Uri.encodeComponent(err)}');
    }
  }

  void _onQrInputChanged(String value) {
    final trimmed = value.trim();
    if (_parseQrData(trimmed) != null) {
      _handleAutoCheckIn(trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return DesktopScaffold(
      selectedIndex: 2, // Quét QR / PIN
      role: UserRole.student,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile: isMobile),
            SizedBox(height: isMobile ? 16 : 24),
            _buildWifiRequirementBanner(),
            SizedBox(height: isMobile ? 18 : 24),
            if (isMobile) ...[
              _buildMainCheckInSection(context, isMobile: isMobile),
              const SizedBox(height: 20),
              _buildSideInfoPanel(),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildMainCheckInSection(context, isMobile: isMobile),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 360,
                    child: _buildSideInfoPanel(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ĐIỂM DANH SINH VIÊN · XÁC NHẬN CÓ MẶT',
          style: AppTextStyles.breadcrumb.copyWith(fontSize: isMobile ? 11 : 12),
        ),
        const SizedBox(height: 8),
        Text(
          'Xác nhận điểm danh phiên học',
          style: AppTextStyles.h1.copyWith(fontSize: isMobile ? 22 : 28),
        ),
        const SizedBox(height: 4),
        Text(
          'Chọn hình thức Quét/Dán mã QR hoặc nhập trực tiếp mã PIN 6 số do giảng viên cung cấp.',
          style: AppTextStyles.bodySmall.copyWith(fontSize: isMobile ? 13 : 14),
        ),
      ],
    );
  }

  Widget _buildWifiRequirementBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2B48),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E88E5).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.wifi, color: Color(0xFF64B5F6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yêu cầu kết nối Wi-Fi phòng học',
                  style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hệ thống đối soát địa chỉ IP mạng nội bộ của phòng học. Sinh viên cần tắt 4G/5G và kết nối vào Wi-Fi giảng đường theo yêu cầu của phiên học.',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCheckInSection(BuildContext context, {bool isMobile = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Banner thông báo lỗi / thành công
          if (_resultMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _isSuccess ? AppColors.successBg : AppColors.errorBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle : Icons.error_outline,
                    color: _isSuccess ? AppColors.success : AppColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _resultMessage!,
                      style: AppTextStyles.body.copyWith(
                        color: _isSuccess ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_needsLogin) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('Đăng nhập lại'),
                      onPressed: () {
                        final currentUri = GoRouterState.of(context).uri.toString();
                        context.go('/login?redirect=${Uri.encodeComponent(currentUri)}');
                      },
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _resultMessage = null),
                  ),
                ],
              ),
            ),

          // Tabs Switch
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.label,
            tabs: const [
              Tab(icon: Icon(Icons.qr_code_scanner, size: 20), text: 'Quét / Dán mã QR'),
              Tab(icon: Icon(Icons.pin, size: 20), text: 'Nhập mã PIN'),
            ],
          ),

          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 24),
            child: SizedBox(
              height: isMobile ? 420 : 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQrTab(),
                  _buildPinTab(),
                ],
              ),
            ),
          ),

          // Nút quay lại Dashboard
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  onPressed: () => context.go('/student/dashboard'),
                  label: const Text('Quay lại Cổng sinh viên'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF141923),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isLoading ? AppColors.warning : const Color(0xFF26C6DA),
                      width: 2.5,
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.warning,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(
                          Icons.qr_code_scanner,
                          size: 44,
                          color: Color(0xFF26C6DA),
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isLoading ? 'Đang xác thực điểm danh...' : 'Mã QR động TOTP đổi chu kỳ 10 giây/lần',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quét hoặc dán chuỗi Hex 8 ký tự, liên kết điểm danh hoặc JSON',
                  style: AppTextStyles.caption.copyWith(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Mã phiên học (nếu có)
          Text('Mã phiên học (Session ID):', style: AppTextStyles.label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _sessionInputController,
            style: AppTextStyles.body.copyWith(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Nhập Session ID (hoặc tự động điền khi quét link)',
              hintStyle: AppTextStyles.caption,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              prefixIcon: const Icon(Icons.meeting_room, size: 18, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          Text('Dữ liệu mã QR / Token Hex 8 ký tự:', style: AppTextStyles.label),
          const SizedBox(height: 6),
          TextFormField(
            controller: _qrInputController,
            maxLines: 2,
            onChanged: _onQrInputChanged,
            style: AppTextStyles.body.copyWith(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'VD: A3F8B12C hoặc {"sessionId":"...", "qrToken":"..."} hoặc liên kết web',
              hintStyle: AppTextStyles.caption.copyWith(fontFamily: 'monospace'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              prefixIcon: const Icon(Icons.qr_code, size: 18, color: AppColors.accent),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: AppColors.accent),
                tooltip: 'Gửi xác nhận',
                onPressed: _isLoading ? null : () => _handleAutoCheckIn(_qrInputController.text),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mã PIN phiên điểm danh (Session PIN)',
          style: AppTextStyles.label,
        ),
        const SizedBox(height: 6),
        Text(
          'Giảng viên hiển thị mã số gồm 6 ký tự trên màn hình lớp học (ví dụ: 849201).',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 20),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: TextField(
              controller: _pinInputController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.text,
              maxLength: 6,
              style: AppTextStyles.h1.copyWith(
                letterSpacing: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                hintStyle: AppTextStyles.h1.copyWith(letterSpacing: 16, color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
              onSubmitted: (_) => _handlePinCheckIn(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: PrimaryButton(
              text: 'Xác nhận điểm danh bằng PIN',
              icon: Icons.check_circle_outline,
              isLoading: _isLoading,
              onPressed: _handlePinCheckIn,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideInfoPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quy định điểm danh', style: AppTextStyles.h4),
              const SizedBox(height: 16),
              _buildRuleItem(
                icon: Icons.timer,
                title: 'Mã QR động TOTP (10s)',
                desc: 'Mã QR đổi sau mỗi 10 giây. Hãy quét mã trực tiếp trên màn chiếu lớp học.',
              ),
              const SizedBox(height: 14),
              _buildRuleItem(
                icon: Icons.wifi,
                title: 'Mạng Wi-Fi nội bộ',
                desc: 'Thiết bị cần kết nối cùng dải Subnet /24 hoặc Access Point phòng học. Tắt VPN/4G.',
              ),
              const SizedBox(height: 14),
              _buildRuleItem(
                icon: Icons.phonelink_lock,
                title: 'Khóa thiết bị sinh viên',
                desc: 'Mỗi thiết bị (Device ID) chỉ điểm danh duy nhất cho một tài khoản trong phiên.',
              ),
              const SizedBox(height: 14),
              _buildRuleItem(
                icon: Icons.pin,
                title: 'Mã PIN dự phòng',
                desc: 'Trong trường hợp camera lỗi, bạn có thể chuyển tab và nhập mã PIN 6 số.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.label.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}
