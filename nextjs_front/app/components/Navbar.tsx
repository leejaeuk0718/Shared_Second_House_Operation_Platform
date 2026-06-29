"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import styles from "./Navbar.module.css";
import { tokenStorage } from "@/lib/token";
import { api } from "@/lib/api";
import { UserResp } from "@/types/auth";

export default function Navbar() {
  const router = useRouter();
  const pathname = usePathname();

  const [user, setUser] = useState<UserResp | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [authLoading, setAuthLoading] = useState(true);
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const [prevPathname, setPrevPathname] = useState(pathname);
  if (pathname !== prevPathname) {
    setPrevPathname(pathname);
    setIsMenuOpen(false);
  }

  useEffect(() => {
    const checkAuth = () => {
      const token = tokenStorage.get();
      if (!token) {
        setUser(null);
        setIsAdmin(false);
        setAuthLoading(false);
        return;
      }

      setAuthLoading(true);
      api
        .get<UserResp>("/api/users")
        .then((res) => {
          setUser(res);
          setIsAdmin(res.role === "ADMIN");
        })
        .catch(() => {
          setUser(null);
          setIsAdmin(false);
        })
        .finally(() => {
          setAuthLoading(false);
        });
    };

    checkAuth();

    window.addEventListener("auth-change", checkAuth);
    return () => window.removeEventListener("auth-change", checkAuth);
  }, []);

  const handleLogout = () => {
    tokenStorage.remove();
    setUser(null);
    setIsAdmin(false);
    router.push("/");
  };

  return (
    <>
      {isMenuOpen && (
        <div className={styles.overlay} onClick={() => setIsMenuOpen(false)} />
      )}
      <header className={styles.header}>
        <div className={styles.headerInner}>
          <Link href="/" className={styles.logo}>
            세컨하우스
          </Link>
          <button
            className={styles.hamburger}
            onClick={() => setIsMenuOpen((prev) => !prev)}
            aria-label="메뉴"
          >
            {isMenuOpen ? "✕" : "☰"}
          </button>
          <nav className={`${styles.nav} ${isMenuOpen ? styles.navOpen : ""}`}>
            <Link href="/accommodations" className={styles.navItem}>
              숙소 목록
            </Link>
            <Link href="/product" className={styles.navItem}>
              배달
            </Link>
            <Link href="/tours" className={styles.navItem}>
              관광지
            </Link>
            {isAdmin && (
              <Link href="/accommodations" className={styles.navItem}>
                숙소 등록
              </Link>
            )}
            <Link href="/mypage" className={styles.navItem}>
              마이페이지
            </Link>

            {isAdmin && (
              <Link
                href="/delivery"
                className={styles.navItem}
                style={{ color: "orange", fontWeight: "bold" }}
              >
                배달 관리 ★
              </Link>
            )}

            {/* 관리자 전용 — 구독 관리 페이지 */}
            {isAdmin && (
              <Link
                href="/admin/subscriptions"
                className={styles.navItem}
                style={{ color: "#3B6D11", fontWeight: "bold" }}
              >
                관리자 페이지
              </Link>
            )}

            {authLoading ? null : user ? (
              <>
                <span className={styles.navItem}>
                  {user.nickname}님 환영합니다 (ID: {user.userId})
                </span>
                <button className={styles.navItem} onClick={handleLogout}>
                  로그아웃
                </button>
              </>
            ) : (
              <Link href="/login" className={styles.navItem}>
                로그인
              </Link>
            )}
          </nav>
        </div>
      </header>
    </>
  );
}
