/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/components/PriceCalculator.tsx
 * 역할  : 월세 자동 계산기 컴포넌트 (팀수·개월수 선택)
 * 사용처 : app/accommodations/page.tsx (숙소 목록 페이지 상단)
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - PriceCalculator.module.css : 계산기 스타일
 * - app/lib/constants.ts       : MONTH_OPTIONS (개월수 드롭다운 옵션)
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 같이 사용할 팀 수 선택 (1~12팀)
 * - 계약 월 수 선택 (MONTH_OPTIONS 기반)
 * - 상태는 부모에서 관리 (controlled 컴포넌트)
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * 부모(teams, months, onTeamsChange, onMonthsChange) props 수신
 * → 드롭다운 onChange → 부모 setState 호출 → AccommodationCard에 전달
 * ==================================================================================
 */

import styles from './PriceCalculator.module.css';
import { MONTH_OPTIONS, TEAM_OPTIONS } from '@/app/lib/constants';

interface PriceCalculatorProps {
  teams: number;
  months: number;
  onTeamsChange: (value: number) => void;
  onMonthsChange: (value: number) => void;
}

export default function PriceCalculator({
  teams,
  months,
  onTeamsChange,
  onMonthsChange,
}: PriceCalculatorProps) {
  return (
    <div className={styles.container}>
      <span className={styles.label}>월세 자동 계산기</span>

      {/* 팀수 선택 */}
      <div className={styles.selectGroup}>
        <span className={styles.selectLabel}>같이 사용할 팀 수</span>
        <select
          className={styles.select}
          value={teams}
          onChange={(e) => onTeamsChange(Number(e.target.value))}
        >
          {TEAM_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      {/* 개월수 선택 */}
      <div className={styles.selectGroup}>
        <span className={styles.selectLabel}>계약 월 수</span>
        <select
          className={styles.select}
          value={months}
          onChange={(e) => onMonthsChange(Number(e.target.value))}
        >
          {MONTH_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
}
