package com.busanit401.spring_back.domain.repository.custom;

import com.busanit401.spring_back.domain.entity.Restaurant;

import java.util.List;

/**
 * 맛집(sh_restaurant) QueryDSL 커스텀 조회 계약.
 */
public interface RestaurantRepositoryCustom {

    /** 특정 숙소에서 placeId 목록에 해당하는 기존 행 조회 (upsert 시 신규/갱신 분기용). */
    List<Restaurant> findByAccommodationIdAndPlaceIdIn(Long accommodationId, List<String> placeIds);

    /** 특정 숙소 부근으로 저장된 맛집을 인기순(popularityRank 오름차순)으로 조회. */
    List<Restaurant> findByAccommodationIdOrderByPopularity(Long accommodationId);
}