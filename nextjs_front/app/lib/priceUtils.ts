/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/lib/priceUtils.ts
 * 역할  : 팀당 월세 계산 유틸리티
 * 사용처 : AccommodationCard, accommodations/[id]/page, subscribe/[id]/page
 * ----------------------------------------------------------------------------------
 * [함수 목록]
 * - calcTeamPrice() : 월세 × 할인율 ÷ 팀수 계산
 * ==================================================================================
 */

interface PriceEntry {
  minMonths: number;
  maxMonths: number | null;
  discountRate: number;
}

export function calcTeamPrice(
  monthlyPrice: number,
  prices: PriceEntry[],
  months: number,
  teams: number,
): number {
  const priceInfo = prices.find(
    (p) => months >= p.minMonths && (p.maxMonths === null || months < p.maxMonths),
  );
  if (!priceInfo) return 0;
  return Math.floor((monthlyPrice * (1 - priceInfo.discountRate)) / teams);
}
