/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/view/main_screen.dart
 * 역할  : 앱 메인 화면 — 홈 탭 / 내 예약 탭 / AI 챗봇 탭 / 마이페이지 탭을 IndexedStack으로 관리
 * 사용처 : app_router.dart → '/' 루트
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_accommodation_controller.dart  : 숙소 목록 + 구독 목록 (Provider)
 * - stay_accommodation_detail_screen.dart : 숙소 카드 탭 시 이동
 * - stay_reservation_calendar_screen.dart : 구독 카드 "예약하기" 탭 시 이동
 * - stay_my_reservation_screen.dart       : BottomNavigationBar [내 예약] 탭
 * - guest_chat_bot_screen.dart            : BottomNavigationBar [AI 챗봇] 탭
 * - mypage_screen.dart                    : BottomNavigationBar [마이페이지] 탭
 * ----------------------------------------------------------------------------------
 * [홈 탭 구성]
 * ① 내 구독 숙소 섹션
 *    - ACTIVE 구독만 표시 (PENDING·EXPIRED·CANCELLED 숨김)
 *    - ACTIVE 없으면 섹션 전체 숨김
 *    - PENDING 건수는 "⏳ 승인 대기 중 N건" 텍스트로만 안내
 *    - 1개 → 100% 너비 카드 / 복수 → 가로 슬라이드
 *    - 예약하기 버튼에 subscriptionStartDate, subscriptionEndDate 전달 (달력 범위 제한용)
 * ② 우리가 머물 집 섹션 — 전체 숙소 가로 슬라이드 (최대 5개)
 * ----------------------------------------------------------------------------------
 * [주의사항]
 * ✅ AuthProvider.userId로 실제 로그인 사용자 연동
 * ⚠️ DevScreenLinks 위젯은 개발 완료 후 삭제 예정
 * ==================================================================================
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:flutter_front/common/constants/app_colors.dart';
import 'package:flutter_front/features/auth/provider/auth_provider.dart';
import 'package:flutter_front/domain/controller/chat_bot_controller.dart';
import 'package:flutter_front/domain/controller/route_controller.dart';
import 'package:flutter_front/domain/controller/stay_accommodation_controller.dart';
import 'package:flutter_front/domain/controller/stay_reservation_controller.dart';
import 'package:flutter_front/domain/dto/stay_accommodation_dto.dart';
import 'package:flutter_front/domain/dto/stay_reservation_dto.dart';
import 'package:flutter_front/domain/view/stay_accommodation_detail_screen.dart';
import 'package:flutter_front/domain/view/stay_accommodation_list_screen.dart';
import 'package:flutter_front/domain/view/stay_reservation_calendar_screen.dart';
import 'package:flutter_front/domain/view/stay_my_reservation_screen.dart';
import 'package:flutter_front/domain/view/guest_chat_bot_screen.dart';
import 'package:flutter_front/features/mypage/screen/mypage_screen.dart'; // 추가
// TODO: [개발 완료 시 삭제]
import 'package:flutter_front/domain/view/dev_screen_links.dart';

