/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/service/stay_subscription_service.dart
 * 역할  : 구독 신청 / 조회 API 통신 레이어
 * 사용처 : StayAccommodationController, StaySubscriptionApplyScreen
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_accommodation_controller.dart   : getMySubscriptions 호출
 * - stay_subscription_apply_screen.dart  : applySubscription 호출
 * - Spring: SubscriptionsController.java : /subscriptions, /waiting
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - applySubscription()      : 구독 신청 POST /waiting/apply/{leaderId}
 * - getMySubscriptions(id)   : 내 구독 목록 GET /subscriptions/my/{userId}
 * - getMyInvitations(id)     : 내 초대 목록 GET /waiting/my/{userId}
 * ==================================================================================
 */

import 'package:dio/dio.dart';
import 'package:flutter_front/core/api/dio_client.dart';
import 'package:flutter_front/domain/dto/stay_subscription_dto.dart';

class SubscriptionService {
  Dio get _dio => DioClient.instance.dio;

  /// 구독 신청 - POST /waiting/apply/{leaderId}
  /// body: { accommodationId, durationMonths, memberIdentifiers, startDate }
  Future<void> applySubscription({
    required int leaderId,
    required int accommodationId,
    required int durationMonths,
    required List<String> memberIdentifiers,
    required String startDate, // [날짜 검증 추가] 희망 구독 시작일 (YYYY-MM-DD)
  }) async {
    await _dio.post(
      '/waiting/apply/$leaderId',
      data: {
        'accommodationId': accommodationId,
        'durationMonths': durationMonths,
        'memberIdentifiers': memberIdentifiers,
        'startDate': startDate, // [날짜 검증 추가]
      },
    );
  }

  // [날짜 검증 추가] 숙소별 사용 불가 기간 조회 - GET /subscriptions/accommodation/{accommodationId}
  Future<List<SubscriptionDateRangeDto>> getSubscriptionBlockedPeriods(int accommodationId) async {
    final response = await _dio.get('/subscriptions/accommodation/$accommodationId');
    if (response.data is! List) return [];
    return (response.data as List)
        .map((e) => SubscriptionDateRangeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 내 구독 목록 조회 - GET /subscriptions/my/{userId}
  Future<List<StaySubscriptionDto>> getMySubscriptions(int userId) async {
    final response = await _dio.get('/subscriptions/my/$userId');
    if (response.data is! List) return [];
    return (response.data as List)
        .map((e) => StaySubscriptionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 내 초대 목록 조회 - GET /waiting/my/{userId}
  Future<List<dynamic>> getMyInvitations(int userId) async {
    final response = await _dio.get('/waiting/my/$userId');
    return response.data as List;
  }
}
