import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Controller quản lý trạng thái xác thực và phiên làm việc của người dùng
class AuthController extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, String> _fieldErrors = {};

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  Map<String, String> get fieldErrors => _fieldErrors;
  bool get isAuthenticated => _currentUser != null;

  /// Khởi tạo và khôi phục phiên đăng nhập từ SharedPreferences
  Future<void> init() async {
    _currentUser = await _repository.getCurrentUser();
    notifyListeners();
  }

  /// Xóa các thông báo lỗi và thành công
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _fieldErrors = {};
    notifyListeners();
  }

  /// Thực hiện đăng nhập
  Future<UserModel?> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _fieldErrors = {};
    notifyListeners();

    try {
      final authResponse = await _repository.login(
        LoginRequest(username: username, password: password),
      );
      _currentUser = authResponse.user;
      _successMessage = 'Đăng nhập thành công!';
      _isLoading = false;
      notifyListeners();
      return _currentUser;
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

  /// Thực hiện đăng ký tài khoản
  Future<UserModel?> register(RegisterRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _fieldErrors = {};
    notifyListeners();

    try {
      final newUser = await _repository.register(request);
      _successMessage = 'Đăng ký tài khoản thành công! Bạn có thể đăng nhập ngay.';
      _isLoading = false;
      notifyListeners();
      return newUser;
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

  /// Cập nhật thông tin cá nhân
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? username,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _fieldErrors = {};
    notifyListeners();

    try {
      final updated = await _repository.updateProfile(
        fullName: fullName,
        email: email,
        username: username,
      );
      _currentUser = updated;
      _successMessage = 'Cập nhật thông tin tài khoản thành công!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiException) {
        _errorMessage = e.message;
        _fieldErrors = e.fieldErrors;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  /// Đổi mật khẩu
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _fieldErrors = {};
    notifyListeners();

    try {
      await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _successMessage = 'Đổi mật khẩu thành công!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is ApiException) {
        _errorMessage = e.message;
        _fieldErrors = e.fieldErrors;
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    _errorMessage = null;
    _successMessage = null;
    _fieldErrors = {};
    notifyListeners();
  }
}
