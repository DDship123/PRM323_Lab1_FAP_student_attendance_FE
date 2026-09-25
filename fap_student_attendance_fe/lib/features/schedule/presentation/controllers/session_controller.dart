import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/session_repository.dart';
import '../../../attendance/data/models/attendance_models.dart';
import '../../../attendance/data/repositories/attendance_repository.dart';

/// Controller quản lý Phiên Điểm Danh (Session) & Điểm danh thời gian thực cho Giảng Viên
class SessionController extends ChangeNotifier {
  final SessionRepository _sessionRepository = SessionRepository();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  static final SessionController _instance = SessionController._internal();
  factory SessionController() => _instance;
  SessionController._internal();

  AttendanceSessionModel? _currentSession;
  List<AttendanceRecordModel> _liveRecords = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ── Dynamic QR Token State (TOTP mặc định 20s) ──
  String? _currentQrToken;
  String? _qrCodeBase64;
  int _tokenRemainingSeconds = 20;
  int _tokenIntervalSeconds = 20;
  bool _isStreamActive = false;

  // Timers & Subscriptions
  Timer? _countdownTimer;
  Timer? _pollTimer;
  Timer? _qrPollTimer;
  Timer? _localTokenTimer;
  StreamSubscription<DynamicQrTokenModel>? _qrStreamSubscription;
  int _remainingSeconds = 0;

  AttendanceSessionModel? get currentSession => _currentSession;
  List<AttendanceRecordModel> get liveRecords => _liveRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get remainingSeconds => _remainingSeconds;

  String? get currentQrToken => _currentQrToken ?? _currentSession?.currentQrToken;
  String? get qrCodeBase64 => _qrCodeBase64 ?? _currentSession?.qrCodeBase64;
  int get tokenRemainingSeconds => _tokenRemainingSeconds;
  int get tokenIntervalSeconds => _tokenIntervalSeconds > 0 ? _tokenIntervalSeconds : 20;
  double get tokenProgress => _tokenIntervalSeconds > 0
      ? (_tokenRemainingSeconds / _tokenIntervalSeconds).clamp(0.0, 1.0)
      : 0.0;
  bool get isStreamActive => _isStreamActive;

