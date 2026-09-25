import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../schedule/presentation/controllers/session_controller.dart';
import '../../../schedule/data/models/session_model.dart';
import '../../data/models/attendance_models.dart';
import '../../data/repositories/attendance_repository.dart';

/// Màn hình kết quả điểm danh — hiển thị dữ liệu thật từ Backend
class AttendanceResultsScreen extends StatefulWidget {
  const AttendanceResultsScreen({super.key});

  @override
  State<AttendanceResultsScreen> createState() => _AttendanceResultsScreenState();
}

class _AttendanceResultsScreenState extends State<AttendanceResultsScreen> {
  final SessionController _sessionController = SessionController();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();

  bool _isLoading = true;
  bool _isExporting = false;
  String? _error;

  AttendanceSessionModel? _session;
  List<AttendanceRecordModel> _records = [];
  List<EnrollmentModel> _enrollments = [];

  // Derived data
  List<_StudentResult> _allStudents = [];
  int _presentCount = 0;
  int _absentCount = 0;
  int _totalCount = 0;

  int _selectedFilter = 0; // 0 = Tất cả, 1 = Có mặt, 2 = Vắng

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _session = _sessionController.currentSession;

      if (_session == null) {
        setState(() {
          _isLoading = false;
          _error = 'Không tìm thấy phiên điểm danh. Vui lòng quay lại.';
        });
        return;
      }

      _records = await _attendanceRepo.getSessionRecords(_session!.sessionId);

      try {
        _enrollments = await _attendanceRepo.getStudentsByCourse(_session!.courseId);
      } catch (_) {
        _enrollments = [];
      }

