import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AttendanceErrorKind {
  invalidOrExpiredQr,
  wifiBssidMismatch,
  subnetIpMismatch,
  deviceAlreadyUsed,
  alreadyCheckedIn,
  notEnrolled,
  sessionClosedOrExpired,
  unknown,
}

/// Helper ánh xạ và xử lý mã lỗi nghiệp vụ điểm danh sang thông báo thân thiện cho Sinh viên
/// Theo quy định tại FRONTEND_QR_ATTENDANCE_INTEGRATION_GUIDE.md (Mục 5)
class AttendanceErrorInfo {
  final AttendanceErrorKind kind;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String? suggestion;

  const AttendanceErrorInfo({
    required this.kind,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.suggestion,
  });

  bool get canScanAgain =>
      kind == AttendanceErrorKind.invalidOrExpiredQr || kind == AttendanceErrorKind.unknown;

  bool get canTryPin =>
      kind != AttendanceErrorKind.deviceAlreadyUsed &&
      kind != AttendanceErrorKind.alreadyCheckedIn &&
      kind != AttendanceErrorKind.notEnrolled &&
      kind != AttendanceErrorKind.sessionClosedOrExpired;
}

class AttendanceErrorHelper {
  AttendanceErrorHelper._();

  /// Phân tích thông điệp lỗi và mã trạng thái HTTP từ Backend để tạo ra UI thân thiện
  static AttendanceErrorInfo parse(String? rawError, {int? statusCode}) {
    final text = (rawError ?? '').trim().toLowerCase();

    // 1. Mã QR đổi chu kỳ / hết hạn chu kỳ TOTP 10s
    if (text.contains('đổi chu kỳ') ||
        text.contains('không hợp lệ hoặc đã hết hạn') ||
        text.contains('hết hạn hoặc không hợp lệ') ||
        text.contains('qr token') ||
        text.contains('chu kỳ mới') ||
        text.contains('quá hạn 20s') ||
        text.contains('mã qr đã đổi')) {
      return const AttendanceErrorInfo(
        kind: AttendanceErrorKind.invalidOrExpiredQr,
        title: 'Mã QR đã đổi chu kỳ (Hết hạn)',
        message: 'Mã QR đã chuyển sang chu kỳ mới. Vui lòng hướng camera quét lại mã trên màn hình!',
        icon: Icons.refresh_rounded,
        color: AppColors.warning,
        suggestion: 'Mã QR trên máy chiếu đổi động mỗi 10 giây qua thuật toán TOTP để chống gian lận. Bạn chỉ cần quét lại mã hiện tại.',
      );
    }

    // 2. Wi-Fi: BSSID không khớp
    if (text.contains('bssid không khớp') ||
        text.contains('đúng mạng wi-fi phòng học') ||
        text.contains('bssid')) {
      return const AttendanceErrorInfo(
        kind: AttendanceErrorKind.wifiBssidMismatch,
        title: 'Sai Wi-Fi phòng học',
        message: 'Bạn chưa kết nối đúng Wi-Fi phòng học. Vui lòng kết nối vào Wi-Fi lớp học để điểm danh!',
        icon: Icons.wifi_off_rounded,
        color: AppColors.error,
        suggestion: 'Hãy ngắt kết nối 4G/5G và bật Wi-Fi của điện thoại, chọn đúng mạng Wi-Fi phòng học đang giảng dạy.',
      );
    }

    // 3. Wi-Fi: Subnet / Public IP không khớp với Giảng viên
    if (text.contains('cùng mạng wi-fi với giảng viên') ||
        text.contains('địa chỉ mạng không khớp') ||
        text.contains('dải mạng ip không khớp') ||
        text.contains('subnet') ||
        text.contains('public ip') ||
        text.contains('khác subnet')) {
      return const AttendanceErrorInfo(
        kind: AttendanceErrorKind.subnetIpMismatch,
        title: 'Không cùng dải mạng phòng học',
        message: 'Địa chỉ mạng không khớp. Vui lòng tắt 4G/VPN và kết nối cùng mạng Wi-Fi với giảng viên!',
        icon: Icons.lan_outlined,
        color: AppColors.error,
        suggestion: 'Kiểm tra xem máy bạn có đang bật VPN, 1.1.1.1, hoặc iCloud Private Relay không. Hãy tắt chúng và kết nối Wi-Fi trường.',
      );
    }

    // 4. Thiết bị đã được dùng cho sinh viên khác (Chống điểm danh hộ)
    if (text.contains('thiết bị này đã được sử dụng') ||
        text.contains('thiết bị này đã dùng cho sinh viên khác') ||
        text.contains('device id') ||
        text.contains('chống điểm danh hộ')) {
      return const AttendanceErrorInfo(
        kind: AttendanceErrorKind.deviceAlreadyUsed,
        title: 'Thiết bị đã điểm danh',
        message: 'Điểm danh thất bại! Thiết bị này đã được dùng để điểm danh cho sinh viên khác trong buổi học.',
        icon: Icons.phonelink_lock_rounded,
        color: AppColors.error,
        suggestion: 'Quy tắc an ninh: Mỗi thiết bị chỉ được điểm danh cho đúng một sinh viên trong một buổi học. Nghiêm cấm điểm danh hộ.',
      );
    }

    // 5. Sinh viên đã điểm danh rồi (Trùng lặp)
    if (text.contains('đã thực hiện điểm danh') ||
        text.contains('đã điểm danh buổi này rồi') ||
        text.contains('đã điểm danh thành công phiên này trước đó') ||
        text.contains('trước đó')) {
      return const AttendanceErrorInfo(
        kind: AttendanceErrorKind.alreadyCheckedIn,
        title: 'Đã được ghi nhận có mặt',
        message: 'Bạn đã hoàn thành điểm danh cho buổi học này rồi.',
        icon: Icons.info_outline_rounded,
        color: AppColors.info,
        suggestion: 'Bạn đã có mặt (PRESENT) trong danh sách của buổi học này. Bạn có thể kiểm tra lại tại mục Lịch sử điểm danh.',
      );
    }

    // 6. Chưa enroll khóa học
    if (text.contains('chưa đăng ký tham gia') ||
        text.contains('chưa enroll') ||
        text.contains('không thuộc danh sách lớp') ||
        text.contains('không có tên trong danh sách') ||
        statusCode == 403) {
      return const AttendanceErrorInfo(
        kind: AttendanceErrorKind.notEnrolled,
        title: 'Không có tên trong lớp',
        message: 'Bạn không có tên trong danh sách đăng ký của khóa học này.',
        icon: Icons.person_off_rounded,
        color: AppColors.error,
        suggestion: 'Hãy kiểm tra lại xem bạn có quét nhầm mã của lớp khác hay chưa được ghi danh vào môn học này.',
      );
    }

    // 7. Phiên điểm danh đã hết hạn / đóng
    if (text.contains('hết hạn') ||
        text.contains('đã kết thúc') ||
        text.contains('đã đóng') ||
        text.contains('buổi học đã hết hạn')) {
      return const AttendanceErrorInfo(
        kind: AttendanceErrorKind.sessionClosedOrExpired,
        title: 'Phiên đã đóng',
        message: 'Buổi điểm danh đã kết thúc.',
        icon: Icons.timer_off_outlined,
        color: AppColors.textSecondary,
        suggestion: 'Giảng viên đã kết thúc phiên điểm danh hoặc thời gian hiệu lực của ca học đã qua.',
      );
    }

    // Mặc định
    final fallbackMsg = rawError?.isNotEmpty == true
        ? rawError!
        : 'Điểm danh thất bại. Vui lòng kiểm tra kết nối mạng và thử lại.';

    return AttendanceErrorInfo(
      kind: AttendanceErrorKind.unknown,
      title: 'Điểm danh không thành công',
      message: fallbackMsg,
      icon: Icons.cancel_outlined,
      color: AppColors.error,
      suggestion: 'Vui lòng kiểm tra kết nối Wi-Fi phòng học, hướng camera quét lại mã trên máy chiếu hoặc liên hệ Giảng viên.',
    );
  }
}
