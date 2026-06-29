/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/accommodations/[id]/components/WelcomeKit.tsx
 * 역할  : 웰컴키트 및 집 사용 설명서 안내 섹션
 * 사용처 : app/accommodations/[id]/page.tsx
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - WelcomeKit.module.css               : 카드 스타일
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 집 사용 설명서 / 웰컴키트 두 항목을 카드 형태로 표시
 * - 고정 텍스트 (props 없음, 정적 컴포넌트)
 * ==================================================================================
 */

import styles from './WelcomeKit.module.css';
import { FaBook, FaGift } from 'react-icons/fa';

export default function WelcomeKit() {
  return (
    <section className={styles.section}>
      <h2 className={styles.sectionTitle}>웰컴키트와 집 사용 설명서</h2>

      <div className={styles.grid}>
        {/* 집 사용 설명서 */}
        <div className={styles.card}>
          <div className={styles.iconWrap}>
            <FaBook />
          </div>
          <h3 className={styles.cardTitle}>집 사용 설명서</h3>
          <p className={styles.cardDesc}>
            공간의 구조부터 가전 사용법, 주변 맛집, 로컬플레이스 등
            낯선 집이 익숙해지는 정보를 담았습니다.
          </p>
        </div>

        {/* 웰컴키트 */}
        <div className={styles.card}>
          <div className={styles.iconWrap}>
            <FaGift />
          </div>
          <h3 className={styles.cardTitle}>웰컴키트</h3>
          <p className={styles.cardDesc}>
            추억을 남길 수 있는 소정의 선물을 준비했습니다.
          </p>
        </div>
      </div>
    </section>
  );
}