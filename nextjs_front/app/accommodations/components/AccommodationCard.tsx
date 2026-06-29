/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/accommodations/components/AccommodationCard.tsx
 * 역할  : 숙소 목록의 개별 카드 컴포넌트 (이미지, 이름, 가격, 주소 표시)
 * 사용처 : app/accommodations/page.tsx
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - AccommodationCard.module.css  : 카드 스타일
 * - app/accommodations/page.tsx   : 부모 컴포넌트 (teams, months props 전달)
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 숙소 대표 이미지 표시 (없으면 "이미지 없음" 플레이스홀더)
 * - 점검 중(MAINTENANCE) 상태 배지 표시
 * - 가격 계산기 설정(팀수, 개월수) 기반 팀당 월세 계산 및 표시
 * - 카드 클릭 시 숙소 상세 페이지로 이동
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * 부모에서 accommodation, teams, months props 수신
 * → calcTeamPrice() 로 팀당 월세 계산
 * → 카드 UI 렌더링 → 클릭 시 /accommodations/{id} 이동
 * ==================================================================================
 */

"use client";

import { useRouter } from 'next/navigation';
import styles from './AccommodationCard.module.css';
import { StayAccommodationDto } from '../page';
import { calcTeamPrice } from '@/app/lib/priceUtils';

interface AccommodationCardProps {
  accommodation: StayAccommodationDto;
  teams: number;
  months: number;
  isAdmin?: boolean;
  onEdit?: (accommodation: StayAccommodationDto) => void;
}


export default function AccommodationCard({
  accommodation,
  teams,
  months,
  isAdmin = false,
  onEdit,
}: AccommodationCardProps) {
  const router = useRouter();

  // 대표 이미지 (첫 번째 이미지)
  const firstImage = accommodation.imageUrl
    ? `${process.env.NEXT_PUBLIC_SERVER_URL}${accommodation.imageUrl.split(",")[0].trim()}`
    : null;

  // 팀당 월세 계산
  const teamPrice = calcTeamPrice(
    accommodation.monthlyPrice,
    accommodation.prices ?? [],
    months,
    teams,
  );

  return (
    <div
      className={styles.card}
      onClick={() => router.push(`/accommodations/${accommodation.id}`)}
      style={{ position: "relative" }}
    >
      {isAdmin && (
        <button
          onClick={(e) => {
            e.stopPropagation();
            onEdit?.(accommodation);
          }}
          className={styles.editBtn}
          style={{
            position: "absolute",
            top: 8,
            right: 8,
            zIndex: 2,
            fontSize: 12,
            padding: "5px 10px",
            background: "white",
            border: "0.5px solid #D6E4C8",
            borderRadius: 6,
            color: "#3B6D11",
            cursor: "pointer",
            opacity: 0,
            transition: "opacity 0.15s",
          }}
        >
          수정
        </button>
      )}

      {/* 숙소 이미지 */}
      <div className={styles.imageWrap}>
        {firstImage ? (
          <img
            src={firstImage}
            alt={accommodation.name}
            className={styles.image}
          />
        ) : (
          <div className={styles.imagePlaceholder}>이미지 없음</div>
        )}
        {accommodation.status === "MAINTENANCE" && (
          <span className={styles.badge}>점검 중</span>
        )}
      </div>

      {/* 숙소 정보 */}
      <div className={styles.info}>
        <h3 className={styles.name}>{accommodation.name}</h3>
        <p className={styles.address}>{accommodation.address}</p>
        <p className={styles.description}>{accommodation.description}</p>

        <div className={styles.priceWrap}>
          {teamPrice > 0 ? (
            <>
              <p className={styles.priceBase}>
                월 {accommodation.monthlyPrice.toLocaleString()}원
              </p>
              <p className={styles.priceTeam}>
                팀당 월세&nbsp;
                <span className={styles.price}>{teamPrice.toLocaleString()}원</span>
                <span className={styles.priceUnit}>&nbsp;/ {months}개월 기준</span>
              </p>
            </>
          ) : (
            <span className={styles.priceEmpty}>가격 정보 없음</span>
          )}
        </div>
      </div>
    </div>
  );
}
