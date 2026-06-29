"use client";

import { Suspense } from "react";
import { useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { tokenStorage } from "@/lib/token";

function OAuthCallbackContent() {
  const router = useRouter();
  const searchParams = useSearchParams();

  useEffect(() => {
    const token = searchParams.get("token");

    if (token) {
      tokenStorage.set(token);
      router.replace("/");
    } else {
      router.replace("/login?error=social");
    }
  }, [router, searchParams]);

  return (
    <div className="w-full h-screen flex items-center justify-center bg-[#F7F4EF]">
      <div className="text-center">
        <div className="w-8 h-8 border-2 border-[#3B6D11] border-t-transparent rounded-full animate-spin mx-auto mb-4" />
        <p className="text-sm text-[#7A8F6A]">로그인 처리 중...</p>
      </div>
    </div>
  );
}

export default function OAuthCallbackPage() {
  return (
    <Suspense>
      <OAuthCallbackContent />
    </Suspense>
  );
}
