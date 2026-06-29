/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/subscribe/[accommodationId]/page.tsx
 * 역할  : 구독 신청 페이지 (대표자 + 팀원 입력 → 구독 신청 요청)
 * 사용처 : 숙소 상세 페이지에서 "구독 신청하기" 버튼 클릭 시 이동
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - app/accommodations/[id]/page.tsx         : calcTeamPrice import 출처
 * - lib/api.ts                               : fetch 기반 API 클라이언트 (Bearer 토큰 자동 첨부)
 * - types/auth.ts                            : UserResp 타입 (userId 획득용)
 * - Spring: StayAccommodationController.java : GET /api/stay/accommodations/{id}  (permitAll)
 * - Spring: SubscriptionsController.java     : POST /api/waiting/apply/{leaderId} (인증 필요)
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 숙소 정보 조회 및 표시 (이름, 주소, 월세)
 * - 로그인 유저가 대표자로 자동 설정 (/api/users 로 userId 획득)
 * - 팀원 추가 / 삭제 (0명부터 자유롭게)
 * - 계약 개월수 선택 (1~12개월)
 * - 팀당 월세 실시간 계산 (대표자 포함 총 인원 기준)
 * - 구독 신청 요청 → 완료 시 상세 페이지로 이동
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * 진입 → GET /api/stay/accommodations/{id} → 숙소 정보 표시
 *       → 팀원 추가/삭제 → totalMembers 변경 → 팀당 월세 재계산
 *       → 구독 신청 버튼 → POST /api/waiting/apply/{leaderId}
 *       → 완료 → /accommodations/{id} 이동
 * ==================================================================================
 */

'use client';

