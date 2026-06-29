import { tokenStorage } from "./token";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080";

async function parseError(res: Response): Promise<string> {
  try {
    const contentType = res.headers.get("content-type");

    if (contentType?.includes("application/json")) {
      const data = await res.json();

      if (data.message) return data.message;
      if (Array.isArray(data)) return data[0];
      if (data.error) return data.error;
      if (typeof data === "string") return data;
    }

    const text = await res.text();
    return text || "요청에 실패했습니다.";
  } catch {
    return "요청에 실패했습니다.";
  }
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const accessToken = tokenStorage.get();

  console.log("========== API REQUEST ==========");
  console.log("BASE_URL:", BASE_URL);
  console.log("PATH:", path);
  console.log("METHOD:", options.method);
  console.log("FULL URL:", `${BASE_URL}${path}`);
  console.log("TOKEN:", accessToken);
  console.log("================================");

  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
      ...options.headers,
    },
    credentials: "include",
  });

  console.log("STATUS:", res.status);

  // 서버가 새 토큰을 내려주면 즉시 교체 (username 변경 등으로 재발급된 경우)
  const newAuthHeader = res.headers.get("Authorization");
  if (newAuthHeader?.startsWith("Bearer ")) {
    const newToken = newAuthHeader.replace("Bearer ", "");
    tokenStorage.set(newToken); // ⚠️ token.ts에 set 메소드명 확인 필요
    console.log("TOKEN UPDATED:", newToken);
  }

  if (!res.ok) {
    const errorMessage = await parseError(res);
    console.log("ERROR RESPONSE:", errorMessage);
    throw new Error(errorMessage);
  }

  return res.json();
}

export const api = {
  get: <T>(path: string) => request<T>(path, { method: "GET" }),

  post: <T>(path: string, body: unknown) =>
    request<T>(path, { method: "POST", body: JSON.stringify(body) }),

  put: <T>(path: string, body: unknown) =>
    request<T>(path, { method: "PUT", body: JSON.stringify(body) }),

  patch: <T>(path: string, body: unknown) =>
    request<T>(path, { method: "PATCH", body: JSON.stringify(body) }),

  delete: <T>(path: string) => request<T>(path, { method: "DELETE" }),
};
