import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fap_student_attendance_fe/app.dart';
import 'package:fap_student_attendance_fe/features/auth/data/models/auth_models.dart';
import 'package:fap_student_attendance_fe/features/auth/data/models/user_model.dart';

void main() {
  group('Auth Model Unit Tests', () {
    test('LoginRequest serialization', () {
      const req = LoginRequest(username: 'datnht', password: '123456');
      final json = req.toJson();
      expect(json['username'], 'datnht');
      expect(json['password'], '123456');
    });

    test('RegisterRequest serialization for STUDENT with fapCode', () {
      const req = RegisterRequest(
        username: 'datnht',
        password: '123456',
        email: 'datnhse192964@fpt.edu.vn',
        fullName: 'Ngô Hoàng Trường Đạt',
        roleId: 'STUDENT',
        fapCode: 'se192964',
      );
      final json = req.toJson();
      expect(json['username'], 'datnht');
      expect(json['fapCode'], 'SE192964'); // uppercase
      expect(json['roleId'], 'STUDENT');
    });

    test('UserModel deserialization and role helpers with ROLE_ prefix', () {
      final user = UserModel.fromJson({
        'userId': 'uuid-1234',
        'username': 'datnht',
        'fapCode': 'SE192964',
        'fullName': 'Ngô Hoàng Trường Đạt',
        'email': 'datnhse192964@fpt.edu.vn',
        'roleId': 'ROLE_STUDENT',
        'createdAt': '2026-09-23T08:00:00',
        'memberCode': null,
      });

      expect(user.isStudent, true);
      expect(user.isLecturer, false);
      expect(user.roleDisplay, 'Sinh viên');

      final lecturer = UserModel.fromJson({
        'userId': 'uuid-5678',
        'username': 'lecturer1',
        'fullName': 'Nguyễn Minh Anh',
        'email': 'minhanh@fpt.edu.vn',
        'roleId': 'ROLE_LECTURER',
      });

      expect(lecturer.isLecturer, true);
      expect(lecturer.isStudent, false);
      expect(lecturer.roleDisplay, 'Giảng viên');
    });

    test('AuthResponseModel deserialization', () {
      final authRes = AuthResponseModel.fromJson({
        'token': 'mock-jwt-token-123',
        'tokenType': 'Bearer',
        'user': {
          'userId': 'uuid-1234',
          'username': 'lecturer1',
          'fullName': 'Nguyễn Minh Anh',
          'email': 'minhanh@fpt.edu.vn',
          'roleId': 'LECTURER',
        },
      });

      expect(authRes.token, 'mock-jwt-token-123');
      expect(authRes.tokenType, 'Bearer');
      expect(authRes.user.isLecturer, true);
      expect(authRes.user.roleDisplay, 'Giảng viên');
    });
  });

  group('Auth UI Tests', () {
    testWidgets('Toggle between Login and Register form works smoothly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const AttendlyApp());
      await tester.pumpAndSettle();

      // Initial state: Login form
      expect(find.text('Đăng nhập'), findsWidgets);
      expect(find.text('Tên đăng nhập / Username'), findsOneWidget);

      // Tap on 'Tạo tài khoản mới' tab
      await tester.tap(find.text('Tạo tài khoản mới'));
      await tester.pumpAndSettle();

      // Should now show Register form
      expect(find.text('Tạo tài khoản'), findsWidgets);
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Mã số sinh viên (FAP Code)'), findsOneWidget);

      // Switch back to Login form via top tab
      await tester.tap(find.text('Đăng nhập').first);
      await tester.pumpAndSettle();

      expect(find.text('Tên đăng nhập / Username'), findsOneWidget);
    });
  });
}