  String get formattedRemainingTime {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Tạo phiên điểm danh mới: POST /api/sessions (Tự động bắt IP của Giảng viên, hỗ trợ qrRefreshSeconds và roomBssid)
  Future<AttendanceSessionModel?> createSession({
    required String courseId,
    required int slotNumber,
    required DateTime sessionDate,
    required int durationMinutes,
    int? qrRefreshSeconds,
    String? roomNetworkIp,
    String? roomBssid,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _sessionRepository.createSession(
        SessionCreateRequest(
          courseId: courseId,
          slotNumber: slotNumber,
          sessionDate: sessionDate,
          durationMinutes: durationMinutes,
          qrRefreshSeconds: qrRefreshSeconds ?? 20,
          roomNetworkIp: roomNetworkIp,
          roomBssid: roomBssid,
        ),
      );

      _currentSession = session;
      _currentQrToken = session.currentQrToken;
      _qrCodeBase64 = session.qrCodeBase64;
      _tokenRemainingSeconds = session.tokenRemainingSeconds ?? session.qrRefreshSeconds ?? 20;
      _tokenIntervalSeconds = session.tokenIntervalSeconds ?? session.qrRefreshSeconds ?? 20;
      _isLoading = false;

      startLiveAttendance(session);
      notifyListeners();
      return session;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Khởi động theo dõi live (đếm ngược session + SSE/Polling Dynamic QR Token + poll danh sách điểm danh)
  void startLiveAttendance(AttendanceSessionModel session) {
    _currentSession = session;
    _currentQrToken = session.currentQrToken;
    _qrCodeBase64 = session.qrCodeBase64;
    _tokenRemainingSeconds = session.tokenRemainingSeconds ?? session.qrRefreshSeconds ?? 20;
    _tokenIntervalSeconds = session.tokenIntervalSeconds ?? session.qrRefreshSeconds ?? 20;
    _liveRecords = [];

    // Tính thời gian còn lại của ca học
    final now = DateTime.now();
    final expireAt = session.expireAt;
    final diff = expireAt.difference(now).inSeconds;
    _remainingSeconds = diff > 0 ? diff : session.durationMinutes * 60;

    // Hủy các timer & subscription cũ nếu có
    stopLiveAttendance();

    // 1. Timer đếm ngược thời gian ca học (mỗi giây)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _pollTimer?.cancel();
        notifyListeners();
      }
    });

    // 2. Timer cục bộ đếm ngược số giây của QR Token (20s -> 0s)
    _localTokenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_tokenRemainingSeconds > 0) {
        _tokenRemainingSeconds--;
        notifyListeners();
      } else {
        // Hết chu kỳ, nếu stream chưa cập nhật thì tải polling ngay
        _tokenRemainingSeconds = _tokenIntervalSeconds > 0 ? _tokenIntervalSeconds : 20;
        _fetchCurrentQrToken();
      }
    });

    // 3. Khởi động nhận Dynamic QR Token (SSE trước, nếu lỗi chuyển qua Polling)
    _startDynamicQrUpdates(session.id);

    // 4. Lần đầu tải ngay danh sách sinh viên điểm danh
    _fetchLiveRecords();

    // 5. Timer polling cập nhật danh sách điểm danh mỗi 3 giây
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchLiveRecords();
    });
  }

  /// Bắt đầu cập nhật mã QR động qua SSE (Server-Sent Events) với fallback sang Polling
  void _startDynamicQrUpdates(String sessionId) {
    try {
      _isStreamActive = false;
      _qrStreamSubscription?.cancel();

      // Đăng ký stream SSE
      _qrStreamSubscription = _sessionRepository.streamQrTokens(sessionId).listen(
        (data) {
          _isStreamActive = true;
          _currentQrToken = data.currentQrToken;
          if (data.qrCodeBase64 != null && data.qrCodeBase64!.isNotEmpty) {
            _qrCodeBase64 = data.qrCodeBase64;
          }
          _tokenRemainingSeconds = data.tokenRemainingSeconds;
          _tokenIntervalSeconds = data.tokenIntervalSeconds;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('SSE Stream disconnected, falling back to HTTP Polling: $err');
          _isStreamActive = false;
          _setupQrPollingFallback(sessionId);
        },
        onDone: () {
          _isStreamActive = false;
          _setupQrPollingFallback(sessionId);
        },
        cancelOnError: true,
      );
    } catch (_) {
      _setupQrPollingFallback(sessionId);
    }
  }

  /// Cấu hình fallback Polling định kỳ mỗi 5 giây nếu SSE không khả dụng
  void _setupQrPollingFallback(String sessionId) {
    _qrPollTimer?.cancel();
    _fetchCurrentQrToken();
    _qrPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchCurrentQrToken();
    });
  }

  /// Gọi API polling lấy mã QR Token hiện tại: GET /api/sessions/{sessionId}/current-token
  Future<void> _fetchCurrentQrToken() async {
    if (_currentSession == null) return;
    try {
      final tokenData = await _sessionRepository.getCurrentToken(_currentSession!.id);
      _currentQrToken = tokenData.currentQrToken;
      if (tokenData.qrCodeBase64 != null && tokenData.qrCodeBase64!.isNotEmpty) {
        _qrCodeBase64 = tokenData.qrCodeBase64;
      }
      _tokenRemainingSeconds = tokenData.tokenRemainingSeconds;
      _tokenIntervalSeconds = tokenData.tokenIntervalSeconds;
      notifyListeners();
    } catch (_) {
      // Bỏ qua lỗi polling im lặng
    }
  }

  /// Lấy danh sách sinh viên đã điểm danh trong phiên
  Future<void> _fetchLiveRecords() async {
    if (_currentSession == null) return;
    try {
      final records = await _attendanceRepository.getSessionRecords(_currentSession!.id);
      _liveRecords = records;
      notifyListeners();
    } catch (_) {
      // Bỏ qua lỗi polling im lặng để không gián đoạn UI
    }
  }

  /// Đóng phiên điểm danh: PUT /api/sessions/{id}/close
  Future<bool> closeCurrentSession() async {
    if (_currentSession == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _sessionRepository.closeSession(_currentSession!.id);
      _currentSession = updated;
      stopLiveAttendance();
      _remainingSeconds = 0;
      await _fetchLiveRecords(); // Tải danh sách lần cuối
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Dừng theo dõi live
  void stopLiveAttendance() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _qrPollTimer?.cancel();
    _localTokenTimer?.cancel();
    _qrStreamSubscription?.cancel();
    _qrStreamSubscription = null;
    _isStreamActive = false;
  }

  @override
  void dispose() {
    stopLiveAttendance();
    super.dispose();
  }
}

