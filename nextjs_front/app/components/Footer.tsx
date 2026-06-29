/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/components/Footer.tsx
 * 역할  : 전체 앱 하단 풋터 (공통 레이아웃)
 * 사용처 : app/layout.tsx
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - Footer.module.css : 풋터 스타일
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 브랜드명 및 소개 문구 표시 (정적 컴포넌트, props 없음)
 * ==================================================================================
 */

import styles from "./Footer.module.css";

export default function Footer() {
  return (
    <footer className={styles.footer}>
      <div className={styles.footerInner}>
        <p className={styles.footerBrand}>세컨하우스</p>
        <p className={styles.footerText}>나만의 두 번째 집을 찾아보세요.</p>
      </div>
    </footer>
  );
}
