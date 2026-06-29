/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/controller/stay_subscription_controller.dart
 * 역할  : 내 구독 목록 상태 관리 (Provider)
 * 사용처 : StayMySubscriptionScreen
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_subscription_service.dart     : 구독 목록 API 호출
 * - stay_accommodation_service.dart    : 숙소 이름/주소 병렬 조회
 * - stay_subscription_dto.dart         : 구독 모델
 * - stay_accommodation_dto.dart        : 숙소 모델 (이름/주소용)
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - loadMySubscriptions(userId) : 구독 목록 + 숙소 정보 병렬 조회
 * ==================================================================================
 */

import 'package:flutter/foundation.dart';
import 'package:flutter_front/domain/dto/stay_accommodation_dto.dart';
import 'package:flutter_front/domain/dto/stay_subscription_dto.dart';
import 'package:flutter_front/domain/service/stay_accommodation_service.dart';
import 'package:flutter_front/domain/service/stay_subscription_service.dart';

class StaySubscriptionController extends ChangeNotifier {
  final SubscriptionService _service = SubscriptionService();
  final StayAccommodationService _accomService = StayAccommodationService();

  List<StaySubscriptionDto> subscriptions = [];
  final Map<int, StayAccommodationDto> accommodationCache = {};
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadMySubscriptions(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      subscriptions = await _service.getMySubscriptions(userId);

      // 숙소 이름/주소를 병렬로 조회
      final ids = subscriptions.map((s) => s.accommodationId).toSet();
      await Future.wait(ids.map((id) async {
        try {
          accommodationCache[id] = await _accomService.getAccommodation(id);
        } catch (_) {}
      }));
    } catch (_) {
      errorMessage = '구독 목록을 불러오지 못했습니다.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
