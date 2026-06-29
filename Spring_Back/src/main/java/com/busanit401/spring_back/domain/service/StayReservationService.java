package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.dto.StayReservationRequestDto;
import com.busanit401.spring_back.dto.StayReservationResponseDto;

import java.util.List;

public interface StayReservationService {

    // ── 내 예약 목록 조회 ─────────────────────────────────────
    List<StayReservationResponseDto> getReservations(Long userId);

    // ── 숙소별 확정 예약 목록 조회 (달력 비활성 날짜용) ──────
    List<StayReservationResponseDto> getReservationsByAccommodation(Long accommodationId);

    // ── 예약 생성 ─────────────────────────────────────────────
    StayReservationResponseDto createReservation(Long userId, StayReservationRequestDto requestDto);

    // ── 예약 취소 ─────────────────────────────────────────────
    void cancelReservation(Long reservationId, Long userId);

    // ── [관리자] 전체 예약 목록 조회 (userId 없으면 전체, 있으면 해당 유저만) ──
    List<StayReservationResponseDto> getAllReservations(Long userId);
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.service.StayReservationService
 * 역할  : 숙소 예약 서비스 인터페이스 (메서드 명세 정의)
 * 구현체 : StayReservationServiceImpl
 * 사용처 : StayReservationController
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - getReservations(userId)                         : 내 예약 목록 조회
 * - getReservationsByAccommodation(accommodationId) : 숙소별 확정 예약 목록 조회
 * - createReservation(userId, requestDto)           : 예약 생성
 * - cancelReservation(reservationId, userId)        : 예약 취소
 * - getAllReservations(userId)                      : [관리자] 전체 예약 목록 조회 (userId 없으면 전체, 있으면 필터링)
 * ==================================================================================
 */