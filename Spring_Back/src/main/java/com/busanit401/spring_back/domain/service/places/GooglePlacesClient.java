package com.busanit401.spring_back.domain.service.places;

import com.busanit401.spring_back.dto.PlaceDTO;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Google Places API (New) 호출 클라이언트 — 주변 맛집(restaurant) 검색.
 *
 * <p>엔드포인트: POST /places:searchNearby
 * <p>인증: 헤더 X-Goog-Api-Key, 반환 필드 지정: 헤더 X-Goog-FieldMask
 * <p>동기 MVC라 WebClient 결과를 {@code block()}으로 받아 {@code List<PlaceDTO>}로 변환한다.
 *
 * <p>과금: nationalPhoneNumber·regularOpeningHours는 상위 등급(Enterprise) 필드라
 * Pro만 쓸 때보다 호출 비용이 올라간다.
 */
@Component
public class GooglePlacesClient {

    /** Places API (New) 주변검색 엔드포인트(절대 URL). 공용 WebClient엔 baseUrl이 없어 여기서 직접 지정. */
    private static final String SEARCH_NEARBY_URL = "https://places.googleapis.com/v1/places:searchNearby";

    /** 응답에서 받아올 필드만 지정(미지정 시 에러). places. 접두어 필수. */
    private static final String FIELD_MASK = String.join(",",
            "places.id",
            "places.displayName",
            "places.primaryType",
            "places.nationalPhoneNumber",
            "places.location",
            "places.googleMapsUri",
            // 영업시간 중 요일별 설명만(openNow 등 불필요)
            "places.regularOpeningHours.weekdayDescriptions");

    private final WebClient googleWebClient;
    private final String apiKey;

    public GooglePlacesClient(WebClient googleWebClient,
                              @Value("${google.places.api.key:}") String apiKey) {
        this.googleWebClient = googleWebClient;
        this.apiKey = apiKey;
    }

    /**
     * 좌표(lat,lng) 중심 radius(m) 반경의 맛집을 인기도(기본) 순으로 최대 maxResults개 반환.
     *
     * @param radius     반경(미터). Places 제약상 0~50000.
     * @param maxResults 최대 결과 수. Places 제약상 1~20.
     * @param languageCode 결과 언어(예: "ko").
     */
    public List<PlaceDTO> searchNearbyRestaurants(double latitude, double longitude,
                                                  double radius, int maxResults, String languageCode) {
        try {
            JsonNode response = googleWebClient.post()
                    .uri(SEARCH_NEARBY_URL)
                    .header("X-Goog-Api-Key", apiKey)
                    .header("X-Goog-FieldMask", FIELD_MASK)
                    .bodyValue(buildRequestBody(latitude, longitude, radius, maxResults, languageCode))
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .block();
            return parse(response);
        } catch (WebClientResponseException e) {
            throw new IllegalStateException(
                    "Google Places 호출 실패: status=" + e.getStatusCode().value()
                            + ", body=" + e.getResponseBodyAsString(), e);
        }
    }

    private Map<String, Object> buildRequestBody(double lat, double lng, double radius,
                                                 int maxResults, String languageCode) {
        Map<String, Object> center = new LinkedHashMap<>();
        center.put("latitude", lat);
        center.put("longitude", lng);

        Map<String, Object> circle = new LinkedHashMap<>();
        circle.put("center", center);
        circle.put("radius", radius);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("includedTypes", List.of("restaurant"));
        body.put("maxResultCount", maxResults);
        body.put("languageCode", languageCode);
        body.put("locationRestriction", Map.of("circle", circle));
        return body;   // rankPreference 미지정 → 기본값 POPULARITY(인기도)순
    }

    /** 응답 JSON의 places[] 배열을 PlaceDTO 리스트로 변환. */
    private List<PlaceDTO> parse(JsonNode response) {
        List<PlaceDTO> out = new ArrayList<>();
        if (response == null) {
            return out;
        }
        JsonNode places = response.path("places");
        if (!places.isArray()) {
            return out;   // 결과 없음(빈 응답)
        }
        for (JsonNode p : places) {
            JsonNode loc = p.path("location");
            JsonNode hours = p.path("regularOpeningHours");
            out.add(PlaceDTO.builder()
                    .id(text(p, "id"))
                    .name(p.path("displayName").path("text").asText(null))
                    .primaryType(text(p, "primaryType"))
                    .phoneNumber(text(p, "nationalPhoneNumber"))
                    .latitude(loc.has("latitude") ? loc.get("latitude").asDouble() : null)
                    .longitude(loc.has("longitude") ? loc.get("longitude").asDouble() : null)
                    .googleMapsUri(text(p, "googleMapsUri"))
                    .weekdayDescriptions(stringList(hours.path("weekdayDescriptions")))
                    .build());
        }
        return out;
    }

    /** 필드가 있으면 문자열, 없으면 null. */
    private static String text(JsonNode node, String field) {
        return node.has(field) ? node.get(field).asText() : null;
    }

    /** 배열 노드를 문자열 리스트로(없으면 null). */
    private static List<String> stringList(JsonNode arr) {
        if (!arr.isArray() || arr.isEmpty()) {
            return null;
        }
        List<String> list = new ArrayList<>(arr.size());
        for (JsonNode n : arr) {
            list.add(n.asText());
        }
        return list;
    }
}