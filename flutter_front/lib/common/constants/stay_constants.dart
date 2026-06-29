/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/common/constants/stay_constants.dart
 * 역할  : 숙소 관련 공통 상수 및 유틸 함수
 * 사용처 : StayAccommodationListScreen, StaySubscriptionApplyScreen 등 stay 전체
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - nextjs_front/app/lib/constants.ts : 동일한 구조의 Next.js 버전
 * ----------------------------------------------------------------------------------
 * [상수 / 함수 목록]
 * - kMonthOptionValues  : 개월수 선택 옵션 목록 [1, 2, 3, 4, 5, 6]
 * - monthOptionLabel()  : 개월수 → 표시 텍스트 (6 → "6개월 이상", 나머지 → "N개월")
 * ----------------------------------------------------------------------------------
 * [주의사항]
 * - Next.js constants.ts와 항상 동일하게 유지할 것
 * ==================================================================================
 */

// 변경 필요 시 이 파일만 수정
// Next.js constants.ts의 MONTH_OPTIONS와 동일한 구조

const List<int> kMonthOptionValues = [1, 2, 3, 4, 5, 6];

String monthOptionLabel(int value) => value == 6 ? '6개월 이상' : '$value개월';
