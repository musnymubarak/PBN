import 'package:dio/dio.dart';
import 'package:pbn/core/constants/api_config.dart';
import 'package:pbn/core/services/secure_storage.dart';

/// Singleton Dio HTTP client with auth interceptor.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));
  }

  /// Attach Bearer token to every request.
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Unwrap the `{data: ...}` envelope.
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  /// Auto-refresh on 401 (one retry).
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        // Retry the original request with new token
        final token = await SecureStorage.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.reject(err);
        }
      }
    }
    handler.reject(err);
  }

  /// Attempt to refresh the access token.
  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      // Use a clean Dio instance to avoid interceptor loop
      final cleanDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      final res = await cleanDio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final newToken = res.data['data']?['access_token'];
      if (newToken != null) {
        await SecureStorage.setAccessToken(newToken);
        return true;
      }
      return false;
    } catch (_) {
      // Refresh failed — user needs to re-login
      await SecureStorage.clearAll();
      return false;
    }
  }

  // ── Convenience methods ───────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      dio.get(path, queryParameters: queryParams);

  Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      dio.patch(path, data: data);

  Future<Response> delete(String path) => dio.delete(path);

  /// Extract the `data` field from the standard API response envelope.
  dynamic unwrap(Response response) => response.data['data'];
}
