import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // 크롬(커스텀탭)으로 상세 페이지 열기
import 'package:flutter_front/domain/controller/restaurant_controller.dart';
import 'package:flutter_front/domain/dto/place_dto.dart';

/// 🗺️ 주변 맛집 지도 화면
/// 숙소 좌표를 중심으로 RestaurantController(캐싱)에서 맛집을 읽어와 마커로 표시
class GuestRestaurantMapScreen extends StatefulWidget {
  const GuestRestaurantMapScreen({super.key});

  @override
  State<GuestRestaurantMapScreen> createState() =>
      _GuestRestaurantMapScreenState();
}

class _GuestRestaurantMapScreenState extends State<GuestRestaurantMapScreen> {
  // 🏠 숙소 좌표 고정 (테스트용 - 부산 해운대 인근, 지도 중심/숙소 마커용)
  static const double _houseLat = 35.1587;
  static const double _houseLng = 129.1604;
  static const LatLng _houseLatLng = LatLng(_houseLat, _houseLng);

  // 🏨 맛집을 읽어올 숙소 id (sh_stay_accommodation). 테스트용 고정값.
  static const int _accommodationId = 1;

  // 🎨 플랫폼 시그니처 테마 컬러
  static const Color primaryNavy = Color(0xFF23399D);

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // 맛집 로드 요청 (컨트롤러가 캐시 여부를 판단해 중복 호출 방지)
    // build 도중 notifyListeners 충돌을 피하려고 첫 프레임 이후에 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<RestaurantController>()
          .loadRestaurants(accommodationId: _accommodationId);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// 🍽️ 숙소 + 맛집 마커 묶음 생성
  Set<Marker> _buildMarkers(List<PlaceDto> places) {
    final markers = <Marker>{
      // 숙소 마커
      Marker(
        markerId: const MarkerId('house'),
        position: _houseLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '🏠 숙소', snippet: '세컨하우스'),
      ),
    };

    for (final p in places) {
      markers.add(
        Marker(
          markerId: MarkerId(p.id),
          position: LatLng(p.latitude, p.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: p.name,
            snippet: _buildSnippet(p),
            onTap: () => _openPlace(p), // 말풍선 탭 → 크롬 커스텀탭으로 상세
          ),
        ),
      );
    }
    return markers;
  }

  /// 🍽️ 말풍선 탭 시 상세 열기 (크롬 커스텀탭)
  /// Places API가 내려준 정식 장소 URL(googleMapsUri, place_id 포함)을 그대로 연다.
  /// 직접 좌표로 URL을 만들면 동명의 엉뚱한 가게가 잡히거나 지도만 떠서 사용하지 않는다.
  Future<void> _openPlace(PlaceDto p) async {
    final url = p.googleMapsUri;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상세 정보 주소가 없어요. 😢')),
      );
      return;
    }

    final uri = Uri.parse(url);

    // 크롬 커스텀탭으로 열기 (앱 위 오버레이, 시스템 뒤로가기로 지도 복귀)
    // 구글맵 앱으로 가로채여 열리는 걸 막기 위해 다른 외부 앱으로는 폴백하지 않는다.
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      launched = false;
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('크롬 브라우저가 필요해요. 크롬을 설치해 주세요. 🌐')),
      );
    }
  }

  /// 마커 말풍선 요약 (한 줄로 짧게 — 길면 기본 InfoWindow가 말줄임 처리됨)
  String _buildSnippet(PlaceDto p) {
    final parts = <String>[
      if (p.primaryType != null && p.primaryType!.isNotEmpty) p.primaryType!,
      if (_todayHours(p) != null) '🕐 ${_todayHours(p)}',
    ];
    return parts.isEmpty ? '탭하면 상세보기' : parts.join(' · ');
  }

  /// 오늘 요일 영업시간만 추출 (weekdayDescriptions의 "월요일: 오전 11:00~..." → "오전 11:00~...")
  String? _todayHours(PlaceDto p) {
    if (p.weekdayDescriptions.isEmpty) return null;
    const days = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final today = days[DateTime.now().weekday - 1]; // weekday: 1=월 ~ 7=일
    for (final d in p.weekdayDescriptions) {
      if (d.startsWith(today)) {
        final idx = d.indexOf(': '); // "월요일: " 접두어 제거
        return idx >= 0 ? d.substring(idx + 2) : d;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 구독 → 맛집/로딩 상태 변화 시 자동 리빌드
    final controller = context.watch<RestaurantController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '주변 맛집',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _houseLatLng,
              zoom: 15,
            ),
            markers: _buildMarkers(controller.places),
            myLocationButtonEnabled: false,
            onMapCreated: (c) => _mapController = c,
          ),
          // 로딩 인디케이터
          if (controller.isLoading)
            const Center(child: CircularProgressIndicator(color: primaryNavy)),
          // 에러 메시지
          if (controller.error != null && !controller.isLoading)
            Center(
              child: Text(
                controller.error!,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          // 🏠 숙소 위치로 되돌리는 버튼 (웹과 동일 UX)
          Positioned(
            left: 12,
            bottom: 12,
            child: _recenterButton(_houseLatLng),
          ),
        ],
      ),
    );
  }

  /// 지도 중심을 숙소 좌표로 되돌리는 흰색 버튼
  Widget _recenterButton(LatLng target) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(target, 15),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            '🏠 숙소 위치로',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }
}