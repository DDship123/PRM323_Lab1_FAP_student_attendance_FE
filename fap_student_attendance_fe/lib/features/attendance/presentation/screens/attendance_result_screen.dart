import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/attendance_error_helper.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/student_attendance_controller.dart';

/// Màn hình hiển thị kết quả điểm danh (Thành công hoặc Thất bại)
class AttendanceResultScreen extends StatelessWidget {
  const AttendanceResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final status = uri.queryParameters['status'] ?? 'success';
    final isSuccess = status == 'success';

    final user = AuthController().currentUser;
    final lastRecord = StudentAttendanceController().lastCheckInRecord;

    final studentName = uri.queryParameters['studentName'] ??
        lastRecord?.studentName ??
        user?.fullName ??
        'Sinh viên';
    final fapCode = uri.queryParameters['fapCode'] ??
        lastRecord?.studentFapCode ??
        user?.fapCode ??
        user?.username ??
        '';
    final subject = uri.queryParameters['subject'] ?? 'Môn học';
    final className = uri.queryParameters['className'] ?? '';
    final slot = uri.queryParameters['slot'] ?? '1';
    final sessionId = uri.queryParameters['sessionId'] ?? lastRecord?.sessionId ?? '';
    final qrCodeSecret = uri.queryParameters['qrCodeSecret'] ?? '';

    final rawCheckedAt = uri.queryParameters['checkedAt'] ?? lastRecord?.checkedAt;
    String timeStr = 'Vừa xong';
    if (rawCheckedAt != null && rawCheckedAt.isNotEmpty) {
      final dt = DateTime.tryParse(rawCheckedAt);
      if (dt != null) {
        timeStr =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} · ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    }

