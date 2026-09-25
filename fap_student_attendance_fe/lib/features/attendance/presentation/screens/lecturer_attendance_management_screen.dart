import '../../data/repositories/attendance_repository.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../schedule/data/models/session_model.dart';
import '../controllers/lecturer_attendance_controller.dart';

/// Màn hình quản lý điểm danh cho Giảng viên
/// Flow: Chọn Course → Chọn Session → Xem danh sách SV đã/chưa điểm danh
class LecturerAttendanceManagementScreen extends StatefulWidget {
  const LecturerAttendanceManagementScreen({super.key});

  @override
  State<LecturerAttendanceManagementScreen> createState() =>
      _LecturerAttendanceManagementScreenState();
}

class _LecturerAttendanceManagementScreenState
    extends State<LecturerAttendanceManagementScreen> {
  final LecturerAttendanceController _controller =
      LecturerAttendanceController();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.loadLecturerCourses();
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _exportExcel() async {
    final session = _controller.selectedSession;
    if (session == null) return;
    setState(() => _isExporting = true);
    try {
      final repo = AttendanceRepository();
      final success = await repo.exportAttendanceExcel(session.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Xuất file Excel (.xlsx) danh sách điểm danh thành công!' : 'Không thể lưu file Excel.'),
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

  Future<void> _exportCsv() async {
    final session = _controller.selectedSession;
    if (session == null) return;
    setState(() => _isExporting = true);
    try {
      final repo = AttendanceRepository();
      final success = await repo.exportAttendanceCsv(session.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Xuất file CSV danh sách điểm danh thành công!' : 'Không thể lưu file CSV.'),
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

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      selectedIndex: 3, // "Điểm danh" tab
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumb(),
            const SizedBox(height: 24),
            _buildHeader(),
            const SizedBox(height: 24),
            if (_controller.error != null) _buildError(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // ── Breadcrumb navigation ──
  Widget _buildBreadcrumb() {
    final parts = <Widget>[
      _BreadcrumbItem(
        label: 'Điểm danh',
        isActive: _controller.selectedCourse == null,
        onTap: () => _controller.goBackToCourses(),
      ),
    ];

    if (_controller.selectedCourse != null) {
      parts.add(const _BreadcrumbDivider());
      parts.add(_BreadcrumbItem(
        label: _controller.selectedCourse!.displayName,
        isActive: _controller.selectedSession == null,
        onTap: () => _controller.goBackToSessions(),
      ));
    }

    if (_controller.selectedSession != null) {
      parts.add(const _BreadcrumbDivider());
      parts.add(_BreadcrumbItem(
        label: 'Slot ${_controller.selectedSession!.slotNumber}',
        isActive: true,
        onTap: null,
      ));
    }

    return Row(children: parts);
  }

  // ── Dynamic header ──
  Widget _buildHeader() {
    String title;
    String subtitle;
    IconData icon;

    if (_controller.selectedSession != null) {
      title = 'Chi tiết phiên điểm danh';
      subtitle =
          '${_controller.selectedCourse?.displayName ?? ''} — Slot ${_controller.selectedSession!.slotNumber}';
      icon = Icons.people_alt_outlined;
    } else if (_controller.selectedCourse != null) {
      title = 'Phiên điểm danh';
      subtitle = _controller.selectedCourse!.displayName;
      icon = Icons.calendar_today_outlined;
    } else {
      title = 'Quản lý điểm danh';
      subtitle = 'Chọn môn học để xem lịch sử điểm danh';
      icon = Icons.qr_code_scanner_outlined;
    }

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accent, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        if (_controller.selectedSession != null) ...[
          _buildStatsBadges(),
          const SizedBox(width: 16),
          _buildExportButtons(),
        ],
      ],
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppColors.cardBorder),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          icon: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF60A5FA)),
          label: const Text('Xuất CSV'),
          onPressed: _isExporting ? null : _exportCsv,
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.table_view, size: 16),
          label: Text(_isExporting ? 'Đang xuất...' : 'Xuất Excel (.xlsx)'),
          onPressed: _isExporting ? null : _exportExcel,
        ),
      ],
    );
  }

  Widget _buildStatsBadges() {
    return Row(
      children: [
        _StatBadge(
          label: 'Có mặt',
          count: _controller.presentCount,
          color: AppColors.success,
          bgColor: AppColors.successBg,
        ),
        const SizedBox(width: 12),
        _StatBadge(
          label: 'Vắng',
          count: _controller.absentCount,
          color: AppColors.error,
          bgColor: AppColors.errorBg,
        ),
        const SizedBox(width: 12),
        _StatBadge(
          label: 'Tổng',
          count: _controller.totalStudents,
          color: AppColors.accent,
          bgColor: AppColors.infoBg,
        ),
      ],
    );
  }


  // ── Error banner ──
  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _controller.error!,
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _controller.clearError(),
          ),
        ],
      ),
    );
  }

  // ── Main content router ──
  Widget _buildContent() {
    if (_controller.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu...'),
          ],
        ),
      );
    }

    if (_controller.selectedSession != null) {
      return _buildStudentAttendanceList();
    } else if (_controller.selectedCourse != null) {
      return _buildSessionList();
    } else {
      return _buildCourseList();
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  VIEW 1: Course List
  // ══════════════════════════════════════════════════════════════
  Widget _buildCourseList() {
    if (_controller.courses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Chưa có khóa học nào',
        subtitle: 'Hãy tạo khóa học trước khi quản lý điểm danh',
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 160,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _controller.courses.length,
      itemBuilder: (context, index) {
        final course = _controller.courses[index];
        return _CourseCard(
          course: course,
          onTap: () => _controller.selectCourse(course),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  VIEW 2: Session List
  // ══════════════════════════════════════════════════════════════
  Widget _buildSessionList() {
    if (_controller.sessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Chưa có phiên điểm danh',
        subtitle: 'Môn học này chưa tạo phiên điểm danh nào',
      );
    }

    return ListView.separated(
      itemCount: _controller.sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = _controller.sessions[index];
        return _SessionCard(
          session: session,
          onTap: () => _controller.selectSession(session),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  VIEW 3: Student Attendance Detail
  // ══════════════════════════════════════════════════════════════
  Widget _buildStudentAttendanceList() {
    if (_controller.studentStatuses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_off_outlined,
        title: 'Chưa có dữ liệu',
        subtitle: 'Phiên này chưa có sinh viên nào điểm danh hoặc đăng ký',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  flex: 2,
                  child: Text('Mã SV',
                      style: AppTextStyles.label.copyWith(fontSize: 13)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Họ và tên',
                      style: AppTextStyles.label.copyWith(fontSize: 13)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Trạng thái',
                      style: AppTextStyles.label.copyWith(fontSize: 13)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Thời gian',
                      style: AppTextStyles.label.copyWith(fontSize: 13)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          // Table body
          Expanded(
            child: ListView.separated(
              itemCount: _controller.studentStatuses.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.cardBorder),
              itemBuilder: (context, index) {
                final status = _controller.studentStatuses[index];
                return _StudentRow(
                  index: index + 1,
                  status: status,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ──
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 40, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  WIDGET COMPONENTS
// ══════════════════════════════════════════════════════════════

class _BreadcrumbItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _BreadcrumbItem({
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: isActive ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: AppTextStyles.breadcrumb.copyWith(
            color: isActive ? AppColors.accent : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _BreadcrumbDivider extends StatelessWidget {
  const _BreadcrumbDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: AppTextStyles.h3.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Course Card ──
class _CourseCard extends StatefulWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? AppColors.accent : AppColors.cardBorder,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_outlined,
                        color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.subjectCode,
                          style: AppTextStyles.h4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.course.className,
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: _isHovered ? AppColors.accent : AppColors.textMuted,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.school_outlined,
                    label: widget.course.semester,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _InfoChip(
                      icon: Icons.person_outline,
                      label: widget.course.lecturerDisplay,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session Card ──
class _SessionCard extends StatefulWidget {
  final AttendanceSessionModel session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _isHovered = false;

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
        ' ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final isOpen = session.isOpen;
    final hasExpired = session.hasExpired;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? AppColors.accent : AppColors.cardBorder,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Slot number badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOpen && !hasExpired
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${session.slotNumber}',
                    style: AppTextStyles.h2.copyWith(
                      color: isOpen && !hasExpired
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Slot ${session.slotNumber}',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tạo lúc: ${_formatDate(session.createdAt)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              // Expired time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Hết hạn',
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                  ),
                  Text(
                    _formatDate(session.expiredAt),
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOpen && !hasExpired
                      ? AppColors.successBg
                      : AppColors.errorBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOpen && !hasExpired ? 'OPEN' : 'CLOSED',
                  style: AppTextStyles.caption.copyWith(
                    color: isOpen && !hasExpired
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: _isHovered ? AppColors.accent : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Student Row ──
class _StudentRow extends StatelessWidget {
  final int index;
  final StudentAttendanceStatus status;

  const _StudentRow({required this.index, required this.status});

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '—';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: index.isOdd ? AppColors.surfaceVariant : AppColors.surface,
      child: Row(
        children: [
          // Index
          SizedBox(
            width: 40,
            child: Text(
              '$index',
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // FAP Code
          Expanded(
            flex: 2,
            child: Text(
              status.fapCode ?? status.studentId.substring(0, 8),
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Name
          Expanded(
            flex: 3,
            child: Text(
              status.studentName ?? 'Không rõ',
              style: AppTextStyles.body.copyWith(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.isPresent
                        ? AppColors.successBg
                        : AppColors.errorBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status.isPresent
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 14,
                        color: status.isPresent
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.isPresent ? 'Có mặt' : 'Vắng',
                        style: AppTextStyles.caption.copyWith(
                          color: status.isPresent
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Check-in time
          Expanded(
            flex: 2,
            child: Text(
              status.isPresent ? _formatTime(status.checkedAt) : '—',
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
