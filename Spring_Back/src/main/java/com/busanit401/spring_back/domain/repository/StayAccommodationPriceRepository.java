package com.busanit401.spring_back.domain.repository;

import com.busanit401.spring_back.domain.entity.StayAccommodationPrice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface StayAccommodationPriceRepository extends JpaRepository<StayAccommodationPrice, Long> {

    // ── 공통 할인율 구간 전체 조회 ───────────────────────────
    // StayAccommodationServiceImpl.getCommonPrices() 에서 호출
    List<StayAccommodationPrice> findAll();
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.repository.StayAccommodationPriceRepository
 * 역할  : 공통 할인율 구간 DB 접근
 * 사용처 : StayAccommodationServiceImpl (getCommonPrices 내부 메서드)
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - findAll() : 전체 할인율 구간 조회 (JpaRepository 기본 재선언)
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * - 숙소별 가격이 아닌 전체 공통 테이블 → 별도 필터 조건 없이 전체 조회
 * ==================================================================================
 */