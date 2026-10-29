import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'error_handler/api_error_model.dart';

/// Optional hook so feature apps can react to an unauthorized response
/// (e.g. force logout) without the core knowing about session specifics.
typedef UnauthorizedHandler = void Function(String reason);

class DioFactory {
  DioFactory._();

  static Dio? dio;
  static UnauthorizedHandler? onUnauthorized;

  static Dio getDio() {
    final Duration timeOut = const Duration(seconds: 30);

    if (dio == null) {
      dio = Dio();
      dio!
        ..options.connectTimeout = timeOut
        ..options.receiveTimeout = timeOut;
      addDioInterceptor();
      return dio!;
    } else {
      return dio!;
    }
  }

  static void addDioInterceptor() {
    dio?.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          // Hook for feature apps: force logout on 401, etc.
          if (error.response?.statusCode == 401) {
            onUnauthorized
                ?.call('Received 401 from ${error.requestOptions.path}');
          }

          if (error.response?.data != null) {
            try {
              final apiError = ApiErrorModel.fromJson(error.response?.data);
              return handler.reject(DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: error.type,
                error: apiError,
              ));
            } catch (e) {
              return handler.reject(error);
            }
          }
          return handler.reject(error);
        },
      ),
    );

    // Verbose request/response logging in DEBUG builds only: in release it
    // would print full headers to stdout on every request — a performance
    // and security concern.
    if (kDebugMode) {
      dio?.interceptors.add(
        PrettyDioLogger(
          requestBody: true,
          requestHeader: true,
          responseHeader: true,
        ),
      );
    }
  }

  static void setAuthorizationHeader(String token) {
    dio?.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authorization header on logout
  static void clearAuthorizationHeader() {
    dio?.options.headers.remove('Authorization');
  }

  /// Reset Dio instance completely (for full logout)
  static void reset() {
    dio?.options.headers.clear();
    dio = null;
  }
}
