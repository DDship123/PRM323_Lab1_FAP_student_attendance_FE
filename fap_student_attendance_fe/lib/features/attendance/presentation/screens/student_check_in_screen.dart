import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../courses/data/repositories/course_repository.dart';
import '../../../schedule/data/models/session_model.dart';
import '../../../schedule/data/repositories/session_repository.dart';
import '../../../../core/utils/attendance_error_helper.dart';
import '../controllers/student_attendance_controller.dart';

/// Màn hình xác nhận phiên điểm danh và môn học trước khi bấm nút điểm danh
class StudentCheckInScreen extends StatefulWidget {
  const StudentCheckInScreen({super.key});

  @override
  State<StudentCheckInScreen> createState() => _StudentCheckInScreenState();
}

class _StudentCheckInScreenState extends State<StudentCheckInScreen> {
  final AuthController _authController = AuthController();
  final SessionRepository _sessionRepository = SessionRepository();
  final CourseRepository _courseRepository = CourseRepository();
  final StudentAttendanceController _attendanceController = StudentAttendanceController();

  String _sessionId = '';
  String _qrToken = '';
  String _qrCodeSecret = '';

  AttendanceSessionModel? _session;
  CourseModel? _course;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoadData();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _checkAuthAndLoadData() {
    final uri = GoRouterState.of(context).uri;
    _sessionId = uri.queryParameters['sessionId'] ?? '';
    _qrToken = uri.queryParameters['qrToken'] ?? '';
    _qrCodeSecret = uri.queryParameters['qrCodeSecret'] ?? '';

    // Nếu người dùng chưa đăng nhập, chuyển hướng đến trang login và đính kèm redirect URL
    if (!_authController.isAuthenticated) {
      final currentUri = uri.toString();
      context.go('/login?redirect=${Uri.encodeComponent(currentUri)}');
      return;
    }

    if (_sessionId.isEmpty || (_qrToken.isEmpty && _qrCodeSecret.isEmpty)) {
      setState(() {
        _isLoading = false;
        _loadError = 'Không tìm thấy thông tin phiên điểm danh hoặc mã QR Token trong liên kết.';
      });
      return;
    }

    _fetchSessionAndCourse(uri.queryParameters);
  }

  Future<void> _fetchSessionAndCourse(Map<String, String> queryParams) async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // 1. Tải thông tin phiên điểm danh từ Backend
      AttendanceSessionModel? session;
      try {
        session = await _sessionRepository.getSessionById(_sessionId);
      } catch (e) {
        // Fallback: khởi tạo session cơ bản nếu server tạm thời lỗi
        final fallbackCourseId = queryParams['courseId'] ?? '';
        session = AttendanceSessionModel(
          sessionId: _sessionId,
          courseId: fallbackCourseId,
          slotNumber: 1,
          qrCodeSecret: _qrCodeSecret,
          expiredAt: DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
          status: 'OPEN',
        );
      }

