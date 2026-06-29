/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/my/reservations/components/ReservationRouteMap.tsx
 * 역할  : 예약 카드 밑에서 그 예약 기간에 기록된 이동경로를 Google Maps로 표시.
 *         - 기록된 경로가 없으면 "이동경로 보기" 버튼 자체를 렌더하지 않음
 *         - 지도는 줌15 + 숙소 중심으로 한 번만 마운트
 *         - 날짜 칩으로 날짜를 고르면 지도는 그대로 두고 경로(Polyline)만 다시 그림
 * 사용처 : app/my/reservations/page.tsx
 * ----------------------------------------------------------------------------------
 * [연관]
 * - Spring: GET /api/routes/sessions/detail?userId=&from=&to=  (세션+좌표)
 * - Spring: GET /api/stay/accommodations/{id}                  (숙소 좌표)
 * - Polyline은 @vis.gl에 컴포넌트가 없어 useMap()+google.maps.Polyline으로 그림
 * ==================================================================================
 */

"use client";

import { useEffect, useMemo, useState } from "react";
import {
  APIProvider,
  Map as GMap,
  useMap,
  useMapsLibrary,
} from "@vis.gl/react-google-maps";
import styles from "./ReservationRouteMap.module.css";
import { api } from "@/lib/api";

interface RoutePoint {
  lat: number;
  lng: number;
  recordedAt?: string | null;
}

interface RouteSessionDetail {
  sessionId: number;
  startedAt: string | null;
  endedAt: string | null;
  points: RoutePoint[];
}

interface LatLng {
  lat: number;
  lng: number;
}

interface Props {
  accommodationId: number;
  startDate: string; // yyyy-MM-dd
  endDate: string; // yyyy-MM-dd
}

// 세션별 색상 구분
const ROUTE_COLORS = ["#245B10", "#1565C0", "#C62828", "#6A1B9A", "#EF6C00"];

