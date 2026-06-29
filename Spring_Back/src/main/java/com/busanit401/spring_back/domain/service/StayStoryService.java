package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.dto.StayStoryRequestDto;
import com.busanit401.spring_back.dto.StayStoryResponseDto;

import java.util.List;

public interface StayStoryService {

    // ── 숙소별 스토리 목록 조회 (표시 순서대로) ───────────────
    List<StayStoryResponseDto> getStories(Long accommodationId);

    // ── 스토리 등록 (관리자) ──────────────────────────────────
    StayStoryResponseDto createStory(StayStoryRequestDto requestDto);

    // ── 스토리 수정 (관리자) ──────────────────────────────────
    StayStoryResponseDto updateStory(Long id, StayStoryRequestDto requestDto);

    // ── 스토리 삭제 (관리자) ──────────────────────────────────
    void deleteStory(Long id);

    // ── 스토리 이미지 URL 저장 (관리자) ──────────────────────
    void updateImageUrl(Long id, String imageUrl);
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.service.StayStoryService
 * 역할  : 숙소 스토리 서비스 인터페이스 (메서드 명세 정의)
 * 구현체 : StayStoryServiceImpl
 * 사용처 : StayStoryController
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - getStories(accommodationId) : 숙소별 스토리 목록 조회 (orderNum 오름차순)
 * - createStory(requestDto)     : 스토리 등록 (관리자)
 * - updateStory(id, requestDto) : 스토리 수정 (관리자)
 * - deleteStory(id)             : 스토리 삭제 (관리자)
 * ==================================================================================
 */