/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/reservations/[accommodationId]/page.tsx
 * 역할  : 예약하기 페이지 (날짜 선택 달력 + 예약 생성)
 * 사용처 : 숙소 상세 페이지 "예약하기" 버튼 클릭 시 이동 (구독 ACTIVE 상태 필수)
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - lib/api.ts : fetch 기반 API 클라이언트 (Bearer 토큰 자동 첨부)
 * - types/auth.ts : UserResp 타입 (userId 획득용)
 * - Spring: StayReservationController.java
 *     GET  /api/stay/reservations/accommodation/{id} : 숙소별 확정 예약 목록 (달력용)
 *     POST /api/stay/reservations                    : 예약 생성
 * - Spring: SubscriptionsController.java
 *     GET  /api/subscriptions/my/{userId}            : 내 구독 정보 (예약 가능 기간 확인)
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 구독 기간 내에서만 날짜 선택 가능 (minDate, maxDate 구독 기간 연동)
 * - 이미 예약된 날짜(CONFIRMED) 달력에서 비활성화 표시
 * - 시작일 선택 후 다음 예약 직전까지만 종료일 선택 가능 (dynamicMaxDate)
 * - 최소 1박 2일 강제 (종료일 > 시작일)
 * - 예약 실패 시 달력 즉시 갱신 (다른 사용자 예약 반영)
 * - 탭 전환 후 돌아올 때 focus 이벤트로 달력 자동 갱신
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * 진입 → Promise.all([구독, 예약목록]) → 구독 기간 설정 + 예약 날짜 비활성화
 * → 시작일 선택 → dynamicMaxDate 계산 → 종료일 선택
 * → "예약 확정" 클릭 → POST /api/stay/reservations
 * → 성공: /my/reservations 이동 / 실패: 달력 즉시 갱신
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * - 비로그인 시 lib/api.ts가 /login 으로 자동 리다이렉트
 * - parseLocalDate(): Spring LocalDate 배열([2026,6,25]) 또는 문자열 두 형태 모두 처리
 * - formatLocalDate(): toISOString() 대신 로컬 기준 포맷 (UTC+9 하루 밀림 방지)
 * ==================================================================================
 */

'use client';

