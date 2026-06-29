"use client";

import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import styles from "./FloatingChatbot.module.css";
import ChatWindow, { STORAGE_KEY } from "./ChatWindow";
import { tokenStorage } from "@/lib/token";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080";

/// 🟦 모든 페이지 우하단에 고정되는 플로팅 챗봇 위젯.
/// 버튼을 누르면 페이지 이동 없이 그 자리에서 챗봇창이 열린다.
export default function FloatingChatbot() {
  const [open, setOpen] = useState(false);
  // 로그인 상태일 때만 챗봇 버튼을 노출한다.
  // 블랙리스트 여부는 서버만 알 수 있으므로 /api/users 호출 성공 여부로 판단한다.
  // 공개 페이지에도 깔리는 위젯이라 api 헬퍼(401 시 /login 리다이렉트) 대신
  // 직접 fetch로 호출해 401이면 조용히 버튼만 숨긴다.
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  // 챗봇은 layout에 있어 앱 전체에서 한 번만 마운트되므로, 로그인 후
  // 클라이언트 네비게이션(/login → /)으로는 useEffect가 재실행되지 않는다.
  // pathname을 의존성으로 두어 경로가 바뀔 때마다 로그인 상태를 다시 확인한다.
  const pathname = usePathname();

  useEffect(() => {
    let active = true; // 경로가 빠르게 바뀔 때 이전 요청의 늦은 응답이 상태를 덮어쓰지 않도록 가드

    // 로그인 여부를 반영한다. 비로그인이면 버튼을 숨기고, 이전 사용자의 챗봇
    // 대화(sessionStorage)도 비워 다음 로그인 시 깨끗한 상태로 시작하게 한다.
    const apply = (loggedIn: boolean) => {
      if (!active) return;
      setIsLoggedIn(loggedIn);
      if (!loggedIn) {
        sessionStorage.removeItem(STORAGE_KEY);
        setOpen(false);
      }
    };

    const verify = async () => {
      const token = tokenStorage.get();
      if (!token) {
        apply(false); // 토큰 없음(로그아웃 등) → 버튼 숨김 + 대화 비움
        return;
      }
      try {
        const res = await fetch(`${BASE_URL}/api/users`, {
          headers: { Authorization: `Bearer ${token}` },
          credentials: "include",
        });
        apply(res.ok); // 200이면 노출, 401(블랙리스트 등)이면 숨김 + 대화 비움
      } catch {
        apply(false);
      }
    };

    verify();
    return () => {
      active = false;
    };
  }, [pathname]);

  if (!isLoggedIn) return null;

  return (
    <>
      {open && (
        <div className={styles.panel}>
          <ChatWindow onClose={() => setOpen(false)} />
        </div>
      )}

      <button
        type="button"
        className={styles.fab}
        onClick={() => setOpen((v) => !v)}
        aria-label={open ? "챗봇 닫기" : "챗봇 열기"}
      >
        {open ? "✕" : "💬"}
      </button>
    </>
  );
}