import 'delivery_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _arrivalMonitorStarted = false; // 도착 감지 중복 시작 방지

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId!;
      context.read<StayAccommodationController>().loadAccommodationsAndFaqs(userId: userId);
      // 이동경로 버튼 활성화 판단(예약 기간)을 위해 내 예약도 로드
      context.read<StayReservationController>().loadMyReservations(userId);
      // 로그인 직후에만 새로 생성되는 화면이므로, 여기서 챗봇 대화를 초기화해
      // 이전 사용자(로그아웃 전)의 대화가 남지 않게 한다.
      context.read<ChatBotController>().clear();
    });
  }

  /// 현재 날짜가 기간 내(취소 아님)인 예약 목록
  List<StayReservationDto> _activeReservations(StayReservationController resCtrl) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return resCtrl.reservations.where((r) {
      if (r.isCancelled) return false;
      final s = DateTime.tryParse(r.startDate);
      final e = DateTime.tryParse(r.endDate);
      if (s == null || e == null) return false;
      // 시작일 ~ 종료일(당일 포함)
      return !today.isBefore(s) && !today.isAfter(e);
    }).toList();
  }

  /// 활성 예약 숙소의 좌표 — 예약의 accommodationId로 숙소 목록에서 좌표를 찾는다.
  LatLng? _activeReservationCoord(
      StayAccommodationController accomCtrl, StayReservationController resCtrl) {
    for (final r in _activeReservations(resCtrl)) {
      for (final a in accomCtrl.accommodations) {
        if (a.id == r.accommodationId &&
            a.latitude != null &&
            a.longitude != null) {
          return LatLng(a.latitude!, a.longitude!);
        }
      }
    }
    return null;
  }

  /// 활성 예약 숙소 좌표가 준비되면 근접 감지를 시작한다.
  /// (예약 기간 중 + 그 숙소 50m 이내에 들어와야 '이동경로 보기' 버튼이 활성화됨)
  void _maybeStartProximityMonitor(LatLng? coord) {
    if (_arrivalMonitorStarted || coord == null) return;
    _arrivalMonitorStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RouteController>().startProximityMonitoring(coord);
    });
  }

  /// 이동경로 화면 진입 — 누른 시점에 예약이 취소되진 않았는지 최신 상태로 재확인
  Future<void> _openRoute(BuildContext context) async {
    final resCtrl = context.read<StayReservationController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 캐시가 아닌 최신 예약 상태로 다시 조회 (다른 화면/웹에서 취소됐을 수 있음)
    await resCtrl.loadMyReservations(context.read<AuthProvider>().userId!);
    if (!mounted) return;

    if (_activeReservations(resCtrl).isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('예약이 취소되었거나 예약 기간이 아니에요. 이동경로를 볼 수 없어요.'),
        ),
      );
      return; // 재조회로 reservations가 갱신되며 버튼도 비활성화됨
    }
    navigator.pushNamed('/route');
  }

  /// '내 이동경로 보기' 진입 카드
  /// 예약 기간 중 + 그 예약 숙소 50m 이내일 때만 활성화
  Widget _buildRouteEntry(BuildContext context) {
    final near = context.watch<RouteController>().isNearAccommodation;
    final resCtrl = context.watch<StayReservationController>();
    final hasActiveReservation = _activeReservations(resCtrl).isNotEmpty;
    final enabled = hasActiveReservation && near;

    // 비활성 사유 안내 (예약 기간 우선, 그다음 거리)
    final String hint = !hasActiveReservation
        ? '예약 기간 중에만 이용할 수 있어요'
        : '예약 숙소 50m 이내에서 활성화돼요';

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: InkWell(
        onTap: enabled ? () => _openRoute(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: enabled ? AppColors.primaryLight : AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? AppColors.primary : AppColors.textHint,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.route,
                  color: enabled ? AppColors.primary : AppColors.textHint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('내 이동경로 보기',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: enabled
                                ? AppColors.textPrimary
                                : AppColors.textHint)),
                    if (!enabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(hint,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textHint)),
                      ),
                  ],
                ),
              ),
              Icon(enabled ? Icons.chevron_right : Icons.lock_outline,
                  size: enabled ? 24 : 18,
                  color: enabled ? AppColors.primary : AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  /// 로그아웃 확인 후 처리 — AuthProvider.logout()이 상태를 unauthenticated로 바꾸면
  /// AuthGate가 자동으로 로그인 화면으로 전환한다(별도 화면 이동 코드 불필요).
  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('로그아웃',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  /// 하단 탭 선택 — 홈 탭을 누르면 예약을 최신으로 다시 불러온다.
  /// (앱이 켜진 채로 두면 initState가 다시 안 돌아 새로고침이 안 되는 문제 해결)
  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      context.read<StayReservationController>().loadMyReservations(context.read<AuthProvider>().userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<StayAccommodationController>();
    final resCtrl = context.watch<StayReservationController>();
    // 활성 예약 숙소 좌표가 준비되면 근접 감지 시작
    _maybeStartProximityMonitor(_activeReservationCoord(ctrl, resCtrl));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScaffold(ctrl),
          // const GuestChatBotScreen(),
          const DeliveryScreen(),
          const MyPageScreen(), // 추가
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            activeIcon: Icon(Icons.delivery_dining),
            label: '배달',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.person_outline),
          //   activeIcon: Icon(Icons.person),
          //   label: '내 정보',
          // ),
          BottomNavigationBarItem( // 추가
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }

  // TODO: 내 정보 담당 멤버가 이 메서드를 자신의 화면으로 교체
  // Widget _buildMyPageScaffold() => Scaffold(
  //   backgroundColor: AppColors.background,
  //   appBar: AppBar(
  //     title: const Text('내 정보', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
  //     centerTitle: true,
  //     backgroundColor: AppColors.primary,
  //     elevation: 0,
  //     automaticallyImplyLeading: false,
  //   ),
  //   body: const Center(
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(Icons.person_outline, size: 56, color: AppColors.textHint),
  //         SizedBox(height: 16),
  //         Text('마이페이지 준비 중', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
  //       ],
  //     ),
  //   ),
  // );

  // TODO: 배달 팀원이 이 메서드를 자신의 화면으로 교체
  // // Widget _buildDeliveryScaffold() => Scaffold(
  //   backgroundColor: AppColors.background,
  //   appBar: AppBar(
  //     title: const Text('배달', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
  //     centerTitle: true,
  //     backgroundColor: AppColors.primary,
  //     elevation: 0,
  //     automaticallyImplyLeading: false,
  //   ),
  //   body: const Center(
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(Icons.delivery_dining, size: 56, color: AppColors.textHint),
  //         SizedBox(height: 16),
  //         Text('배달 서비스 준비 중', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
  //       ],
  //     ),
  //   ),
  // );

  Widget _buildHomeScaffold(StayAccommodationController ctrl) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '세컨하우스',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: '로그아웃',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: ctrl.isLoadingList
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ctrl.errorMessage != null
          ? Center(child: Text(ctrl.errorMessage!, style: const TextStyle(color: AppColors.danger)))
          : _buildBody(ctrl),
    );
  }

  Widget _buildBody(StayAccommodationController ctrl) {
    final accommodations = ctrl.accommodations.take(5).toList();
    final subscribedAccommodations = ctrl.mySubscribedAccommodations;
    final pendingCount = ctrl.mySubscriptions.where((s) => s.status == 'PENDING').length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // 🗺️ 내 이동경로 보기 (숙소 50m 이내일 때만 활성화)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildRouteEntry(context),
          ),
          const SizedBox(height: 20),

          // 내 구독 숙소 섹션 (ACTIVE만 표시)
          if (subscribedAccommodations.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('내 구독 숙소', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/my/subscriptions'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      children: [
                        Text('전체보기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // const SizedBox(height: 12),
            if (pendingCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    const Text('⏳', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      '승인 대기 중 $pendingCount건',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (subscribedAccommodations.length == 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSubscribedCard(ctrl, subscribedAccommodations.first, fullWidth: true),
              )
            else
              SizedBox(
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: subscribedAccommodations.length,
                  itemBuilder: (_, index) => _buildSubscribedCard(ctrl, subscribedAccommodations[index]),
                ),
              ),

            const SizedBox(height: 28),
          ],

          // 숙소 목록 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('우리가 머물 집', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StayAccommodationListScreen())),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    children: [
                      Text('전체보기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: accommodations.length,
              itemBuilder: (_, index) => _buildAccommodationCard(accommodations[index]),
            ),
          ),
          const SizedBox(height: 32),

          // TODO: [개발 완료 시 삭제] 팀원 화면 링크
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('개발용 화면 링크', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 12),
          const DevScreenLinks(),
        ],
      ),
    );
  }

  Widget _buildSubscribedCard(StayAccommodationController ctrl, StayAccommodationDto item, {bool fullWidth = false}) {
    final activeSub = ctrl.activeSubscriptionFor(item.id);
    final subStart = activeSub != null ? _parseDate(activeSub.startDate) : null;
    final subEnd = activeSub != null ? _parseDate(activeSub.endDate) : null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StayAccommodationDetailScreen(accommodationId: item.id))),
      child: Container(
        width: fullWidth ? double.infinity : 220,
        margin: fullWidth ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: item.firstImageUrl != null
                  ? Image.network(item.firstImageUrl!, height: fullWidth ? 180 : 130, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _imagePlaceholder(height: fullWidth ? 180 : 130))
                  : _imagePlaceholder(height: fullWidth ? 180 : 130),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.black45),
                      const SizedBox(width: 2),
                      Expanded(child: Text(item.address, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StayReservationCalendarScreen(
                            accommodationId: item.id,
                            accommodationName: item.name,
                            subscriptionStartDate: subStart,
                            subscriptionEndDate: subEnd,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('예약하기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildAccommodationCard(StayAccommodationDto item) {
    final tags = (item.amenities ?? '').split(',').where((t) => t.trim().isNotEmpty).take(2).toList();

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StayAccommodationDetailScreen(accommodationId: item.id))),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  item.firstImageUrl != null
                      ? Image.network(item.firstImageUrl!, height: 130, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _imagePlaceholder())
                      : _imagePlaceholder(),
                  Positioned(
                    left: 10, bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.address.split(' ').take(2).join(' '),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(item.address, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: tags.map((tag) => Text('#${tag.trim()}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500))).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder({double height = 130}) => Container(
    height: height, color: AppColors.border,
    child: const Center(child: Icon(Icons.home_outlined, size: 40, color: AppColors.textHint)),
  );
}