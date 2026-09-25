import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/course_model.dart';

/// Repository xử lý API khóa học / lớp học phần
class CourseRepository {
  final ApiClient _apiClient = ApiClient();

  static final CourseRepository _instance = CourseRepository._internal();
  factory CourseRepository() => _instance;
  CourseRepository._internal();

  /// Lấy danh sách khóa học (có thể lọc theo lecturerId)
  Future<List<CourseModel>> getCourses({String? lecturerId}) async {
    final queryParams = lecturerId != null ? {'lecturerId': lecturerId} : null;
    final response = await _apiClient.get(
      ApiEndpoints.courses,
      queryParams: queryParams,
      requiresAuth: true,
    );

    if (response.data is List) {
      final list = response.data as List;
      return list
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Lấy chi tiết khóa học theo ID
  Future<CourseModel> getCourseById(String courseId) async {
    final response = await _apiClient.get(
      ApiEndpoints.courseDetail(courseId),
      requiresAuth: true,
    );

    if (response.data == null) {
      throw ApiException(
        statusCode: 404,
        message: 'Không tìm thấy thông tin khóa học',
      );
    }

    return CourseModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Tạo khóa học mới: POST /api/courses
  Future<CourseModel> createCourse(CourseCreateRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.courses,
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.data == null) {
      throw ApiException(
        statusCode: 500,
        message: 'Không nhận được dữ liệu khóa học vừa tạo',
      );
    }

    return CourseModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Tìm kiếm khóa học: GET /api/courses/search (Mục 2.6)
  Future<List<CourseModel>> searchCourses({
    String? className,
    String? subjectCode,
    String? semester,
    String? lecturerName,
  }) async {
    final queryParams = <String, String>{};
    if (className != null && className.trim().isNotEmpty) {
      queryParams['className'] = className.trim();
    }
    if (subjectCode != null && subjectCode.trim().isNotEmpty) {
      queryParams['subjectCode'] = subjectCode.trim();
    }
    if (semester != null && semester.trim().isNotEmpty) {
      queryParams['semester'] = semester.trim();
    }
    if (lecturerName != null && lecturerName.trim().isNotEmpty) {
      queryParams['lecturerName'] = lecturerName.trim();
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.searchCourses,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        requiresAuth: true,
      );

      if (response.data is List) {
        final list = response.data as List;
        return list
            .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException catch (e) {
      // Nếu máy chủ chưa cấu hình route /search hoặc lỗi 404, fallback lấy all courses và lọc client-side
      if (e.statusCode == 404) {
        final all = await getCourses();
        return all.where((c) {
          final matchClass = queryParams['className'] == null ||
              c.className.toLowerCase().contains(queryParams['className']!.toLowerCase());
          final matchSubject = queryParams['subjectCode'] == null ||
              c.subjectCode.toLowerCase().contains(queryParams['subjectCode']!.toLowerCase());
          final matchSemester = queryParams['semester'] == null ||
              c.semester.toLowerCase().contains(queryParams['semester']!.toLowerCase());
          final matchLecturer = queryParams['lecturerName'] == null ||
              (c.lecturerName?.toLowerCase().contains(queryParams['lecturerName']!.toLowerCase()) ?? false);
          return matchClass && matchSubject && matchSemester && matchLecturer;
        }).toList();
      }
      rethrow;
    }
  }

  /// Học sinh đăng ký khóa học: POST /api/courses/register (Mục 2.7)
  Future<dynamic> registerCourse(CourseRegisterRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.registerCourse,
        body: request.toJson(),
        requiresAuth: true,
      );
      return response.data;
    } on ApiException catch (e) {
      // Fallback 1: Thử endpoint /api/courses/enroll
      if (e.statusCode == 404) {
        try {
          final res2 = await _apiClient.post(
            ApiEndpoints.enrollCourseAlias,
            body: request.toJson(),
            requiresAuth: true,
          );
          return res2.data;
        } catch (_) {
          // Fallback 2: Thử endpoint /api/enrollments
          final res3 = await _apiClient.post(
            ApiEndpoints.enrollments,
            body: {
              'courseId': request.courseId,
              'studentId': request.userId,
            },
            requiresAuth: true,
          );
          return res3.data;
        }
      }
      rethrow;
    }
  }

  /// Cập nhật khóa học: PUT /api/courses/{id} (Mục 2.4)
  Future<CourseModel> updateCourse(
    String courseId,
    CourseUpdateRequest request,
  ) async {
    final response = await _apiClient.put(
      ApiEndpoints.courseDetail(courseId),
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.data == null) {
      throw ApiException(
        statusCode: 500,
        message: 'Không nhận được dữ liệu phản hồi sau khi cập nhật khóa học.',
      );
    }

    return CourseModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Xóa khóa học: DELETE /api/courses/{id} (Mục 2.5)
  Future<void> deleteCourse(String courseId) async {
    await _apiClient.delete(
      ApiEndpoints.courseDetail(courseId),
      requiresAuth: true,
    );
  }

  /// Import danh sách sinh viên vào khóa học qua Excel: POST /api/courses/{courseId}/import-students (Mục 2.9)
  Future<dynamic> importStudentsToCourse(
    String courseId,
    List<int> fileBytes,
    String filename,
  ) async {
    final response = await _apiClient.postMultipart(
      ApiEndpoints.importCourseStudents(courseId),
      fileBytes: fileBytes,
      filename: filename,
      fieldName: 'file',
      requiresAuth: true,
    );
    return response.data;
  }

  /// Lấy danh sách khóa học của học sinh (hỗ trợ lọc theo subjectCode, semester, lecturerName): GET /api/courses/my-courses (Mục 2.8)
  Future<List<CourseModel>> getMyCourses({
    String? subjectCode,
    String? semester,
    String? lecturerName,
  }) async {
    final queryParams = <String, String>{};
    if (subjectCode != null && subjectCode.trim().isNotEmpty) {
      queryParams['subjectCode'] = subjectCode.trim();
    }
    if (semester != null && semester.trim().isNotEmpty) {
      queryParams['semester'] = semester.trim();
    }
    if (lecturerName != null && lecturerName.trim().isNotEmpty) {
      queryParams['lecturerName'] = lecturerName.trim();
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.coursesMyCourses,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        requiresAuth: true,
      );

      if (response.data is List) {
        final list = response.data as List;
        return list
            .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException catch (e) {
      // Fallback nếu endpoint /api/courses/my-courses 404, dùng /api/enrollments/my-courses
      if (e.statusCode == 404) {
        final enrollmentsRes = await _apiClient.get(
          ApiEndpoints.myCourses,
          requiresAuth: true,
        );
        if (enrollmentsRes.data is List) {
          final list = enrollmentsRes.data as List;
          final allCourses = list.map((e) {
            final m = e as Map<String, dynamic>;
            return CourseModel(
              courseId: m['courseId']?.toString() ?? '',
              subjectCode: m['subjectCode']?.toString() ?? '',
              className: m['className']?.toString() ?? '',
              semester: m['semester']?.toString() ?? '',
              lecturerName: m['lecturerName']?.toString(),
            );
          }).toList();

          return allCourses.where((c) {
            final matchSubj = queryParams['subjectCode'] == null ||
                c.subjectCode.toLowerCase().contains(queryParams['subjectCode']!.toLowerCase());
            final matchSem = queryParams['semester'] == null ||
                c.semester.toLowerCase().contains(queryParams['semester']!.toLowerCase());
            final matchLec = queryParams['lecturerName'] == null ||
                (c.lecturerName?.toLowerCase().contains(queryParams['lecturerName']!.toLowerCase()) ?? true);
            return matchSubj && matchSem && matchLec;
          }).toList();
        }
      }
      rethrow;
    }
  }

  /// Lấy số liệu thống kê Dashboard của giảng viên: GET /api/lecturer/dashboard-stats (alias /api/lecturer/stats)
  Future<LecturerDashboardStatsModel> getLecturerDashboardStats({String? lecturerId}) async {
    final queryParams = lecturerId != null && lecturerId.isNotEmpty ? {'lecturerId': lecturerId} : null;
    try {
      final response = await _apiClient.get(
        ApiEndpoints.lecturerDashboardStats,
        queryParams: queryParams,
        requiresAuth: true,
      );
      if (response.data is Map<String, dynamic>) {
        return LecturerDashboardStatsModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ApiException(statusCode: 500, message: 'Dữ liệu thống kê không đúng định dạng');
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Fallback endpoint alias: /api/lecturer/stats
        final resAlias = await _apiClient.get(
          ApiEndpoints.lecturerStatsAlias,
          queryParams: queryParams,
          requiresAuth: true,
        );
        if (resAlias.data is Map<String, dynamic>) {
          return LecturerDashboardStatsModel.fromJson(resAlias.data as Map<String, dynamic>);
        }
      }
      rethrow;
    }
  }
}
