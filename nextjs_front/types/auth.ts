export interface SignupReq {
  username: string; // 아이디 (영문+숫자 4~20자)
  password: string; // 영문+숫자+특수문자 8~16자
  nickname: string;
  email: string;
  phoneNumber: string;
}

export interface LoginReq {
  username: string;
  password: string;
}

export interface AuthResp {
  accessToken: string;
}

// 마이페이지, 회원수정에서 사용
export interface UserResp {
  userId: number;
  username: string;
  email: string;
  nickname: string;
  phoneNumber: string;
  role: "USER" | "SOCIAL" | "ADMIN";
}

// 회원 정보 수정
export interface UserSimpleReq {
  username: string;
  nickname: string;
}
