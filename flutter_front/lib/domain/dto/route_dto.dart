// 🗺️ 이동경로 추적 관련 DTO
// 백엔드 /api/routes 의 RoutePointDTO / RouteSessionDTO 규격과 매칭

/// 좌표 1건
class RoutePointData {
  final double lat;
  final double lng;
  final DateTime? recordedAt;

  RoutePointData({required this.lat, required this.lng, this.recordedAt});

  /// 백엔드 전송용 JSON (recordedAt은 ISO-8601, Java LocalDateTime과 호환)
  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (recordedAt != null) 'recordedAt': recordedAt!.toIso8601String(),
      };

  factory RoutePointData.fromJson(Map<String, dynamic> json) => RoutePointData(
        lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
        recordedAt: json['recordedAt'] != null
            ? DateTime.tryParse(json['recordedAt'].toString())
            : null,
      );
}

/// 추적 세션 1건 (이력 표시용)
class RouteSessionData {
  final int sessionId;
  final int userId;
  final DateTime? startedAt;
  final DateTime? endedAt;

  RouteSessionData({
    required this.sessionId,
    required this.userId,
    this.startedAt,
    this.endedAt,
  });

  factory RouteSessionData.fromJson(Map<String, dynamic> json) => RouteSessionData(
        sessionId: (json['sessionId'] as num?)?.toInt() ?? 0,
        userId: (json['userId'] as num?)?.toInt() ?? 0,
        startedAt: json['startedAt'] != null
            ? DateTime.tryParse(json['startedAt'].toString())
            : null,
        endedAt: json['endedAt'] != null
            ? DateTime.tryParse(json['endedAt'].toString())
            : null,
      );
}