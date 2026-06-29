package com.busanit401.spring_back.dto;

import com.busanit401.spring_back.domain.entity.Restaurant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Arrays;
import java.util.List;

/**
 * Google Places 검색 결과 1건(맛집 한 곳). 구글에서 읽어와 {@code sh_restaurant}에 저장하고,
 * 이후 내 DB 조회 응답으로도 재사용한다.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PlaceDTO {

    /** Places 고유 id (place id). 숙소별 중복 판단 기준. */
    private String id;
    /** 가게 이름 (displayName.text). */
    private String name;
    /** 대표 타입 코드 (primaryType, 예: "japanese_restaurant"). */
    private String primaryType;
    /** 전화번호 (nationalPhoneNumber, 예: "051-123-4567"). */
    private String phoneNumber;
    /** 위도 (location.latitude). */
    private Double latitude;
    /** 경도 (location.longitude). */
    private Double longitude;
    /** 구글 지도 링크 (googleMapsUri). */
    private String googleMapsUri;
    /** 요일별 영업시간 설명 (regularOpeningHours.weekdayDescriptions). */
    private List<String> weekdayDescriptions;
    /** 어느 숙소 부근인지 (sh_stay_accommodation FK). 응답에만 채워짐. */
    private Long accommodationId;
    /** 인기도 순위 (0이 가장 인기). 구글 응답 순서 기준. */
    private Integer popularityRank;

    /** 엔티티 → DTO 변환 (내 DB 조회 응답용). */
    public static PlaceDTO from(Restaurant r) {
        String desc = r.getWeekdayDescriptions();
        return PlaceDTO.builder()
                .id(r.getPlaceId())
                .name(r.getName())
                .primaryType(r.getPrimaryType())
                .phoneNumber(r.getPhoneNumber())
                .latitude(r.getLatitude())
                .longitude(r.getLongitude())
                .googleMapsUri(r.getGoogleMapsUri())
                .weekdayDescriptions(desc == null || desc.isBlank()
                        ? null : Arrays.asList(desc.split("\n")))
                .accommodationId(r.getAccommodation().getId())
                .popularityRank(r.getPopularityRank())
                .build();
    }
}