      _buildStudentResults();
    } catch (e) {
      _error = 'Lỗi khi tải dữ liệu: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExportExcel() async {
    if (_session == null) return;
    setState(() => _isExporting = true);
    try {
      final success = await _attendanceRepo.exportAttendanceExcel(_session!.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Xuất file Excel (.xlsx) thành công! File đã được lưu về máy.' : 'Không thể lưu file Excel.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất file Excel: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleExportCsv() async {
    if (_session == null) return;
    setState(() => _isExporting = true);
    try {
      final success = await _attendanceRepo.exportAttendanceCsv(_session!.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Xuất file CSV thành công! File đã được lưu về máy.' : 'Không thể lưu file CSV.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất file CSV: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _buildStudentResults() {
    final recordMap = <String, AttendanceRecordModel>{};
    for (final r in _records) {
      recordMap[r.studentId] = r;
    }

    final results = <_StudentResult>[];
    final processedIds = <String>{};

    for (final e in _enrollments) {
      processedIds.add(e.studentId);
      final record = recordMap[e.studentId];
      results.add(_StudentResult(
        mssv: record?.studentFapCode ?? e.fapCode ?? e.studentId.substring(0, 8),
        fullName: record?.studentName ?? e.studentName ?? 'Không rõ',
        checkedAt: record?.checkedAt,
        isPresent: record != null,
      ));
    }

    for (final r in _records) {
      if (!processedIds.contains(r.studentId)) {
        results.add(_StudentResult(
          mssv: r.studentFapCode ?? r.studentId.substring(0, 8),
          fullName: r.studentName ?? 'Không rõ',
          checkedAt: r.checkedAt,
          isPresent: true,
        ));
      }
    }

    results.sort((a, b) {
      if (a.isPresent != b.isPresent) return a.isPresent ? -1 : 1;
      return a.fullName.compareTo(b.fullName);
    });

    _allStudents = results;
    _presentCount = results.where((s) => s.isPresent).length;
    _absentCount = results.where((s) => !s.isPresent).length;
    _totalCount = results.length;
  }

  List<_StudentResult> get _filteredStudents {
    switch (_selectedFilter) {
      case 1:
        return _allStudents.where((s) => s.isPresent).toList();
      case 2:
        return _allStudents.where((s) => !s.isPresent).toList();
      default:
        return _allStudents;
    }
  }

  String _formatSessionInfo() {
    if (_session == null) return '';
    final dt = _session!.sessionDate;
    return 'Slot ${_session!.slotNumber} · '
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} · '
        'Trạng thái: ${_session!.status}';
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '—';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String get _attendanceRate {
    if (_totalCount == 0) return '0%';
    final rate = (_presentCount / _totalCount * 100);
    return '${rate.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      selectedIndex: 3,
      role: UserRole.lecturer,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  SizedBox(height: 16),
                  Text('Đang tải kết quả điểm danh...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: AppTextStyles.body),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'Quay lại',
                        onPressed: () => context.go('/attendance/manage'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 28),
                      _buildStatsRow(),
                      const SizedBox(height: 28),
                      _buildStudentTable(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ĐÃ KẾT THÚC PHIÊN ĐIỂM DANH',
                style: AppTextStyles.breadcrumb.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Text(
                'Kết quả điểm danh',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 4),
              Text(
                _formatSessionInfo(),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go('/attendance/manage'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Quản lý điểm danh'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.cardBorder),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              icon: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF60A5FA)),
              label: const Text('Xuất CSV'),
              onPressed: _isExporting ? null : _handleExportCsv,
            ),
            const SizedBox(width: 12),
            PrimaryButton(
              text: 'Xuất file Excel (.xlsx)',
              icon: Icons.table_view,
              isLoading: _isExporting,
              onPressed: _handleExportExcel,
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('$_presentCount', 'Có mặt', AppColors.success),
        const SizedBox(width: 16),
        _buildStatCard('$_absentCount', 'Vắng mặt', AppColors.error),
        const SizedBox(width: 16),
        _buildStatCard('$_totalCount', 'Tổng sinh viên', AppColors.accent),
        const SizedBox(width: 16),
        _buildStatCard(_attendanceRate, 'Tỷ lệ tham gia', AppColors.info),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
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
              value,
              style: AppTextStyles.statNumber.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.statLabel),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTable() {
    final filtered = _filteredStudents;

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
          // ── Title + Filter Tabs ──
          Row(
            children: [
              Text('Danh sách sinh viên', style: AppTextStyles.h4),
              const Spacer(),
              _buildFilterTabs(),
            ],
          ),
          const SizedBox(height: 20),
          // ── Table ──
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  _selectedFilter == 0
                      ? 'Không có dữ liệu sinh viên'
                      : _selectedFilter == 1
                          ? 'Không có sinh viên có mặt'
                          : 'Không có sinh viên vắng',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            )
          else
            _buildTable(filtered),
          const SizedBox(height: 16),
          Text(
            'Dữ liệu được tải trực tiếp từ Ứng dụng. '
            'Tổng: $_totalCount sinh viên · Có mặt: $_presentCount · Vắng: $_absentCount.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      ('Tất cả $_totalCount', AppColors.textSecondary, AppColors.surfaceVariant),
      ('Có mặt $_presentCount', AppColors.success, AppColors.successBg),
      ('Vắng $_absentCount', AppColors.error, AppColors.errorBg),
    ];

    return Row(
      children: List.generate(filters.length, (index) {
        final isSelected = _selectedFilter == index;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? filters[index].$3 : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: filters[index].$2.withValues(alpha: 0.3))
                    : null,
              ),
              child: Text(
                filters[index].$1,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? filters[index].$2 : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTable(List<_StudentResult> students) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(0.5),  // #
        1: FlexColumnWidth(1.2),  // MSSV
        2: FlexColumnWidth(2),    // Họ và tên
        3: FlexColumnWidth(1.2),  // Thời gian
        4: FlexColumnWidth(1.2),  // Trạng thái
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: AppColors.divider, width: 1),
      ),
      children: [
        // ── Header ──
        TableRow(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          children: [
            _tableHeaderCell('#'),
            _tableHeaderCell('MSSV'),
            _tableHeaderCell('Họ và tên'),
            _tableHeaderCell('Thời gian'),
            _tableHeaderCell('Trạng thái'),
          ],
        ),
        // ── Data Rows ──
        ...students.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final student = entry.value;
          return TableRow(
            decoration: BoxDecoration(
              color: index.isOdd ? AppColors.surfaceVariant.withValues(alpha: 0.3) : null,
            ),
            children: [
              _tableDataCell('$index'),
              _tableDataCell(student.mssv),
              _tableDataCell(student.fullName),
              _tableDataCell(
                student.isPresent ? _formatTime(student.checkedAt) : '—',
              ),
              _tableStatusCell(
                student.isPresent ? 'Có mặt' : 'Vắng',
                student.isPresent ? AppColors.success : AppColors.error,
                student.isPresent ? Icons.check_circle : Icons.cancel,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tableDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(text, style: AppTextStyles.body),
    );
  }

  Widget _tableStatusCell(String text, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class kết quả điểm danh cho mỗi sinh viên
class _StudentResult {
  final String mssv;
  final String fullName;
  final String? checkedAt;
  final bool isPresent;

  const _StudentResult({
    required this.mssv,
    required this.fullName,
    this.checkedAt,
    required this.isPresent,
  });
}
