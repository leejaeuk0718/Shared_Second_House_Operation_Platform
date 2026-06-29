// TODO: [개발 완료 시 이 파일 전체 삭제]
import 'package:flutter/material.dart';
import 'package:flutter_front/common/constants/app_colors.dart';
import 'package:flutter_front/domain/view/product_list_screen.dart';
import 'package:flutter_front/domain/view/stay_accommodation_list_screen.dart';
import 'package:flutter_front/domain/view/stay_my_reservation_screen.dart';
import 'package:flutter_front/domain/view/stay_my_subscription_screen.dart';
import 'package:flutter_front/domain/view/stay_reservation_calendar_screen.dart';
import 'package:flutter_front/domain/view/stay_subscription_apply_screen.dart';
import 'package:flutter_front/domain/dto/stay_accommodation_dto.dart';
import 'package:flutter_front/domain/view/guest_chat_main_screen.dart';
import 'package:flutter_front/domain/view/guest_chat_screen.dart';
import 'package:flutter_front/domain/view/guest_chat_bot_screen.dart';
import 'package:flutter_front/domain/view/guest_restaurant_map_screen.dart';
import 'package:provider/provider.dart';

import '../controller/cart_controller.dart';
import 'cart_screen.dart';
import 'delivery_admin_screen.dart';

/// TODO: [개발 완료 시 삭제] 팀원 화면 링크 모음 (개발 중 임시 사용)
class DevScreenLinks extends StatelessWidget {
  const DevScreenLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('혜은 — Stay (숙소 / 예약)'),
          _DevTile(
            icon: Icons.list_alt,
            title: '숙소 목록',
            subtitle: '전체 숙소 카드 목록',
            onTap: () => _go(context, const StayAccommodationListScreen()),
          ),
          _DevTile(
            icon: Icons.calendar_month_outlined,
            title: '내 예약 목록',
            subtitle: '예약 카드 · 취소 기능',
            onTap: () => _go(context, const StayMyReservationScreen()),
          ),
          _DevTile(
            icon: Icons.home_outlined,
            title: '내 구독 목록',
            subtitle: '구독 카드 · 예약하기 버튼',
            onTap: () => _go(context, const StayMySubscriptionScreen()),
          ),
          _DevTile(
            icon: Icons.date_range_outlined,
            title: '예약 캘린더',
            subtitle: '날짜 선택 예약 화면',
            onTap: () => _go(
              context,
              const StayReservationCalendarScreen(
                accommodationId: 1,
                accommodationName: '테스트 숙소',
              ),
            ),
          ),
          _DevTile(
            icon: Icons.subscriptions_outlined,
            title: '구독 신청',
            subtitle: '팀원 추가 · 계약 개월수 · 신청',
            onTap: () => _go(
              context,
              StaySubscriptionApplyScreen(
                accommodation: StayAccommodationDto(
                  id: 1,
                  name: '테스트 숙소',
                  address: '부산광역시 해운대구',
                  description: '테스트용 더미 데이터입니다.',
                  monthlyPrice: 4650000,
                  status: 'AVAILABLE',
                  prices: [
                    StayAccommodationPriceDto(id: 1, minMonths: 1, maxMonths: 3, discountRate: 0.0),
                    StayAccommodationPriceDto(id: 2, minMonths: 3, maxMonths: 6, discountRate: 0.05),
                    StayAccommodationPriceDto(id: 3, minMonths: 6, maxMonths: null, discountRate: 0.10),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          const _SectionLabel('진주 — 게스트 채팅방'),
          // _DevTile(
          //   icon: Icons.chat_outlined,
          //   title: '채팅 메인',
          //   subtitle: '채팅방 목록 · AI챗봇 · 맛집 진입 허브',
          //   onTap: () => _go(context, const GuestChatMainScreen()),
          // ),

          _DevTile(
            icon: Icons.chat_bubble_outline,
            title: '게스트 채팅방',
            subtitle: 'WebSocket · 채팅방 ID: 1번',
            onTap: () => _go(
              context,
              const GuestChatScreen(
                chatRoomId: 1,
                currentUserId: 100,
                currentUserName: '홍길동',
              ),
            ),
          ),

          const SizedBox(height: 16),

          const _SectionLabel('태흔 — AI / 맛집'),
          _DevTile(
            icon: Icons.smart_toy_outlined,
            title: 'AI 챗봇',
            subtitle: 'Gemini RAG 기반 QnA 챗봇',
            onTap: () => _go(context, const GuestChatBotScreen()),
          ),
          _DevTile(
            icon: Icons.restaurant_menu_outlined,
            title: '맛집 지도',
            subtitle: '주변 맛집 지도 화면',
            onTap: () => _go(context, const GuestRestaurantMapScreen()),
          ),

          const SizedBox(height: 16),

          // 🍔 성규 — 커머스 & 관리자 전용 섹션 (직접 파일 연동 완료)
          const _SectionLabel('성규 — 커머스 & 관리자'),
          _DevTile(
            icon: Icons.fastfood_outlined,
            title: '상품 스토어',
            subtitle: '상품 리스트 및 주문서 작성 화면',
            onTap: () => _go(context, const ProductListScreen()),
          ),
          _DevTile(
            icon: Icons.shopping_cart_outlined,
            title: '장바구니',
            subtitle: '담은 상품 확인 및 수량 조절',
            onTap: () {
              // 💡 CartScreen 위에 CartController 공급(주입)해주기
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => CartController(), // 👈 여기에 프로젝트에서 쓰는 CartController 인스턴스를 넣어줍니다.
                    child: const CartScreen(),
                  ),
                ),
              );
            },
          ),
          _DevTile(
            icon: Icons.delivery_dining_outlined,
            title: '배달 주문 내역 콘솔',
            subtitle: '👑 관리자 전용 배달 콘솔 관제 센터',
            onTap: () => _go(context, const DeliveryAdminScreen()),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textHint,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _DevTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DevTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      ),
    );
  }
}