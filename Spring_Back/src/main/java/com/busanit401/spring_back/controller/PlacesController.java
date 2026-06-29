package com.busanit401.spring_back.controller;

import com.busanit401.spring_back.domain.service.PlacesService;
import com.busanit401.spring_back.dto.PlaceDTO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "주변 맛집 검색 (Google Places)", description = "좌표+반경으로 주변 맛집 조회")
@RestController
@RequestMapping("/api/places")
@RequiredArgsConstructor
public class PlacesController {

    private final PlacesService placesService;

    @GetMapping("/restaurants/sync")
    @Operation(summary = "주변 맛집 동기화 (숙소 좌표 기준 구글 호출 → 내 DB 저장)",
            description = "숙소(accommodationId) 좌표 중심 radius(m) 반경의 맛집을 Google Places(New) Nearby Search로 "
                    + "가져와 그 숙소 FK로 sh_restaurant에 저장(있으면 갱신)하고 저장 내용을 반환.")
    public List<PlaceDTO> syncNearbyRestaurants(
            @Parameter(description = "숙소 id (sh_stay_accommodation)", example = "1")
            @RequestParam Long accommodationId,
            @Parameter(description = "반경(미터, 최대 50000)", example = "2000")
            @RequestParam(defaultValue = "2000") int radius,
            @Parameter(description = "결과 개수(최대 20)", example = "20")
            @RequestParam(defaultValue = "20") int limit) {

        return placesService.syncNearbyRestaurants(accommodationId, radius, limit);
    }

    @GetMapping("/restaurants")
    @Operation(summary = "저장된 맛집 조회 (내 DB, 숙소별)",
            description = "특정 숙소(accommodationId) 부근으로 sh_restaurant에 저장된 맛집을 이름순으로 반환. 구글 미호출.")
    public List<PlaceDTO> listSavedRestaurants(
            @Parameter(description = "숙소 id (sh_stay_accommodation)", example = "1")
            @RequestParam Long accommodationId) {
        return placesService.listSavedRestaurants(accommodationId);
    }
}