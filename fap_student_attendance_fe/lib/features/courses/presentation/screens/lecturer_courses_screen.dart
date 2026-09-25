import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/layouts/desktop_scaffold.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/models/course_model.dart';
import '../controllers/course_controller.dart';
import '../widgets/edit_course_dialog.dart';
import '../widgets/course_students_dialog.dart';

/// Màn hình danh sách môn học & lớp học của giảng viên
class LecturerCoursesScreen extends StatefulWidget {
  const LecturerCoursesScreen({super.key});

  @override
  State<LecturerCoursesScreen> createState() => _LecturerCoursesScreenState();
}

class _LecturerCoursesScreenState extends State<LecturerCoursesScreen> {
  final CourseController _controller = CourseController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      selectedIndex: 1, // Môn học
      role: UserRole.lecturer,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildFilterBar(),
                const SizedBox(height: 24),
                if (_controller.isLoading && _controller.rawCourses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  _buildCourseCards(context),
              ],
            ),
          );
        },
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
                'CỔNG GIẢNG VIÊN · QUẢN LÝ ĐÀO TẠO',
                style: AppTextStyles.breadcrumb,
              ),
              const SizedBox(height: 8),
              Text(
                'Môn học và lớp học của tôi',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 4),
              Text(
                'Quản lý danh sách môn học, cập nhật thông tin, xem sinh viên và tạo phiên điểm danh bằng mã QR.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại danh sách',
              onPressed: () => _controller.loadCourses(),
            ),
            const SizedBox(width: 8),
            PrimaryButton(
              text: 'Tạo môn học',
              icon: Icons.add,
              onPressed: () => context.go('/courses/create'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // ── Search Input ──
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo mã môn hoặc tên lớp (VD: PRM392, SE1701)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _controller.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => _controller.setSearchQuery(v),
            ),
          ),
          const SizedBox(width: 16),

          // ── Semester Dropdown Filter ──
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text('Học kỳ: ', style: AppTextStyles.label),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _controller.filterSemester,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _controller.availableSemesters.map((sem) {
                      return DropdownMenuItem<String>(
                        value: sem,
                        child: Text(sem, style: AppTextStyles.body),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _controller.setFilterSemester(val);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCards(BuildContext context) {
    final courses = _controller.courses;

    if (courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.school_outlined, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                _controller.searchQuery.isNotEmpty || _controller.filterSemester != 'Tất cả'
                    ? 'Không tìm thấy môn học phù hợp'
                    : 'Chưa có môn học nào',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Text(
                _controller.searchQuery.isNotEmpty || _controller.filterSemester != 'Tất cả'
                    ? 'Hãy thử thay đổi từ khóa tìm kiếm hoặc chọn học kỳ khác.'
                    : 'Hãy khởi tạo môn học đầu tiên để bắt đầu quản lý và điểm danh sinh viên.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              if (_controller.rawCourses.isEmpty)
                PrimaryButton(
                  text: 'Tạo môn học ngay',
                  icon: Icons.add,
                  onPressed: () => context.go('/courses/create'),
                ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: 265,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return _buildCourseCard(context, course);
          },
        );
      },
    );
  }

  Future<void> _handleEditCourse(CourseModel course) async {
    final updated = await EditCourseDialog.show(context, course);
    if (updated != null) {
      _controller.loadCourses();
    }
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFF0284C7),
      const Color(0xFF059669),
      const Color(0xFFD97706),
    ];
    final color = colors[course.subjectCode.hashCode.abs() % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Tag ──
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        course.subjectCode.length > 2
                            ? course.subjectCode.substring(0, 2)
                            : course.subjectCode,
                        style: AppTextStyles.label.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.subjectCode,
                            style: AppTextStyles.h4.copyWith(color: color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Lớp ${course.className}',
                            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        course.semester,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                      tooltip: 'Tùy chọn môn học',
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _handleEditCourse(course);
                        } else if (value == 'students') {
                          CourseStudentsDialog.show(context, course);
                        } else if (value == 'import') {
                          _controller.setSelectedCourse(course);
                          context.go('/courses/import');
                        } else if (value == 'qr') {
                          _controller.setSelectedCourse(course);
                          context.go('/schedule/create');
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
                              SizedBox(width: 10),
                              Text('Cập nhật môn học', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'students',
                          child: Row(
                            children: [
                              Icon(Icons.people_outline, size: 18, color: AppColors.textPrimary),
                              SizedBox(width: 10),
                              Text('Danh sách sinh viên', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'import',
                          child: Row(
                            children: [
                              Icon(Icons.upload_file_outlined, size: 18, color: AppColors.textPrimary),
                              SizedBox(width: 10),
                              Text('Nhập Excel sinh viên', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // ── Lecturer info & ID ──
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        course.lecturerDisplay,
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.fingerprint, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ID: ${course.id}',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // ── Action Buttons ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                // Button Điểm danh QR
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code, size: 15),
                    label: const Text('Tạo QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      _controller.setSelectedCourse(course);
                      context.go('/schedule/create');
                    },
                  ),
                ),
                const SizedBox(width: 6),

                // Button Cập nhật môn học (Nổi bật, rõ ràng)
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.accent),
                  label: const Text('Sửa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.accent, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleEditCourse(course),
                ),
                const SizedBox(width: 6),

                // Button DS Sinh viên
                Tooltip(
                  message: 'Xem danh sách sinh viên lớp',
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.inputBorder),
                    ),
                    child: InkWell(
                      onTap: () => CourseStudentsDialog.show(context, course),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(Icons.people_alt_outlined, size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Button Nhập Excel
                Tooltip(
                  message: 'Import sinh viên từ Excel',
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.inputBorder),
                    ),
                    child: InkWell(
                      onTap: () {
                        _controller.setSelectedCourse(course);
                        context.go('/courses/import');
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(Icons.upload_file_outlined, size: 16, color: AppColors.textPrimary),
                      ),
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
}
