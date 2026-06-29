/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/view/stay_accommodation_detail_screen.dart
 * 역할  : 숙소 상세 화면 — 이미지 슬라이더, 가격 계산기, 스토리, 지도, 바텀바 CTA
 * 사용처 : MainScreen, StayAccommodationListScreen 에서 카드 탭 시 push
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_accommodation_controller.dart  : 숙소 상세 + 구독 목록 로드 (Provider)
 * - stay_reservation_calendar_screen.dart : "예약하기" 탭 시 push
 * - stay_subscription_apply_screen.dart   : "구독 신청" 탭 시 push
 * - stay_constants.dart                   : kMonthOptionValues, monthOptionLabel
 * - price_calculator.dart                 : 팀당 월세 계산 유틸
 * - Spring: StayAccommodationController   : GET /api/stay/accommodations/{id}
 * - Spring: SubscriptionsUserController   : GET /api/subscriptions/my/{userId}
 * ----------------------------------------------------------------------------------
 * [바텀바 CTA — 구독 상태 4분기]
 * ┌─────────────────┬─────────────────────────────────────────────────────────────┐
 * │ subscriptionStatus │ 버튼                                                      │
 * ├─────────────────┼─────────────────────────────────────────────────────────────┤
 * │ none            │ 구독 신청 → StaySubscriptionApplyScreen push                │
 * │ waiting         │ 승인 대기 중 (비활성)                                        │
 * │ active          │ 예약하기 → StayReservationCalendarScreen push               │
 * │ expired         │ 재구독하기 → StaySubscriptionApplyScreen push               │
 * └─────────────────┴─────────────────────────────────────────────────────────────┘
 * ----------------------------------------------------------------------------------
 * [주의사항]
 * ✅ AuthProvider.userId로 실제 로그인 사용자 연동
 * ==================================================================================
 */

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Factory
import 'package:flutter/gestures.dart'; // EagerGestureRecognizer (스크롤 뷰 안에서 지도 드래그 허용)
import 'package:flutter_front/domain/controller/restaurant_controller.dart';
import 'package:flutter_front/domain/dto/place_dto.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_front/common/constants/app_colors.dart';
import 'package:flutter_front/common/constants/stay_constants.dart';
import 'package:flutter_front/common/widget/bottom_sheet_selector.dart';
import 'package:flutter_front/config/app_config.dart';
import 'package:flutter_front/features/auth/provider/auth_provider.dart';
import 'package:flutter_front/domain/controller/stay_accommodation_controller.dart';
import 'package:flutter_front/domain/dto/stay_accommodation_dto.dart';
import 'package:flutter_front/domain/dto/stay_story_dto.dart';
import 'package:flutter_front/domain/view/stay_reservation_calendar_screen.dart';
import 'package:flutter_front/domain/view/stay_subscription_apply_screen.dart';
import 'package:flutter_front/util/price_calculator.dart';
import 'package:url_launcher/url_launcher.dart';

class StayAccommodationDetailScreen extends StatefulWidget {
  final int accommodationId;
  const StayAccommodationDetailScreen({super.key, required this.accommodationId});

  @override
  State<StayAccommodationDetailScreen> createState() => _StayAccommodationDetailScreenState();
}

class _StayAccommodationDetailScreenState extends State<StayAccommodationDetailScreen> {

