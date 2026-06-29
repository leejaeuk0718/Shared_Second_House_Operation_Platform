package com.busanit401.spring_back.dto;

import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class StayReservationRequestDto {

    private Long accommodationId;   // 예약할 숙소 ID
    private Long userId;            // 예약한 유저 ID
    private LocalDate startDate;    // 예약 시작일
    private LocalDate endDate;      // 예약 종료일
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.dto.StayReservationRequestDto
 * 역할  : 예약 생성 요청 DTO (프론트 → Controller → Service)
 * 사용처 : StayReservationController.createReservation()
 * ----------------------------------------------------------------------------------
 * [파일 흐름]
 * 프론트(캘린더 날짜 선택) → POST /api/stay/reservations → 이 DTO 수신
 * → StayReservationServiceImpl.createReservation() 에서 Entity 변환 후 저장
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * ⚠️ [TODO] 로그인 완전 연동 후 userId 필드 제거 → userDetails.getId() 로 교체 예정
 * ==================================================================================
 */