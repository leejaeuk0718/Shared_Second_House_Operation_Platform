package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.dto.PlaceDTO;

import java.util.List;

/**
 * 주변 맛집 서비스의 공개 계약.
 * <ul>
 *   <li>{@link #syncNearbyRestaurants}: 숙소 좌표 기준 구글 Places 호출 → sh_restaurant 저장(upsert) → 결과 반환</li>
 *   <li>{@link #listSavedRestaurants}: 특정 숙소 부근으로 저장된 맛집 조회(구글 미호출)</li>
 * </ul>
 */
public interface PlacesService {

    /**
     * 숙소(accommodationId)의 좌표를 중심으로 radius(m) 반경의 맛집을 구글에서 최대 limit개 가져와
     * 그 숙소 FK로 sh_restaurant에 저장(있으면 갱신)하고, 저장한 내용을 반환한다.
     */
    List<PlaceDTO> syncNearbyRestaurants(Long accommodationId, int radius, int limit);

    /** 특정 숙소 부근으로 저장된 맛집을 조회. */
    List<PlaceDTO> listSavedRestaurants(Long accommodationId);
}