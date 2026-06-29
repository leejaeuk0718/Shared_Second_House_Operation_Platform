"use client";

import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import ReservationRouteMap from "@/app/my/reservations/components/ReservationRouteMap";

interface ReservationDto {
  id: number;
  accommodationId: number;
  accommodationName: string;
  accommodationAddress: string;
  startDate: string;
  endDate: string;
  status: "CONFIRMED" | "CANCELLED";
}

export default function ReservationsSection() {
  const [reservations, setReservations] = useState<ReservationDto[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .get<ReservationDto[]>("/api/stay/reservations")
      .then((data) => setReservations(Array.isArray(data) ? data : []))
      .catch((err) => console.log("예약 목록 조회 실패:", err))
      .finally(() => setLoading(false));
  }, []);

  const handleCancel = (id: number) => {
    if (!confirm("예약을 취소할까요?")) return;

    api
      .patch<boolean>(`/api/stay/reservations/${id}/cancel`, {})
      .then(() => {
        setReservations((prev) =>
          prev.map((r) => (r.id === id ? { ...r, status: "CANCELLED" } : r)),
        );
      })
      .catch(() => alert("예약 취소에 실패했어요. 다시 시도해주세요."));
  };

  const getStatusLabel = (r: ReservationDto) => {
    if (r.status === "CANCELLED")
      return { label: "취소됨", cls: "bg-[#F0EBE5] text-[#8C8178]" };
    if (new Date(r.endDate) < new Date())
      return { label: "지난 예약", cls: "bg-[#fef3c7] text-[#92400e]" };
    return { label: "예약 확정", cls: "bg-[#EAF3DE] text-[#3B6D11]" };
  };

  if (loading) {
    return (
      <div className="bg-white border border-[#E4DDD3] rounded-xl overflow-hidden">
        <div className="bg-[#3B6D11] px-5 py-3.5 flex items-center gap-2 text-white text-sm font-medium">
          <CalendarIcon />내 예약 목록
        </div>
        <div className="flex items-center justify-center py-16">
          <div className="w-6 h-6 border-2 border-[#3B6D11] border-t-transparent rounded-full animate-spin" />
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white border border-[#E4DDD3] rounded-xl overflow-hidden">
      {/* 헤더 */}
      <div className="bg-[#3B6D11] px-5 py-3.5 flex items-center justify-between">
        <div className="flex items-center gap-2 text-white text-sm font-medium">
          <CalendarIcon />내 예약 목록
        </div>
        <span className="text-xs text-white/60">{reservations.length}건</span>
      </div>

      {/* 목록 */}
      {reservations.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-[#8C8178]">
          <svg
            width="36"
            height="36"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.4"
            className="mb-3 opacity-40"
            aria-hidden="true"
          >
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
            <line x1="16" y1="2" x2="16" y2="6" />
            <line x1="8" y1="2" x2="8" y2="6" />
            <line x1="3" y1="10" x2="21" y2="10" />
          </svg>
          <p className="text-sm">예약 내역이 없어요.</p>
        </div>
      ) : (
        reservations.map((r, i) => {
          const { label, cls } = getStatusLabel(r);
          const isFuture =
            r.status === "CONFIRMED" && new Date(r.startDate) > new Date();

          return (
            <div
              key={r.id}
              className={`px-5 py-4 ${i < reservations.length - 1 ? "border-b border-[#F0EBE5]" : ""}`}
            >
              {/* 숙소명 + 상태 */}
              <div className="flex items-center justify-between mb-1">
                <h3 className="text-base font-medium text-[#2A2520]">
                  {r.accommodationName}
                </h3>
                <span
                  className={`text-xs px-2 py-0.5 rounded-full font-medium ${cls}`}
                >
                  {label}
                </span>
              </div>

              {/* 주소 */}
              <p className="text-xs text-[#8C8178] mb-3">
                {r.accommodationAddress}
              </p>

              {/* 날짜 */}
              <div className="flex items-center gap-2 text-xs text-[#171717] bg-[#F7F4EF] rounded-lg px-3 py-2 w-fit mb-3">
                <svg
                  width="13"
                  height="13"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  aria-hidden="true"
                >
                  <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
                  <line x1="16" y1="2" x2="16" y2="6" />
                  <line x1="8" y1="2" x2="8" y2="6" />
                  <line x1="3" y1="10" x2="21" y2="10" />
                </svg>
                <span>{r.startDate}</span>
                <span className="text-[#B5ADA4]">→</span>
                <span>{r.endDate}</span>
              </div>

              {/* 취소 버튼 (미래 확정 예약만) */}
              {isFuture && (
                <button
                  onClick={() => handleCancel(r.id)}
                  className="w-full h-10 text-sm text-red-500 border border-red-200 bg-red-50 rounded-lg hover:bg-red-100 transition-colors"
                >
                  예약 취소
                </button>
              )}
              {/* 이 예약 기간에 기록된 이동경로 지도 (경로 없으면 자동 숨김) */}
              <ReservationRouteMap
                accommodationId={r.accommodationId}
                startDate={r.startDate}
                endDate={r.endDate}
              />
            </div>
          );
        })
      )}
    </div>
  );
}

function CalendarIcon() {
  return (
    <svg
      width="17"
      height="17"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      aria-hidden="true"
    >
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
      <line x1="16" y1="2" x2="16" y2="6" />
      <line x1="8" y1="2" x2="8" y2="6" />
      <line x1="3" y1="10" x2="21" y2="10" />
    </svg>
  );
}
