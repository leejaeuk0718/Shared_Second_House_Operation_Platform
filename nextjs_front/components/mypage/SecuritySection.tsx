"use client";

import { useState } from "react";
import { api } from "@/lib/api";

export default function SecuritySection() {
  const [form, setForm] = useState({
    currentPassword: "",
    newPassword: "",
    newPasswordConfirm: "",
  });
  const [showPw, setShowPw] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const [loading, setLoading] = useState(false);

  const PASSWORD_PATTERN =
    /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@#$%^&+=!])(?!.*\s).{8,16}$/;

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
    setError("");
    setSuccess(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    if (!PASSWORD_PATTERN.test(form.newPassword)) {
      setError(
        "비밀번호는 영문, 숫자, 특수문자를 모두 포함해 주세요. (8~16자)",
      );
      return;
    }
    if (form.newPassword !== form.newPasswordConfirm) {
      setError("새 비밀번호가 일치하지 않아요.");
      return;
    }

    setLoading(true);
    try {
      // newPasswordConfirm은 클라이언트 검증용이라 서버 DTO(PasswordUpdateReq)에는
      // currentPassword, newPassword만 존재함 — 그대로 보내면 Jackson이
      // UnrecognizedPropertyException을 던지므로 제외하고 전송
      await api.patch("/api/users/password", {
        currentPassword: form.currentPassword,
        newPassword: form.newPassword,
      });
      setSuccess(true);
      setForm({ currentPassword: "", newPassword: "", newPasswordConfirm: "" });
    } catch (err: unknown) {
      setError(
        err instanceof Error ? err.message : "비밀번호 변경에 실패했어요.",
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white border border-[#E4DDD3] rounded-xl overflow-hidden">
      <div className="bg-[#3B6D11] px-5 py-3.5 flex items-center justify-between">
        <div className="flex items-center gap-2 text-white text-sm font-medium">
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
        </div>
      </div>

      <form onSubmit={handleSubmit} className="p-6 flex flex-col gap-4">
        {[
          {
            name: "currentPassword",
            label: "현재 비밀번호",
            placeholder: "현재 비밀번호 입력",
          },
          {
            name: "newPassword",
            label: "새 비밀번호",
            placeholder: "영문+숫자+특수문자 8~16자",
          },
          {
            name: "newPasswordConfirm",
            label: "새 비밀번호 확인",
            placeholder: "새 비밀번호 다시 입력",
          },
        ].map(({ name, label, placeholder }) => (
          <div key={name}>
            <label className="block text-xs text-[#7A8F6A] mb-1.5">
              {label}
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
                type={showPw ? "text" : "password"}
                name={name}
                value={form[name as keyof typeof form]}
                onChange={handleChange}
                placeholder={placeholder}
                required
                className="flex-1 bg-transparent text-sm text-[#1E2D14] placeholder:text-[#A8B89A] outline-none"
              />
              {name === "currentPassword" && (
                <button
                  type="button"
                  onClick={() => setShowPw((v) => !v)}
                  className="text-[#A8B89A] hover:text-[#3B6D11] transition-colors"
                  aria-label="비밀번호 보기"
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
              )}
            </div>
          </div>
        ))}

        {error && <p className="text-xs text-red-500">{error}</p>}
        {success && (
          <p className="text-xs text-[#3B6D11]">비밀번호가 변경됐어요.</p>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full h-11 bg-[#3B6D11] hover:bg-[#2D5509] text-white text-sm font-medium rounded-lg transition-colors disabled:opacity-60 mt-2"
        >
          {loading ? "변경 중..." : "비밀번호 변경"}
        </button>
      </form>
    </div>
  );
}
