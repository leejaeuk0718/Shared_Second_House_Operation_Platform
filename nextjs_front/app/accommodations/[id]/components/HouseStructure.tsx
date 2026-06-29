/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/accommodations/[id]/components/HouseStructure.tsx
 * 역할  : 숙소 집 구조 정보 섹션 (방, 화장실, 층수, 주차, 면적)
 * 사용처 : app/accommodations/[id]/page.tsx
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - HouseStructure.module.css           : 구조 섹션 스타일
 * - app/accommodations/[id]/page.tsx    : 부모 (각 구조 수치 props 전달)
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 방 / 화장실 / 층수 요약 한 줄 표시
 * - 대지면적 / 건물면적 / 주차 대수 상세 그리드 표시
 * ==================================================================================
 */

import styles from './HouseStructure.module.css';

interface HouseStructureProps {
  roomCount: number;
  bathroomCount: number;
  floorCount: number;
  parkingCount: number;
  landArea: number;
  buildingArea: number;
}

export default function HouseStructure({
  roomCount,
  bathroomCount,
  floorCount,
  parkingCount,
  landArea,
  buildingArea,
}: HouseStructureProps) {
  return (
    <section className={styles.section}>
      <h2 className={styles.sectionTitle}>집 구조</h2>

      {/* 상단 요약 */}
      <div className={styles.summary}>
        <span className={styles.summaryItem}>방 {roomCount}</span>
        <span className={styles.divider}>·</span>
        <span className={styles.summaryItem}>화장실 {bathroomCount}</span>
        <span className={styles.divider}>·</span>
        <span className={styles.summaryItem}>{floorCount}층 단독주택</span>
      </div>

      {/* 상세 그리드 */}
      <div className={styles.grid}>
        <div className={styles.item}>
          <span className={styles.itemLabel}>대지면적</span>
          <span className={styles.itemValue}>{landArea}평</span>
        </div>
        <div className={styles.item}>
          <span className={styles.itemLabel}>건물면적</span>
          <span className={styles.itemValue}>{buildingArea}평</span>
        </div>
        <div className={styles.item}>
          <span className={styles.itemLabel}>주차</span>
          <span className={styles.itemValue}>{parkingCount}대 이상</span>
        </div>
      </div>
    </section>
  );
}