export default function ReservationRouteMap({
  accommodationId,
  startDate,
  endDate,
}: Props) {
  const [sessions, setSessions] = useState<RouteSessionDetail[] | null>(null);
  const [open, setOpen] = useState(false);
  const [mounted, setMounted] = useState(false); // 한 번이라도 펼친 적 있으면 true
  const [coord, setCoord] = useState<LatLng | null>(null);
  const [mapError, setMapError] = useState<string | null>(null);
  const [selectedDate, setSelectedDate] = useState<string | null>(null);

  // 1) 마운트 시 경로 데이터 로드 — 있어야만 버튼을 보여주므로 먼저 받아둔다.
  //    유저는 서버에서 JWT로 획득하므로 from~to 기간만 보낸다.
  useEffect(() => {
    let alive = true;
    api
      .get<RouteSessionDetail[]>(
        `/api/routes/sessions/detail?from=${startDate}&to=${endDate}`,
      )
      .then((data) => {
        if (alive) setSessions(Array.isArray(data) ? data : []);
      })
      .catch(() => {
        if (alive) setSessions([]);
      });
    return () => {
      alive = false;
    };
  }, [startDate, endDate]);

  // 날짜(yyyy-MM-dd)별로 세션 묶기 — 좌표 있는 세션만
  const dateGroups = useMemo(() => {
    const m = new Map<string, RouteSessionDetail[]>();
    (sessions ?? []).forEach((s) => {
      if (!s.points?.length) return;
      const d = (s.startedAt ?? "").slice(0, 10);
      if (!d) return;
      if (!m.has(d)) m.set(d, []);
      m.get(d)!.push(s);
    });
    return m;
  }, [sessions]);

  const availableDates = useMemo(
    () => [...dateGroups.keys()].sort(),
    [dateGroups],
  );

  // 선택 날짜 — 직접 고른 게 없거나 목록에 없으면 첫 날짜 (effect 없이 렌더에서 파생)
  const effectiveDate =
    selectedDate && availableDates.includes(selectedDate)
      ? selectedDate
      : (availableDates[0] ?? null);

  // 선택 날짜의 세션만 (참조 안정화 → 같은 날짜면 폴리라인 재생성 안 함)
  const selectedSessions = useMemo(
    () => (effectiveDate ? (dateGroups.get(effectiveDate) ?? []) : []),
    [dateGroups, effectiveDate],
  );

  // 펼칠 때 숙소 좌표를 한 번만 로드 (지도 중심용)
  const openMap = () => {
    setOpen(true);
    setMounted(true); // 이후로는 닫아도 언마운트하지 않음
    if (coord === null && !mapError) {
      api
        .get<{ latitude?: number; longitude?: number }>(
          `/api/stay/accommodations/${accommodationId}`,
        )
        .then((d) => {
          const lat = d?.latitude;
          const lng = d?.longitude;
          if (typeof lat === "number" && typeof lng === "number") {
            setCoord({ lat, lng });
          } else {
            setMapError("숙소 위치 정보가 없어요.");
          }
        })
        .catch(() => setMapError("숙소 위치를 불러오지 못했어요."));
    }
  };

  // 기록된 이동경로가 없으면 버튼 자체를 그리지 않는다.
  if (!sessions || availableDates.length === 0) return null;

  return (
    <div className={styles.wrap}>
      <button
        type="button"
        className={styles.toggle}
        onClick={() => (open ? setOpen(false) : openMap())}
      >
        {open ? "이동경로 숨기기 ▴" : "이동경로 보기 ▾"}
      </button>

      {/* 한 번 펼친 뒤엔 언마운트하지 않고 숨기기만 한다(지도 재마운트 비용 방지) */}
      {mounted && (
        <div className={open ? styles.body : `${styles.body} ${styles.hidden}`}>
          {/* 날짜 선택 칩 — 누르면 지도는 그대로, 경로만 교체 */}
          <div className={styles.dates}>
            {availableDates.map((d) => (
              <button
                key={d}
                type="button"
                className={
                  d === effectiveDate
                    ? `${styles.dateChip} ${styles.dateChipActive}`
                    : styles.dateChip
                }
                onClick={() => setSelectedDate(d)}
              >
                {dateLabel(d)}
              </button>
            ))}
          </div>

          {mapError && <div className={styles.msg}>{mapError}</div>}

          {!mapError && !coord && (
            <div className={styles.msg}>지도 불러오는 중...</div>
          )}

          {/* 숙소 좌표가 준비되면 지도를 한 번만 마운트 (줌15·숙소 중심) */}
          {coord && (
            <APIProvider apiKey={process.env.NEXT_PUBLIC_GOOGLE_MAP_KEY || ""}>
              <GMap
                className={styles.map}
                defaultZoom={15}
                defaultCenter={coord}
                mapId={process.env.NEXT_PUBLIC_GOOGLE_MAP_ID || "DEMO_MAP_ID"}
                gestureHandling="greedy"
                disableDefaultUI
                zoomControl
                scrollwheel={false} // 1. 휠로 확대되는 건 끈다! (스크롤 방해 금지)
              >
                <RoutePolylines sessions={selectedSessions} />
              </GMap>
            </APIProvider>
          )}
        </div>
      )}
    </div>
  );
}

// "2026-06-24" -> "6/24"
function dateLabel(d: string) {
  const [, m, day] = d.split("-");
  return `${Number(m)}/${Number(day)}`;
}

/**
 * 선택된 세션들의 Polyline만 지도에 그린다.
 * 지도 중심/줌은 숙소 기준(줌15)으로 고정하고 fit은 하지 않는다.
 * sessions가 바뀔 때만 이전 선을 지우고 다시 그린다(지도 자체는 유지).
 */
function RoutePolylines({ sessions }: { sessions: RouteSessionDetail[] }) {
  const map = useMap();
  const mapsLib = useMapsLibrary("maps"); // google.maps가 로드됐는지 보장

  useEffect(() => {
    if (!map || !mapsLib) return;

    const lines: google.maps.Polyline[] = [];
    sessions.forEach((s, i) => {
      if (!s.points?.length) return;
      lines.push(
        new google.maps.Polyline({
          path: s.points.map((p) => ({ lat: p.lat, lng: p.lng })),
          strokeColor: ROUTE_COLORS[i % ROUTE_COLORS.length],
          strokeWeight: 5,
          strokeOpacity: 0.9,
          map,
        }),
      );
    });

    // 날짜 변경/언마운트 시 기존 선 제거 후 다시 그림
    return () => lines.forEach((l) => l.setMap(null));
  }, [map, mapsLib, sessions]);

  return null;
}
