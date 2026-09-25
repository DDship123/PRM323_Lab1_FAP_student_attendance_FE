import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

/// Lớp ngoại lệ trả về từ Backend API hoặc sự cố mạng
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic errors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  Map<String, String> get fieldErrors {
    if (errors is Map) {
      final map = errors as Map;
      return map.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  @override
  String toString() => message;
}

/// Chuẩn Response chuẩn hóa từ hệ thống Spring Boot Backend
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? timestamp;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic)? fromData,
  ]) {
    final rawData = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (rawData != null && fromData != null)
          ? fromData(rawData)
          : (rawData as T?),
      timestamp: json['timestamp'] as String?,
    );
  }
}

/// Client gọi HTTP request thống nhất cho toàn bộ ứng dụng
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final TokenStorage _tokenStorage = TokenStorage();
  final Duration _timeout = const Duration(seconds: 15);

  /// Tạo Header mặc định kèm Authorization nếu cần
  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Gửi POST request
  Future<ApiResponse<dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Không thể kết nối đến máy chủ Ứng dụng (http://localhost:8080). Vui lòng kiểm tra lại dịch vụ.',
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Kết nối đến máy chủ quá thời gian chờ (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Đã xảy ra lỗi kết nối: $e',
      );
    }
  }

  /// Gửi PUT request
  Future<ApiResponse<dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Không thể kết nối đến máy chủ Ứng dụng (http://localhost:8080). Vui lòng kiểm tra lại dịch vụ.',
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Kết nối đến máy chủ quá thời gian chờ (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Đã xảy ra lỗi kết nối: $e',
      );
    }
  }

  /// Gửi GET request
  Future<ApiResponse<dynamic>> get(
    String url, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await http.get(uri, headers: headers).timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Không thể kết nối đến máy chủ Ứng dụng. Vui lòng kiểm tra lại dịch vụ.',
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Kết nối đến máy chủ quá thời gian chờ (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Đã xảy ra lỗi kết nối: $e',
      );
    }
  }

  /// Gửi DELETE request
  Future<ApiResponse<dynamic>> delete(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Không thể kết nối đến máy chủ Ứng dụng. Vui lòng kiểm tra lại dịch vụ.',
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Kết nối đến máy chủ quá thời gian chờ (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Đã xảy ra lỗi kết nối: $e',
      );
    }
  }

  /// Gửi multipart POST request để upload file (Excel, CSV)
  Future<ApiResponse<dynamic>> postMultipart(
    String url, {
    required List<int> fileBytes,
    required String filename,
    required String fieldName,
    Map<String, String>? fields,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      if (requiresAuth) {
        final token = await _tokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: filename,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Không thể kết nối đến máy chủ Ứng dụng. Vui lòng kiểm tra lại dịch vụ.',
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Quá thời gian upload file lên máy chủ.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Đã xảy ra lỗi khi tải file lên: $e',
      );
    }
  }

  /// Tải dữ liệu nhị phân (Binary bytes) như file Excel / CSV
  Future<Uint8List> getBytes(
    String url, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final headers = <String, String>{};
      if (requiresAuth) {
        final token = await _tokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final response = await http.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: 'Không thể tải file từ máy chủ (HTTP ${response.statusCode})',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Không thể kết nối đến máy chủ Ứng dụng để tải file.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Lỗi tải file: $e',
      );
    }
  }

  /// Xử lý HTTP response và parse dữ liệu ApiResponse
  ApiResponse<dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic>? bodyJson;
    try {
      if (response.body.isNotEmpty) {
        bodyJson = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (_) {
      // Body không phải JSON hợp lệ
    }

    final isSuccessStatus = response.statusCode >= 200 && response.statusCode < 300;

    if (bodyJson != null) {
      final apiResponse = ApiResponse.fromJson(bodyJson);

      if (!isSuccessStatus || !apiResponse.success) {
        // Trích xuất thông điệp lỗi cụ thể
        String errorMsg = apiResponse.message.isNotEmpty
            ? apiResponse.message
            : 'Yêu cầu không thành công (Mã: ${response.statusCode})';

        // Nếu có validation errors chi tiết trong data
        if (apiResponse.data is Map) {
          final errorMap = apiResponse.data as Map;
          final details = errorMap.values.join(', ');
          if (details.isNotEmpty) {
            errorMsg = '$errorMsg: $details';
          }
        }

        throw ApiException(
          statusCode: response.statusCode,
          message: errorMsg,
          errors: apiResponse.data,
        );
      }

      return apiResponse;
    }

    if (!isSuccessStatus) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Lỗi từ máy chủ (HTTP ${response.statusCode})',
      );
    }

    return ApiResponse(
      success: true,
      message: 'Thành công',
      data: null,
    );
  }
}
