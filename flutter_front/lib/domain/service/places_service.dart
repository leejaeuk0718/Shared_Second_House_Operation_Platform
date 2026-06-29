import 'package:flutter_front/config/app_config.dart';
import 'package:flutter_front/core/api/dio_client.dart';
import 'package:flutter_front/domain/dto/place_dto.dart';

/// 🍽️ 주변 맛집 서비스 (백엔드 호출)
/// - savedRestaurants: 내 DB(sh_restaurant)에 저장된 숙소별 맛집 조회 (구글 미호출)
///   ※ 구글 동기화는 서버 스케줄러(주 1회 + 기동 시)가 담당. 프론트는 DB만 읽는다.
/// - 서버 /api/places/** 는 인증 필수 → JWT가 자동 첨부되는 DioClient 사용
class PlacesService {
  // 안드로이드 에뮬레이터 전용 메인 백엔드 주소 (포트 8080)
  final String _baseUrl = AppConfig.baseUrl + "/places";
  final _dio = DioClient.instance.dio;

  /// 특정 숙소 부근으로 저장된 맛집 조회 (내 DB)
  /// 백엔드: GET /api/places/restaurants?accommodationId=
  Future<List<PlaceDto>> savedRestaurants({required int accommodationId}) async {
    print("🚀 [맛집 조회] accommodationId: $accommodationId");

    final response = await _dio.get(
      "$_baseUrl/restaurants",
      queryParameters: {"accommodationId": accommodationId},
    );

    final List<dynamic> data = response.data as List<dynamic>;
    print("🟢 [맛집 조회 성공]: ${data.length}건");
    return data
        .map((e) => PlaceDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}