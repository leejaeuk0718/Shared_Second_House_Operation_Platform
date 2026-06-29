package com.busanit401.spring_back.enums;

public enum StayAccommodationStatus {
    AVAILABLE,      // 예약 가능
    MAINTENANCE     // 점검 중
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.enums.StayAccommodationStatus
 * 역할  : 숙소 상태 Enum
 * 사용처 : StayAccommodation.status 필드, StayAccommodationRepository.findByStatus()
 * ----------------------------------------------------------------------------------
 * [값 목록]
 * - AVAILABLE   : 예약 가능 상태
 * - MAINTENANCE : 점검 중 (예약 불가)
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * - DB 저장 방식: EnumType.STRING → "AVAILABLE", "MAINTENANCE" 문자열로 저장
 * ==================================================================================
 */