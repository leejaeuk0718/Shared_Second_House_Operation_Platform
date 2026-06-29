package com.busanit401.spring_back.domain.repository;

import com.busanit401.spring_back.domain.entity.StayAccommodation;
import com.busanit401.spring_back.enums.StayAccommodationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface StayAccommodationRepository extends JpaRepository<StayAccommodation, Long> {

    // ── 상태별 숙소 목록 조회 ────────────────────────────────
    List<StayAccommodation> findByStatus(StayAccommodationStatus status);

    // ── 이름 검색 + 페이징 ───────────────────────────────────
    Page<StayAccommodation> findByNameContainingIgnoreCase(String keyword, Pageable pageable);
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.repository.StayAccommodationRepository
 * 역할  : 숙소 DB 접근 (JpaRepository 기본 CRUD + 상태별 조회)
 * 사용처 : StayAccommodationServiceImpl
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - findAll()          : 전체 숙소 목록 조회 (JpaRepository 기본)
 * - findById(id)       : 단건 조회 (JpaRepository 기본)
 * - save(entity)       : 저장/수정 (JpaRepository 기본)
 * - deleteById(id)     : 삭제 (JpaRepository 기본)
 * - existsById(id)     : 존재 여부 확인 (JpaRepository 기본)
 * - findByStatus(status) : 상태별 숙소 목록 조회 (커스텀)
 * ==================================================================================
 */