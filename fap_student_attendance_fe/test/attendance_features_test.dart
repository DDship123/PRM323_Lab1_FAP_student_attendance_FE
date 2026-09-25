import 'package:flutter_test/flutter_test.dart';
import 'package:fap_student_attendance_fe/features/courses/data/models/course_model.dart';
import 'package:fap_student_attendance_fe/features/schedule/data/models/session_model.dart';
import 'package:fap_student_attendance_fe/features/attendance/data/models/attendance_models.dart';
import 'package:fap_student_attendance_fe/features/schedule/presentation/controllers/session_controller.dart';
import 'package:fap_student_attendance_fe/features/attendance/presentation/controllers/student_attendance_controller.dart';
import 'package:fap_student_attendance_fe/core/utils/attendance_error_helper.dart';

void main() {
  group('Course Models Tests', () {
    test('CourseModel deserializes correctly and provides id getter', () {
      final json = {
        'courseId': 'crs-12345',
        'subjectCode': 'PRM392',
        'className': 'SE1701',
        'semester': 'Spring2026',
        'lecturerId': 'lec-001',
        'createdAt': '2026-09-23T08:00:00',
      };

      final course = CourseModel.fromJson(json);
      expect(course.id, 'crs-12345');
      expect(course.courseId, 'crs-12345');
      expect(course.subjectCode, 'PRM392');
      expect(course.className, 'SE1701');
      expect(course.displayName, 'PRM392 · SE1701');
    });

    test('CourseCreateRequest serializes correctly', () {
      const req = CourseCreateRequest(
        subjectCode: 'PRM392',
        className: 'SE1701',
        semester: 'Spring2026',
        lecturerId: 'lec-001',
      );

      final json = req.toJson();
      expect(json['subjectCode'], 'PRM392');
      expect(json['className'], 'SE1701');
      expect(json['semester'], 'Spring2026');
      expect(json['lecturerId'], 'lec-001');
    });
  });

  group('Session Models Tests', () {
    test('AttendanceSessionModel calculates expiration properly', () {
      final futureTime = DateTime.now().add(const Duration(minutes: 15)).toIso8601String();
      final json = {
        'sessionId': 'sess-999',
        'courseId': 'crs-12345',
        'slotNumber': 2,
        'qrCodeSecret': 'sec-abc-xyz',
        'qrCodeBase64': 'data:image/png;base64,...',
        'expiredAt': futureTime,
        'status': 'OPEN',
      };

      final session = AttendanceSessionModel.fromJson(json);
      expect(session.id, 'sess-999');
      expect(session.slotNumber, 2);
      expect(session.isOpen, isTrue);
      expect(session.hasExpired, isFalse);
    });

    test('DynamicQrTokenModel deserializes and serializes properly', () {
      final json = {
        'sessionId': 'sess-123',
        'currentQrToken': 'A3F8B12C',
        'qrCodeBase64': 'data:image/png;base64,iVBORw0KGgo...',
        'tokenIntervalSeconds': 10,
        'remainingSeconds': 7,
        'timestamp': 1727220000,
        'serverTime': '2026-09-25T08:00:00Z',
      };

      final tokenModel = DynamicQrTokenModel.fromJson(json);
      expect(tokenModel.sessionId, 'sess-123');
      expect(tokenModel.currentQrToken, 'A3F8B12C');
      expect(tokenModel.remainingSeconds, 7);
      expect(tokenModel.tokenIntervalSeconds, 10);
      expect(tokenModel.formattedRemaining, '7s');

      final serialized = tokenModel.toJson();
      expect(serialized['currentQrToken'], 'A3F8B12C');
      expect(serialized['remainingSeconds'], 7);
    });

    test('AttendanceSessionModel with TOTP fields and adaptive Wi-Fi parses correctly', () {
      final json = {
        'sessionId': 'sess-456',
        'courseId': 'crs-12345',
        'slotNumber': 1,
        'status': 'OPEN',
        'hostPublicIp': '113.161.45.67',
        'roomBssid': 'a4:b2:c3:d4:e5:f6',
        'currentQrToken': 'B90EF45A',
        'tokenRemainingSeconds': 9,
        'tokenIntervalSeconds': 10,
      };

      final session = AttendanceSessionModel.fromJson(json);
      expect(session.hostPublicIp, '113.161.45.67');
      expect(session.roomBssid, 'a4:b2:c3:d4:e5:f6');
      expect(session.currentQrToken, 'B90EF45A');
      expect(session.tokenRemainingSeconds, 9);
      expect(session.tokenIntervalSeconds, 10);
    });

    test('SessionCreateRequest serializes with optional roomBssid and qrRefreshSeconds', () {
      final req = SessionCreateRequest(
        courseId: 'crs-12345',
        slotNumber: 3,
        durationMinutes: 20,
        qrRefreshSeconds: 20,
        roomBssid: 'AA:BB:CC:DD:EE:FF',
      );

      final json = req.toJson();
      expect(json['roomBssid'], 'AA:BB:CC:DD:EE:FF');
      expect(json['qrRefreshSeconds'], 20);
    });

    test('AttendanceSessionModel and DynamicQrTokenModel support qrRefreshSeconds and default 20s interval', () {
      final json = {
        'sessionId': 'sess-totp-20',
        'courseId': 'crs-12345',
        'slotNumber': 1,
        'status': 'OPEN',
        'currentQrToken': '4F3A8B12',
        'tokenRemainingSeconds': 17,
        'qrRefreshSeconds': 20,
      };

      final session = AttendanceSessionModel.fromJson(json);
      expect(session.qrRefreshSeconds, 20);
      expect(session.tokenIntervalSeconds, 20);

      final tokenModel = DynamicQrTokenModel.fromJson(json);
      expect(tokenModel.qrRefreshSeconds, 20);
      expect(tokenModel.tokenIntervalSeconds, 20);
      expect(tokenModel.remainingSeconds, 17);
    });
  });

  group('Attendance Models Tests', () {
    test('AttendanceRecordModel parses timestamp and status correctly', () {
      final json = {
        'recordId': 'rec-001',
        'sessionId': 'sess-999',
        'studentId': 'stu-123',
        'studentFapCode': 'SE160001',
        'studentName': 'Nguyen Van A',
        'status': 'PRESENT',
        'checkedAt': '2026-09-23T08:05:00',
        'distanceMeters': 12.5,
        'deviceId': 'device-uuid-123',
      };

      final record = AttendanceRecordModel.fromJson(json);
      expect(record.id, 'rec-001');
      expect(record.studentCode, 'SE160001');
      expect(record.studentName, 'Nguyen Van A');
      expect(record.isPresent, isTrue);
      expect(record.distanceMeters, 12.5);
      expect(record.deviceId, 'device-uuid-123');
    });

    test('CheckInRequest serializes with qrToken, deviceId, and bssid correctly', () {
      const req = CheckInRequest(
        sessionId: 'sess-999',
        qrToken: 'A3F8B12C',
        deviceId: 'uuid-device-999',
        bssid: 'a4:b2:c3:d4:e5:f6',
        latitude: 10.8412,
        longitude: 106.8099,
      );

      final json = req.toJson();
      expect(json['sessionId'], 'sess-999');
      expect(json['qrToken'], 'A3F8B12C');
      expect(json['deviceId'], 'uuid-device-999');
      expect(json['bssid'], 'a4:b2:c3:d4:e5:f6');
      expect(json['latitude'], 10.8412);
      expect(json['longitude'], 106.8099);
    });

    test('CheckInRequest sanitizes dummy BSSID (02:00:00:00:00:00 and unknown)', () {
      const dummyReq1 = CheckInRequest(
        sessionId: 'sess-999',
        qrToken: 'A3F8B12C',
        bssid: '02:00:00:00:00:00',
      );
      final json1 = dummyReq1.toJson();
      expect(json1.containsKey('bssid'), isFalse);

      const dummyReq2 = CheckInRequest(
        sessionId: 'sess-999',
        qrToken: 'A3F8B12C',
        bssid: 'unknown',
      );
      final json2 = dummyReq2.toJson();
      expect(json2.containsKey('bssid'), isFalse);
    });

    test('EnrollmentModel parses enrolledDate cleanly', () {
      final json = {
        'enrollmentId': 'enr-777',
        'courseId': 'crs-12345',
        'studentId': 'stu-123',
        'enrolledAt': '2026-09-20T10:00:00',
        'subjectCode': 'PRM392',
        'className': 'SE1701',
      };

      final enrollment = EnrollmentModel.fromJson(json);
      expect(enrollment.enrollmentId, 'enr-777');
      expect(enrollment.courseTitle, 'PRM392 · SE1701');
      expect(enrollment.enrolledDate.year, 2026);
    });
  });

  group('AttendanceErrorHelper Tests', () {
    test('Correctly maps QR expired / changed cycle', () {
      final info = AttendanceErrorHelper.parse('Mã QR đã hết hạn hoặc không hợp lệ');
      expect(info.kind, AttendanceErrorKind.invalidOrExpiredQr);
      expect(info.title, 'Mã QR đã đổi chu kỳ (Hết hạn)');
      expect(info.message, 'Mã QR đã chuyển sang chu kỳ mới. Vui lòng hướng camera quét lại mã trên màn hình!');
      expect(info.canScanAgain, isTrue);
    });

    test('Correctly maps Wi-Fi BSSID mismatch', () {
      final info = AttendanceErrorHelper.parse('Không kết nối đúng điểm truy cập Wi-Fi phòng học (BSSID không khớp)');
      expect(info.kind, AttendanceErrorKind.wifiBssidMismatch);
      expect(info.title, 'Sai Wi-Fi phòng học');
      expect(info.message, 'Bạn chưa kết nối đúng Wi-Fi phòng học. Vui lòng kết nối vào Wi-Fi lớp học để điểm danh!');
    });

    test('Correctly maps Subnet IP mismatch', () {
      final info = AttendanceErrorHelper.parse('Dải mạng IP không khớp với phòng học (4G/VPN)');
      expect(info.kind, AttendanceErrorKind.subnetIpMismatch);
      expect(info.title, 'Không cùng dải mạng phòng học');
      expect(info.message, 'Địa chỉ mạng không khớp. Vui lòng tắt 4G/VPN và kết nối cùng mạng Wi-Fi với giảng viên!');
    });

    test('Correctly maps duplicate device ID', () {
      final info = AttendanceErrorHelper.parse('Thiết bị này đã được sử dụng để điểm danh cho sinh viên khác');
      expect(info.kind, AttendanceErrorKind.deviceAlreadyUsed);
      expect(info.title, 'Thiết bị đã điểm danh');
      expect(info.message, 'Điểm danh thất bại! Thiết bị này đã được dùng để điểm danh cho sinh viên khác trong buổi học.');
      expect(info.canTryPin, isFalse);
    });

    test('Correctly maps already checked in', () {
      final info = AttendanceErrorHelper.parse('Sinh viên đã điểm danh thành công phiên này trước đó');
      expect(info.kind, AttendanceErrorKind.alreadyCheckedIn);
      expect(info.title, 'Đã được ghi nhận có mặt');
      expect(info.message, 'Bạn đã hoàn thành điểm danh cho buổi học này rồi.');
    });

    test('Correctly maps not enrolled', () {
      final info = AttendanceErrorHelper.parse('Sinh viên không thuộc danh sách lớp học');
      expect(info.kind, AttendanceErrorKind.notEnrolled);
      expect(info.title, 'Không có tên trong lớp');
      expect(info.message, 'Bạn không có tên trong danh sách đăng ký của khóa học này.');
    });

    test('Correctly maps session closed', () {
      final info = AttendanceErrorHelper.parse('Phiên điểm danh đã kết thúc');
      expect(info.kind, AttendanceErrorKind.sessionClosedOrExpired);
      expect(info.title, 'Phiên đã đóng');
      expect(info.message, 'Buổi điểm danh đã kết thúc.');
    });
  });

  group('Controllers Unit Tests', () {
    test('SessionController formats remaining time correctly', () {
      final controller = SessionController();
      expect(controller.formattedRemainingTime, isNotNull);
    });

    test('StudentAttendanceController initializes cleanly', () {
      final controller = StudentAttendanceController();
      expect(controller.enrollments, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.lastCheckInRecord, isNull);
    });
  });
}
