package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.domain.entity.Restaurant;
import com.busanit401.spring_back.domain.entity.StayAccommodation;
import com.busanit401.spring_back.domain.repository.RestaurantRepository;
import com.busanit401.spring_back.domain.repository.StayAccommodationRepository;
import com.busanit401.spring_back.domain.service.places.GooglePlacesClient;
import com.busanit401.spring_back.domain.service.places.PrimaryTypeConverter;
import com.busanit401.spring_back.dto.PlaceDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * {@link PlacesService} 구현. 숙소 좌표를 중심으로 Google Places(New)를 호출하고,
 * 결과를 그 숙소 FK로 sh_restaurant에 upsert한다.
 */
@Service
@RequiredArgsConstructor
public class PlacesServiceImpl implements PlacesService {

    /** Places 제약: 반경 0~50000m. */
    private static final int MAX_RADIUS = 50_000;
    /** Places 제약: 결과 1~20개. */
    private static final int MAX_LIMIT = 20;
    /** 결과 언어. */
    private static final String LANG = "ko";
    /** 조회 시 인기 상위 그대로 보여줄 개수. */
    private static final int TOP_COUNT = 10;
    /** 상위 이후 나머지에서 랜덤으로 더 보여줄 개수. */
    private static final int RANDOM_COUNT = 5;

    private final GooglePlacesClient googlePlacesClient;
    private final RestaurantRepository restaurantRepository;
    private final StayAccommodationRepository accommodationRepository;

    @Override
    @Transactional
    public List<PlaceDTO> syncNearbyRestaurants(Long accommodationId, int radius, int limit) {
        StayAccommodation accommodation = accommodationRepository.findById(accommodationId)
                .orElseThrow(() -> new IllegalArgumentException("숙소를 찾을 수 없습니다. id=" + accommodationId));
        if (accommodation.getLatitude() == null || accommodation.getLongitude() == null) {
            throw new IllegalStateException("숙소에 좌표(위/경도)가 없어 주변 맛집을 검색할 수 없습니다. id=" + accommodationId);
        }

        int safeRadius = clamp(radius, 1, MAX_RADIUS);
        int safeLimit = clamp(limit, 1, MAX_LIMIT);

        List<PlaceDTO> fetched = googlePlacesClient.searchNearbyRestaurants(
                accommodation.getLatitude(), accommodation.getLongitude(), safeRadius, safeLimit, LANG);

        upsert(accommodation, fetched);
        // 응답에 숙소 id + 인기순위(구글 응답 순서) 표시
        for (int rank = 0; rank < fetched.size(); rank++) {
            fetched.get(rank).setAccommodationId(accommodationId);
            fetched.get(rank).setPopularityRank(rank);
        }
        return fetched;
    }

    @Override
    @Transactional(readOnly = true)
    public List<PlaceDTO> listSavedRestaurants(Long accommodationId) {
        // 인기순으로 전부 가져와 → 상위 TOP_COUNT는 그대로, 나머지에서 RANDOM_COUNT개만 랜덤 선별
        List<Restaurant> all =
                restaurantRepository.findByAccommodationIdOrderByPopularity(accommodationId);

        int topCount = Math.min(TOP_COUNT, all.size());
        List<Restaurant> result = new ArrayList<>(all.subList(0, topCount));

        if (all.size() > topCount) {
            List<Restaurant> rest = new ArrayList<>(all.subList(topCount, all.size()));
            Collections.shuffle(rest);   // 매 조회마다 다른 5개가 노출됨
            result.addAll(rest.subList(0, Math.min(RANDOM_COUNT, rest.size())));
        }

        return result.stream().map(PlaceDTO::from).toList();
    }

    /** (숙소, placeId) 기준으로 있으면 갱신, 없으면 신규 저장. */
    private void upsert(StayAccommodation accommodation, List<PlaceDTO> places) {
        if (places.isEmpty()) {
            return;
        }
        List<String> placeIds = places.stream().map(PlaceDTO::getId).toList();
        // QueryDSL로 같은 숙소의 기존 행을 한 번에 조회 → placeId로 매핑
        Map<String, Restaurant> existing = restaurantRepository
                .findByAccommodationIdAndPlaceIdIn(accommodation.getId(), placeIds)
                .stream()
                .collect(Collectors.toMap(Restaurant::getPlaceId, Function.identity()));

        List<Restaurant> toInsert = new ArrayList<>();
        for (int rank = 0; rank < places.size(); rank++) {
            PlaceDTO p = places.get(rank);   // 구글 응답 순서 = 인기순위(0이 가장 인기)
            String weekday = joinWeekday(p.getWeekdayDescriptions());
            // primaryType 코드 → 한글 표시명("한식" 등)으로 변환해 저장
            String primaryTypeKo = PrimaryTypeConverter.toKorean(p.getPrimaryType());
            Restaurant found = existing.get(p.getId());
            if (found != null) {
                // 영속 상태라 변경감지(dirty checking)로 flush 시 자동 UPDATE
                found.update(p.getName(), primaryTypeKo, p.getPhoneNumber(),
                        p.getLatitude(), p.getLongitude(), p.getGoogleMapsUri(), weekday, rank);
            } else {
                toInsert.add(Restaurant.builder()
                        .accommodation(accommodation)
                        .placeId(p.getId())
                        .name(p.getName())
                        .primaryType(primaryTypeKo)
                        .phoneNumber(p.getPhoneNumber())
                        .latitude(p.getLatitude())
                        .longitude(p.getLongitude())
                        .googleMapsUri(p.getGoogleMapsUri())
                        .weekdayDescriptions(weekday)
                        .popularityRank(rank)
                        .build());
            }
        }
        if (!toInsert.isEmpty()) {
            restaurantRepository.saveAll(toInsert);
        }
    }

    /** 요일별 영업시간 리스트를 줄바꿈으로 합쳐 TEXT 한 칼럼에 저장. */
    private static String joinWeekday(List<String> weekdayDescriptions) {
        return (weekdayDescriptions == null || weekdayDescriptions.isEmpty())
                ? null : String.join("\n", weekdayDescriptions);
    }

    private static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }
}