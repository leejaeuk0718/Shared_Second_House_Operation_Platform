"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import AuthLayout from "@/components/auth/AuthLayout";
import { api } from "@/lib/api";
import { SignupReq } from "@/types/auth";

// 유효성 검사 패턴 (백엔드와 동일하게)
const PATTERNS = {
  username: /^[a-zA-Z0-9]{4,20}$/,
  password: /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@#$%^&+=!])(?!.*\s).{8,16}$/,
  nickname: /^[가-힣a-zA-Z0-9]{2,10}$/,
  email: /\w+@\w+\.\w+(\.\w+)?/,
  phoneNumber: /^01(?:0|1|[6-9])[0-9]{7,8}$/,
};

export default function SignupPage() {
  const router = useRouter();
  const [step, setStep] = useState(1); // 1단계, 2단계
  const [form, setForm] = useState({
    username: "",
    password: "",
    passwordConfirm: "",
    nickname: "",
    email: "",
    phoneNumber: "",
  });
  const [showPassword, setShowPassword] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
    setErrors((prev) => ({ ...prev, [e.target.name]: "" }));
  };

  // 1단계 유효성 검사
  const validateStep1 = () => {
    const errs: Record<string, string> = {};
    if (!PATTERNS.username.test(form.username))
      errs.username = "아이디는 특수문자를 제외한 4~20자로 입력해 주세요.";
    if (!PATTERNS.password.test(form.password))
      errs.password =
        "비밀번호는 영문, 숫자, 특수문자를 모두 포함해 주세요. (8~16자)";
    if (form.password !== form.passwordConfirm)
      errs.passwordConfirm = "비밀번호가 일치하지 않아요.";
    return errs;
  };

  // 2단계 유효성 검사
  const validateStep2 = () => {
    const errs: Record<string, string> = {};
    if (!form.nickname.trim()) errs.nickname = "닉네임을 입력해 주세요.";
    if (!PATTERNS.nickname.test(form.nickname))
      errs.nickname = "닉네임은 2~10자의 한글, 영문, 숫자만 입력해 주세요.";
    if (!PATTERNS.email.test(form.email))
      errs.email = "올바른 이메일 형식이 아니에요.";
    if (!PATTERNS.phoneNumber.test(form.phoneNumber))
      errs.phoneNumber =
        "올바른 휴대폰 번호 형식이 아니에요. (예: 01012345678)";
    return errs;
  };

  const handleNextStep = () => {
    const errs = validateStep1();
    if (Object.keys(errs).length > 0) {
      setErrors(errs);
      return;
    }
    setStep(2);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const errs = validateStep2();
    if (Object.keys(errs).length > 0) {
      setErrors(errs);
      return;
    }

    setLoading(true);
    try {
      await api.post("/api/users", {
        username: form.username,
        password: form.password,
        nickname: form.nickname,
        email: form.email,
        phoneNumber: form.phoneNumber,
      } satisfies SignupReq);

      router.push("/login?registered=true");
    } catch (err: unknown) {
      setErrors({
        submit: err instanceof Error ? err.message : "회원가입에 실패했어요.",
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout
      headline={`함께 쓰는\n두 번째 집`}
      subline="부산 · 제주 · 강원 · 전국의 별장에서 특별한 추억을 만들어 보세요 나중에 사용할 지역 적기"
    >
      <h1 className="text-2xl font-medium text-[#1E2D14] leading-snug mb-1">
        계정 만들기
      </h1>
      <p className="text-sm text-[#9BA88D] mb-5">두 번째 집을 함께 시작해요</p>

      {/* 스텝 인디케이터 */}
      <div className="flex gap-1.5 mb-5">
        <div className="h-[3px] w-7 rounded-full bg-[#3B6D11]" />
        <div
          className={`h-[3px] w-7 rounded-full transition-colors ${step === 2 ? "bg-[#3B6D11]" : "bg-[#E0EAD4]"}`}
        />
      </div>

      {/* ───── 1단계 ───── */}
      {step === 1 && (
        <>
          {/* 소셜 가입 */}
          <div className="flex gap-2 mb-4">
            <a
              href={`${process.env.NEXT_PUBLIC_API_URL}/oauth2/authorization/google`}
              className="flex-1 h-10 flex items-center justify-center gap-2 bg-white border border-[#E0EAD4] text-[#444] text-xs font-medium rounded-lg hover:bg-gray-50 transition"
            >
              <svg
                width="15"
                height="15"
                viewBox="0 0 24 24"
                aria-hidden="true"
              >
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
              구글로 가입
            </a>
            <a
              href={`${process.env.NEXT_PUBLIC_API_URL}/oauth2/authorization/naver`}
              className="flex-1 h-10 flex items-center justify-center gap-2 bg-[#03C75A] text-white text-xs font-medium rounded-lg hover:brightness-95 transition"
            >
              <span className="font-bold text-sm">N</span>
              네이버로 가입
            </a>
          </div>

          <div className="flex items-center gap-3 mb-4">
            <div className="flex-1 h-px bg-[#E0EAD4]" />
            <span className="text-xs text-[#B0BEA0]">또는 이메일로 가입</span>
            <div className="flex-1 h-px bg-[#E0EAD4]" />
          </div>

          <div className="flex flex-col gap-3">
            {/* 아이디 */}
            <div>
              <label className="block text-xs text-[#7A8F6A] mb-1">
                아이디
              </label>
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
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                  <circle cx="12" cy="7" r="4" />
                </svg>
                <input
                  type="text"
                  name="username"
                  value={form.username}
                  onChange={handleChange}
                  placeholder="영문+숫자 4~20자"
                  className="flex-1 bg-transparent text-sm text-[#1E2D14] placeholder:text-[#A8B89A] outline-none"
                />
              </div>
              {errors.username && (
                <p className="text-xs text-red-500 mt-1">{errors.username}</p>
              )}
            </div>

            {/* 비밀번호 */}
            <div>
              <label className="block text-xs text-[#7A8F6A] mb-1">
                비밀번호
              </label>
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
                  placeholder="영문+숫자+특수문자 8~16자"
                  className="flex-1 bg-transparent text-sm text-[#1E2D14] placeholder:text-[#A8B89A] outline-none"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label="비밀번호 보기"
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
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                    <circle cx="12" cy="12" r="3" />
                  </svg>
                </button>
              </div>
              {errors.password && (
                <p className="text-xs text-red-500 mt-1">{errors.password}</p>
              )}
            </div>

            {/* 비밀번호 확인 */}
            <div>
              <label className="block text-xs text-[#7A8F6A] mb-1">
                비밀번호 확인
              </label>
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
                  name="passwordConfirm"
                  value={form.passwordConfirm}
                  onChange={handleChange}
                  placeholder="비밀번호를 다시 입력하세요"
                  className="flex-1 bg-transparent text-sm text-[#1E2D14] placeholder:text-[#A8B89A] outline-none"
                />
              </div>
              {errors.passwordConfirm && (
                <p className="text-xs text-red-500 mt-1">
                  {errors.passwordConfirm}
                </p>
              )}
            </div>

            <button
              type="button"
              onClick={handleNextStep}
              className="w-full h-11 bg-[#3B6D11] hover:bg-[#2D5509] text-white text-sm font-medium rounded-lg transition-colors"
            >
              다음 단계로 →
            </button>
          </div>
        </>
      )}

      {/* ───── 2단계 ───── */}
      {step === 2 && (
        <form onSubmit={handleSubmit} className="flex flex-col gap-3">
          {/* 닉네임 */}
          <div>
            <label className="block text-xs text-[#7A8F6A] mb-1">닉네임</label>
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
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
              </svg>
              <input
                type="text"
                name="nickname"
                value={form.nickname}
                onChange={handleChange}
                placeholder="2~10자 (한글, 영문, 숫자)"
                className="flex-1 bg-transparent text-sm text-[#1E2D14] placeholder:text-[#A8B89A] outline-none"
              />
            </div>
            {errors.nickname && (
              <p className="text-xs text-red-500 mt-1">{errors.nickname}</p>
            )}
          </div>

          {/* 이메일 */}
          <div>
            <label className="block text-xs text-[#7A8F6A] mb-1">이메일</label>
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
                <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                <polyline points="22,6 12,13 2,6" />
              </svg>
              <input
                type="email"
                name="email"
                value={form.email}
                onChange={handleChange}
                placeholder="example@email.com"
                className="flex-1 bg-transparent text-sm text-[#1E2D14] placeholder:text-[#A8B89A] outline-none"
              />
            </div>
            {errors.email && (
              <p className="text-xs text-red-500 mt-1">{errors.email}</p>
            )}
          </div>

          {/* 휴대폰 번호 */}
          <div>
            <label className="block text-xs text-[#7A8F6A] mb-1">
              휴대폰 번호
            </label>
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
                <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.41 2 2 0 0 1 3.6 1.23h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.69a16 16 0 0 0 5.4 5.4l1.52-1.52a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 21.73 15z" />
              </svg>
              <input
                type="tel"
                name="phoneNumber"
                value={form.phoneNumber}
                onChange={handleChange}
                placeholder="01012345678 (- 없이 입력)"
                className="flex-1 bg-transparent text-sm text-[#1E2D14] placeholder:text-[#A8B89A] outline-none"
              />
            </div>
            {errors.phoneNumber && (
              <p className="text-xs text-red-500 mt-1">{errors.phoneNumber}</p>
            )}
          </div>

          {errors.submit && (
            <p className="text-xs text-red-500">{errors.submit}</p>
          )}

          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => setStep(1)}
              className="h-11 px-4 border border-[#D6E4C8] text-[#7A8F6A] text-sm rounded-lg hover:bg-[#F2F7EC] transition-colors"
            >
              ← 이전
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 h-11 bg-[#3B6D11] hover:bg-[#2D5509] text-white text-sm font-medium rounded-lg transition-colors disabled:opacity-60"
            >
              {loading ? "처리 중..." : "가입 완료"}
            </button>
          </div>
        </form>
      )}

      <p className="text-xs text-[#B0BEA0] text-center mt-4">
        이미 계정이 있으신가요?{" "}
        <Link
          href="/login"
          className="text-[#3B6D11] font-medium hover:underline"
        >
          로그인
        </Link>
      </p>
    </AuthLayout>
  );
}
