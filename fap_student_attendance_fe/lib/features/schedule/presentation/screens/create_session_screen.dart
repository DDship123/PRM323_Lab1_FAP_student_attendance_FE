import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../courses/presentation/controllers/course_controller.dart';
import '../../../courses/data/models/course_model.dart';
import '../controllers/session_controller.dart';

/// Màn hình lên lịch & tạo phiên điểm danh cho giảng viên
class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final CourseController _courseController = CourseController();
  final SessionController _sessionController = SessionController();

  CourseModel? _selectedCourse;
  int _slotNumber = 1;
  DateTime _sessionDate = DateTime.now();
  int _durationMinutes = 15;
  int _qrRefreshSeconds = 20;
  final TextEditingController _roomNetworkIpController = TextEditingController();
  final TextEditingController _roomBssidController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _roomNetworkIpController.dispose();
    _roomBssidController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    if (_courseController.courses.isEmpty) {
      await _courseController.loadCourses();
    }
    setState(() {
      _selectedCourse = _courseController.selectedCourse ??
          (_courseController.courses.isNotEmpty ? _courseController.courses.first : null);
    });
  }

  Future<void> _handleStartSession() async {
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn hoặc tạo ít nhất một khóa học trước!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final session = await _sessionController.createSession(
      courseId: _selectedCourse!.id,
      slotNumber: _slotNumber,
      sessionDate: _sessionDate,
      durationMinutes: _durationMinutes,
      qrRefreshSeconds: _qrRefreshSeconds,
      roomNetworkIp: _roomNetworkIpController.text.trim().isNotEmpty
          ? _roomNetworkIpController.text.trim()
          : null,
      roomBssid: _roomBssidController.text.trim().isNotEmpty
          ? _roomBssidController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (session != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Khởi tạo phiên điểm danh Slot $_slotNumber cho lớp ${_selectedCourse!.className} thành công!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/attendance/live');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _sessionController.errorMessage ??
                'Không thể tạo phiên điểm danh. Vui lòng kiểm tra lại máy chủ.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      selectedIndex: 2, // Lịch học
      role: UserRole.lecturer,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildForm(context),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 320,
                  child: _buildSummaryPanel(),
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
                'QUẢN LÝ PHIÊN HỌC · TẠO MÃ QR ĐIỂM DANH',
                style: AppTextStyles.breadcrumb,
              ),
              const SizedBox(height: 8),
              Text(
                'Khởi tạo phiên điểm danh',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 4),
              Text(
                'Tạo phiên điểm danh trực tiếp kết nối với Ứng dụng, sinh mã QR bảo mật theo thời gian thực.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cấu hình phiên điểm danh', style: AppTextStyles.h3),
          const SizedBox(height: 24),

          // ── Chọn khóa học ──
          Text('Môn học & Lớp học *', style: AppTextStyles.label),
          const SizedBox(height: 8),
          if (_courseController.courses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Bạn chưa có môn học nào. Hãy tạo môn học trước.'),
                  ),
                  PrimaryButton(
                    text: 'Tạo môn ngay',
                    onPressed: () => context.go('/courses/create'),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<CourseModel>(
              initialValue: _selectedCourse,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _courseController.courses.map((course) {
                return DropdownMenuItem<CourseModel>(
                  value: course,
                  child: Text(
                    '${course.subjectCode} · ${course.className} (${course.semester})',
                    style: AppTextStyles.body,
                  ),
                );
              }).toList(),
              onChanged: (course) {
                setState(() => _selectedCourse = course);
                _courseController.setSelectedCourse(course);
              },
            ),

          const SizedBox(height: 20),

          // ── Row: Slot học + Thời lượng QR ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ca học (Slot: 1 - 6) *', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _slotNumber,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [1, 2, 3, 4, 5, 6].map((slot) {
                        return DropdownMenuItem<int>(
                          value: slot,
                          child: Text('Slot $slot (Ca $slot)'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _slotNumber = v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thời hạn hiệu lực mã QR *', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _durationMinutes,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [5, 10, 15, 30, 45, 60].map((min) {
                        return DropdownMenuItem<int>(
                          value: min,
                          child: Text('$min phút'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _durationMinutes = v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Chu kỳ đổi mã QR động (TOTP qrRefreshSeconds - Mặc định 20s) ──
          Text('Thời gian tự động làm mới mã QR (qrRefreshSeconds) *', style: AppTextStyles.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _qrRefreshSeconds,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              helperText: 'Thời gian đổi mã QR động TOTP trên máy chiếu (Mặc định: 20 giây per Section 4.1).',
            ),
            items: const [
              DropdownMenuItem<int>(value: 10, child: Text('10 giây')),
              DropdownMenuItem<int>(value: 20, child: Text('20 giây (Mặc định)')),
              DropdownMenuItem<int>(value: 30, child: Text('30 giây')),
              DropdownMenuItem<int>(value: 60, child: Text('60 giây (1 phút)')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _qrRefreshSeconds = v);
            },
          ),

          const SizedBox(height: 20),

          // ── Ngày học ──
          Text('Ngày học (sessionDate) *', style: AppTextStyles.label),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _sessionDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _sessionDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Text(
                    '${_sessionDate.year}-${_sessionDate.month.toString().padLeft(2, '0')}-${_sessionDate.day.toString().padLeft(2, '0')}',
                    style: AppTextStyles.body,
                  ),
                  const Spacer(),
                  const Text('Chọn ngày', style: TextStyle(color: AppColors.accent)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Mạng Wi-Fi Thích Ứng (Adaptive Wi-Fi - Tự động) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wifi_protected_setup, color: AppColors.info, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Bảo mật Wi-Fi Thích Ứng (Tự động nhận diện)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.info),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Hệ thống tự động ghi nhận địa chỉ mạng của giảng viên và so khớp Subnet /24 với sinh viên. Giảng viên không cần nhập trường IP và BSSID khi tạo phiên mới.',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Cài đặt mạng nâng cao (Tùy chọn ghi đè - Mặc định ẩn) ──
          Material(
            color: Colors.transparent,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Cài đặt mạng nâng cao (Tùy chọn ghi đè)',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                const SizedBox(height: 8),
                // Địa chỉ MAC Router Wi-Fi (BSSID)
                Text('Địa chỉ MAC Router Wi-Fi phòng học (BSSID) - Tùy chọn', style: AppTextStyles.label),
                const SizedBox(height: 8),
                TextField(
                  controller: _roomBssidController,
                  decoration: const InputDecoration(
                    hintText: 'VD: c8:0e:14:2b:8a:90',
                    helperText: 'Nếu nhập, sinh viên trên Mobile App bắt buộc phải kết nối đúng Router phòng học này.',
                    prefixIcon: Icon(Icons.router_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Ghi đè IP Wi-Fi thủ công (nếu cần)
                Text('Ghi đè IP mạng phòng học (Tùy chọn ghi đè)', style: AppTextStyles.label),
                const SizedBox(height: 8),
                TextField(
                  controller: _roomNetworkIpController,
                  decoration: const InputDecoration(
                    hintText: 'Để trống = Tự động lấy IP của Giảng viên',
                    helperText: 'Chỉ nhập nếu bạn muốn chỉ định một dải mạng LAN hoặc IP cụ thể.',
                    prefixIcon: Icon(Icons.wifi, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

          const SizedBox(height: 32),

          // ── Action Buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SecondaryButton(
                text: 'Hủy',
                onPressed: () => context.go('/courses'),
              ),
              const SizedBox(width: 16),
              PrimaryButton(
                text: 'Khởi tạo phiên & Mở mã QR',
                icon: Icons.qr_code_2,
                isLoading: _isLoading,
                onPressed: _handleStartSession,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel() {
    final dateStr =
        '${_sessionDate.day}/${_sessionDate.month}/${_sessionDate.year}';
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
          Text('Tóm tắt cấu hình', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          if (_selectedCourse != null) ...[
            Text(
              '${_selectedCourse!.subjectCode} · ${_selectedCourse!.className}',
              style: AppTextStyles.label.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: 8),
            _summaryRow('Học kỳ: ${_selectedCourse!.semester}'),
          ] else ...[
            Text('Chưa chọn khóa học', style: AppTextStyles.bodySmall),
          ],
          _summaryRow('Ngày: $dateStr'),
          _summaryRow('Ca học: Slot $_slotNumber'),
          _summaryRow('Thời lượng: $_durationMinutes phút'),
          const Divider(height: 24),
          Text(
            'Sau khi bấm khởi tạo, hệ thống sẽ kích hoạt phiên điểm danh trên Ứng dụng và mở màn hình QR Live cho sinh viên quét.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.bodySmall),
    );
  }
}
