/// 🍽️ 주변 맛집 1건 DTO
/// 백엔드 GET /api/places/restaurants 의 PlaceDTO 규격과 1:1 매칭
class PlaceDto {
  final String id;                       // Places 고유 id (place id)
  final String name;                     // 가게 이름
  final String? primaryType;             // 대표 업종 코드 (예: japanese_restaurant)
  final String? phoneNumber;             // 전화번호 (없으면 null)
  final double latitude;                 // 위도
  final double longitude;                // 경도
  final String googleMapsUri;            // 구글지도 장소 페이지 URL
  final List<String> weekdayDescriptions; // 요일별 영업시간 (없으면 빈 리스트)
  final int? accommodationId;            // 어느 숙소 부근인지 (FK)
  final int? popularityRank;             // 인기도 순위 (0이 가장 인기, 없으면 null)

  PlaceDto({
    required this.id,
    required this.name,
    this.primaryType,
    this.phoneNumber,
    required this.latitude,
    required this.longitude,
    this.googleMapsUri = '',
    this.weekdayDescriptions = const [],
    this.accommodationId,
    this.popularityRank,
  });

  factory PlaceDto.fromJson(Map<String, dynamic> json) {
    return PlaceDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '이름 없음',
      primaryType: json['primaryType']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      googleMapsUri: json['googleMapsUri']?.toString() ?? '',
      weekdayDescriptions: (json['weekdayDescriptions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      accommodationId: (json['accommodationId'] as num?)?.toInt(),
      popularityRank: (json['popularityRank'] as num?)?.toInt(),
    );
  }
}