/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/dto/stay_story_dto.dart
 * 역할  : 숙소 스토리 데이터 모델 (Spring 응답 JSON → Dart 객체 변환)
 * 사용처 : StayStoryService, StayAccommodationController (상세 화면)
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_story_service.dart           : fromJson 호출
 * - stay_accommodation_controller.dart : List<StayStoryDto> 보관
 * - Spring: StayStoryController.java  : GET /api/stay/stories/{accommodationId}
 * ----------------------------------------------------------------------------------
 * [클래스 목록]
 * - StayStoryDto : 스토리 단건 (id, orderNum, title, content, imageUrl)
 * ==================================================================================
 */

class StayStoryDto {
  final int id;
  final int orderNum;
  final String title;
  final String content;
  final String? imageUrl;

  StayStoryDto({
    required this.id,
    required this.orderNum,
    required this.title,
    required this.content,
    this.imageUrl,
  });

  factory StayStoryDto.fromJson(Map<String, dynamic> json) {
    return StayStoryDto(
      id: json['id'],
      orderNum: json['orderNum'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}
