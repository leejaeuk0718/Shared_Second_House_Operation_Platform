package com.busanit401.spring_back.enums;

public enum StayReservationStatus {
    CONFIRMED,  // 예약 확정
    CANCELLED   // 예약 취소
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.enums.StayReservationStatus
 * 역할  : 숙소 예약 상태 Enum
 * 사용처 : StayReservation.status 필드, StayReservationRepository 조회 조건
 * ----------------------------------------------------------------------------------
 * [값 목록]
 * - CONFIRMED : 예약 확정 (달력 비활성 날짜 표시, 중복 체크 대상)
 * - CANCELLED : 예약 취소 (이력 보존, 중복 체크 제외)
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * - DB 저장 방식: EnumType.STRING → "CONFIRMED", "CANCELLED" 문자열로 저장
 * - 취소 시 DB에서 삭제하지 않고 CANCELLED 로 상태 변경 → 이력 조회 가능
 * ==================================================================================
 */