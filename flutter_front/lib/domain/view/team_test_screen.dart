// import 'package:flutter/material.dart';
// import 'package:flutter_front/common/constants/app_colors.dart';
// import 'package:flutter_front/domain/view/main_screen.dart';
// import 'package:flutter_front/domain/view/stay_home_screen.dart';
// import 'package:flutter_front/domain/view/stay_accommodation_list_screen.dart';
// import 'package:flutter_front/domain/view/stay_accommodation_detail_screen.dart';
// import 'package:flutter_front/domain/view/stay_my_reservation_screen.dart';
// import 'package:flutter_front/domain/view/stay_reservation_calendar_screen.dart';
// import 'package:flutter_front/domain/view/stay_subscription_apply_screen.dart';
// import 'package:flutter_front/domain/dto/stay_accommodation_dto.dart';
// import 'package:flutter_front/domain/view/guest_chat_main_screen.dart';
// import 'package:flutter_front/domain/view/guest_chat_screen.dart';
// import 'package:flutter_front/domain/view/guest_chat_bot_screen.dart';
// import 'package:flutter_front/domain/view/guest_restaurant_map_screen.dart';
//
// /// 팀 통합 로컬 테스트 화면
// /// - 각 멤버가 본인 파트 화면을 확인할 수 있습니다
// /// - main.dart에서 이 화면으로 진입 설정
// class TeamTestScreen extends StatelessWidget {
//   const TeamTestScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text(
//           '팀 테스트 화면',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: AppColors.primary,
//         centerTitle: true,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(20),
//         children: [
//           // ── 통합 메인 ──────────────────────────────────────
//           const _SectionLabel('통합 메인'),
//           _TestTile(
//             icon: Icons.home,
//             title: '통합 메인 화면',
//             subtitle: '홈 · 내 예약 · AI 챗봇 (바텀 네비 포함)',
//             onTap: () => _go(context, const MainScreen()),
//           ),
//
//           const SizedBox(height: 16),
//
//           // ── 혜은 파트 ──────────────────────────────────────
//           const _SectionLabel('혜은hyen — Stay (숙소 / 예약)'),
//           // _TestTile(
//           //   icon: Icons.home_outlined,
//           //   title: '홈 화면',
//           //   subtitle: '숙소 배너 · 가로 스크롤 카드 목록',
//           //   onTap: () => _go(context, const StayHomeScreen()),
//           // ),
//           _TestTile(
//             icon: Icons.list_alt,
//             title: '숙소 목록',
//             subtitle: '전체 숙소 카드 목록',
//             onTap: () => _go(context, const StayAccommodationListScreen()),
//           ),
//           // _TestTile(
//           //   icon: Icons.info_outline,
//           //   title: '숙소 상세',
//           //   subtitle: 'ID 1번 숙소 상세 페이지',
//           //   onTap: () => _go(context, const StayAccommodationDetailScreen(accommodationId: 1)),
//           // ),
//           _TestTile(
//             icon: Icons.calendar_month_outlined,
//             title: '내 예약 목록',
//             subtitle: '예약 카드 · 취소 기능',
//             onTap: () => _go(context, const StayMyReservationScreen()),
//           ),
//           _TestTile(
//             icon: Icons.date_range_outlined,
//             title: '예약 캘린더',
//             subtitle: '날짜 선택 예약 화면',
//             onTap: () => _go(
//               context,
//               const StayReservationCalendarScreen(
//                 accommodationId: 1,
//                 accommodationName: '테스트 숙소',
//               ),
//             ),
//           ),
//           _TestTile(
//             icon: Icons.subscriptions_outlined,
//             title: '구독 신청',
//             subtitle: '팀원 추가 · 계약 개월수 · 신청',
//             onTap: () => _go(
//               context,
//               StaySubscriptionApplyScreen(
//                 accommodation: StayAccommodationDto(
//                   id: 1,
//                   name: '테스트 숙소',
//                   address: '부산광역시 해운대구',
//                   description: '테스트용 더미 데이터입니다.',
//                   monthlyPrice: 4650000,
//                   status: 'AVAILABLE',
//                   prices: [
//                     StayAccommodationPriceDto(id: 1, minMonths: 1, maxMonths: 3, discountRate: 0.0),
//                     StayAccommodationPriceDto(id: 2, minMonths: 3, maxMonths: 6, discountRate: 0.05),
//                     StayAccommodationPriceDto(id: 3, minMonths: 6, maxMonths: null, discountRate: 0.10),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           // ── 진주 파트 ────────────────────────────
//           const _SectionLabel('진주 - 게스트 채팅방'),
//           // _TestTile(
//           //   icon: Icons.chat_outlined,
//           //   title: '채팅 메인',
//           //   subtitle: '채팅방 목록 · AI챗봇 · 맛집 진입 허브',
//           //   onTap: () => _go(context, const GuestChatMainScreen()),
//           // ),
//           //
//           _TestTile(
//             icon: Icons.chat_bubble_outline,
//             title: '게스트 채팅방',
//             subtitle: 'WebSocket · 채팅방 ID: 1번',
//             onTap: () => _go(
//               context,
//               const GuestChatScreen(
//                   chatRoomId: 1,
//                   currentUserId: 100,
//                   currentUserName: 'string'
//               ),
//             ),
//           ),
//
//           // ── 태흔 파트 ────────────────────────────
//           const _SectionLabel('태흔 - AI / 맛집 파트'),
//           _TestTile(
//             icon: Icons.smart_toy_outlined,
//             title: 'AI 챗봇',
//             subtitle: 'Gemini RAG 기반 QnA 챗봇',
//             onTap: () => _go(context, const GuestChatBotScreen()),
//           ),
//           _TestTile(
//             icon: Icons.restaurant_menu_outlined,
//             title: '맛집 지도',
//             subtitle: '주변 맛집 지도 화면',
//             onTap: () => _go(context, const GuestRestaurantMapScreen()),
//           ),
//
//           const SizedBox(height: 24),
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: AppColors.primaryBg,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: AppColors.primaryBorder),
//             ),
//             child: const Text(
//               '※ 이 화면은 로컬 테스트 전용입니다.\n'
//                   '   팀 병합 시 main.dart → AppRouter로 변경하세요.',
//               style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _go(BuildContext context, Widget screen) {
//     Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
//   }
// }
//
// class _SectionLabel extends StatelessWidget {
//   final String label;
//   const _SectionLabel(this.label);
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8, top: 4),
//       child: Text(
//         label,
//         style: const TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.bold,
//           color: AppColors.textHint,
//           letterSpacing: 1.0,
//         ),
//       ),
//     );
//   }
// }
//
// class _TestTile extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final VoidCallback onTap;
//
//   const _TestTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
//       ),
//       child: ListTile(
//         onTap: onTap,
//         leading: CircleAvatar(
//           backgroundColor: AppColors.primaryLight,
//           child: Icon(icon, color: AppColors.primary, size: 20),
//         ),
//         title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
//         subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
//         trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
//       ),
//     );
//   }
// }