      // 2. Tải thông tin môn học tương ứng
      CourseModel? course;
      final courseId = session.courseId.isNotEmpty ? session.courseId : (queryParams['courseId'] ?? '');
      if (courseId.isNotEmpty) {
        try {
          course = await _courseRepository.getCourseById(courseId);
        } catch (_) {
          // Fallback từ URL params nếu có
          if (queryParams.containsKey('subject')) {
            course = CourseModel(
              courseId: courseId,
              subjectCode: queryParams['subject'] ?? 'Môn học',
              className: queryParams['className'] ?? 'Lớp học',
              semester: queryParams['semester'] ?? 'Học kỳ',
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _session = session;
        _course = course;
        _isLoading = false;
      });

      _startCountdown(session);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Không thể tải thông tin phiên điểm danh: ${e.toString().replaceFirst("Exception: ", "")}';
      });
    }
  }

  void _startCountdown(AttendanceSessionModel session) {
    _countdownTimer?.cancel();
    final expiredAt = session.expiredDateTime;
    if (expiredAt == null) return;

    final diff = expiredAt.difference(DateTime.now());
    if (diff.isNegative) {
      _remainingTime = Duration.zero;
      return;
    }

    _remainingTime = diff;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final nowDiff = expiredAt.difference(DateTime.now());
      if (nowDiff.isNegative) {
        timer.cancel();
        setState(() => _remainingTime = Duration.zero);
      } else {
        setState(() => _remainingTime = nowDiff);
      }
    });
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return '00:00 (Đã hết hạn)';
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ── Xử lý khi sinh viên nhấn nút ĐIỂM DANH ──
  Future<void> _handleSubmitAttendance() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final record = await _attendanceController.checkIn(
      sessionId: _sessionId,
      qrToken: _qrToken.isNotEmpty ? _qrToken : null,
      qrCodeSecret: _qrCodeSecret.isNotEmpty ? _qrCodeSecret : null,
      latitude: 10.8412,
      longitude: 106.8099,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final user = _authController.currentUser;
    final subject = _course?.subjectCode ?? 'Môn học';
    final className = _course?.className ?? '';
    final slot = _session?.slotNumber.toString() ?? '1';

    if (record != null) {
      // Thành công -> chuyển qua màn hình kết quả thành công
      final studentName = record.studentName ?? user?.fullName ?? 'Sinh viên';
      final fapCode = record.studentFapCode ?? user?.fapCode ?? '';
      final checkedAt = record.checkedAt ?? DateTime.now().toIso8601String();

      context.go(
        '/student/result?status=success'
        '&sessionId=${Uri.encodeComponent(_sessionId)}'
        '&courseId=${Uri.encodeComponent(_session?.courseId ?? "")}'
        '&subject=${Uri.encodeComponent(subject)}'
        '&className=${Uri.encodeComponent(className)}'
        '&slot=${Uri.encodeComponent(slot)}'
        '&studentName=${Uri.encodeComponent(studentName)}'
        '&fapCode=${Uri.encodeComponent(fapCode)}'
        '&checkedAt=${Uri.encodeComponent(checkedAt)}'
        '&statusResult=PRESENT',
      );
    } else {
      // Thất bại -> Phân tích mã lỗi theo FRONTEND_QR_ATTENDANCE_INTEGRATION_GUIDE.md (Mục 5)
      final errorInfo = AttendanceErrorHelper.parse(
        _attendanceController.errorMessage,
        statusCode: _attendanceController.lastStatusCode,
      );

      context.go(
        '/student/result?status=failure'
        '&title=${Uri.encodeComponent(errorInfo.title)}'
        '&message=${Uri.encodeComponent(errorInfo.message)}'
        '&suggestion=${Uri.encodeComponent(errorInfo.suggestion ?? "")}'
        '&rawMessage=${Uri.encodeComponent(_attendanceController.errorMessage ?? "")}'
        '&sessionId=${Uri.encodeComponent(_sessionId)}'
        '&qrToken=${Uri.encodeComponent(_qrToken)}'
        '&qrCodeSecret=${Uri.encodeComponent(_qrCodeSecret)}'
        '&courseId=${Uri.encodeComponent(_session?.courseId ?? "")}'
        '&subject=${Uri.encodeComponent(subject)}'
        '&className=${Uri.encodeComponent(className)}'
        '&slot=${Uri.encodeComponent(slot)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.currentUser;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return DesktopScaffold(
      selectedIndex: 0,
      role: UserRole.student,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: isMobile ? 16 : 36,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _buildContent(context, user, isMobile: isMobile),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic user, {required bool isMobile}) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Đang tải thông tin phiên điểm danh & môn học...',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_loadError != null) {
      return Container(
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Không thể xác thực mã điểm danh', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              _loadError!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => context.go('/student/dashboard'),
                  child: const Text('Về trang chính'),
                ),
                const SizedBox(width: 12),
                PrimaryButton(
                  text: 'Nhập mã PIN thủ công',
                  icon: Icons.pin,
                  onPressed: () => context.go('/student/scan'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final session = _session;
    final course = _course;
    final isExpired = session != null && session.hasExpired;
    final isClosed = session != null && session.isClosed;
    final canCheckIn = !isExpired && !isClosed;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header status banner ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: canCheckIn ? AppColors.successBg : AppColors.errorBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: canCheckIn
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  canCheckIn ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: canCheckIn ? AppColors.success : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    canCheckIn
                        ? 'PHIÊN ĐIỂM DANH ĐANG HOẠT ĐỘNG'
                        : (isClosed ? 'PHIÊN ĐIỂM DANH ĐÃ ĐÓNG' : 'PHIÊN ĐIỂM DANH ĐÃ HẾT HẠN'),
                    style: TextStyle(
                      color: canCheckIn ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (canCheckIn && _remainingTime.inSeconds > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(_remainingTime),
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title & Intro ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: isMobile ? 40 : 48,
                      height: isMobile ? 40 : 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.qr_code_scanner, color: AppColors.accent, size: isMobile ? 22 : 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xác nhận điểm danh',
                            style: isMobile ? AppTextStyles.h3 : AppTextStyles.h2,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kiểm tra thông tin môn học và nhấn nút điểm danh bên dưới.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: isMobile ? 12 : 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // ── Box 1: Thông tin Môn học & Lớp ──
                Container(
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      if (isMobile)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    course?.subjectCode ?? 'MÔN HỌC',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (session != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.infoBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Ca học (Slot ${session.slotNumber})',
                                      style: const TextStyle(
                                        color: AppColors.info,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lớp ${course?.className ?? "Chưa rõ"}',
                              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary, fontSize: 16),
                            ),
                            Text(
                              'Học kỳ: ${course?.semester ?? "Hiện tại"}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                course?.subjectCode ?? 'MÔN HỌC',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lớp ${course?.className ?? "Chưa rõ"}',
                                    style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    'Học kỳ: ${course?.semester ?? "Hiện tại"}',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (session != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.infoBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Ca học (Slot ${session.slotNumber})',
                                  style: const TextStyle(
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 14),
                      _buildInfoRow(
                        icon: Icons.person_outline,
                        label: 'Giảng viên',
                        value: course?.lecturerDisplay ?? 'Giảng viên phụ trách',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        icon: Icons.fingerprint,
                        label: 'Mã phiên',
                        value: _sessionId,
                        isMonospace: true,
                      ),
                      if (_qrToken.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.token,
                          label: 'Dynamic Token',
                          value: _qrToken,
                          isMonospace: true,
                        ),
                      ],
                      if (session?.sessionCode != null) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.pin,
                          label: 'Mã PIN buổi học',
                          value: session!.sessionCode!,
                          isMonospace: true,
                        ),
                      ],
                      if (session?.roomNetworkIp != null && session!.roomNetworkIp!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.wifi,
                          label: 'Wi-Fi yêu cầu',
                          value: 'Phòng học (${session.roomNetworkIp})',
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Icons.security,
                          label: 'Bảo mật Wi-Fi',
                          value: 'Khớp BSSID hoặc Subnet /24',
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 14 : 20),

                // ── Box 2: Thông tin Sinh viên xác nhận ──
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 18 : 22,
                        backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                        child: Text(
                          user?.fullName.isNotEmpty == true ? user.fullName[0].toUpperCase() : 'S',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: isMobile ? 15 : 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Sinh viên',
                              style: AppTextStyles.label.copyWith(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'MSSV: ${user?.fapCode ?? user?.username ?? "Chưa rõ"}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Đã đăng nhập',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 20 : 28),

                // ── Nút ĐIỂM DANH NGAY ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: canCheckIn && !_isSubmitting ? _handleSubmitAttendance : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.inputBorder,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Đang gửi dữ liệu điểm danh về hệ thống...',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.how_to_reg, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'ĐIỂM DANH NGAY',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Hủy / Về trang chủ
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/student/dashboard'),
                    child: const Text(
                      'Hủy và quay lại trang chính',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
