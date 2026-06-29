'use client';

import { useEffect, useState, useMemo } from 'react';
import AccommodationCard from './components/AccommodationCard';
import PriceCalculator from '../components/PriceCalculator';
import AccommodationFormModal from './components/AccommodationFormModal';
import { api } from '@/lib/api';
import { UserResp } from '@/types/auth';
import styles from './page.module.css';

export interface StayAccommodationPriceDto {
  id: number;
  minMonths: number;
  maxMonths: number | null;
  discountRate: number;
}

export interface StayAccommodationDto {
  id: number;
  name: string;
  address: string;
  description: string;
  imageUrl: string;
  amenities: string;
  monthlyPrice: number;
  roomCount: number;
  bathroomCount: number;
  floorCount: number;
  parkingCount: number;
  landArea: number;
  buildingArea: number;
  latitude: number;
  longitude: number;
  status: 'AVAILABLE' | 'MAINTENANCE';
  prices: StayAccommodationPriceDto[];
}

interface PageResponse<T> {
  content: T[];
  totalPages: number;
  totalElements: number;
  number: number;
}

const PAGE_SIZE = 6;

export default function AccommodationsPage() {
  const [currentPage, setCurrentPage] = useState(0);
  const [keyword, setKeyword] = useState('');
  const [inputValue, setInputValue] = useState('');
  const [isAdmin, setIsAdmin] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);

  // 등록/수정 모달 상태
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editTarget, setEditTarget] = useState<StayAccommodationDto | null>(
    null
  );

  const [teams, setTeams] = useState(1);
  const [months, setMonths] = useState(1);

  // 응답 데이터 + 그 데이터가 어떤 요청에 대한 응답인지 함께 보관
  const [result, setResult] = useState<{
    requestId: string;
    accommodations: StayAccommodationDto[];
    totalPages: number;
  } | null>(null);

  // 이번 렌더링에서 "있어야 할" 요청을 식별하는 키 (순수 함수만 사용)
  const requestId = useMemo(
    () => `${currentPage}::${keyword}::${refreshKey}`,
    [currentPage, keyword, refreshKey]
  );

  // loading은 별도 state가 아니라 파생값
  const loading = result?.requestId !== requestId;

  useEffect(() => {
    let ignore = false;

    const params = new URLSearchParams({
      page: String(currentPage),
      size: String(PAGE_SIZE),
    });
    if (keyword) params.set('keyword', keyword);

    fetch(
      `${process.env.NEXT_PUBLIC_SERVER_URL}/api/stay/accommodations?${params}`
    )
      .then((res) => res.json())
      .then((data: PageResponse<StayAccommodationDto>) => {
        if (ignore) return;
        setResult({
          requestId,
          accommodations: data.content,
          totalPages: data.totalPages,
        });
      })
      .catch((err) => {
        if (!ignore) console.log('숙소 목록 조회 실패:', err);
      });

    return () => {
      ignore = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [requestId]);

  // admin 여부 확인 (비로그인/일반 유저는 false 유지, 화면은 정상 노출)
  useEffect(() => {
    api
      .get<UserResp>('/api/users')
      .then((user) => setIsAdmin(user.role === 'ADMIN'))
      .catch(() => setIsAdmin(false));
  }, []);

  const accommodations = result?.accommodations ?? [];
  const totalPages = result?.totalPages ?? 0;

  const handleSearch = () => {
    setCurrentPage(0);
    setKeyword(inputValue.trim());
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') handleSearch();
  };

  return (
    <div className={styles.container}>
      <div className={styles.calculatorWrap}>
        <PriceCalculator
          teams={teams}
          months={months}
          onTeamsChange={setTeams}
          onMonthsChange={setMonths}
        />
      </div>

      <div className={styles.searchWrap}>
        <div className={styles.searchInputWrap}>
          <input
            className={styles.searchInput}
            placeholder="숙소 이름으로 검색"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyDown={handleKeyDown}
          />
          {inputValue && (
            <button
              className={styles.clearBtn}
              onClick={() => {
                setInputValue('');
                setCurrentPage(0);
                setKeyword('');
              }}
            >
              ✕
            </button>
          )}
        </div>
        <button
          className={`btn-primary ${styles.searchBtn}`}
          onClick={handleSearch}
        >
          검색
        </button>

        {isAdmin && (
          <button
            className="btn-primary"
            style={{ marginLeft: 8, flex: 1 }}
            onClick={() => setShowCreateModal(true)}
          >
            + 숙소 등록
          </button>
        )}
      </div>

      {loading ? (
        <div className={styles.loading}>불러오는 중...</div>
      ) : accommodations.length === 0 ? (
        <div className={styles.empty}>검색 결과가 없습니다.</div>
      ) : (
        <div className={styles.grid}>
          {accommodations.map((accommodation) => (
            <AccommodationCard
              key={accommodation.id}
              accommodation={accommodation}
              teams={teams}
              months={months}
              isAdmin={isAdmin}
              onEdit={(acc) => setEditTarget(acc)}
            />
          ))}
        </div>
      )}

      {totalPages > 1 &&
        (() => {
          const start = Math.max(0, Math.min(currentPage - 2, totalPages - 5));
          const end = Math.min(totalPages - 1, Math.max(currentPage + 2, 4));
          const pages = Array.from(
            { length: end - start + 1 },
            (_, i) => start + i
          );
          return (
            <div className={styles.pagination}>
              <button
                className={styles.pageBtn}
                onClick={() => setCurrentPage((p) => p - 1)}
                disabled={currentPage === 0}
              >
                이전
              </button>
              {pages.map((i) => (
                <button
                  key={i}
                  className={`${styles.pageBtn} ${i === currentPage ? styles.pageBtnActive : ''}`}
                  onClick={() => setCurrentPage(i)}
                >
                  {i + 1}
                </button>
              ))}
              <button
                className={styles.pageBtn}
                onClick={() => setCurrentPage((p) => p + 1)}
                disabled={currentPage === totalPages - 1}
              >
                다음
              </button>
            </div>
          );
        })()}

      {/* 등록 모달 */}
      {showCreateModal && isAdmin && (
        <AccommodationFormModal
          mode="create"
          onClose={() => setShowCreateModal(false)}
          onSuccess={() => setRefreshKey((k) => k + 1)}
        />
      )}

      {/* 수정 모달 */}
      {editTarget && isAdmin && (
        <AccommodationFormModal
          mode="edit"
          initialData={editTarget}
          onClose={() => setEditTarget(null)}
          onSuccess={() => setRefreshKey((k) => k + 1)}
        />
      )}
    </div>
  );
}
