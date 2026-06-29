"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/lib/api";
import { tokenStorage } from "@/lib/token";

export default function DeleteAccountSection() {
  const router = useRouter();
  const [confirm, setConfirm] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleDelete = async (e: React.FormEvent) => {
    e.preventDefault();
    if (confirm !== "탈퇴하겠습니다") {
      setError("확인 문구를 정확히 입력해 주세요.");
      return;
    }

    setLoading(true);
    try {
      await api.delete("/api/users");
      tokenStorage.remove();
      router.push("/login");
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "탈퇴 처리에 실패했어요.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white border border-[#E4DDD3] rounded-xl overflow-hidden">
      <div className="bg-[#A32D2D] px-5 py-3.5 flex items-center gap-2">
        <svg
          width="17"
          height="17"
          viewBox="0 0 24 24"
          fill="none"
          stroke="white"
          strokeWidth="1.8"
          aria-hidden="true"
        >
          <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
          <line x1="12" y1="9" x2="12" y2="13" />
          <line x1="12" y1="17" x2="12.01" y2="17" />
        </svg>
        <span className="text-white text-sm font-medium">회원 탈퇴</span>
      </div>

      <div className="p-6">
        <div className="bg-red-50 border border-red-100 rounded-lg p-4 mb-6">
          <p className="text-sm text-red-700 font-medium mb-2">
            탈퇴 전 꼭 확인해 주세요
          </p>
          <ul className="text-xs text-red-600 flex flex-col gap-1.5">
            <li>• 탈퇴 시 모든 예약 내역과 구독 정보가 삭제돼요.</li>
            <li>• 삭제된 계정 정보는 복구할 수 없어요.</li>
            <li>• 진행 중인 구독이 있다면 먼저 해지해 주세요.</li>
          </ul>
        </div>

        <form onSubmit={handleDelete} className="flex flex-col gap-4">
          <div>
            <label className="block text-xs text-[#7A8F6A] mb-1.5">
              확인 문구 입력 —{" "}
              <span className="font-medium text-[#2A2520]">탈퇴하겠습니다</span>
              를 입력해 주세요
            </label>
            <input
              type="text"
              value={confirm}
              onChange={(e) => {
                setConfirm(e.target.value);
                setError("");
              }}
              placeholder="탈퇴하겠습니다"
              className="w-full h-11 bg-[#F2F7EC] border border-[#D6E4C8] rounded-lg px-3 text-sm text-[#1E2D14] placeholder:text-[#A8B89A] outline-none focus:border-red-400 focus:bg-white transition-colors"
            />
          </div>

          {error && <p className="text-xs text-red-500">{error}</p>}

          <button
            type="submit"
            disabled={loading || confirm !== "탈퇴하겠습니다"}
            className="w-full h-11 bg-red-500 hover:bg-red-600 text-white text-sm font-medium rounded-lg transition-colors disabled:opacity-40"
          >
            {loading ? "처리 중..." : "회원 탈퇴"}
          </button>
        </form>
      </div>
    </div>
  );
}
