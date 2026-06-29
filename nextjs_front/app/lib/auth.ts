import axios from 'axios';

// ===== 로그인 연동 시 이 파일만 수정하면 됩니다 =====
// .env 파일에 NEXT_PUBLIC_TEMP_USER_ID=본인_userId 추가하면 됩니다.
export const TEMP_USER_ID = Number(process.env.NEXT_PUBLIC_TEMP_USER_ID) || 1;

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_SERVER_URL,
});

// [로그인 연동 시 아래 주석 해제]
// api.interceptors.request.use((config) => {
//   const token = localStorage.getItem('accessToken');
//   if (token) config.headers.Authorization = `Bearer ${token}`;
//   return config;
// });

export default api;
