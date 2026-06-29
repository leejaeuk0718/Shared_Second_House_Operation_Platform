"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import AuthLayout from "@/components/auth/AuthLayout";
import { AuthResp } from "@/types/auth";
import { tokenStorage } from "@/lib/token"; // 추가

export default function LoginPage() {
  const router = useRouter();
  const [form, setForm] = useState({ username: "", password: "" });
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
    setError("");
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080"}/api/users/login`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" }, // JSON으로 변경
          credentials: "include", // refresh_token 쿠키 자동 수신
          body: JSON.stringify({
            username: form.username,
            password: form.password,
          }),
        },
      );

      if (!res.ok) throw new Error("아이디 또는 비밀번호가 올바르지 않아요.");

      const data: AuthResp = await res.json();
      tokenStorage.set(data.accessToken); // 이걸로 교체
      router.push("/");
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "로그인에 실패했어요.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout
      headline={`머릿속에만 그리던\n별장 생활`}
      subline="지금, 세컨 하우스에서 시작해요"
    >
      <h1 className="text-2xl font-medium text-[#1E2D14] leading-snug mb-1">
        다시 만나서
        <br />
        반가워요
      </h1>
      <p className="text-sm text-[#9BA88D] mb-7">
        로그인하고 두 번째 집을 예약하세요
      </p>

      <form onSubmit={handleSubmit} className="flex flex-col gap-3">
        {/* 아이디 */}
        <div>
          <label className="block text-xs text-[#7A8F6A] mb-1">아이디</label>

          <div className="flex items-center gap-2 h-11 bg-[#F2F7EC] border border-[#D6E4C8] rounded-lg px-3 focus-within:border-[#3B6D11] focus-within:bg-white transition-colors">
            <svg
              width="15"
              height="15"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#A8B89A"
              strokeWidth="1.8"
              aria-hidden="true"
            >
              <circle cx="12" cy="8" r="4" />
              <path d="M4 20c0-4 3.5-7 8-7s8 3 8 7" />
            </svg>

            <input
              type="text"
              name="username"
              value={form.username}
              onChange={handleChange}
              placeholder="아이디를 입력하세요"
              required
              className="flex-1 bg-transparent text-sm text-[#1E2D14] placeholder:text-[#A8B89A] outline-none"
            />
          </div>
        </div>

        {/* 비밀번호 */}
        <div>
          <label className="block text-xs text-[#7A8F6A] mb-1">비밀번호</label>
          <div className="flex items-center gap-2 h-11 bg-[#F2F7EC] border border-[#D6E4C8] rounded-lg px-3 focus-within:border-[#3B6D11] focus-within:bg-white transition-colors">
            <svg
              width="15"
              height="15"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#A8B89A"
              strokeWidth="1.8"
              aria-hidden="true"
            >
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            <input
              type={showPassword ? "text" : "password"}
              name="password"
              value={form.password}
              onChange={handleChange}
              placeholder="비밀번호를 입력하세요"
              required
              className="flex-1 bg-transparent text-sm text-[#1E2D14] placeholder:text-[#A8B89A] outline-none"
            />
            <button
              type="button"
              onClick={() => setShowPassword((v) => !v)}
              aria-label={showPassword ? "비밀번호 숨기기" : "비밀번호 보기"}
              className="text-[#A8B89A] hover:text-[#3B6D11] transition-colors"
            >
              <svg
                width="15"
                height="15"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.8"
              >
                {showPassword ? (
                  <>
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94" />
                    <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" />
                    <line x1="1" y1="1" x2="23" y2="23" />
                  </>
                ) : (
                  <>
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                    <circle cx="12" cy="12" r="3" />
                  </>
                )}
              </svg>
            </button>
          </div>
        </div>

        {/* 에러 메시지 */}
        {error && <p className="text-xs text-red-500">{error}</p>}

        {/* 비밀번호 찾기 */}
        <div className="text-right -mt-1">
          <Link
            href="/forgot-password"
            className="text-xs text-[#3B6D11] hover:underline"
          >
            비밀번호를 잊으셨나요?
          </Link>
        </div>

        {/* 로그인 버튼 */}
        <button
          type="submit"
          disabled={loading}
          className="w-full h-11 bg-[#3B6D11] hover:bg-[#2D5509] text-white text-sm font-medium rounded-lg transition-colors disabled:opacity-60"
        >
          {loading ? "로그인 중..." : "로그인"}
        </button>
      </form>

      {/* 소셜 로그인 */}
      <div className="flex items-center gap-3 my-4">
        <div className="flex-1 h-px bg-[#E0EAD4]" />
        <span className="text-xs text-[#B0BEA0]">소셜 로그인</span>
        <div className="flex-1 h-px bg-[#E0EAD4]" />
      </div>

      <div className="flex gap-2">
        <a
          href={`${process.env.NEXT_PUBLIC_API_URL}/oauth2/authorization/google`}
          className="flex-1 h-10 flex items-center justify-center gap-2 bg-white border border-[#E0EAD4] text-[#444] text-xs font-medium rounded-lg hover:bg-gray-50 transition"
        >
          <svg width="15" height="15" viewBox="0 0 24 24" aria-hidden="true">
            <path
              fill="#4285F4"
              d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
            />
            <path
              fill="#34A853"
              d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
            />
            <path
              fill="#FBBC05"
              d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"
            />
            <path
              fill="#EA4335"
              d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84z"
            />
          </svg>
          구글
        </a>

        <a
          href={`${process.env.NEXT_PUBLIC_API_URL}/oauth2/authorization/naver`}
          className="flex-1 h-10 flex items-center justify-center gap-2 bg-[#03C75A] text-white text-xs font-medium rounded-lg hover:brightness-95 transition"
        >
          <span className="font-bold text-sm">N</span>
          네이버
        </a>
      </div>

      <p className="text-xs text-[#B0BEA0] text-center mt-5">
        아직 계정이 없으신가요?{" "}
        <Link
          href="/signup"
          className="text-[#3B6D11] font-medium hover:underline"
        >
          회원가입
        </Link>
      </p>
    </AuthLayout>
  );
}
