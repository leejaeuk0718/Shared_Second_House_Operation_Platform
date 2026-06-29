"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/lib/api";
import { UserResp } from "@/types/auth";
import {
  SubscriptionsUserResp,
  SubscriptionStatus,
} from "@/types/subscription";

const STATUS_LABEL: Record<SubscriptionStatus, string> = {
  PENDING: "승인 대기",
  ACTIVE: "구독 중",
  EXPIRED: "만료",
  CANCELLED: "취소",
};

const STATUS_BADGE: Record<SubscriptionStatus, string> = {
  PENDING: "bg-amber-50 text-amber-700",
  ACTIVE: "bg-[#EAF3DE] text-[#3B6D11]",
  EXPIRED: "bg-gray-100 text-gray-500",
  CANCELLED: "bg-red-50 text-red-600",
};

export default function AdminSubscriptionsPage() {
  const router = useRouter();
  const [authChecked, setAuthChecked] = useState(false);
  const [list, setList] = useState<SubscriptionsUserResp[]>([]);
  const [loading, setLoading] = useState(true);

  const [username, setUsername] = useState("");
  const [status, setStatus] = useState<SubscriptionStatus | "">("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");

  const fetchList = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (username) params.set("username", username);
      if (status) params.set("status", status);
      if (startDate) params.set("startDate", startDate);
      if (endDate) params.set("endDate", endDate);

      const data = await api.get<SubscriptionsUserResp[]>(
        `/api/subscriptions/admin/search?${params.toString()}`,
      );
      setList(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [username, status, startDate, endDate]);

  useEffect(() => {
    api
      .get<UserResp>("/api/users")
      .then((user) => {
        if (user.role !== "ADMIN") {
          router.replace("/");
          return;
        }
        setAuthChecked(true);
        fetchList();
      })
      .catch(() => router.replace("/login"));
  }, [router, fetchList]);

  // 👍 PUT으로 수정 (백엔드가 @PutMapping이므로 메서드를 맞춰줌)
  const handleApprove = async (id: number) => {
    if (!confirm("이 구독을 승인하시겠어요?")) return;
    await api.put(`/api/subscriptions/admin/${id}/approve`, {});
    fetchList();
  };

  const handleReject = async (id: number) => {
    if (!confirm("이 구독을 반려하시겠어요?")) return;
    await api.put(`/api/subscriptions/admin/${id}/reject`, {});
    fetchList();
  };

  const stats = {
    PENDING: list.filter((s) => s.status === "PENDING").length,
    ACTIVE: list.filter((s) => s.status === "ACTIVE").length,
    EXPIRED: list.filter((s) => s.status === "EXPIRED").length,
    CANCELLED: list.filter((s) => s.status === "CANCELLED").length,
  };

  if (!authChecked) {
    return (
      <div className="w-full h-screen flex items-center justify-center bg-[#F7F4EF]">
        <div className="w-8 h-8 border-2 border-[#3B6D11] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F7F4EF] p-8">
      <div className="max-w-6xl mx-auto">
        <div className="mb-5">
          <h1 className="text-lg font-medium text-[#2A2520]">구독 관리</h1>
          <p className="text-sm text-[#8C8178] mt-0.5">
            전체 구독 신청 현황을 확인하고 승인/반려할 수 있어요
          </p>
        </div>

        <div className="grid grid-cols-4 gap-3 mb-5">
          <div className="bg-white border border-[#E4DDD3] rounded-lg p-4">
            <p className="text-xs text-[#8C8178] mb-1">승인 대기</p>
            <p className="text-2xl font-medium text-[#2A2520]">
              {stats.PENDING}
            </p>
          </div>
          <div className="bg-white border border-[#E4DDD3] rounded-lg p-4">
            <p className="text-xs text-[#8C8178] mb-1">구독 중</p>
            <p className="text-2xl font-medium text-[#2A2520]">
              {stats.ACTIVE}
            </p>
          </div>
          <div className="bg-white border border-[#E4DDD3] rounded-lg p-4">
            <p className="text-xs text-[#8C8178] mb-1">만료</p>
            <p className="text-2xl font-medium text-[#2A2520]">
              {stats.EXPIRED}
            </p>
          </div>
          <div className="bg-white border border-[#E4DDD3] rounded-lg p-4">
            <p className="text-xs text-[#8C8178] mb-1">취소</p>
            <p className="text-2xl font-medium text-[#2A2520]">
              {stats.CANCELLED}
            </p>
          </div>
        </div>

        <div className="flex gap-2 mb-4 flex-wrap">
          <input
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="아이디 검색"
            className="h-9 px-3 text-sm border border-[#D6E4C8] rounded-lg outline-none focus:border-[#3B6D11] w-40"
          />
          <select
            value={status}
            onChange={(e) =>
              setStatus(e.target.value as SubscriptionStatus | "")
            }
            className="h-9 px-3 text-sm border border-[#D6E4C8] rounded-lg outline-none focus:border-[#3B6D11] w-32 bg-white"
          >
            <option value="">전체 상태</option>
            <option value="PENDING">승인 대기</option>
            <option value="ACTIVE">구독 중</option>
            <option value="EXPIRED">만료</option>
            <option value="CANCELLED">취소</option>
          </select>
          <input
            type="date"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            className="h-9 px-3 text-sm border border-[#D6E4C8] rounded-lg outline-none focus:border-[#3B6D11] w-36"
          />
          <span className="flex items-center text-sm text-[#8C8178]">~</span>
          <input
            type="date"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
            className="h-9 px-3 text-sm border border-[#D6E4C8] rounded-lg outline-none focus:border-[#3B6D11] w-36"
          />
          <button
            onClick={fetchList}
            className="h-9 px-4 text-sm font-medium bg-[#3B6D11] text-white rounded-lg hover:bg-[#2D5509]"
          >
            검색
          </button>
        </div>

        <div className="bg-white border border-[#E4DDD3] rounded-xl overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-[#F7F4EF]">
                <th className="text-left text-xs text-[#8C8178] font-medium px-4 py-2.5">
                  구독ID
                </th>
                <th className="text-left text-xs text-[#8C8178] font-medium px-4 py-2.5">
                  아이디
                </th>
                <th className="text-left text-xs text-[#8C8178] font-medium px-4 py-2.5">
                  숙소ID
                </th>
                <th className="text-left text-xs text-[#8C8178] font-medium px-4 py-2.5">
                  기간
                </th>
                <th className="text-left text-xs text-[#8C8178] font-medium px-4 py-2.5">
                  시작일
                </th>
                <th className="text-left text-xs text-[#8C8178] font-medium px-4 py-2.5">
                  종료일
                </th>
                <th className="text-left text-xs text-[#8C8178] font-medium px-4 py-2.5">
                  상태
                </th>
                <th className="text-left text-xs text-[#8C8178] font-medium px-4 py-2.5">
                  신청일
                </th>
                <th className="text-left text-xs text-[#8C8178] font-medium px-4 py-2.5">
                  처리
                </th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={9} className="text-center py-10 text-[#8C8178]">
                    불러오는 중...
                  </td>
                </tr>
              ) : list.length === 0 ? (
                <tr>
                  <td colSpan={9} className="text-center py-10 text-[#8C8178]">
                    조건에 맞는 구독이 없어요.
                  </td>
                </tr>
              ) : (
                list.map((sub) => (
                  <tr
                    key={sub.subscriptionId}
                    className="border-t border-[#F0EBE5]"
                  >
                    <td className="px-4 py-3 text-[#2A2520]">
                      #{sub.subscriptionId}
                    </td>
                    <td className="px-4 py-3 text-[#2A2520]">{sub.username}</td>
                    <td className="px-4 py-3 text-[#2A2520]">
                      {sub.accommodationId}
                    </td>
                    <td className="px-4 py-3 text-[#2A2520]">
                      {sub.durationMonths}개월
                    </td>
                    <td className="px-4 py-3 text-[#8C8178]">
                      {sub.startDate}
                    </td>
                    <td className="px-4 py-3 text-[#8C8178]">{sub.endDate}</td>
                    <td className="px-4 py-3">
                      <span
                        className={`text-xs px-2.5 py-1 rounded-full font-medium ${STATUS_BADGE[sub.status]}`}
                      >
                        {STATUS_LABEL[sub.status]}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-[#8C8178]">
                      {new Date(sub.createdAt).toLocaleDateString("ko-KR")}
                    </td>
                    <td className="px-4 py-3">
                      {sub.status === "PENDING" ? (
                        <div className="flex gap-1.5">
                          <button
                            onClick={() => handleApprove(sub.subscriptionId)}
                            className="text-xs px-3 py-1.5 rounded-lg bg-[#3B6D11] text-white font-medium hover:bg-[#2D5509]"
                          >
                            승인
                          </button>
                          <button
                            onClick={() => handleReject(sub.subscriptionId)}
                            className="text-xs px-3 py-1.5 rounded-lg bg-white text-red-600 border border-red-200 font-medium hover:bg-red-50"
                          >
                            반려
                          </button>
                        </div>
                      ) : (
                        <span className="text-xs text-[#8C8178]">상세보기</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
