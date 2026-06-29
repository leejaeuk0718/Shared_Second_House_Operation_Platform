package com.busanit401.spring_back.domain.repository;

import com.busanit401.spring_back.domain.entity.StayReservation;
import com.busanit401.spring_back.enums.StayReservationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface StayReservationRepository extends JpaRepository<StayReservation, Long> {

    // ── 숙소별 예약 목록 조회 ────────────────────────────────
    List<StayReservation> findByStayAccommodationId(Long accommodationId);

    // ── 유저별 예약 목록 조회 ────────────────────────────────
    // 내 예약 목록 페이지 (/my/reservations) 에서 사용
    List<StayReservation> findByUserId(Long userId);

    // ── 숙소별 + 상태별 예약 목록 조회 ──────────────────────
    // CONFIRMED 예약만 조회 → 프론트 달력 비활성 날짜 표시 + 중복 예약 체크에 사용
    List<StayReservation> findByStayAccommodationIdAndStatus(Long accommodationId, StayReservationStatus status);
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.repository.StayReservationRepository
 * 역할  : 숙소 예약 DB 접근 (JpaRepository 기본 CRUD + 커스텀 조회)
 * 사용처 : StayReservationServiceImpl
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - findByUserId(userId)                               : 유저별 예약 목록 조회
 * - findByStayAccommodationId(accommodationId)         : 숙소별 예약 목록 조회
 * - findByStayAccommodationIdAndStatus(id, status)     : 숙소별 + 상태별 예약 조회
 *   → CONFIRMED 상태 조회 시 용도:
 *      1) 달력 비활성 날짜 표시 (getReservationsByAccommodation)
 *      2) 신규 예약 중복 체크 (createReservation)
 * ==================================================================================
 */