/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/accommodations/[id]/components/LocationMap.tsx
 * 역할  : 숙소 주변 맛집을 Google Maps로 표시하는 지도 컴포넌트
 * 사용처 : app/accommodations/[id]/page.tsx
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - LocationMap.module.css              : 지도 레이아웃 스타일
 * - Spring: PlacesController.java       : GET /api/places/restaurants?accommodationId=
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 숙소별 저장된 맛집 목록 조회 (백엔드 DB 기반, Google API 직접 호출 없음)
 * - 숙소 위치 파란색 마커 표시
 * - 맛집 마커 인기도 순위에 따라 색상 구분 (상위 빨강 / 10등 이하 주황)
 * - 마커 클릭 시 InfoWindow로 맛집 이름, 업종, 영업시간, 구글지도 링크 표시
 * - 오늘 요일 기준 영업시간 추출 (TodayHoursLine)
 * - "숙소 위치로" 버튼으로 지도 중심 재이동 (RecenterButton)
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * props(accommodationId, lat, lng) 수신
 * → useEffect → GET /api/places/restaurants?accommodationId=
 * → places 상태 업데이트 → 마커 렌더링
 * → 마커 클릭 → setSelectedPlace → InfoWindow 표시
 * ==================================================================================
 */

'use client';

import styles from './LocationMap.module.css';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import {
  AdvancedMarker,
  APIProvider,
  ControlPosition,
  InfoWindow,
  Map,
  MapControl,
  Pin,
  useMap,
} from '@vis.gl/react-google-maps';

interface PlaceDto {
  id: string;
  name: string;
  primaryType?: string | null;
  phoneNumber?: string | null;
  latitude: number;
  longitude: number;
  googleMapsUri?: string;
  weekdayDescriptions?: string[];
  accommodationId?: number | null;
  popularityRank?: number | null; // 인기도 순위 (0이 가장 인기, 없으면 null)
}

interface LocationMapProps {
  accommodationId: number;
  latitude: number;
  longitude: number;
  address: string;
  // 부모(상세 페이지)가 /api/users 검증까지 끝낸 "유효 로그인" 여부.
  // true일 때만 구글맵을 마운트해 과금을 막는다. (검증 중복 방지: 여기선 다시 호출하지 않음)
  showMap: boolean;
}

export default function LocationMap({
  accommodationId,
  latitude,
  longitude,
  address,
  showMap,
}: LocationMapProps) {
  const [places, setPlaces] = useState<PlaceDto[]>([]);
  const [selectedPlace, setSelectedPlace] = useState<PlaceDto | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!showMap) return; // 검증 통과 전/비회원이면 맛집도 조회하지 않음
    async function fetchRestaurants() {
      try {
        // 내 DB에 저장된 숙소별 맛집 조회 (구글 호출은 백엔드 /sync에서 별도 수행)
        // api.get 이 accessToken 을 Authorization: Bearer 로 자동 첨부 (JWT 인증)
        const data = await api.get<PlaceDto[]>(
          `/api/places/restaurants?accommodationId=${accommodationId}`
        );
        setPlaces(data);
      } catch {
        setError('맛집 정보를 가져오지 못했어요. 😢');
      } finally {
        setIsLoading(false);
      }
    }
    fetchRestaurants();
  }, [accommodationId, showMap]);

  return (
    // <div className={styles.screen}>
    //   <header className={styles.appBar}>주변 맛집</header>
    <section className={styles.section}>
      <h2 className={styles.sectionTitle}>주변 맛집</h2>
      <p className={styles.address}>{address}</p>

      {!showMap ? (
        // 비회원/만료·블랙리스트 토큰: 구글맵을 마운트하지 않아 과금이 발생하지 않음
        <div className={styles.loginNotice}>
          로그인 후 주변 맛집 지도를 확인할 수 있어요.
        </div>
      ) : (
      <div className={styles.mapWrap}>
        {/* 1. API 키 설정 */}
        <APIProvider apiKey={process.env.NEXT_PUBLIC_GOOGLE_MAP_KEY || ''}>
          {/* 2. 지도 띄우기 */}
          <Map
            defaultCenter={{ lat: latitude, lng: longitude }}
            defaultZoom={15}
            disableDefaultUI={true} // 기존의 구글 기본 버튼들(로드뷰 등) 한방에 숨기기
            className={styles.map}
            mapId={process.env.NEXT_PUBLIC_GOOGLE_MAP_ID || 'DEMO_MAP_ID'}
            gestureHandling={'greedy'} //인삿말 안하기
            scrollwheel={false} // 1. 휠로 확대되는 건 끈다! (스크롤 방해 금지)
            zoomControl={true} // 3. 👈 확대/축소 (+, -) 버튼 딱 이거 하나만 우측 하단에 띄운다!
          >
            {/* 🏠 숙소 마커 (파란색으로 강조) */}
            <AdvancedMarker
              position={{ lat: latitude, lng: longitude }}
              title="🏠 숙소"
            >
              <Pin
                background="#4285F4"
                borderColor="#1a73e8"
                glyphColor="#ffffff"
              />
            </AdvancedMarker>

            {/* 🍽️ 맛집 마커들 — 순위로 색 구분 (상위 빨강 / 10등~ 주황) */}
            {places.map((p) => {
              const rank = p.popularityRank;
              const isTop = rank == null || rank < 10; // 상위(또는 순위 없음)
              return (
                <AdvancedMarker
                  key={p.id}
                  position={{ lat: p.latitude, lng: p.longitude }}
                  title={p.name}
                  onClick={() => setSelectedPlace(p)} // 클릭하면 이 맛집을 선택!
                >
                  <Pin
                    background={isTop ? '#EA4335' : '#FB8C00'}
                    borderColor={isTop ? '#C5221F' : '#E07B00'}
                    glyphColor="#ffffff"
                  />
                </AdvancedMarker>
              );
            })}

            {/* 💬 마커 클릭 시 나타날 말풍선 (InfoWindow) */}
            {selectedPlace && (
              <InfoWindow
                position={{
                  lat: selectedPlace.latitude,
                  lng: selectedPlace.longitude,
                }}
                onCloseClick={() => setSelectedPlace(null)} // 닫기 버튼 누르면 초기화
              >
                <div
                  style={{
                    padding: '4px',
                    fontSize: '13px',
                    maxWidth: '220px',
                    color: '#000',
                  }}
                >
                  <strong>{selectedPlace.name}</strong>
                  <br />
                  <span style={{ color: '#555' }}>
                    {[selectedPlace.primaryType, selectedPlace.phoneNumber]
                      .filter(Boolean)
                      .join(' · ') || '상세는 아래 링크에서'}
                  </span>
                  <br />
                  {todayHours(selectedPlace) && (
                    <>
                      <TodayHoursLine place={selectedPlace} />
                      <br />
                    </>
                  )}
                  {selectedPlace.googleMapsUri ? (
                    <a
                      href={selectedPlace.googleMapsUri}
                      target="_blank"
                      rel="noopener noreferrer"
                      style={{ color: '#23399d', fontWeight: 600 }}
                    >
                      구글지도에서 보기 ↗
                    </a>
                  ) : (
                    <span style={{ color: '#888' }}>상세 정보 없음 😢</span>
                  )}
                </div>
              </InfoWindow>
            )}
            {/* 🎯 숙소 위치로 돌아오는 버튼 (구글맵 컨트롤 레이어 우상단에 얹는다) */}
            <MapControl position={ControlPosition.RIGHT_TOP}>
              <RecenterButton latitude={latitude} longitude={longitude} />
            </MapControl>
          </Map>
        </APIProvider>

        {/* 로딩 및 에러 처리 */}
        {isLoading && (
          <div className={styles.overlay}>
            <span className={styles.spinner} />
          </div>
        )}
        {error && !isLoading && <div className={styles.overlay}>{error}</div>}
      </div>
      )}
      {/* </div> */}
    </section>
  );
}
/// 🕐 오늘 요일 기준 영업시간 한 줄 추출 (weekdayDescriptions에서 "월요일: ..." 매칭)
function todayHours(p: PlaceDto): string | null {
  if (!p.weekdayDescriptions || p.weekdayDescriptions.length === 0) return null;
  // getDay(): 0=일 ~ 6=토
  const days = [
    '일요일',
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
  ];
  const today = days[new Date().getDay()];
  return p.weekdayDescriptions.find((d) => d.startsWith(today)) ?? null;
}

