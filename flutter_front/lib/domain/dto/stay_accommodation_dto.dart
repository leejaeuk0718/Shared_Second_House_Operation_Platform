/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/dto/stay_accommodation_dto.dart
 * 역할  : 숙소 및 가격 구간 데이터 모델 (Spring 응답 JSON → Dart 객체 변환)
 * 사용처 : StayAccommodationService, StayAccommodationController, 각 화면
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_accommodation_service.dart  : fromJson 호출
 * - stay_accommodation_controller.dart : List<StayAccommodationDto> 보관
 * - Spring: StayAccommodationResponseDto.java : 응답 구조 대응
 * ----------------------------------------------------------------------------------
 * [클래스 목록]
 * - StayAccommodationPriceDto : 할인 구간 (minMonths, maxMonths, discountRate)
 * - StayAccommodationDto      : 숙소 전체 정보 + 가격 구간 리스트
 * ----------------------------------------------------------------------------------
 * [주요 getter]
 * - firstImageUrl : 첫 번째 이미지 URL (상대경로면 baseUrl 자동 조합)
 * - imageUrls     : 전체 이미지 URL 리스트
 * - amenityList   : 쉼표 구분 amenities → List<String>
 * ==================================================================================
 */

import 'package:flutter_front/config/app_config.dart';

class StayAccommodationPriceDto {
  final int id;
  final int minMonths;
  final int? maxMonths;
  final double discountRate;

  StayAccommodationPriceDto({
    required this.id,
    required this.minMonths,
    this.maxMonths,
    required this.discountRate,
  });

  factory StayAccommodationPriceDto.fromJson(Map<String, dynamic> json) {
    return StayAccommodationPriceDto(
      id: json['id'],
      minMonths: json['minMonths'],
      maxMonths: json['maxMonths'],
      discountRate: (json['discountRate'] as num).toDouble(),
    );
  }
}

class StayAccommodationDto {
  final int id;
  final String name;
  final String address;
  final String description;
  final String? imageUrl;
  final String? amenities;
  final int monthlyPrice;
  final int? roomCount;
  final int? bathroomCount;
  final int? floorCount;
  final int? parkingCount;
  final double? landArea;
  final double? buildingArea;
  final double? latitude;
  final double? longitude;
  final String status;
  final List<StayAccommodationPriceDto> prices;

  StayAccommodationDto({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    this.imageUrl,
    this.amenities,
    required this.monthlyPrice,
    this.roomCount,
    this.bathroomCount,
    this.floorCount,
    this.parkingCount,
    this.landArea,
    this.buildingArea,
    this.latitude,
    this.longitude,
    required this.status,
    required this.prices,
  });

  factory StayAccommodationDto.fromJson(Map<String, dynamic> json) {
    return StayAccommodationDto(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      amenities: json['amenities'],
      monthlyPrice: json['monthlyPrice'] ?? 0,
      roomCount: json['roomCount'],
      bathroomCount: json['bathroomCount'],
      floorCount: json['floorCount'],
      parkingCount: json['parkingCount'],
      landArea: json['landArea'] != null ? (json['landArea'] as num).toDouble() : null,
      buildingArea: json['buildingArea'] != null ? (json['buildingArea'] as num).toDouble() : null,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      status: json['status'] ?? 'AVAILABLE',
      prices: (json['prices'] is List
          ? (json['prices'] as List<dynamic>)
          : <dynamic>[])
          .map((e) => StayAccommodationPriceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // 첫 번째 이미지 URL (쉼표 구분 목록에서, 상대경로면 baseUrl 붙임)
  String? get firstImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    final url = imageUrl!.split(',').first.trim();
    return _resolveUrl(url);
  }

  List<String> get imageUrls {
    if (imageUrl == null || imageUrl!.isEmpty) return [];
    return imageUrl!.split(',').map((e) => _resolveUrl(e.trim())).toList();
  }

  static String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${AppConfig.imageBaseUrl}$url';
  }

  List<String> get amenityList {
    if (amenities == null || amenities!.isEmpty) return [];
    return amenities!.split(',').map((e) => e.trim()).toList();
  }
}
