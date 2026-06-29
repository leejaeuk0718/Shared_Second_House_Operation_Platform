package com.busanit401.spring_back.domain.repository;

import com.busanit401.spring_back.domain.entity.StayStory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface StayStoryRepository extends JpaRepository<StayStory, Long> {

    // ── 숙소별 스토리 목록 조회 (orderNum 오름차순) ──────────
    // 프론트 스토리 섹션 표시 순서 보장 (1 → 2 → 3 → 4)
    List<StayStory> findByStayAccommodationIdOrderByOrderNumAsc(Long accommodationId);
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.repository.StayStoryRepository
 * 역할  : 숙소 스토리 DB 접근 (JpaRepository 기본 CRUD + 순서 정렬 조회)
 * 사용처 : StayStoryServiceImpl
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - findByStayAccommodationIdOrderByOrderNumAsc(id) : 숙소별 스토리 순서대로 조회
 * ==================================================================================
 */