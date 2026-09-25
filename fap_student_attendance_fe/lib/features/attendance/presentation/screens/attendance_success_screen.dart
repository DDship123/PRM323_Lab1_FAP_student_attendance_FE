import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/student_attendance_controller.dart';

/// Màn hình xác nhận điểm danh thành công cho sinh viên
class AttendanceSuccessScreen extends StatelessWidget {
  const AttendanceSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = StudentAttendanceController();
    final record = controller.lastCheckInRecord;

    final studentName = record?.studentName ?? record?.studentCode ?? 'Sinh viên';
    final timeStr = record != null
        ? '${record.checkInTime.hour.toString().padLeft(2, '0')}:${record.checkInTime.minute.toString().padLeft(2, '0')}:${record.checkInTime.second.toString().padLeft(2, '0')} · ${record.checkInTime.day}/${record.checkInTime.month}/${record.checkInTime.year}'
        : 'Vừa xong';
    final status = record?.status ?? 'PRESENT';

    return DesktopScaffold(
      selectedIndex: 0, // Buổi học
      role: UserRole.student,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // ── Success Card ──
              Container(
                width: 520,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Checkmark icon ──
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.success,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ── Success badge ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ĐIỂM DANH THÀNH CÔNG',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Title ──
                    Text(
                      'Xin chúc mừng, $studentName!',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Lượt điểm danh của bạn đã được ghi nhận trên hệ thống máy chủ.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    // ── Details Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          if (record != null) ...[
                            _buildDetailRow('ID Lượt điểm danh', record.id),
                            const SizedBox(height: 12),
                            _buildDetailRow('ID Phiên học', record.sessionId),
                            const SizedBox(height: 12),
                          ],
                          _buildDetailRow('Thời gian ghi nhận', timeStr),
                          const SizedBox(height: 12),
                          _buildDetailRow('Phương thức', 'Xác thực QR Code Token'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Trạng thái kết quả', status == 'PRESENT' ? 'Có mặt (Hợp lệ)' : status),
                          if (record?.distanceMeters != null) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow('Khoảng cách GPS', '${record!.distanceMeters!.toStringAsFixed(1)} mét'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // ── Back Button ──
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: 'Về trang sinh viên',
                        onPressed: () => context.go('/student/dashboard'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTextStyles.bodySmall,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.label.copyWith(fontSize: 13),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
