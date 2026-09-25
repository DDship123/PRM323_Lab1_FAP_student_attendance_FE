import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/utils/network_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../schedule/presentation/controllers/session_controller.dart';
import '../../../schedule/data/models/session_model.dart';
import '../../../courses/presentation/controllers/course_controller.dart';
import '../../data/models/attendance_models.dart';

/// Màn hình điểm danh QR real-time cho Giảng viên
class AttendanceLiveScreen extends StatefulWidget {
  const AttendanceLiveScreen({super.key});

  @override
  State<AttendanceLiveScreen> createState() => _AttendanceLiveScreenState();
}

class _AttendanceLiveScreenState extends State<AttendanceLiveScreen> {
  final SessionController _sessionController = SessionController();

  late TextEditingController _hostController;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: '192.168.1.101:5000');
    _detectLocalHost();
  }

  Future<void> _detectLocalHost() async {
    final host = await NetworkInfo.getLocalHost(port: 5000);
    if (mounted) {
      setState(() {
        _hostController.text = host;
      });
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  bool _showBackendQrImage = true;

  /// Tạo nội dung cho mã QR quét qua điện thoại
  String _buildQrPayload(AttendanceSessionModel session) {
    final host = _hostController.text.trim().isNotEmpty
        ? _hostController.text.trim()
        : '192.168.1.101:5000';
    final scheme = (Uri.base.scheme.isNotEmpty && Uri.base.scheme.startsWith('http'))
        ? Uri.base.scheme
        : 'http';

    final course = CourseController().selectedCourse;
    final courseParams = course != null
        ? '&courseId=${course.courseId}&subject=${Uri.encodeComponent(course.subjectCode)}&className=${Uri.encodeComponent(course.className)}&semester=${Uri.encodeComponent(course.semester)}'
        : (session.courseId.isNotEmpty ? '&courseId=${session.courseId}' : '');

    final dynamicToken = _sessionController.currentQrToken;
    final tokenParam = dynamicToken != null && dynamicToken.isNotEmpty
        ? '&qrToken=$dynamicToken'
        : '&qrCodeSecret=${session.qrCodeSecret}';

    return '$scheme://$host/#/student/check-in?sessionId=${session.id}$tokenParam$courseParams';
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      selectedIndex: 3, // Điểm danh
      role: UserRole.lecturer,
      body: ListenableBuilder(
        listenable: _sessionController,
        builder: (context, _) {
          final session = _sessionController.currentSession;

          if (session == null) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 20),
                    Text('Chưa có phiên điểm danh nào đang chạy', style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy tạo một phiên học mới để mở mã QR và bắt đầu nhận diện điểm danh.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Tạo phiên điểm danh mới',
                      icon: Icons.add,
                      onPressed: () => context.go('/schedule/create'),
                    ),
                  ],
                ),
              ),
            );
          }

          final isExpired = _sessionController.remainingSeconds <= 0;
          final qrPayload = _buildQrPayload(session);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, session, isExpired),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left: QR Code ──
                    Expanded(
                      flex: 3,
                      child: _buildQRSection(context, session, qrPayload, isExpired),
                    ),
                    const SizedBox(width: 24),
                    // ── Right: Stats + Live check-ins ──
                    Expanded(
                      flex: 3,
                      child: _buildStatsSection(context),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AttendanceSessionModel session, bool isExpired) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isExpired ? 'PHIÊN ĐIỂM DANH ĐÃ HẾT HẠN' : 'ĐANG ĐIỂM DANH THỜI GIAN THỰC (DYNAMIC TOTP)',
                style: AppTextStyles.breadcrumb.copyWith(
                  color: isExpired ? AppColors.textSecondary : AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phiên học Ca (Slot) ${session.slotNumber}',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 4),
              Text(
                'Ngày: ${session.sessionDate.year}-${session.sessionDate.month.toString().padLeft(2, '0')}-${session.sessionDate.day.toString().padLeft(2, '0')} · Trạng thái: ${session.status}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            DangerButton(
              text: 'Kết thúc điểm danh',
              icon: Icons.stop_circle_outlined,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Đóng phiên điểm danh'),
                    content: const Text(
                      'Bạn có chắc chắn muốn đóng phiên điểm danh này? Sinh viên sẽ không thể quét QR được nữa.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Đóng phiên ngay', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _sessionController.closeCurrentSession();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đóng phiên điểm danh thành công!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.go('/attendance/results');
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQRSection(
    BuildContext context,
    AttendanceSessionModel session,
    String qrPayload,
    bool isExpired,
  ) {
    final currentToken = _sessionController.currentQrToken ?? session.currentQrToken ?? '4F3A8B12';
    final tokenRemaining = _sessionController.tokenRemainingSeconds;
    final tokenInterval = _sessionController.tokenIntervalSeconds;
    final tokenProgress = _sessionController.tokenProgress;
    final isStream = _sessionController.isStreamActive;
    final base64Image = _sessionController.qrCodeBase64 ?? session.qrCodeBase64;

    // Màu sắc thanh countdown thay đổi theo độ khẩn cấp (xanh -> cam -> đỏ)
    final Color progressColor = tokenRemaining > 5
        ? AppColors.success
        : (tokenRemaining > 2 ? AppColors.warning : AppColors.error);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // ── Status bar & Stream Badge ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isExpired ? AppColors.warningBg : AppColors.successBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isExpired ? 'MÃ QR ĐÃ HẾT HẠN' : 'MÃ QR ĐỘNG ĐANG CHẠY',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isExpired ? AppColors.warning : AppColors.success,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isStream ? AppColors.success.withValues(alpha: 0.1) : AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isStream ? AppColors.success.withValues(alpha: 0.3) : AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isStream ? Icons.sensors : Icons.sync,
                          size: 13,
                          color: isStream ? AppColors.success : AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isStream ? 'SSE Stream' : 'Auto Polling',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isStream ? AppColors.success : AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                _sessionController.formattedRemainingTime,
                style: AppTextStyles.h2.copyWith(
                  color: isExpired ? AppColors.textSecondary : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── THANH COUNTDOWN ĐẾM NGƯỢC 10s (TOTP Countdown Bar) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: progressColor),
                        const SizedBox(width: 6),
                        Text(
                          'Đổi chu kỳ QR mới sau:',
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      '${tokenRemaining}s / ${tokenInterval}s',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: progressColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tokenProgress,
                    minHeight: 6,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── QR Code View (Backend Base64 hoặc QrImageView) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox(
              width: 220,
              height: 220,
              child: (_showBackendQrImage && base64Image != null && base64Image.isNotEmpty)
                  ? Image.memory(
                      base64Decode(base64Image.split(',').last),
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return QrImageView(
                          data: qrPayload,
                          version: QrVersions.auto,
                          size: 220,
                          gapless: true,
                        );
                      },
                    )
                  : QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 220,
                      gapless: true,
                      errorStateBuilder: (context, error) {
                        return const Center(child: Text('Lỗi hiển thị QR'));
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // Nút đổi chế độ hiển thị QR (TOTP Token vs Web Deep Link)
          TextButton.icon(
            onPressed: () {
              setState(() => _showBackendQrImage = !_showBackendQrImage);
            },
            icon: Icon(
              _showBackendQrImage ? Icons.link : Icons.qr_code_2,
              size: 16,
              color: AppColors.accent,
            ),
            label: Text(
              _showBackendQrImage
                  ? 'Chuyển sang: Mã QR chứa liên kết Web'
                  : 'Chuyển sang: Mã QR động TOTP (Khuyến nghị)',
              style: const TextStyle(fontSize: 12, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),

          // ── DYNAMIC QR TOKEN (8 ký tự Hex) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.token, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text('Mã Dynamic Token: ', style: AppTextStyles.label.copyWith(fontSize: 13)),
                Text(
                  currentToken,
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 3,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: AppColors.accent),
                  tooltip: 'Sao chép mã QR Token 8 ký tự',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: currentToken));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép Dynamic QR Token vào bộ nhớ tạm!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── PIN CODE Display (Học sinh có thể nhập mã code nếu camera hỏng) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pin, color: AppColors.textPrimary, size: 20),
                const SizedBox(width: 8),
                Text('Mã PIN 6 số dự phòng: ', style: AppTextStyles.label.copyWith(fontSize: 13)),
                Text(
                  session.sessionCode ?? '849201',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
                  tooltip: 'Sao chép mã PIN 6 số',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: session.sessionCode ?? '849201'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép mã PIN 6 số vào bộ nhớ tạm!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Ghi chú Chống gian lận ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 15, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chống gian lận: 1 thiết bị chỉ điểm danh cho đúng 1 sinh viên/buổi học.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Instructions ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sinh viên dùng App mở Camera quét mã QR (hoặc nhập Token / mã PIN) để điểm danh.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Refresh / New Session button ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tạo phiên mới khác'),
              onPressed: () => context.go('/schedule/create'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final records = _sessionController.liveRecords;
    return Column(
      children: [
        // ── Stats Cards Row ──
        Row(
          children: [
            Expanded(
              child: _buildStatCard('${records.length}', 'Đã điểm danh', AppColors.success),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard('Đang mở', 'Trạng thái phiên', AppColors.accent),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // ── Recent Check-ins Panel ──
        _buildRecentPanel(records),
      ],
    );
  }

  Widget _buildStatCard(String number, String label, Color color) {
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
          Text(
            number,
            style: AppTextStyles.statNumber.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.statLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPanel(List<AttendanceRecordModel> records) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sinh viên vừa điểm danh (Live)', style: AppTextStyles.h4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Chưa có sinh viên nào điểm danh trong phiên này.\nDanh sách sẽ tự động cập nhật khi có sinh viên quét mã.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final r = records[index];
                final checkInTimeStr =
                    '${r.checkInTime.hour.toString().padLeft(2, '0')}:${r.checkInTime.minute.toString().padLeft(2, '0')}:${r.checkInTime.second.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${r.studentName ?? r.studentCode ?? "Sinh viên"} · $checkInTimeStr',
                          style: AppTextStyles.body,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.status,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