import { useEffect, useState, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import DatePicker from 'react-datepicker';
import { ko } from 'date-fns/locale';
import 'react-datepicker/dist/react-datepicker.css';
import styles from './page.module.css';
import {
  StayAccommodationDto,
  StayAccommodationPriceDto,
} from '../../accommodations/page';
import { calcTeamPrice } from '@/app/lib/priceUtils';
import { api } from '@/lib/api';
import { UserResp } from '@/types/auth';
import { tokenStorage } from '@/lib/token';
import { SubscriptionDateRangeResp } from '@/types/subscription';

// 예약 페이지와 동일한 로컬 날짜 포맷 헬퍼 (UTC 변환 시 하루 밀림 방지)
const formatLocalDate = (date: Date): string => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

export default function SubscribePage() {
  const params = useParams();
  const router = useRouter();
  const accommodationId = params.accommodationId as string;

  const [accommodation, setAccommodation] =
    useState<StayAccommodationDto | null>(null);
  const [prices, setPrices] = useState<StayAccommodationPriceDto[]>([]);
  const [loading, setLoading] = useState(true);

  // 폼 상태
  const [memberIds, setMemberIds] = useState<string[]>([]);
  const [durationMonths, setDurationMonths] = useState(1);

  const [leaderId, setLeaderId] = useState<number | null>(null);

  // [날짜 검증 추가] 희망 시작일 + 사용 불가 기간 목록
  const todayStr = formatLocalDate(new Date()); // YYYY-MM-DD
  const todayDate = useMemo(() => { const d = new Date(); d.setHours(0,0,0,0); return d; }, []);
  const [startDate, setStartDate] = useState<Date | null>(null);
  const [blockedPeriods, setBlockedPeriods] = useState<SubscriptionDateRangeResp[]>([]);

  // [날짜 검증 추가] 달력에 표시할 사용 불가 날짜 배열 (startDate 포함 ~ endDate 미포함)
  const blockedDates = useMemo(() => {
    const dates: Date[] = [];
    blockedPeriods.forEach((p) => {
      const current = new Date(p.startDate);
      const end = new Date(p.endDate);
      while (current < end) {
        dates.push(new Date(current));
        current.setDate(current.getDate() + 1);
      }
    });
    return dates;
  }, [blockedPeriods]);

  // [날짜 검증 추가] 선택한 기간이 사용 불가 기간과 겹치는지 실시간 체크
  const startDateStr = startDate ? formatLocalDate(startDate) : '';
  const endDateStr = startDate
    ? (() => {
        const d = new Date(startDate);
        d.setMonth(d.getMonth() + durationMonths);
        return formatLocalDate(d);
      })()
    : '';
  const hasDateConflict = startDateStr
    ? blockedPeriods.some(
        (p) => p.startDate < endDateStr && p.endDate > startDateStr
      )
    : false;

  // [날짜 검증 추가] 신청 가능한 기간 계산 — 사용 불가 기간 사이의 빈 구간
  const availableWindows = useMemo(() => {
    if (blockedPeriods.length === 0) return [{ from: todayStr, to: null }];
    const sorted = [...blockedPeriods].sort((a, b) =>
      a.startDate.localeCompare(b.startDate)
    );
    const windows: { from: string; to: string | null }[] = [];
    if (sorted[0].startDate > todayStr) {
      windows.push({ from: todayStr, to: sorted[0].startDate });
    }
    for (let i = 0; i < sorted.length - 1; i++) {
      if (sorted[i].endDate < sorted[i + 1].startDate) {
        windows.push({ from: sorted[i].endDate, to: sorted[i + 1].startDate });
      }
    }
    windows.push({ from: sorted[sorted.length - 1].endDate, to: null });
    return windows;
  }, [blockedPeriods, todayStr]);

  // 팀 인원 (대표자 + 실제 입력된 팀원)
  const totalMembers = memberIds.filter((id) => id.trim() !== '').length + 1;

  // 팀당 월세 계산
  const teamPrice = accommodation
    ? calcTeamPrice(
        accommodation.monthlyPrice,
        prices,
        durationMonths,
        totalMembers
      )
    : 0;

  useEffect(() => {
    if (!tokenStorage.get()) {
      router.push('/login');
      return;
    }

    // userId 획득 + 숙소 정보 + 사용 불가 기간 병렬 조회
    Promise.all([
      api.get<UserResp>('/api/users'),
      api.get<StayAccommodationDto>(`/api/stay/accommodations/${accommodationId}`),
      api.get<SubscriptionDateRangeResp[]>(`/api/subscriptions/accommodation/${accommodationId}`),
    ])
      .then(([userData, accommodationData, blockedData]) => {
        console.log('유저 데이터:', userData);
        console.log('숙소 데이터:', accommodationData);
        setLeaderId(userData.userId);
        setAccommodation(accommodationData);
        setPrices(accommodationData.prices ?? []);
        // [날짜 검증 추가] 사용 불가 기간 저장
        setBlockedPeriods(blockedData);
      })
      .catch((err) => console.log('데이터 조회 실패:', err))
      .finally(() => setLoading(false));
  }, [accommodationId]);

  // 팀원 추가
  const addMember = () => {
    setMemberIds((prev) => [...prev, '']);
  };

  // 팀원 삭제
  const removeMember = (index: number) => {
    setMemberIds((prev) => prev.filter((_, i) => i !== index));
  };

  // 팀원 ID 변경
  const updateMember = (index: number, value: string) => {
    setMemberIds((prev) => prev.map((id, i) => (i === index ? value : id)));
  };

  // 구독 신청
  const handleSubmit = () => {
    const body = {
      accommodationId: Number(accommodationId),
      durationMonths,
      memberIdentifiers: memberIds.filter((id) => id.trim() !== ''),
      startDate: startDateStr, // [날짜 검증 추가] 희망 시작일 전달
    };

    console.log('구독 신청 요청:', body);

    api.post<unknown>(`/api/waiting/apply/${leaderId}`, body)
      .then((data) => {
        console.log('구독 신청 완료:', data);
        alert('구독 신청이 완료됐어요! 관리자 승인을 기다려주세요.');
        router.push(`/accommodations/${accommodationId}`);
      })
      .catch((err) => {
        console.log('구독 신청 실패:', err);
        alert('구독 신청에 실패했어요. 다시 시도해주세요.');
      });
  };

  if (loading) return <div className={styles.loading}>불러오는 중...</div>;
  if (!accommodation)
    return <div className={styles.loading}>숙소를 찾을 수 없습니다.</div>;

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>구독 신청</h1>

      {/* 숙소 정보 */}
      <div className={styles.accommodationInfo}>
        <h2 className={styles.accommodationName}>{accommodation.name}</h2>
        <p className={styles.accommodationAddress}>{accommodation.address}</p>
        <p className={styles.accommodationPrice}>
          월 {accommodation.monthlyPrice.toLocaleString()}원
        </p>
      </div>

      {/* 폼 */}
      <div className={styles.form}>
        {/* 대표자 */}
        <div className={styles.formGroup}>
          <label className={styles.label}>대표자 ID</label>
          <input className={styles.input} value={leaderId ?? ''} disabled />
          <span className={styles.hint}>
            ※ 로그인한 유저가 대표자로 자동 설정됩니다.
          </span>
        </div>

        {/* 함께할 팀원 */}
        <div className={styles.formGroup}>
          <label className={styles.label}>함께할 팀원 아이디 또는 이메일</label>
          {memberIds.map((memberId, index) => (
            <div key={index} className={styles.memberRow}>
              <input
                className={styles.input}
                placeholder={`팀원 ${index + 1} 아이디 또는 이메일 입력`}
                value={memberId}
                onChange={(e) => updateMember(index, e.target.value)}
              />
              <button
                className="btn-danger"
                onClick={() => removeMember(index)}
              >
                삭제
              </button>
            </div>
          ))}
          <button className="btn-secondary" onClick={addMember}>
            + 팀원 추가
          </button>
        </div>

        {/* 개월수 선택 */}
        <div className={styles.formGroup}>
          <label className={styles.label}>계약 개월수</label>
          <select
            className={styles.select}
            value={durationMonths}
            onChange={(e) => setDurationMonths(Number(e.target.value))}
          >
            {Array.from({ length: 12 }, (_, i) => i + 1).map((n) => (
              <option key={n} value={n}>
                {n} 개월
              </option>
            ))}
          </select>
        </div>

        {/* [날짜 검증 추가] 희망 시작일 선택 */}
        <div className={styles.formGroup}>
          <label className={styles.label}>희망 구독 시작일</label>

          {/* 기간 현황 안내 */}
          <div className={styles.periodInfo}>
            {blockedPeriods.length > 0 && (
              <div className={styles.blockedPeriods}>
                <p className={styles.blockedTitle}>❌ 사용 불가 기간</p>
                <ul className={styles.blockedList}>
                  {[...blockedPeriods]
                    .sort((a, b) => a.startDate.localeCompare(b.startDate))
                    .map((p, i) => (
                      <li key={i} className={styles.blockedItem}>
                        {p.startDate} ~ {p.endDate}
                        <span className={styles.blockedStatus}>
                          {p.status === 'ACTIVE' ? ' (구독 중)' : ' (승인 대기)'}
                        </span>
                      </li>
                    ))}
                </ul>
              </div>
            )}
            <div className={styles.availablePeriods}>
              <p className={styles.availableTitle}>✅ 신청 가능 기간</p>
              <ul className={styles.availableList}>
                {availableWindows.map((w, i) => (
                  <li key={i} className={styles.availableItem}>
                    {w.from} ~ {w.to ?? '제한 없음'}
                  </li>
                ))}
              </ul>
            </div>
          </div>

          {/* 달력 — 사용 불가 날짜 주황색 표시, 오늘 이전 비활성화 */}
          <div className={styles.calendarWrap}>
            <DatePicker
              selected={startDate}
              onChange={(date: Date | null) => setStartDate(date)}
              minDate={todayDate}
              excludeDates={blockedDates}
              inline
              locale={ko}
              dateFormat="yyyy-MM-dd"
              disabledKeyboardNavigation
            />
          </div>
          {startDateStr && endDateStr && (
            <span className={styles.hint}>
              선택한 구독 기간: {startDateStr} ~ {endDateStr}
            </span>
          )}
          {hasDateConflict && (
            <span className={styles.conflictWarning}>
              ⚠ 선택한 기간이 기존 구독과 겹칩니다. 위 신청 가능 기간을 확인해주세요.
            </span>
          )}
        </div>

        {/* 구독 요약 */}
        <div className={styles.summary}>
          <div className={styles.summaryRow}>
            <span className={styles.summaryLabel}>원래 월세</span>
            <span className={styles.summaryValue}>
              {accommodation.monthlyPrice.toLocaleString()}원 / 월
            </span>
          </div>
          <div className={styles.summaryRow}>
            <span className={styles.summaryLabel}>팀 인원</span>
            <span className={styles.summaryValue}>
              {totalMembers}명 (대표자 포함)
            </span>
          </div>
          <div className={styles.summaryRow}>
            <span className={styles.summaryLabel}>계약 기간</span>
            <span className={styles.summaryValue}>{durationMonths}개월</span>
          </div>

          <hr className={styles.summaryDivider} />

          <div className={styles.summaryRow}>
            <span className={styles.summaryLabel}>팀당 월세</span>
            <span className={styles.summaryPrice}>
              {teamPrice > 0 ? `${teamPrice.toLocaleString()}원` : '-'} / 월
            </span>
          </div>
        </div>

        {/* 신청 버튼 — 날짜 미선택 또는 겹침 시 비활성화 */}
        <button
          className={!startDateStr || hasDateConflict ? 'btn-disabled' : 'btn-primary'}
          onClick={handleSubmit}
          disabled={!startDateStr || hasDateConflict}
        >
          구독 신청하기
        </button>
      </div>
    </div>
  );
}
