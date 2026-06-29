"use client";

import { useState } from "react";
import { api } from "@/lib/api";
import { UserResp } from "@/types/auth";

interface Props {
  user: UserResp;
  onUpdate: () => Promise<void>;
}

export default function ProfileSection({ user, onUpdate }: Props) {
  const [editing, setEditing] = useState<"username" | "nickname" | null>(null);
  const [form, setForm] = useState({
    username: user.username,
    nickname: user.nickname,
  });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const PATTERNS = {
    username: /^[a-zA-Z0-9]{4,20}$/,
    nickname: /^[가-힣a-zA-Z0-9]{2,10}$/,
  };

  const handleSave = async (field: "username" | "nickname") => {
    setError("");

    if (!PATTERNS[field].test(form[field])) {
      setError(
        field === "username"
          ? "아이디는 특수문자를 제외한 4~20자로 입력해 주세요."
          : "닉네임은 2~10자의 한글, 영문, 숫자만 입력해 주세요.",
      );
      return;
    }

    setLoading(true);
    try {
      await api.patch("/api/users", {
        username: form.username,
        nickname: form.nickname,
      });
      await onUpdate();
      setEditing(null);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "수정에 실패했어요.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-4">
      {/* 내 프로필 섹션 */}
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
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
            내 프로필
          </div>
          <svg
            width="17"
            height="17"
            viewBox="0 0 24 24"
            fill="none"
            stroke="rgba(255,255,255,0.7)"
            strokeWidth="1.8"
            aria-hidden="true"
          >
            <polyline points="9 18 15 12 9 6" />
          </svg>
        </div>

        {/* 아이디 */}
        <div className="flex items-center px-5 py-4 border-b border-[#F0EBE5]">
          <svg
            width="17"
            height="17"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#8C8178"
            strokeWidth="1.8"
            className="mr-3"
            aria-hidden="true"
          >
            <rect x="2" y="7" width="20" height="14" rx="2" />
            <path d="M16 3H8a2 2 0 0 0-2 2v2h12V5a2 2 0 0 0-2-2z" />
          </svg>
          <span className="text-sm text-[#2A2520] flex-1">아이디</span>

          {editing === "username" ? (
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={form.username}
                onChange={(e) =>
                  setForm((p) => ({ ...p, username: e.target.value }))
                }
                className="h-8 px-2 text-sm border border-[#D6E4C8] rounded-lg outline-none focus:border-[#3B6D11] w-36"
              />
              <button
                onClick={() => handleSave("username")}
                disabled={loading}
                className="text-xs text-white bg-[#3B6D11] px-3 py-1.5 rounded-lg hover:bg-[#2D5509] disabled:opacity-60"
              >
                저장
              </button>
              <button
                onClick={() => {
                  setEditing(null);
                  setError("");
                }}
                className="text-xs text-[#8C8178] px-2 py-1.5"
              >
                취소
              </button>
            </div>
          ) : (
            <>
              <span className="text-sm text-[#8C8178] mr-3">
                {user.username}
              </span>
              <button
                onClick={() => setEditing("username")}
                className="text-sm text-[#3B6D11] font-medium hover:underline"
              >
                수정
              </button>
            </>
          )}
        </div>

        {/* 닉네임 */}
        <div className="flex items-center px-5 py-4 border-b border-[#F0EBE5]">
          <svg
            width="17"
            height="17"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#8C8178"
            strokeWidth="1.8"
            className="mr-3"
            aria-hidden="true"
          >
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
          </svg>
          <span className="text-sm text-[#2A2520] flex-1">닉네임</span>

          {editing === "nickname" ? (
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={form.nickname}
                onChange={(e) =>
                  setForm((p) => ({ ...p, nickname: e.target.value }))
                }
                className="h-8 px-2 text-sm border border-[#D6E4C8] rounded-lg outline-none focus:border-[#3B6D11] w-36"
              />
              <button
                onClick={() => handleSave("nickname")}
                disabled={loading}
                className="text-xs text-white bg-[#3B6D11] px-3 py-1.5 rounded-lg hover:bg-[#2D5509] disabled:opacity-60"
              >
                저장
              </button>
              <button
                onClick={() => {
                  setEditing(null);
                  setError("");
                }}
                className="text-xs text-[#8C8178] px-2 py-1.5"
              >
                취소
              </button>
            </div>
          ) : (
            <>
              <span className="text-sm text-[#8C8178] mr-3">
                {user.nickname}
              </span>
              <button
                onClick={() => setEditing("nickname")}
                className="text-sm text-[#3B6D11] font-medium hover:underline"
              >
                수정
              </button>
            </>
          )}
        </div>

        {/* 이메일 */}
        <div className="flex items-center px-5 py-4 border-b border-[#F0EBE5]">
          <svg
            width="17"
            height="17"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#8C8178"
            strokeWidth="1.8"
            className="mr-3"
            aria-hidden="true"
          >
            <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
            <polyline points="22,6 12,13 2,6" />
          </svg>
          <span className="text-sm text-[#2A2520] flex-1">이메일</span>
          <span className="text-sm text-[#8C8178] mr-3">{user.email}</span>
          <span className="text-sm text-[#B5ADA4]">변경불가</span>
        </div>

        {/* 휴대폰 번호 */}
        <div className="flex items-center px-5 py-4 border-b border-[#F0EBE5]">
          <svg
            width="17"
            height="17"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#8C8178"
            strokeWidth="1.8"
            className="mr-3"
            aria-hidden="true"
          >
            <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.41 2 2 0 0 1 3.6 1.23h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.69a16 16 0 0 0 5.4 5.4l1.52-1.52a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 21.73 15z" />
          </svg>
          <span className="text-sm text-[#2A2520] flex-1">휴대폰 번호</span>
          <span className="text-sm text-[#8C8178] mr-3">
            {user.phoneNumber}
          </span>
          <span className="text-sm text-[#B5ADA4]">변경불가</span>
        </div>
      </div>

      {/* 에러 메시지 */}
      {error && <p className="text-xs text-red-500 px-1">{error}</p>}
    </div>
  );
}
