import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository.dart';

/// Controller quản lý danh sách và tạo khóa học của Giảng viên
class CourseController extends ChangeNotifier {
  final CourseRepository _repository = CourseRepository();

  static final CourseController _instance = CourseController._internal();
  factory CourseController() => _instance;
  CourseController._internal();

  List<CourseModel> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;
  CourseModel? _selectedCourse;
  Map<String, String> _fieldErrors = {};

  String _searchQuery = '';
  String _filterSemester = 'Tất cả';

  List<CourseModel> get courses {
    return _courses.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          c.subjectCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.className.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSemester = _filterSemester == 'Tất cả' ||
          c.semester.toLowerCase() == _filterSemester.toLowerCase();
      return matchesSearch && matchesSemester;
    }).toList();
  }

  List<CourseModel> get rawCourses => _courses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CourseModel? get selectedCourse => _selectedCourse;
  Map<String, String> get fieldErrors => _fieldErrors;
  String get searchQuery => _searchQuery;
  String get filterSemester => _filterSemester;

  List<String> get availableSemesters {
    final sems = _courses.map((c) => c.semester).where((s) => s.isNotEmpty).toSet().toList();
    sems.sort();
    return ['Tất cả', ...sems];
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setFilterSemester(String semester) {
    _filterSemester = semester;
    notifyListeners();
  }

  void setSelectedCourse(CourseModel? course) {
    _selectedCourse = course;
    notifyListeners();
  }

  /// Tải danh sách khóa học từ Backend
  Future<void> loadCourses({String? lecturerId}) async {
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors = {};
    notifyListeners();

    try {
      _courses = await _repository.getCourses(lecturerId: lecturerId);
      if (_courses.isNotEmpty && _selectedCourse == null) {
        _selectedCourse = _courses.first;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Tạo khóa học mới: POST /api/courses
  Future<CourseModel?> createCourse({
    required String subjectCode,
    required String className,
    required String semester,
    String? lecturerId,
    String password = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors = {};
    notifyListeners();

    try {
      final newCourse = await _repository.createCourse(
        CourseCreateRequest(
          subjectCode: subjectCode,
          className: className,
          semester: semester,
          lecturerId: lecturerId,
          password: password,
        ),
      );

      _courses.insert(0, newCourse);
      _selectedCourse = newCourse;
      _isLoading = false;
      notifyListeners();
      return newCourse;
    } catch (e) {
      _isLoading = false;
      if (e is ApiException) {
        _errorMessage = e.message;
        _fieldErrors = e.fieldErrors;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return null;
    }
  }

  /// Cập nhật khóa học: PUT /api/courses/{id}
  Future<CourseModel?> updateCourse({
    required String courseId,
    required String subjectCode,
    required String className,
    required String semester,
    String? password,
    String? lecturerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors = {};
    notifyListeners();

    try {
      final updated = await _repository.updateCourse(
        courseId,
        CourseUpdateRequest(
          subjectCode: subjectCode,
          className: className,
          semester: semester,
          password: password,
          lecturerId: lecturerId,
        ),
      );

      final idx = _courses.indexWhere((c) => c.courseId == courseId);
      if (idx != -1) {
        _courses[idx] = updated;
      }
      if (_selectedCourse?.courseId == courseId) {
        _selectedCourse = updated;
      }

      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _isLoading = false;
      if (e is ApiException) {
        _errorMessage = e.message;
        _fieldErrors = e.fieldErrors;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return null;
    }
  }

  /// Xóa khóa học: DELETE /api/courses/{id}
  Future<bool> deleteCourse(String courseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteCourse(courseId);
      _courses.removeWhere((c) => c.courseId == courseId);
      if (_selectedCourse?.courseId == courseId) {
        _selectedCourse = _courses.isNotEmpty ? _courses.first : null;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