  int _currentImageIndex = 0;
  int _months = 1;
  int _teams = 1;
  final ScrollController _scrollController = ScrollController();
  GoogleMapController? _mapController;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context
          .read<StayAccommodationController>()
          .loadAccommodationDetail(widget.accommodationId, context.read<AuthProvider>().userId!);
      if (!mounted) return;
      final accommodation =
          context.read<StayAccommodationController>().selectedAccommodation;
      if (accommodation != null) {
        // 내 DB(sh_restaurant)에서 이 숙소 부근 맛집을 읽어온다 (구글 동기화는 서버 스케줄러 담당)
        context
            .read<RestaurantController>()
            .loadRestaurants(accommodationId: widget.accommodationId);
      }
    });

    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 220;
      if (shouldShow != _showTitle) setState(() => _showTitle = shouldShow);
    });
  }


  @override
  void dispose() {
    _scrollController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<StayAccommodationController>();
    final controller = context.watch<RestaurantController>();

    if (ctrl.isLoadingDetail) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (ctrl.selectedAccommodation == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primary, iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: Text(ctrl.errorMessage ?? '숙소 정보를 불러올 수 없습니다.')),
      );
    }

    final item = ctrl.selectedAccommodation!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(item),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfo(item),
                const Divider(height: 1),
                _buildPriceTable(item),
                const Divider(height: 1),
                _buildAmenities(item),
                const Divider(height: 1),
                _buildMapPlaceholder(item, controller),
                const Divider(height: 1),
                _buildStories(ctrl.stories),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(item),
    );
  }

  Widget _buildSliverAppBar(StayAccommodationDto item) {
    final images = item.imageUrls;
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      iconTheme: IconThemeData(color: _showTitle ? Colors.white : AppColors.primary),
      title: AnimatedOpacity(
        opacity: _showTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          item.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            images.isNotEmpty
                ? PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (context, err, _) => Container(color: Colors.grey.shade300),
                    ),
                  )
                : Container(color: Colors.grey.shade300, child: const Icon(Icons.home_outlined, size: 64, color: Colors.grey)),
            if (images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentImageIndex ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _currentImageIndex ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(StayAccommodationDto item) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: item.status == 'AVAILABLE' ? AppColors.primaryLight : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status == 'AVAILABLE' ? '예약가능' : '점검중',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.status == 'AVAILABLE' ? const Color(0xFF00A878) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(item.description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6)),
          const SizedBox(height: 16),
          // 스펙 그리드
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (item.roomCount != null) _specItem(Icons.bed_outlined, '방 ${item.roomCount}개'),
              if (item.bathroomCount != null) _specItem(Icons.bathtub_outlined, '화장실 ${item.bathroomCount}개'),
              if (item.floorCount != null) _specItem(Icons.layers_outlined, '${item.floorCount}층'),
              if (item.parkingCount != null) _specItem(Icons.local_parking, '주차 ${item.parkingCount}대'),
              if (item.buildingArea != null) _specItem(Icons.square_foot, '건물 ${item.buildingArea}평'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  Widget _buildPriceTable(StayAccommodationDto item) {
    final teamPrice = PriceCalculator.calculateTeamPrice(
      monthlyPrice: item.monthlyPrice,
      months: _months,
      teams: _teams,
      prices: item.prices,
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('가격 안내', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // 계산기 컨트롤
          Row(
            children: [
              Expanded(
                child: BottomSheetSelector(
                  label: '팀수',
                  value: _teams,
                  options: List.generate(12, (i) => i + 1),
                  displayText: (v) => '$v팀',
                  onSelected: (v) => setState(() => _teams = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BottomSheetSelector(
                  label: '개월수',
                  value: _months,
                  options: kMonthOptionValues,
                  displayText: monthOptionLabel,
                  onSelected: (v) => setState(() => _months = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 결과 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('팀당 월세', style: TextStyle(color: Colors.black54, fontSize: 14)),
                    Text(
                      '${_fmt(teamPrice)}원 / 월',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 할인율 구간표
          if (item.prices.isNotEmpty) ...[
            const Text('구간별 할인율', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 8),
            ...item.prices.map((p) => _priceRow(p, _months)),
          ],
        ],
      ),
    );
  }


  Widget _priceRow(StayAccommodationPriceDto p, int selectedMonths) {
    final isActive = selectedMonths >= p.minMonths && (p.maxMonths == null || selectedMonths < p.maxMonths!);
    final label = p.maxMonths != null ? '${p.minMonths}~${p.maxMonths! - 1}개월' : '${p.minMonths}개월 이상';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isActive ? AppColors.primary : Colors.black54, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          Text(
            p.discountRate > 0 ? '${(p.discountRate * 100).toInt()}% 할인' : '기본가',
            style: TextStyle(fontSize: 13, color: isActive ? Colors.red : Colors.black38, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities(StayAccommodationDto item) {
    if (item.amenityList.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('구성 용품', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.amenityList
                .map((a) => Chip(
                      label: Text(a, style: const TextStyle(fontSize: 13)),
                      backgroundColor: const Color(0xFFF0F3FF),
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(StayAccommodationDto item, RestaurantController controller) {
    final houseLatLng = (item.latitude != null && item.longitude != null)
        ? LatLng(item.latitude!, item.longitude!)
        : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('위치', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.black45),
              const SizedBox(width: 4),
              // 주소가 길어 공간이 모자라면 흐르는(마퀴) 효과
              Expanded(
                child: _MarqueeText(
                  item.address,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              // 🏠 숙소 위치로 버튼 (주소 오른쪽, 좌표 있을 때만)
              if (houseLatLng != null) ...[
                const SizedBox(width: 8),
                _recenterButton(houseLatLng),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (houseLatLng == null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('지도 정보가 없습니다.', style: TextStyle(color: Colors.black54)),
              ),
            )
          else
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: houseLatLng,
                        zoom: 15,
                      ),
                      markers: _buildMarkers(controller.places, houseLatLng),
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (c) => _mapController = c,
                      // CustomScrollView 안에 있어 부모가 드래그를 가로채므로,
                      // 지도가 제스처를 우선 차지하도록 EagerGestureRecognizer 등록
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                    ),
                    if (controller.isLoading)
                      Container(
                        color: Colors.white.withValues(alpha: 0.7),
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                    if (controller.error != null && !controller.isLoading)
                      Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: Text(
                            controller.error!,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '🏠 숙소 위치로',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStories(List<StayStoryDto> stories) {
    if (stories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('숙소 스토리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...stories.map((s) => _storyCard(s)),
        ],
      ),
    );
  }

  Widget _storyCard(StayStoryDto story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (story.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                story.imageUrl!.startsWith('http') ? story.imageUrl! : '${AppConfig.imageBaseUrl}${story.imageUrl}',
                // 1. 고정 높이(height) 제거하여 Auto 상태로 전환
                // height: 180,
                width: double.infinity,
                fit: BoxFit.fitWidth, // 2. 가로에 맞추고 세로는 원본 비율 유지
                // fit: BoxFit.cover,
                errorBuilder: (context, err, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Story ${story.orderNum}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(story.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(story.content, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBottomBar(StayAccommodationDto item) {
    final ctrl = context.read<StayAccommodationController>();
    final teamPrice = PriceCalculator.calculateTeamPrice(
      monthlyPrice: item.monthlyPrice,
      months: _months,
      teams: _teams,
      prices: item.prices,
    );
    final isAvailable = item.status == 'AVAILABLE';
    final subStatus = ctrl.subscriptionStatusFor(item.id);

    Widget actionButton;
    if (!isAvailable) {
      actionButton = _ctaButton(label: '점검중', onPressed: null);
    } else {
      switch (subStatus) {
        case 'waiting':
          actionButton = _ctaButton(label: '승인 대기 중', onPressed: null);
        case 'active':
          final activeSub = ctrl.activeSubscriptionFor(item.id);
          actionButton = _ctaButton(
            label: '예약하기',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StayReservationCalendarScreen(
                  accommodationId: item.id,
                  accommodationName: item.name,
                  subscriptionStartDate: activeSub != null ? _parseDate(activeSub.startDate) : null,
                  subscriptionEndDate: activeSub != null ? _parseDate(activeSub.endDate) : null,
                ),
              ),
            ),
          );
        case 'expired':
          actionButton = _ctaButton(
            label: '재구독하기',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StaySubscriptionApplyScreen(accommodation: item)),
            ),
          );
        default: // 'none'
          actionButton = _ctaButton(
            label: '구독 신청',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StaySubscriptionApplyScreen(accommodation: item)),
            ),
          );
      }
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('월 ${_fmt(teamPrice)}원', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Text('팀당 · ${monthOptionLabel(_months)} · $_teams팀 기준', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(child: actionButton),
          ],
        ),
      ),
    );
  }

  Widget _ctaButton({required String label, required VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
      ),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  String _fmt(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  /// 🍽️ 숙소 + 맛집 마커 묶음 생성
  Set<Marker> _buildMarkers(List<PlaceDto> places, LatLng houseLatLng) {
    final markers = <Marker>{
      // 숙소 마커
      Marker(
        markerId: const MarkerId('house'),
        position: houseLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '🏠 숙소', snippet: '세컨하우스'),
      ),
    };

    for (final p in places) {
      final rank = p.popularityRank;
      final hue = (rank == null || rank < 10)
        ? BitmapDescriptor.hueRed   // 상위
        : BitmapDescriptor.hueOrange;  // 나머지
      markers.add(
         Marker(
          markerId: MarkerId(p.id),
          position: LatLng(p.latitude, p.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            hue
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

}

/// 텍스트가 가로 공간을 넘치면 좌우로 흐르게(마퀴) 보여주는 위젯. 넘치지 않으면 그냥 표시.
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  const _MarqueeText(this.text, {this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  final ScrollController _controller = ScrollController();
  bool _looping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startIfOverflow());
  }

  Future<void> _startIfOverflow() async {
    if (_looping || !_controller.hasClients) return;
    if (_controller.position.maxScrollExtent <= 0) return; // 안 넘치면 스크롤 안 함
    _looping = true;
    while (mounted && _controller.hasClients) {
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) break;
      final ms = (max * 25).toInt() + 1; // 거리에 비례한 속도
      await _controller.animateTo(max,
          duration: Duration(milliseconds: ms), curve: Curves.linear);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted || !_controller.hasClients) break;
      await _controller.animateTo(0,
          duration: Duration(milliseconds: ms), curve: Curves.linear);
      await Future.delayed(const Duration(milliseconds: 700));
    }
    _looping = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, maxLines: 1, style: widget.style),
    );
  }
}
