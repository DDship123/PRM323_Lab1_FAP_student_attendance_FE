import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../attendance/data/models/attendance_models.dart';
import '../../../attendance/presentation/controllers/student_attendance_controller.dart';

/// Màn hình Xem lịch sử điểm danh của Sinh viên
/// Hỗ trợ lọc theo khoảng thời gian (2 ô input Từ ngày - Đến ngày), theo môn học, và theo trạng thái
class StudentAttendanceHistoryScreen extends StatefulWidget {
  const StudentAttendanceHistoryScreen({super.key});

  @override
  State<StudentAttendanceHistoryScreen> createState() => _StudentAttendanceHistoryScreenState();
}

class _StudentAttendanceHistoryScreenState extends State<StudentAttendanceHistoryScreen> {
  final StudentAttendanceController _controller = StudentAttendanceController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedCourseId = 'ALL';
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.loadEnrollments();
    await _controller.loadAttendanceHistory();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2027),
      helpText: 'CHỌN TỪ NGÀY',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2023),
      lastDate: DateTime(2027),
      helpText: 'CHỌN ĐẾN NGÀY',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedCourseId = 'ALL';
      _selectedStatus = 'ALL';
    });
    _controller.loadAttendanceHistory();
  }

  List<AttendanceHistoryItemModel> _getFilteredHistory() {
    return _controller.attendanceHistory.where((item) {
      // 1. Filter theo Course
      if (_selectedCourseId != 'ALL' &&
          item.courseId != _selectedCourseId &&
          item.subjectCode != _selectedCourseId) {
        return false;
      }

      // 2. Filter theo Status
      if (_selectedStatus != 'ALL') {
        if (_selectedStatus == 'PRESENT' && !item.isPresent) return false;
        if (_selectedStatus == 'ABSENT' && item.isPresent) return false;
      }

      // 3. Filter theo khoảng thời gian
      if (item.checkedDateTime != null) {
        final dt = item.checkedDateTime!;
        if (_startDate != null) {
          final startDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          if (dt.isBefore(startDay)) return false;
        }
        if (_endDate != null) {
          final endDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
          if (dt.isAfter(endDay)) return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return DesktopScaffold(
      selectedIndex: 3, // Lịch sử điểm danh
      role: UserRole.student,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final filteredList = _getFilteredHistory();
          final totalRecords = filteredList.length;
          final presentRecords = filteredList.where((e) => e.isPresent).length;
          final absentRecords = totalRecords - presentRecords;
          final attendanceRate = totalRecords > 0 ? (presentRecords * 100 / totalRecords).toStringAsFixed(1) : '100';

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile: isMobile),
                SizedBox(height: isMobile ? 16 : 24),
                _buildStatsRow(totalRecords, presentRecords, absentRecords, attendanceRate, isMobile: isMobile),
                SizedBox(height: isMobile ? 16 : 24),
                _buildFilterBar(isMobile: isMobile, totalResults: totalRecords),
                SizedBox(height: isMobile ? 16 : 24),
                _buildHistorySection(filteredList, isMobile: isMobile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CỔNG SINH VIÊN · CHUYÊN CẦN',
                style: AppTextStyles.breadcrumb.copyWith(fontSize: 11),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Tải lại',
                onPressed: () => _controller.loadAttendanceHistory(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lịch sử điểm danh',
            style: AppTextStyles.h2.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            'Theo dõi chi tiết các phiên điểm danh và tỷ lệ chuyên cần.',
            style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CỔNG THÔNG TIN SINH VIÊN · LỊCH SỬ ĐIỂM DANH',
              style: AppTextStyles.breadcrumb,
            ),
            const SizedBox(height: 8),
            Text(
              'Nhật ký chuyên cần cá nhân',
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: 4),
            Text(
              'Theo dõi chi tiết các phiên điểm danh theo từng môn học và khoảng thời gian.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        Row(
          children: [
            SecondaryButton(
              text: 'Điểm danh ngay',
              icon: Icons.qr_code_scanner,
              onPressed: () => context.go('/student/scan'),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại',
              onPressed: () => _controller.loadAttendanceHistory(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(int total, int present, int absent, String rate, {required bool isMobile}) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  title: 'Tổng số buổi',
                  value: '$total',
                  color: AppColors.accent,
                  icon: Icons.event_note,
                  isMobile: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  title: 'Số buổi có mặt',
                  value: '$present',
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_outline,
                  isMobile: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  title: 'Số buổi vắng',
                  value: '$absent',
                  color: const Color(0xFFEF4444),
                  icon: Icons.cancel_outlined,
                  isMobile: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  title: 'Tỷ lệ chuyên cần',
                  value: '$rate%',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.pie_chart_outline,
                  isMobile: true,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            title: 'Tổng số buổi ghi nhận',
            value: '$total',
            color: AppColors.accent,
            icon: Icons.event_note,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            title: 'Số buổi có mặt',
            value: '$present',
            color: const Color(0xFF10B981),
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            title: 'Số buổi vắng mặt',
            value: '$absent',
            color: const Color(0xFFEF4444),
            icon: Icons.cancel_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            title: 'Tỷ lệ chuyên cần',
            value: '$rate%',
            color: const Color(0xFFF59E0B),
            icon: Icons.pie_chart_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 24),
          ),
          SizedBox(width: isMobile ? 10 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontSize: isMobile ? 11 : 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: isMobile ? 20 : 26,
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFromDatePicker() {
    return InkWell(
      onTap: _selectStartDate,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Từ ngày',
          labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          prefixIcon: const Icon(Icons.calendar_today, size: 16, color: AppColors.accent),
          suffixIcon: _startDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 14, color: AppColors.textMuted),
                  onPressed: () => setState(() => _startDate = null),
                )
              : null,
        ),
        child: Text(
          _startDate != null
              ? '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year}'
              : 'dd/mm/yyyy',
          style: AppTextStyles.body.copyWith(
            color: _startDate != null ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildToDatePicker() {
    return InkWell(
      onTap: _selectEndDate,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Đến ngày',
          labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          prefixIcon: const Icon(Icons.event, size: 16, color: AppColors.accent),
          suffixIcon: _endDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 14, color: AppColors.textMuted),
                  onPressed: () => setState(() => _endDate = null),
                )
              : null,
        ),
        child: Text(
          _endDate != null
              ? '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}'
              : 'dd/mm/yyyy',
          style: AppTextStyles.body.copyWith(
            color: _endDate != null ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: _endDate != null ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildFilterBar({required bool isMobile, int totalResults = 0}) {
    final courses = _controller.myCourses;
    final enrollments = _controller.enrollments;

    final courseOptions = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'ALL', child: Text('Tất cả môn học')),
    ];

    if (courses.isNotEmpty) {
      for (final c in courses) {
        if (!courseOptions.any((o) => o.value == c.id)) {
          courseOptions.add(DropdownMenuItem(
            value: c.id,
            child: Text('${c.subjectCode} - ${c.className}'),
          ));
        }
      }
    } else {
      for (final e in enrollments) {
        if (!courseOptions.any((o) => o.value == e.courseId)) {
          courseOptions.add(DropdownMenuItem(
            value: e.courseId,
            child: Text(e.courseTitle.isNotEmpty ? e.courseTitle : e.courseId),
          ));
        }
      }
    }

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCourseId,
              dropdownColor: Colors.white,
              isExpanded: true,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Môn học',
                labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
              items: courseOptions,
              onChanged: (val) {
                if (val != null) setState(() => _selectedCourseId = val);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              dropdownColor: Colors.white,
              isExpanded: true,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Trạng thái',
                labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Tất cả trạng thái')),
                DropdownMenuItem(value: 'PRESENT', child: Text('Có mặt (PRESENT)')),
                DropdownMenuItem(value: 'ABSENT', child: Text('Vắng mặt (ABSENT)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildFromDatePicker()),
                const SizedBox(width: 8),
                Expanded(child: _buildToDatePicker()),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tìm thấy $totalResults bản ghi',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 14, color: AppColors.textSecondary),
                  label: Text('Xóa lọc', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                  onPressed: _clearFilter,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // 1. Filter Course
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCourseId,
              dropdownColor: Colors.white,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Môn học',
                labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
              items: courseOptions,
              onChanged: (val) {
                if (val != null) setState(() => _selectedCourseId = val);
              },
            ),
          ),
          const SizedBox(width: 12),

          // 2. Filter Status
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              dropdownColor: Colors.white,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Trạng thái',
                labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Tất cả trạng thái')),
                DropdownMenuItem(value: 'PRESENT', child: Text('Có mặt (PRESENT)')),
                DropdownMenuItem(value: 'ABSENT', child: Text('Vắng mặt (ABSENT)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
          ),
          const SizedBox(width: 12),

          // 3. Input Từ ngày (From Date)
          Expanded(
            flex: 2,
            child: _buildFromDatePicker(),
          ),
          const SizedBox(width: 12),

          // 4. Input Đến ngày (To Date)
          Expanded(
            flex: 2,
            child: _buildToDatePicker(),
          ),
          const SizedBox(width: 12),

          // 5. Nút Xóa lọc
          TextButton.icon(
            icon: const Icon(Icons.clear, size: 16, color: AppColors.textSecondary),
            label: Text('Xóa lọc', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
            onPressed: _clearFilter,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(List<AttendanceHistoryItemModel> items, {required bool isMobile}) {
    if (_controller.isLoading && items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            const Icon(Icons.history_toggle_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Chưa có dữ liệu điểm danh', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              'Không tìm thấy bản ghi điểm danh nào phù hợp với bộ lọc hiện tại.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      return _buildMobileHistoryList(items);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
            horizontalMargin: 24,
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text('Môn học / Lớp', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Slot học', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Thời gian điểm danh', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Mã phiên', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Trạng thái', style: AppTextStyles.label.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
            ],
            rows: items.map((item) {
              final dt = item.checkedDateTime;
              final timeStr = dt != null
                  ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}'
                  : item.checkedAt;

              return DataRow(
                cells: [
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.subjectCode.isNotEmpty ? item.subjectCode : item.courseId,
                          style: AppTextStyles.label.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
                        ),
                        if (item.className.isNotEmpty)
                          Text(item.className, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Slot ${item.slotNumber}',
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                    ),
                  ),
                  DataCell(Text(timeStr, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
                  DataCell(
                    Text(
                      item.sessionId.length > 8 ? item.sessionId.substring(0, 8) : item.sessionId,
                      style: AppTextStyles.caption.copyWith(fontFamily: 'monospace', color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isPresent ? AppColors.successBg : AppColors.errorBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.isPresent ? Icons.check_circle : Icons.cancel,
                            size: 14,
                            color: item.isPresent ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.isPresent ? 'Có mặt' : 'Vắng mặt',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: item.isPresent ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHistoryList(List<AttendanceHistoryItemModel> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final dt = item.checkedDateTime;
        final timeStr = dt != null
            ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} · ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
            : item.checkedAt;

        return Container(
          padding: const EdgeInsets.all(14),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.subjectCode.isNotEmpty ? item.subjectCode : item.courseId,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.isPresent ? AppColors.successBg : AppColors.errorBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isPresent ? Icons.check_circle : Icons.cancel,
                          size: 13,
                          color: item.isPresent ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isPresent ? 'Có mặt' : 'Vắng mặt',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: item.isPresent ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.className.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.className,
                  style: AppTextStyles.h4.copyWith(fontSize: 15),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Slot ${item.slotNumber}',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  Text(
                    item.sessionId.length > 8 ? item.sessionId.substring(0, 8) : item.sessionId,
                    style: AppTextStyles.caption.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
