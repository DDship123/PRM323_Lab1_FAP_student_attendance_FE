import 'package:flutter_test/flutter_test.dart';
import 'package:fap_student_attendance_fe/features/courses/data/models/course_model.dart';
import 'package:fap_student_attendance_fe/features/attendance/presentation/controllers/student_attendance_controller.dart';
import 'package:fap_student_attendance_fe/core/constants/api_endpoints.dart';

void main() {
  group('Section 2.6 & 2.7 Student Courses Search and Register Tests', () {
    test('ApiEndpoints includes searchCourses, registerCourse, and enrollCourseAlias', () {
      expect(ApiEndpoints.searchCourses, 'http://localhost:8080/api/courses/search');
      expect(ApiEndpoints.registerCourse, 'http://localhost:8080/api/courses/register');
      expect(ApiEndpoints.enrollCourseAlias, 'http://localhost:8080/api/courses/enroll');
    });

    test('CourseModel deserializes section 2.6 search response JSON with lecturerName', () {
      final json = {
        'courseId': 'CRS-001',
        'subjectCode': 'PRM392',
        'className': 'SE1701',
        'semester': 'FA24',
        'lecturerId': 'USR-LEC1',
        'lecturerName': 'Nguyen Van A',
        'createdAt': '2026-09-20T10:00:00',
      };

      final course = CourseModel.fromJson(json);
      expect(course.id, 'CRS-001');
      expect(course.subjectCode, 'PRM392');
      expect(course.className, 'SE1701');
      expect(course.semester, 'FA24');
      expect(course.lecturerId, 'USR-LEC1');
      expect(course.lecturerName, 'Nguyen Van A');
      expect(course.lecturerDisplay, 'Nguyen Van A');
    });

    test('CourseRegisterRequest serializes to Section 2.7 request format with aliases', () {
      const req = CourseRegisterRequest(
        courseId: 'CRS-001',
        userId: 'USR-STU1',
        coursePassword: 'secretPassword123',
      );

      final json = req.toJson();
      expect(json['courseId'], 'CRS-001');
      expect(json['userId'], 'USR-STU1');
      expect(json['studentId'], 'USR-STU1');
      expect(json['coursePassword'], 'secretPassword123');
      expect(json['password'], 'secretPassword123');
    });

    test('StudentAttendanceController isCourseEnrolled detects registered courses accurately', () {
      final controller = StudentAttendanceController();
      expect(controller.isCourseEnrolled('CRS-NON-EXISTENT'), isFalse);
    });
  });
}
