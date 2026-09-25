/// Constants dùng chung toàn bộ ứng dụng
class AppConstants {
  AppConstants._();

  static const String appName = 'Attendly';
  static const String appTagline = 'Điểm danh thông minh';
  static const String appVersion = '1.0.0';

  // ── Branding ──
  static const String universityName = 'FPT UNIVERSITY';
  static const String educationBrand = 'FPT Education';
  static const String brandSlogan = 'Nâng tầm quản lý\nbuổi học';
  static const List<String> brandFeatures = [
    'Quét mã thông minh, định vị thiết bị',
    'Dữ liệu chính xác, tức thì',
    'Nhập/Xuất dữ liệu nhanh chóng, tiện lợi',
  ];
  static const String brandFooter = 'Attendly · Dành cho trường học hiện đại';

  // ── API ──
  static const String baseUrl = 'http://localhost:8080';
  static const String apiPrefix = '/api';
}
