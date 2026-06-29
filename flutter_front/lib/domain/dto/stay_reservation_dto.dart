/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/dto/stay_reservation_dto.dart
 * 역할  : 숙소 예약 요청/응답 데이터 모델
 * 사용처 : StayReservationService, StayReservationController
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_reservation_service.dart     : fromJson / toJson 호출
 * - stay_reservation_controller.dart  : List<StayReservationDto> 보관
 * - Spring: StayReservationController.java : 응답 구조 대응
 * ----------------------------------------------------------------------------------
 * [클래스 목록]
 * - StayReservationRequestDto : 예약 생성 요청 (accommodationId, userId, startDate, endDate)
 * - StayReservationDto        : 예약 응답 (id, 숙소정보, 날짜, status)
 * ----------------------------------------------------------------------------------
 * [주요 getter]
 * - isCancelled : status == 'CANCELLED' 여부
 * ==================================================================================
 */

class StayReservationRequestDto {
  final int accommodationId;
  final int userId;
  final String startDate; // yyyy-MM-dd
  final String endDate;   // yyyy-MM-dd

  StayReservationRequestDto({
    required this.accommodationId,
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() => {
    'accommodationId': accommodationId,
    'userId': userId,
    'startDate': startDate,
    'endDate': endDate,
  };
}

class StayReservationDto {
  final int id;
  final int accommodationId;
  final String accommodationName;
  final String accommodationAddress;
  final String startDate;
  final String endDate;
  final String status; // CONFIRMED / CANCELLED

  StayReservationDto({
    required this.id,
    required this.accommodationId,
    required this.accommodationName,
    required this.accommodationAddress,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory StayReservationDto.fromJson(Map<String, dynamic> json) {
    return StayReservationDto(
      id: json['id'],
      accommodationId: json['accommodationId'],
      accommodationName: json['accommodationName'] ?? '',
      accommodationAddress: json['accommodationAddress'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? 'CONFIRMED',
    );
  }

  bool get isCancelled => status == 'CANCELLED';
}
