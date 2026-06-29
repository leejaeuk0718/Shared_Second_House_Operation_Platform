/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/service/stay_reservation_service.dart
 * 역할  : 숙소 예약 API 통신 레이어 (Dio → Spring REST API 호출)
 * 사용처 : StayReservationController
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_reservation_dto.dart          : 요청/응답 모델
 * - stay_reservation_controller.dart   : 이 서비스 호출
 * - Spring: StayReservationController  : /stay/reservations
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - getMyReservations(userId)               : 내 예약 목록 조회
 * - getAccommodationReservations(id)        : 숙소별 예약 목록 조회 (달력 블록용)
 * - createReservation(req)                  : 예약 생성
 * - cancelReservation(id, userId)           : 예약 취소
 * ==================================================================================
 */

import 'package:dio/dio.dart';
import 'package:flutter_front/core/api/dio_client.dart';
import 'package:flutter_front/domain/dto/stay_reservation_dto.dart';

class StayReservationService {
  Dio get _dio => DioClient.instance.dio;

  Future<List<StayReservationDto>> getMyReservations(int userId) async {
    final response = await _dio.get(
      '/stay/reservations',
      queryParameters: {'userId': userId},
    );
    if (response.data is! List) return [];
    return (response.data as List)
        .map((e) => StayReservationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StayReservationDto>> getAccommodationReservations(int accommodationId) async {
    final response = await _dio.get('/stay/reservations/accommodation/$accommodationId');
    if (response.data is! List) return [];
    return (response.data as List)
        .map((e) => StayReservationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StayReservationDto> createReservation(StayReservationRequestDto req) async {
    final response = await _dio.post('/stay/reservations', data: req.toJson());
    return StayReservationDto.fromJson(response.data);
  }

  Future<void> cancelReservation(int id, int userId) async {
    await _dio.patch(
      '/stay/reservations/$id/cancel',
      queryParameters: {'userId': userId},
    );
  }
}
