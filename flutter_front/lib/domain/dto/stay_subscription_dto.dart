/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/dto/stay_subscription_dto.dart
 * 역할  : 구독 정보 데이터 모델 (Spring 응답 JSON → Dart 객체 변환)
 * 사용처 : SubscriptionService, StayAccommodationController
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_subscription_service.dart      : fromJson 호출
 * - stay_accommodation_controller.dart  : List<StaySubscriptionDto> 보관
 * - Spring: SubscriptionsController.java : GET /api/subscriptions/my/{userId}
 * ----------------------------------------------------------------------------------
 * [클래스 목록]
 * - StaySubscriptionDto : 구독 단건 (subscriptionId, userId, accommodationId, status 등)
 * ----------------------------------------------------------------------------------
 * [주요 getter]
 * - isActive : status == 'ACTIVE' 여부 (구독 활성 판단)
 * ----------------------------------------------------------------------------------
 * [status 값]
 * PENDING(대기) / ACTIVE(활성) / EXPIRED(만료) / CANCELLED(취소)
 * ==================================================================================
 */

class StaySubscriptionDto {
  final int subscriptionId;
  final int userId;
  final int accommodationId;
  final int durationMonths;
  final String startDate;
  final String endDate;
  final String status; // PENDING, ACTIVE, EXPIRED, CANCELLED

  StaySubscriptionDto({
    required this.subscriptionId,
    required this.userId,
    required this.accommodationId,
    required this.durationMonths,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory StaySubscriptionDto.fromJson(Map<String, dynamic> json) {
    return StaySubscriptionDto(
      subscriptionId: json['subscriptionId'],
      userId: json['userId'],
      accommodationId: json['accommodationId'],
      durationMonths: json['durationMonths'] ?? 0,
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? '',
    );
  }

  bool get isActive => status == 'ACTIVE';
}

// [날짜 검증 추가] 숙소별 사용 불가 기간 응답 — GET /api/subscriptions/accommodation/{id}
class SubscriptionDateRangeDto {
  final String startDate;
  final String endDate;
  final String status; // PENDING, ACTIVE

  SubscriptionDateRangeDto({
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory SubscriptionDateRangeDto.fromJson(Map<String, dynamic> json) {
    return SubscriptionDateRangeDto(
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
