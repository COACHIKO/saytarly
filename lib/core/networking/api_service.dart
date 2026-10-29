import 'package:dio/dio.dart';

import '../utils/helpers/base_url_helper.dart';
import 'error_handler/api_error_model.dart';

/// Generic REST client built over [Dio].
///
/// The core app only ships the transport primitives — every feature
/// app defines its own endpoints in its [ApiService] subclass
/// (or repositories that use this class directly).
class ApiService {
  final Dio _dio;
  String _baseUrl;

  ApiService(this._dio, {String? baseUrl})
      : _baseUrl = adjustUrl(baseUrl ?? _effectiveBaseUrl()) ?? '';

  static String _effectiveBaseUrl() {
    try {
      return getBaseUrl();
    } catch (_) {
      return '';
    }
  }

  String get baseUrl => _baseUrl;

  /// Refresh the base URL after login/logout/config change.
  void refreshBaseUrl({String? baseUrl}) {
    _baseUrl = adjustUrl(baseUrl ?? _effectiveBaseUrl()) ?? _baseUrl;
  }

  /// Default authorization header management (Bearer token).
  void setAuthorizationHeader(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthorizationHeader() {
    _dio.options.headers.remove('Authorization');
  }

  // ── Transport primitives ────────────────────────────────────────────────────

  Future<Response> post(String endpoint, dynamic data) async {
    try {
      return await _dio.post('$_baseUrl$endpoint', data: data);
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: endpoint),
        error: ApiErrorModel(message: e.toString()),
      );
    }
  }

  Future<Response> put(String endpoint, dynamic data) async {
    return _dio.put('$_baseUrl$endpoint', data: data);
  }

  Future<Response> get(String endpoint) async {
    return _dio.get('$_baseUrl$endpoint');
  }

  Future<Response> delete(String endpoint) async {
    try {
      return await _dio.delete('$_baseUrl$endpoint');
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: endpoint),
        error: ApiErrorModel(message: e.toString()),
      );
    }
  }

  /// Compact a payload: remove null values and empty strings.
  static Map<String, dynamic> compactPayload(Map<String, dynamic> payload) {
    final compacted = <String, dynamic>{};
    payload.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      compacted[key] = value;
    });
    return compacted;
  }
}