/// 🕐 오늘 영업시간 한 줄. 콤마(분리영업)는 줄바꿈하되, 둘째 줄부터 시간 시작 위치에 맞춰 정렬
function TodayHoursLine({ place }: { place: PlaceDto }) {
  const hours = todayHours(place);
  if (!hours) return null;
  const idx = hours.indexOf(':'); // "목요일: 시간들" → 라벨/본문 분리
  const label = idx >= 0 ? hours.slice(0, idx + 1) : ''; // "목요일:"
  const body = (idx >= 0 ? hours.slice(idx + 1) : hours).trim();
  const ranges = body.split(',').map((r) => r.trim()); // 콤마 제거 + 시간대 분리

  return (
    <span style={{ color: '#1a7f37', display: 'flex' }}>
      <span style={{ whiteSpace: 'nowrap' }}>🕐 {label}&nbsp;</span>
      <span style={{ display: 'flex', flexDirection: 'column' }}>
        {ranges.map((r, i) => (
          <span key={i}>{r}</span>
        ))}
      </span>
    </span>
  );
}

/// 🎯 클릭하면 숙소 위치로 부드럽게 이동하는 버튼 컴포넌트
function RecenterButton({
  latitude,
  longitude,
}: {
  latitude: number;
  longitude: number;
}) {
  const map = useMap(); // 👈 현재 켜져있는 구글 맵 객체를 가져오는 치트키야!

  const handleRecenter = () => {
    if (!map) return;

    // 지도의 중심을 숙소 좌표로 부드럽게(panTo) 이동시켜줘!
    map.panTo({ lat: latitude, lng: longitude });
    // 원한다면 줌 크기도 원래대로(15) 리셋 가능!
    map.setZoom(15);
  };

  return (
    <button
      type="button"
      onClick={handleRecenter}
      style={{
        margin: '10px',
        padding: '10px 14px',
        backgroundColor: '#ffffff',
        border: 'none',
        borderRadius: '8px',
        boxShadow: '0 2px 6px rgba(0,0,0,0.3)',
        cursor: 'pointer',
        fontSize: '14px',
        fontWeight: 'bold',
        color: '#333',
        display: 'flex',
        alignItems: 'center',
        gap: '4px',
      }}
    >
      🏠 숙소 위치로
    </button>
  );
}
