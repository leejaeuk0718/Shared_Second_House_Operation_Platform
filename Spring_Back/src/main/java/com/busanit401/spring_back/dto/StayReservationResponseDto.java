package com.busanit401.spring_back.dto;

import com.busanit401.spring_back.domain.entity.StayReservation;
import com.busanit401.spring_back.enums.StayReservationStatus;
import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class StayReservationResponseDto {

    private Long id;                        // 예약 ID
    private Long accommodationId;           // 숙소 ID
    private String accommodationName;       // 숙소명
    private String accommodationAddress;    // 숙소 주소
    private LocalDate startDate;            // 예약 시작일
    private LocalDate endDate;              // 예약 종료일
    private StayReservationStatus status;   // CONFIRMED / CANCELLED

    // ── Entity → DTO 변환 메서드 ──────────────────────────────
    public static StayReservationResponseDto from(StayReservation reservation) {
        return StayReservationResponseDto.builder()
                .id(reservation.getId())
                .accommodationId(reservation.getStayAccommodation().getId())
                .accommodationName(reservation.getStayAccommodation().getName())
                .accommodationAddress(reservation.getStayAccommodation().getAddress())
                .startDate(reservation.getStartDate())
                .endDate(reservation.getEndDate())
                .status(reservation.getStatus())
                .build();
    }
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.dto.StayReservationResponseDto
 * 역할  : 예약 응답 DTO (Service → Controller → 프론트)
 * 사용처 : StayReservationServiceImpl (getReservations, createReservation, getReservationsByAccommodation)
 * ----------------------------------------------------------------------------------
 * [파일 흐름]
 * StayReservation 엔티티 → from() → 이 DTO → 프론트 응답
 * 사용 화면: 내 예약 목록 (/my/reservations), 달력 비활성 날짜 표시
 * ----------------------------------------------------------------------------------
 * [정적 메서드]
 * - from(reservation) : StayReservation Entity → 이 DTO 변환
 * ==================================================================================
 */