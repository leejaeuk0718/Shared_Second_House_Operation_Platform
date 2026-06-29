/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/service/stay_story_service.dart
 * 역할  : 숙소 스토리 API 통신 레이어
 * 사용처 : StayAccommodationController (상세 화면 병렬 로드)
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_story_dto.dart                 : 응답 모델
 * - stay_accommodation_controller.dart  : 이 서비스 호출
 * - Spring: StayStoryController.java    : GET /stay/stories/{accommodationId}
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - getStories(accommodationId) : 숙소별 스토리 목록 조회
 * ==================================================================================
 */

import 'package:dio/dio.dart';
import 'package:flutter_front/config/app_config.dart';
import 'package:flutter_front/domain/dto/stay_story_dto.dart';

class StayStoryService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  Future<List<StayStoryDto>> getStories(int accommodationId) async {
    final response = await _dio.get('/stay/stories/$accommodationId');
    return (response.data as List)
        .map((e) => StayStoryDto.fromJson(e))
        .toList();
  }
}
