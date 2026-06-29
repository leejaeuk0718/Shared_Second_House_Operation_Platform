import 'package:dio/dio.dart';
import 'package:flutter_front/core/api/dio_client.dart';
import 'package:flutter_front/domain/dto/route_dto.dart';

/// 🗺️ 이동경로 추적 서비스 (백엔드 /api/routes 호출)
///
/// ⚠️ baseUrl / accessToken 을 생성자로 받는 이유:
/// 이 서비스는 UI isolate뿐 아니라 flutter_foreground_task의 별도 isolate에서도 쓰인다.
/// 그 isolate에는 dotenv도, DioClient(토큰 인터셉터)도 없으므로 baseUrl과 accessToken을
/// 호출 측(UI isolate)에서 saveData로 넘겨받아 직접 헤더에 실어 전송한다.
///
/// ⚠️ 인증 (서버 /api/routes/** 는 인증 필수):
/// - startSession / endSession / getPoints / getSessions : UI isolate에서 호출 →
///   JWT가 자동으로 붙는 DioClient.instance.dio 사용.
/// - addPoints : 백그라운드 isolate에서 호출 → DioClient를 못 쓰므로,
///   넘겨받은 accessToken을 Authorization 헤더로 직접 붙인 bare Dio 사용.
class RouteService {
  final String baseUrl; // 예: http://10.0.2.2:8080/api
  final Dio _dio;

  RouteService(this.baseUrl, {String? accessToken})
      : _dio = Dio(BaseOptions(
          headers: {
            if (accessToken != null && accessToken.isNotEmpty)
              'Authorization': 'Bearer $accessToken',
          },
        ));

  String get _root => '$baseUrl/routes';

  /// 추적 시작 — 새 세션 생성 후 sessionId 반환 (유저는 서버가 JWT로 식별)
  Future<int> startSession() async {
    final res = await DioClient.instance.dio.post('$_root/sessions');
    return (res.data['sessionId'] as num).toInt();
  }

  /// 좌표 묶음 저장 (백그라운드 isolate) — 생성자에서 받은 accessToken으로 인증
  Future<int> addPoints(int sessionId, List<RoutePointData> points) async {
    if (points.isEmpty) return 0;
    final res = await _dio.post(
      '$_root/sessions/$sessionId/points',
      data: points.map((p) => p.toJson()).toList(),
    );
    return (res.data['saved'] as num?)?.toInt() ?? 0;
  }

  /// 추적 종료 (UI isolate)
  Future<void> endSession(int sessionId) async {
    await DioClient.instance.dio.post('$_root/sessions/$sessionId/end');
  }

  /// 세션 좌표 조회 (폴리라인용, UI isolate)
  Future<List<RoutePointData>> getPoints(int sessionId) async {
    final res =
        await DioClient.instance.dio.get('$_root/sessions/$sessionId/points');
    final List<dynamic> data = res.data as List<dynamic>;
    return data
        .map((e) => RoutePointData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 세션 이력 조회 (최신순, UI isolate) — 유저는 서버가 JWT로 식별
  Future<List<RouteSessionData>> getSessions() async {
    final res = await DioClient.instance.dio.get('$_root/sessions');
    final List<dynamic> data = res.data as List<dynamic>;
    return data
        .map((e) => RouteSessionData.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}