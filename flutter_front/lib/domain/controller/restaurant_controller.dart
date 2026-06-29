import 'package:flutter/foundation.dart';
import 'package:flutter_front/domain/dto/place_dto.dart';
import 'package:flutter_front/domain/service/places_service.dart';

/// 🍽️ 맛집 상태 관리 컨트롤러 (ChangeNotifier)
/// 받아온 맛집 목록을 캐싱해, 화면 재진입 시 백엔드를 다시 부르지 않는다.
class RestaurantController extends ChangeNotifier {
  final PlacesService _placesService = PlacesService();

  List<PlaceDto> _places = [];
  bool _isLoading = false;
  int? _loadedAccommodationId; // 마지막으로 받아온 숙소 (캐시 키)
  String? _error;

  List<PlaceDto> get places => _places;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 숙소 부근 맛집 목록 로드 (내 DB 조회). 같은 숙소를 이미 받아왔으면 캐시 재사용.
  Future<void> loadRestaurants({
    required int accommodationId,
    bool forceRefresh = false,
  }) async {
    // 같은 숙소 재진입 시에만 캐시 재사용
    if (!forceRefresh && _loadedAccommodationId == accommodationId) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _places =
          await _placesService.savedRestaurants(accommodationId: accommodationId);
      _loadedAccommodationId = accommodationId;
    } catch (e) {
      _error = '맛집 정보를 가져오지 못했어요. 😢';
      debugPrint('🔴 [맛집 컨트롤러] 로드 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}