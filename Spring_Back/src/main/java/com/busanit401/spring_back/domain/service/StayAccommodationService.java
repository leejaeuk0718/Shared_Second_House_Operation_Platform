package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.dto.StayAccommodationRequestDto;
import com.busanit401.spring_back.dto.StayAccommodationResponseDto;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface StayAccommodationService {

    // ── 숙소 목록 조회 (검색 + 페이징) ──────────────────────
    Page<StayAccommodationResponseDto> getAccommodations(String keyword, Pageable pageable);

    // ── 숙소 상세 조회 ────────────────────────────────────────
    StayAccommodationResponseDto getAccommodation(Long id);

    // ── 숙소 등록 (관리자) ────────────────────────────────────
    StayAccommodationResponseDto createAccommodation(StayAccommodationRequestDto requestDto);

    // ── 숙소 수정 (관리자) ────────────────────────────────────
    StayAccommodationResponseDto updateAccommodation(Long id, StayAccommodationRequestDto requestDto);

    // ── 숙소 삭제 (관리자) ────────────────────────────────────
    void deleteAccommodation(Long id);

    // ── 숙소 이미지 URL 저장 (관리자) ────────────────────────
    void updateImageUrl(Long id, String imageUrl);
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.service.StayAccommodationService
 * 역할  : 숙소 서비스 인터페이스 (메서드 명세 정의)
 * 구현체 : StayAccommodationServiceImpl
 * 사용처 : StayAccommodationController
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - getAccommodations()                     : 숙소 목록 조회
 * - getAccommodation(id)                    : 숙소 상세 조회
 * - createAccommodation(requestDto)         : 숙소 등록 (관리자)
 * - updateAccommodation(id, requestDto)     : 숙소 수정 (관리자)
 * - deleteAccommodation(id)                 : 숙소 삭제 (관리자)
 * ==================================================================================
 */