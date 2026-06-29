"use client";

import { useState, useEffect } from "react";
// import { useRouter } from "next/navigation"; // 변경 전
import { useRouter, useSearchParams } from "next/navigation"; // useSearchParams 추가: URL ?tab= 파라미터로 초기 탭 지정
import Link from "next/link";
import { api } from "@/lib/api";
import { tokenStorage } from "@/lib/token";
import { UserResp } from "@/types/auth";
import ProfileSection from "@/components/mypage/ProfileSection";
import SecuritySection from "@/components/mypage/SecuritySection";
import DeleteAccountSection from "@/components/mypage/DeleteAccountSection";
import ReservationsSection from "@/components/mypage/ReservationsSection";
import SubscriptionsSection from "@/components/mypage/SubscriptionsSection";

type Menu = "profile" | "password" | "reservations" | "subscriptions" | "delete";

export default function MyPage() {
  const router = useRouter();
  const [user, setUser] = useState<UserResp | null>(null);
  const [loading, setLoading] = useState(true);
  const searchParams = useSearchParams(); // URL ?tab= 파라미터 읽기
  // const [activeMenu, setActiveMenu] = useState<Menu>("profile"); // 변경 전: 항상 profile 탭으로 시작
  const [activeMenu, setActiveMenu] = useState<Menu>(
    (searchParams.get("tab") as Menu) ?? "profile" // ?tab=reservations 등으로 초기 탭 지정 가능
  );

  useEffect(() => {
    api
      .get<UserResp>("/api/users")
      .then(setUser)
      .catch(() => router.push("/login"))
      .finally(() => setLoading(false));
  }, [router]);

  const handleLogout = async () => {
    try {
      await api.post("/api/users/logout", {});
    } finally {
      tokenStorage.remove();
      router.push("/login");
    }
  };

  const refreshUser = async () => {
    const updated = await api.get<UserResp>("/api/users");
    setUser(updated);
  };

  if (loading) {
    return (
      <div className="w-full h-screen flex items-center justify-center bg-[#F7F4EF]">
        <div className="w-8 h-8 border-2 border-[#3B6D11] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!user) return null;

  const initials = user.nickname?.charAt(0) ?? user.username?.charAt(0) ?? "?";

  return (
    <div className="min-h-screen bg-[#F7F4EF]">
      {/* 상단 네비게이션 */}
      <header className="bg-white border-b border-[#E4DDD3] px-8 py-4 flex items-center justify-between">
        <Link
          href="/"
          className="text-[#3B6D11] text-sm font-semibold tracking-widest"
        >
          SECOND HOUSE
        </Link>
        <span className="text-sm text-[#8C8178]">{user.nickname}님</span>
      </header>

      <div className="max-w-5xl mx-auto px-6 py-8 grid grid-cols-[220px_1fr] gap-6">
        {/* 사이드바 */}
        <aside className="flex flex-col gap-1.5">
          {/* 프로필 요약 */}
          <div className="bg-white border border-[#E4DDD3] rounded-xl p-5 text-center mb-2">
            <div className="w-16 h-16 rounded-full bg-[#EAF3DE] flex items-center justify-center mx-auto mb-3 text-2xl font-medium text-[#3B6D11]">
              {initials}
            </div>
            <p className="text-sm font-medium text-[#2A2520]">
              {user.nickname}
            </p>
            <p className="text-xs text-[#8C8178] mt-0.5">{user.email}</p>
          </div>

          {/* 메뉴 */}
          <button
            onClick={() => setActiveMenu("profile")}
            className={`flex items-center gap-2 px-3 py-2.5 rounded-lg text-sm transition-colors text-left ${
              activeMenu === "profile"
                ? "bg-[#EAF3DE] text-[#3B6D11] font-medium"
                : "text-[#8C8178] hover:bg-[#F7F4EF]"
            }`}
          >
            <svg
              width="17"
              height="17"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.8"
              aria-hidden="true"
            >
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
            내 프로필
          </button>

          <button
            onClick={() => setActiveMenu("password")}
            className={`flex items-center gap-2 px-3 py-2.5 rounded-lg text-sm transition-colors text-left ${
              activeMenu === "password"
                ? "bg-[#EAF3DE] text-[#3B6D11] font-medium"
                : "text-[#8C8178] hover:bg-[#F7F4EF]"
            }`}
          >
            <svg
              width="17"
              height="17"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.8"
              aria-hidden="true"
            >
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            비밀번호 변경
          </button>

          <button
            onClick={() => setActiveMenu("reservations")}
            className={`flex items-center gap-2 px-3 py-2.5 rounded-lg text-sm transition-colors text-left ${
              activeMenu === "reservations"
                ? "bg-[#EAF3DE] text-[#3B6D11] font-medium"
                : "text-[#8C8178] hover:bg-[#F7F4EF]"
            }`}
          >
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
            내 예약
          </button>

          <button
            onClick={() => setActiveMenu("subscriptions")}
            className={`flex items-center gap-2 px-3 py-2.5 rounded-lg text-sm transition-colors text-left ${
              activeMenu === "subscriptions"
                ? "bg-[#EAF3DE] text-[#3B6D11] font-medium"
                : "text-[#8C8178] hover:bg-[#F7F4EF]"
            }`}
          >
            <svg
              width="17"
              height="17"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.8"
              aria-hidden="true"
            >
              <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
              <polyline points="9 22 9 12 15 12 15 22" />
            </svg>
            내 구독
          </button>

          <div className="h-px bg-[#E4DDD3] my-2" />

          <button
            onClick={() => setActiveMenu("delete")}
            className={`flex items-center gap-2 px-3 py-2.5 rounded-lg text-sm transition-colors text-left ${
              activeMenu === "delete"
                ? "bg-red-50 text-red-500 font-medium"
                : "text-[#8C8178] hover:bg-[#F7F4EF]"
            }`}
          >
            <svg
              width="17"
              height="17"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.8"
              aria-hidden="true"
            >
              <polyline points="3 6 5 6 21 6" />
              <path d="M19 6l-1 14H6L5 6" />
              <path d="M10 11v6M14 11v6" />
              <path d="M9 6V4h6v2" />
            </svg>
            회원 탈퇴
          </button>

          <div className="h-px bg-[#E4DDD3] my-2" />

          <button
            onClick={handleLogout}
            className="flex items-center gap-2 px-3 py-2 text-sm text-[#8C8178] hover:text-[#2A2520] transition-colors"
          >
            <svg
              width="17"
              height="17"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.8"
              aria-hidden="true"
            >
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
              <polyline points="16 17 21 12 16 7" />
              <line x1="21" y1="12" x2="9" y2="12" />
            </svg>
            로그아웃
          </button>
        </aside>

        {/* 메인 콘텐츠 */}
        <main>
          {activeMenu === "profile" && (
            <ProfileSection user={user} onUpdate={refreshUser} />
          )}
          {activeMenu === "password" && <SecuritySection />}
          {activeMenu === "reservations" && <ReservationsSection />}
          {activeMenu === "subscriptions" && <SubscriptionsSection />}
          {activeMenu === "delete" && <DeleteAccountSection />}
        </main>
      </div>
    </div>
  );
}
