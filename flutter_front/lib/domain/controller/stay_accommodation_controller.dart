/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/controller/stay_accommodation_controller.dart
 * 역할  : 숙소 관련 상태 관리 (ChangeNotifier + Provider 패턴)
 * 사용처 : StayAccommodationListScreen, StayAccommodationDetailScreen, MainScreen
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_accommodation_service.dart  : API 호출
 * - stay_story_service.dart          : 스토리 API 호출 (상세 화면)
 * - stay_subscription_service.dart   : 구독 API 호출
 * - config/app_router.dart           : ChangeNotifierProvider 등록
 * ----------------------------------------------------------------------------------
 * [상태 목록]
 * - accommodations       : 전체 숙소 목록 (홈화면용)
 * - pagedAccommodations  : 무한 스크롤용 누적 목록 (목록화면용)
 * - currentPage / totalPages / keyword : 무한 스크롤 페이징 상태
 * - isLoadingPaged / isLoadingMore : 로딩 상태 구분
 * - selectedAccommodation / stories : 상세 화면 데이터
 * - mySubscriptions      : 내 구독 목록 (구독 상태 판단용)
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - loadAccommodationsAndFaqs()   : 홈화면 초기 로드 (전체 목록 + 구독 목록)
 * - loadAccommodationsPaged()     : 목록화면 무한 스크롤 (page=0이면 교체, 이상이면 append)
 * - loadAccommodationDetail()     : 상세화면 병렬 로드 (숙소 + 스토리 + 구독)
 * - subscriptionStatusFor(id)     : 특정 숙소 구독 상태 반환
 * - activeSubscriptionFor(id)     : ACTIVE 구독 단건 반환 (달력 날짜 제한용)
 * ==================================================================================
 */

import 'package:flutter/material.dart';
import 'package:flutter_front/domain/dto/stay_accommodation_dto.dart';
import 'package:flutter_front/domain/dto/stay_story_dto.dart';
import 'package:flutter_front/domain/dto/stay_subscription_dto.dart';
import 'package:flutter_front/domain/service/stay_accommodation_service.dart';
import 'package:flutter_front/domain/service/stay_story_service.dart';
import 'package:flutter_front/domain/service/stay_subscription_service.dart';

class StayAccommodationController extends ChangeNotifier {
  final StayAccommodationService _accommodationService = StayAccommodationService();
  final StayStoryService _storyService = StayStoryService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<StayAccommodationDto> accommodations = [];
  StayAccommodationDto? selectedAccommodation;
  List<StayStoryDto> stories = [];
  List<StaySubscriptionDto> mySubscriptions = [];

  // 목록 화면 전용 무한 스크롤 상태
  List<StayAccommodationDto> pagedAccommodations = [];
  int currentPage = 0;
  int totalPages = 0;
  String keyword = '';
  bool isLoadingPaged = false;
  bool isLoadingMore = false;

  bool get hasMore => currentPage < totalPages - 1;

  bool isLoadingList = false;
  bool isLoadingDetail = false;
  String? errorMessage;

  List<StayAccommodationDto> get mySubscribedAccommodations {
    final activeIds = mySubscriptions
        .where((s) => s.isActive)
        .map((s) => s.accommodationId)
        .toSet();
    return accommodations.where((a) => activeIds.contains(a.id)).toList();
  }

  /// 특정 숙소의 구독 상태 반환
  /// 반환값: 'none' | 'waiting' | 'active' | 'expired'
  String subscriptionStatusFor(int accommodationId) {
    final subs = mySubscriptions.where((s) => s.accommodationId == accommodationId).toList();
    if (subs.isEmpty) return 'none';
    if (subs.any((s) => s.status == 'ACTIVE')) return 'active';
    if (subs.any((s) => s.status == 'PENDING')) return 'waiting';
    if (subs.any((s) => s.status == 'EXPIRED')) return 'expired';
    return 'none';
  }

  /// 특정 숙소의 활성(ACTIVE) 구독 반환 (예약 달력 날짜 범위 제한용)
  StaySubscriptionDto? activeSubscriptionFor(int accommodationId) {
    return mySubscriptions
        .where((s) => s.accommodationId == accommodationId && s.status == 'ACTIVE')
        .firstOrNull;
  }

  // 숙소 목록 + 내 구독 목록 로드 (홈화면용)
  Future<void> loadAccommodationsAndFaqs({int? userId}) async {
    isLoadingList = true;
    errorMessage = null;
    notifyListeners();

    try {
      final futures = <Future>[
        _accommodationService.getAccommodations(),
        if (userId != null) _subscriptionService.getMySubscriptions(userId),
      ];
      final results = await Future.wait(futures);
      accommodations = results[0] as List<StayAccommodationDto>;
      if (userId != null) {
        mySubscriptions = results[1] as List<StaySubscriptionDto>;
        debugPrint('📋 [내 구독 목록] userId=$userId, 총 ${mySubscriptions.length}건');
        for (final s in mySubscriptions) {
          debugPrint('  └ id=${s.subscriptionId} | accommodationId=${s.accommodationId} | status=${s.status} | ${s.startDate}~${s.endDate}');
        }
        final activeOnly = mySubscriptions.where((s) => s.isActive).toList();
        debugPrint('🟢 [ACTIVE 구독] ${activeOnly.length}건 → accommodationIds: ${activeOnly.map((s) => s.accommodationId).toList()}');
      }
    } catch (e) {
      errorMessage = '데이터를 불러오지 못했습니다.';
      debugPrint('❌ [숙소 컨트롤러] $e');
    }

    isLoadingList = false;
    notifyListeners();
  }

  // 목록 화면 전용: 검색 + 무한 스크롤 로드
  // page=0 → 새 검색/초기화 (목록 교체), page>0 → 추가 로드 (목록 append)
  Future<void> loadAccommodationsPaged({String? newKeyword, int page = 0}) async {
    if (newKeyword != null) keyword = newKeyword;

    if (page == 0) {
      pagedAccommodations = [];
      isLoadingPaged = true;
    } else {
      if (isLoadingMore || !hasMore) return;
      isLoadingMore = true;
    }
    notifyListeners();

    try {
      final data = await _accommodationService.getAccommodationsPaged(
        keyword: keyword.isEmpty ? null : keyword,
        page: page,
      );
      final newItems = (data['content'] as List)
          .map((e) => StayAccommodationDto.fromJson(e as Map<String, dynamic>))
          .toList();
      currentPage = page;
      totalPages = data['totalPages'] as int;
      pagedAccommodations = [...pagedAccommodations, ...newItems];
    } catch (e) {
      debugPrint('❌ [숙소 무한 스크롤] $e');
    }

    isLoadingPaged = false;
    isLoadingMore = false;
    notifyListeners();
  }

  // 숙소 상세 + 스토리 + 내 구독 동시 로드 (상세 화면용)
  Future<void> loadAccommodationDetail(int id, int userId) async {
    isLoadingDetail = true;
    selectedAccommodation = null;
    stories = [];
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _accommodationService.getAccommodation(id),
        _storyService.getStories(id),
        _subscriptionService.getMySubscriptions(userId),
      ]);
      selectedAccommodation = results[0] as StayAccommodationDto;
      stories = results[1] as List<StayStoryDto>;
      mySubscriptions = results[2] as List<StaySubscriptionDto>;
    } catch (e) {
      errorMessage = '숙소 정보를 불러오지 못했습니다.';
      debugPrint('❌ [숙소 상세 컨트롤러] $e');
    }

    isLoadingDetail = false;
    notifyListeners();
  }
}
