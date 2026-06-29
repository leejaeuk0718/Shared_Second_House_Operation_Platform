/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/accommodations/[id]/components/PriceTable.tsx
 * 역할  : 장기 계약 할인 구간 테이블 표시
 * 사용처 : app/accommodations/[id]/page.tsx
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - PriceTable.module.css               : 테이블 스타일
 * - app/accommodations/[id]/page.tsx    : 부모 (monthlyPrice, prices props 전달)
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 할인 구간(minMonths ~ maxMonths)별 적용 월세 및 할인율 표시
 * - prices 배열이 비어있으면 null 반환 (렌더링 안 함)
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * prices props 수신 → 각 구간 map → 적용 월세(monthlyPrice × (1-discountRate)) 계산
 * → 기간 범위 텍스트 + 할인율 텍스트 표시
 * ==================================================================================
 */

import styles from './PriceTable.module.css';
import { StayAccommodationPriceDto } from '../../page';

interface PriceTableProps {
  monthlyPrice: number;
  prices: StayAccommodationPriceDto[];
}

function formatPriceRange(price: StayAccommodationPriceDto): string {
  const min = price.minMonths;
  const max = price.maxMonths;

  if (max === null) return `${min}개월 이상`;
  return `${min}개월 이상 ${max}개월 미만`;
}

function formatDiscount(discountRate: number): string {
  if (discountRate === 0) return '정가';
  return `${Math.round(discountRate * 100)}% 할인`;
}

export default function PriceTable({ monthlyPrice, prices }: PriceTableProps) {
  if (!prices || prices.length === 0) return null;

  return (
    <section className={styles.section}>
      <h2 className={styles.sectionTitle}>장기 계약 할인</h2>
      <div className={styles.list}>
        {prices.map((price) => (
          <div key={price.id} className={styles.row}>
            <span className={styles.price}>
              월세{' '}
              {Math.round(
                monthlyPrice * (1 - price.discountRate)
              ).toLocaleString()}
              원
            </span>
            <span className={styles.range}>/ {formatPriceRange(price)}</span>
            <span className={styles.discount}>
              {formatDiscount(price.discountRate)}
            </span>
          </div>
        ))}
      </div>
    </section>
  );
}
