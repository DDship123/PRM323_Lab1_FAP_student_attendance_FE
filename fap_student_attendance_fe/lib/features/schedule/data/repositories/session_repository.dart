import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/session_model.dart';

/// Repository xử lý API phiên / buổi điểm danh
class SessionRepository {
  final ApiClient _apiClient = ApiClient();

  static final SessionRepository _instance = SessionRepository._internal();
  factory SessionRepository() => _instance;
  SessionRepository._internal();

  /// Tạo buổi điểm danh mới: POST /api/sessions
  Future<AttendanceSessionModel> createSession(SessionCreateRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.sessions,
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.data == null) {
      throw ApiException(
        statusCode: 500,
        message: 'Không nhận được dữ liệu phiên điểm danh vừa tạo',
      );
    }

    return AttendanceSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Lấy thông tin chi tiết phiên điểm danh: GET /api/sessions/{sessionId}
  Future<AttendanceSessionModel> getSessionById(String sessionId) async {
    final response = await _apiClient.get(
      ApiEndpoints.sessionDetail(sessionId),
      requiresAuth: true,
    );

    if (response.data == null) {
      throw ApiException(
        statusCode: 404,
        message: 'Không tìm thấy phiên điểm danh',
      );
    }

    return AttendanceSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Lấy danh sách buổi điểm danh theo môn học: GET /api/sessions/course/{courseId}
  Future<List<AttendanceSessionModel>> getSessionsByCourse(String courseId) async {
    final response = await _apiClient.get(
      ApiEndpoints.sessionsByCourse(courseId),
      requiresAuth: true,
    );

    if (response.data is List) {
      final list = response.data as List;
      return list
          .map((e) => AttendanceSessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Lấy mã Dynamic QR Token hiện tại (Polling): GET /api/sessions/{sessionId}/current-token
  Future<DynamicQrTokenModel> getCurrentToken(String sessionId) async {
    final response = await _apiClient.get(
      ApiEndpoints.currentToken(sessionId),
      requiresAuth: true,
    );

    if (response.data == null) {
      throw ApiException(
        statusCode: 500,
        message: 'Không nhận được dữ liệu Dynamic QR Token',
      );
    }

    return DynamicQrTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Stream SSE mã QR động realtime (Server-Sent Events): GET /api/sessions/{sessionId}/qr-stream
  Stream<DynamicQrTokenModel> streamQrTokens(String sessionId) async* {
    final token = await TokenStorage().getToken();
    final client = http.Client();
    final uri = Uri.parse(ApiEndpoints.qrStream(sessionId));
    final request = http.Request('GET', uri);
    request.headers['Accept'] = 'text/event-stream';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await client.send(request);
      if (response.statusCode == 200) {
        final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());
        String currentEvent = '';
        try {
          await for (final line in stream) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;

            if (trimmed.startsWith('event:')) {
              currentEvent = trimmed.substring(6).trim();
            } else if (trimmed.startsWith('data:')) {
              final dataStr = trimmed.substring(5).trim();
              if (dataStr.isNotEmpty && (currentEvent == 'qr-token' || currentEvent.isEmpty)) {
                try {
                  final json = jsonDecode(dataStr) as Map<String, dynamic>;
                  yield DynamicQrTokenModel.fromJson(json);
                } catch (_) {}
              }
            }
          }
        } catch (_) {
          // SSE stream connection closed by server or network; gracefully completes to trigger polling fallback
        }
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Không thể kết nối stream QR SSE: HTTP ${response.statusCode}',
        );
      }
    } finally {
      client.close();
    }
  }

  /// Đóng buổi điểm danh: PUT /api/sessions/{sessionId}/close
  Future<AttendanceSessionModel> closeSession(String sessionId) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.closeSession(sessionId),
        requiresAuth: true,
      );
      if (response.data != null) {
        return AttendanceSessionModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback
    }

    return getSessionById(sessionId);
  }
}
