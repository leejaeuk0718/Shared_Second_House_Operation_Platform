import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../storage/secure_storage.dart';
import 'api_constants.dart';
import '../../config/app_config.dart'; // 실제 경로에 맞춰져 있음

class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  late final Dio dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  bool _isRefreshing = false;
  final List<Completer<void>> _refreshWaiters = [];

  /// main()에서 앱 시작 시 1회 호출
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(path.join(dir.path, '.cookies')),
    );
    dio.interceptors.add(CookieManager(cookieJar)); // refresh_token 쿠키 자동 첨부/저장

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.instance.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (isUnauthorized && !alreadyRetried) {
          try {
            await _refreshAccessToken();

            final retryOptions = error.requestOptions;
            retryOptions.extra['retried'] = true;
            final newToken = await SecureStorage.instance.getAccessToken();
            retryOptions.headers['Authorization'] = 'Bearer $newToken';

            final response = await dio.fetch(retryOptions);
            return handler.resolve(response);
          } catch (_) {
            await SecureStorage.instance.clearAccessToken();
            return handler.next(error);
          }
        }
        handler.next(error);
      },
    ));
  }

  /// 동시에 여러 요청이 401을 맞아도 refresh-token 호출은 한 번만 나가게 함
  Future<void> _refreshAccessToken() async {
    if (_isRefreshing) {
      final completer = Completer<void>();
      _refreshWaiters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    try {
      final response = await dio.post(ApiConstants.refreshToken);
      final body = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final newAccessToken = body['accessToken'] as String;
      await SecureStorage.instance.saveAccessToken(newAccessToken);

      for (final waiter in _refreshWaiters) {
        waiter.complete();
      }
      _refreshWaiters.clear();
    } catch (e) {
      for (final waiter in _refreshWaiters) {
        waiter.completeError(e);
      }
      _refreshWaiters.clear();
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }
}