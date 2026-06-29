export type SubscriptionStatus = "PENDING" | "ACTIVE" | "EXPIRED" | "CANCELLED";

export interface SubscriptionsUserResp {
  subscriptionId: number;
  userId: number;
  username: string;
  accommodationId: number;
  durationMonths: number;
  startDate: string; // ISO date string
  endDate: string;
  status: SubscriptionStatus;
  createdAt: string;
}

export interface SubscriptionSearchCondition {
  username?: string;
  status?: SubscriptionStatus;
  startDate?: string;
  endDate?: string;
}

export type MemberRole = "LEADER" | "MEMBER";
export type MemberStatus = "PENDING" | "APPROVED" | "REJECTED";

export interface SubscriptionsUserResp {
  subscriptionId: number;
  userId: number;
  username: string;
  accommodationId: number;
  durationMonths: number;
  startDate: string;
  endDate: string;
  status: SubscriptionStatus;
  createdAt: string;
}

export interface SubscriptionSearchCondition {
  username?: string;
  status?: SubscriptionStatus;
  startDate?: string;
  endDate?: string;
}

// 구독 신청 요청
export interface WaitingSubscriptionReq {
  accommodationId: number;
  durationMonths: number;
  memberIdentifiers: string[];
  startDate: string; // [날짜 검증 추가] 희망 구독 시작일 (YYYY-MM-DD)
}

// [날짜 검증 추가] 숙소별 사용 불가 기간 응답 — GET /api/subscriptions/accommodation/{id}
export interface SubscriptionDateRangeResp {
  startDate: string;
  endDate: string;
  status: SubscriptionStatus;
}

// 초대 응답
export interface WaitingSubscriptionResp {
  waitingId: number;
  subscriptionId: number;
  accommodationId: number;
  userId: number;
  username: string;
  memberRole: MemberRole;
  status: MemberStatus;
  requestedAt: string;
  respondedAt: string | null;
}