    final rawMessage = uri.queryParameters['rawMessage'] ?? uri.queryParameters['message'];
    final errorInfo = AttendanceErrorHelper.parse(rawMessage ?? uri.queryParameters['message']);
    final errorTitle = uri.queryParameters['title'] ?? errorInfo.title;
    final errorMessage = uri.queryParameters['message'] ?? errorInfo.message;
    final errorSuggestion = uri.queryParameters['suggestion'] ?? errorInfo.suggestion;
    final qrToken = uri.queryParameters['qrToken'] ?? '';

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
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 18 : 36,
                vertical: isMobile ? 24 : 40,
              ),
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
              child: isSuccess
                  ? _buildSuccessView(
                      context: context,
                      studentName: studentName,
                      fapCode: fapCode,
                      subject: subject,
                      className: className,
                      slot: slot,
                      sessionId: sessionId,
                      timeStr: timeStr,
                      isMobile: isMobile,
                    )
                  : _buildFailureView(
                      context: context,
                      errorTitle: errorTitle,
                      errorMessage: errorMessage,
                      errorSuggestion: errorSuggestion,
                      errorInfo: errorInfo,
                      sessionId: sessionId,
                      qrToken: qrToken,
                      qrCodeSecret: qrCodeSecret,
                      subject: subject,
                      className: className,
                      isMobile: isMobile,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Giao diện KẾT QUẢ THÀNH CÔNG ──
  Widget _buildSuccessView({
    required BuildContext context,
    required String studentName,
    required String fapCode,
    required String subject,
    required String className,
    required String slot,
    required String sessionId,
    required String timeStr,
    required bool isMobile,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon checkmark
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 44,
          ),
        ),
        const SizedBox(height: 18),

        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'ĐIỂM DANH THÀNH CÔNG',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          'Xin chúc mừng, $studentName!',
          style: AppTextStyles.h2.copyWith(fontSize: isMobile ? 18 : 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Lượt điểm danh của bạn đã được ghi nhận trên hệ thống máy chủ FAP.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Bảng chi tiết
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                'Sinh viên',
                fapCode.isNotEmpty ? '$studentName ($fapCode)' : studentName,
                isMobile: isMobile,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Môn học & Lớp',
                className.isNotEmpty ? '$subject · Lớp $className' : subject,
                isHighlight: true,
                isMobile: isMobile,
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Ca học (Slot)', 'Slot $slot', isMobile: isMobile),
              const SizedBox(height: 12),
              _buildDetailRow('Thời gian', timeStr, isMobile: isMobile),
              const SizedBox(height: 12),
              _buildDetailRow('Phương thức', 'Xác thực mã QR hợp lệ', isMobile: isMobile),
              const SizedBox(height: 12),
              _buildDetailRow('Trạng thái', 'Có mặt (PRESENT)', statusColor: AppColors.success, isMobile: isMobile),
              if (sessionId.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Mã phiên', sessionId, isMonospace: true, isMobile: isMobile),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        if (isMobile)
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Về trang sinh viên',
                  icon: Icons.home_outlined,
                  onPressed: () => context.go('/student/dashboard'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.inputBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.go('/student/history'),
                  child: const Text('Xem lịch sử điểm danh', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.inputBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.go('/student/history'),
                  child: const Text('Xem lịch sử', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'Về trang sinh viên',
                  icon: Icons.home_outlined,
                  onPressed: () => context.go('/student/dashboard'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Giao diện KẾT QUẢ THẤT BẠI (UI Handling chuẩn theo Section 5) ──
  Widget _buildFailureView({
    required BuildContext context,
    required String errorTitle,
    required String errorMessage,
    required String? errorSuggestion,
    required AttendanceErrorInfo errorInfo,
    required String sessionId,
    required String qrToken,
    required String qrCodeSecret,
    required String subject,
    required String className,
    required bool isMobile,
  }) {
    final isQrExpired = errorMessage.contains('đổi chu kỳ') ||
        errorTitle.contains('chu kỳ') ||
        errorMessage.contains('quét lại mã mới');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon cảnh báo / lỗi tùy biến theo loại lỗi
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: errorInfo.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: errorInfo.color.withValues(alpha: 0.35), width: 2),
          ),
          child: Icon(
            errorInfo.icon,
            color: errorInfo.color,
            size: 40,
          ),
        ),
        const SizedBox(height: 18),

        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: errorInfo.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            errorTitle.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: errorInfo.color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          errorTitle,
          style: AppTextStyles.h2.copyWith(fontSize: isMobile ? 18 : 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Hệ thống đã phát hiện điều kiện không thỏa mãn an ninh hoặc chu kỳ mã.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Hộp thông báo lỗi thân thiện (UI Handling theo bảng Mục 5)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: errorInfo.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: errorInfo.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: errorInfo.color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông báo từ hệ thống:',
                      style: TextStyle(
                        color: errorInfo.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      errorMessage,
                      style: TextStyle(
                        color: errorInfo.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Hộp gợi ý giải pháp hành động
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text(
                    'Hướng dẫn khắc phục:',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (errorSuggestion != null && errorSuggestion.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    errorSuggestion,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
              _buildBulletPoint('Mã QR đổi mới mỗi 10 giây qua TOTP: Hướng camera quét lại mã mới nhất trên máy chiếu.'),
              _buildBulletPoint('Wi-Fi phòng học: Tắt 4G/5G/VPN và kết nối vào Wi-Fi phòng học để cùng dải mạng.'),
              _buildBulletPoint('Chống điểm danh hộ: Không dùng một máy điện thoại để quét hộ cho sinh viên khác.'),
              _buildBulletPoint('Nếu camera gặp lỗi: Sử dụng chức năng Nhập mã PIN 6 số trên màn hình máy chiếu.'),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Action Buttons
        Column(
          children: [
            if (isQrExpired) ...[
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Quét lại mã mới trên máy chiếu',
                  icon: Icons.qr_code_scanner,
                  onPressed: () => context.go('/student/scan'),
                ),
              ),
              const SizedBox(height: 10),
            ] else if (sessionId.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Thử lại điểm danh',
                  icon: Icons.refresh,
                  onPressed: () {
                    final tokenParam = qrToken.isNotEmpty
                        ? '&qrToken=${Uri.encodeComponent(qrToken)}'
                        : '&qrCodeSecret=${Uri.encodeComponent(qrCodeSecret)}';

                    context.go(
                      '/student/check-in?sessionId=${Uri.encodeComponent(sessionId)}'
                      '$tokenParam'
                      '&subject=${Uri.encodeComponent(subject)}'
                      '&className=${Uri.encodeComponent(className)}',
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (isMobile) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.pin, size: 18),
                  label: const Text('Nhập mã PIN thủ công'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.inputBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.go('/student/scan'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text('Về trang sinh viên'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.inputBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.go('/student/dashboard'),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.pin, size: 18),
                      label: const Text('Nhập mã PIN'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.inputBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => context.go('/student/scan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text('Về trang chính'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.inputBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => context.go('/student/dashboard'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
    bool isMonospace = false,
    Color? statusColor,
    bool isMobile = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 115 : 150,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: statusColor ?? (isHighlight ? AppColors.accent : AppColors.textPrimary),
              fontWeight: isHighlight || statusColor != null ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}