import { useEffect, useState, useMemo, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import DatePicker from 'react-datepicker';
import { ko } from 'date-fns/locale';
import 'react-datepicker/dist/react-datepicker.css';
import styles from './page.module.css';
import { MdHouse } from 'react-icons/md';
import { api } from '@/lib/api';
import { UserResp } from '@/types/auth';

// Spring LocalDate가 배열([2026,6,25]) 또는 문자열("2026-06-25") 두 형태로 올 수 있음
// 로컬 자정 기준으로 변환해야 한국(UTC+9)에서 하루 밀림 현상 없음
const parseLocalDate = (dateInput: string | number[]): Date => {
  if (Array.isArray(dateInput)) {
    const [year, month, day] = dateInput;
    return new Date(year, month - 1, day);
  }
  const [year, month, day] = dateInput.split('-').map(Number);
  return new Date(year, month - 1, day);
};

// toISOString()은 UTC 기준이라 한국(+9)에서 하루 밀림 → 로컬 기준으로 포맷
const formatLocalDate = (date: Date): string => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

interface ReservationDto {
  id: number;
  startDate: string | number[];
  endDate: string | number[];
  status: string;
}

interface SubscriptionDto {
  accommodationId: number;
  startDate: string | number[];
  endDate: string | number[];
  status: string;
}

interface AccommodationDto {
  name: string;
}

export default function ReservationPage() {
  const params = useParams();
  const router = useRouter();
  const accommodationId = params.accommodationId as string;

  const [startDate, setStartDate] = useState<Date | null>(null);
  const [endDate, setEndDate] = useState<Date | null>(null);
  const [reservedDates, setReservedDates] = useState<Date[]>([]);
  const [subscription, setSubscription] = useState<SubscriptionDto | null>(
    null
  );
  const [loading, setLoading] = useState(true);
  const [accommodationName, setAccommodationName] = useState<string>('');

  const [userId, setUserId] = useState<number | null>(null);

  // 예약 데이터 fetch (실시간 갱신을 위해 함수로 분리)
  const fetchReservations = useCallback(() => {
    api
      .get<ReservationDto[]>(
        `/api/stay/reservations/accommodation/${accommodationId}`
      )
      .then((reservationsData) => {
        console.log('[ReservationPage] 예약 데이터 갱신:', reservationsData);
        const dates: Date[] = [];
        reservationsData
          .filter((r: ReservationDto) => r.status === 'CONFIRMED')
          .forEach((r: ReservationDto) => {
            const start = parseLocalDate(r.startDate);
            const end = parseLocalDate(r.endDate);
            const current = new Date(start);
            while (current <= end) {
              dates.push(new Date(current));
              current.setDate(current.getDate() + 1);
            }
          });
        setReservedDates(dates);
        // 날짜 갱신 시 선택 초기화
        setStartDate(null);
        setEndDate(null);
      })
      .catch((err) =>
        console.log('[ReservationPage] 예약 데이터 갱신 실패:', err)
      );
  }, [accommodationId]);

  // 초기 로딩 (userId 획득 → 구독 + 예약 데이터 병렬 조회)
  useEffect(() => {
    api
      .get<UserResp>('/api/users')
      .then((userData) => {
        setUserId(userData.userId);
        return Promise.all([
          api.get<SubscriptionDto[]>(
            `/api/subscriptions/my/${userData.userId}`
          ),
          api.get<ReservationDto[]>(
            `/api/stay/reservations/accommodation/${accommodationId}`
          ),
          api.get<AccommodationDto>(
            `/api/stay/accommodations/${accommodationId}`
          ),
        ]);
      })
      .then(([subscriptionData, reservationsData, accommodationData]) => {
        setAccommodationName(accommodationData.name);
        console.log('[ReservationPage] 구독 데이터:', subscriptionData);
        console.log('[ReservationPage] 예약 데이터:', reservationsData);

        const activeSubscription = Array.isArray(subscriptionData)
          ? subscriptionData.find(
              (s) =>
                s.status === 'ACTIVE' &&
                s.accommodationId === Number(accommodationId)
            )
          : null;
        setSubscription(activeSubscription ?? null);

        const dates: Date[] = [];
        reservationsData
          .filter((r: ReservationDto) => r.status === 'CONFIRMED')
          .forEach((r: ReservationDto) => {
            const start = parseLocalDate(r.startDate);
            const end = parseLocalDate(r.endDate);
            const current = new Date(start);
            while (current <= end) {
              dates.push(new Date(current));
              current.setDate(current.getDate() + 1);
            }
          });
        setReservedDates(dates);
      })
      .catch((err) => console.log('[ReservationPage] 데이터 조회 실패:', err))
      .finally(() => setLoading(false));
  }, []);

  // 탭 전환 후 돌아왔을 때 예약 데이터 실시간 갱신
  useEffect(() => {
    const handleFocus = () => fetchReservations();
    window.addEventListener('focus', handleFocus);
    return () => window.removeEventListener('focus', handleFocus);
  }, [fetchReservations]);

  const today = useMemo(() => {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    return d;
  }, []);

  const baseMinDate = useMemo(() => {
    if (!subscription) return today;
    const subStart = parseLocalDate(subscription.startDate);
    return subStart > today ? subStart : today;
  }, [subscription, today]);

  const baseMaxDate = useMemo(() => {
    return subscription ? parseLocalDate(subscription.endDate) : today;
  }, [subscription, today]);

  // 시작일 선택 후: 다음 예약 날짜 직전까지만 종료일 선택 가능
  const dynamicMaxDate = useMemo(() => {
    if (!startDate) return baseMaxDate;

    const nextBlocked = reservedDates
      .filter((d) => d.getTime() > startDate.getTime())
      .sort((a, b) => a.getTime() - b.getTime())[0];

    if (!nextBlocked) return baseMaxDate;

    const dayBefore = new Date(nextBlocked);
    dayBefore.setDate(dayBefore.getDate() - 1);

    return dayBefore.getTime() < baseMaxDate.getTime()
      ? dayBefore
      : baseMaxDate;
  }, [startDate, reservedDates, baseMaxDate]);

  // 시작일 선택 후 연박 불가 여부
  const noEndDateAvailable =
    startDate !== null && dynamicMaxDate.getTime() <= startDate.getTime();

  // 예약 생성
  const handleReserve = () => {
    if (!startDate || !endDate) {
      alert('시작일과 종료일을 모두 선택해주세요.');
      return;
    }

    const body = {
      accommodationId: Number(accommodationId),
      startDate: formatLocalDate(startDate),
      endDate: formatLocalDate(endDate),
    };

    console.log('[ReservationPage] 예약 생성 요청:', body);

    api
      .post<unknown>(`/api/stay/reservations`, body)
      .then((data) => {
        console.log('[ReservationPage] 예약 생성 완료:', data);
        alert('예약이 완료됐어요!');
        // router.push('/my/reservations'); // /my/reservations 사용 안함 → /mypage 내예약 탭으로 통합
        router.push('/mypage?tab=reservations');
      })
      .catch((err) => {
        const msg =
          err instanceof Error
            ? err.message
            : '예약에 실패했어요. 다시 시도해주세요.';
        console.log('[ReservationPage] 예약 생성 실패:', err);
        alert(msg);
        // 실패 시 달력 즉시 갱신 (다른 사용자가 먼저 예약한 경우 반영)
        fetchReservations();
      });
  };

  if (loading) return <div className={styles.loading}>불러오는 중...</div>;

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>예약하기</h1>
      {accommodationName && (
        <p className={styles.accommodationName}>
          <MdHouse className={styles.accommodationIcon} />
          {accommodationName}
        </p>
      )}

      {/* 기본 안내 */}
      {/* {!startDate && ( */}
      <p className={styles.calendarHint}>
        시작일을 먼저 선택해주세요. 회색 날짜는 이미 예약된 날짜입니다.
      </p>
      {/* )} */}

      {/* 연박 불가 안내 */}
      {noEndDateAvailable && (
        <p className={styles.calendarWarning}>
          선택하신 날짜는 연박 예약이 어렵습니다. 다른 시작일을 선택해주세요.
        </p>
      )}

      <div className={styles.calendarWrap}>
        <DatePicker
          selected={startDate}
          onChange={(dates) => {
            const [start, end] = dates as [Date | null, Date | null];
            // 최소 1박 2일: 종료일이 시작일과 같거나 이전이면 종료일 초기화
            if (start && end && end.getTime() <= start.getTime()) {
              setStartDate(start);
              setEndDate(null);
              return;
            }
            setStartDate(start);
            setEndDate(end);
          }}
          startDate={startDate}
          endDate={endDate}
          selectsRange
          inline
          minDate={baseMinDate}
          maxDate={dynamicMaxDate}
          excludeDates={reservedDates}
          locale={ko}
          monthsShown={2}
          disabledKeyboardNavigation
        />
      </div>

      {/* 선택된 날짜 표시 */}
      <div className={styles.selectedDates}>
        <div className={styles.dateItem}>
          <span className={styles.dateLabel}>시작일</span>
          <span className={styles.dateValue}>
            {startDate ? startDate.toLocaleDateString('ko-KR') : '선택해주세요'}
          </span>
        </div>
        <div className={styles.dateDivider}>→</div>
        <div className={styles.dateItem}>
          <span className={styles.dateLabel}>종료일</span>
          <span className={styles.dateValue}>
            {endDate ? endDate.toLocaleDateString('ko-KR') : '선택해주세요'}
          </span>
        </div>
        {(startDate || endDate) && (
          <button
            className="btn-reset"
            onClick={() => {
              setStartDate(null);
              setEndDate(null);
            }}
          >
            초기화
          </button>
        )}
      </div>

      {/* 예약 버튼 */}
      <button
        className="btn-primary"
        onClick={handleReserve}
        disabled={!startDate || !endDate}
      >
        예약 확정
      </button>
    </div>
  );
}
