/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/service/stay_accommodation_service.dart
 * 역할  : 숙소 API 통신 레이어 (Dio → Spring REST API 호출)
 * 사용처 : StayAccommodationController
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_accommodation_dto.dart          : 응답 모델
 * - stay_accommodation_controller.dart   : 이 서비스 호출
 * - Spring: StayAccommodationController  : GET /stay/accommodations
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - getAccommodations()           : 전체 목록 조회 (홈화면용, size=100)
 * - getAccommodationsPaged()      : 검색 + 페이징 조회 (목록화면용, 기본 size=3)
 * - getAccommodation(id)          : 단건 상세 조회
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * Controller 호출 → Dio GET 요청 → 응답 JSON → fromJson() → DTO 반환
 * ==================================================================================
 */

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_front/core/api/dio_client.dart';
import 'package:flutter_front/domain/dto/stay_accommodation_dto.dart';

class StayAccommodationService {
  Dio get _dio => DioClient.instance.dio;

  Future<List<StayAccommodationDto>> getAccommodations() async {
    final response = await _dio.get('/stay/accommodations', queryParameters: {'page': 0, 'size': 100});
    debugPrint('🔍 서버 실제 응답 데이터 타입: ${response.data.runtimeType}');
    debugPrint('🔍 서버 실제 응답 데이터 내용: ${response.data}');
    final data = response.data as Map<String, dynamic>;
    return (data['content'] as List).map((e) => StayAccommodationDto.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getAccommodationsPaged({String? keyword, int page = 0, int size = 6}) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    final response = await _dio.get('/stay/accommodations', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<StayAccommodationDto> getAccommodation(int id) async {
    final response = await _dio.get('/stay/accommodations/$id');
    return StayAccommodationDto.fromJson(response.data);
  }
}
