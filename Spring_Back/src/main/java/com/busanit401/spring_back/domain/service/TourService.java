package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.dto.TourDto;
import com.busanit401.spring_back.dto.TourResponseListDto;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TourService {

    // 외부 API와 HTTP 통신을 수행하기 위한 스프링 내장 객체 초기화
    private final RestTemplate restTemplate;

    @Value("${tour.api.service-key}")
    private String serviceKey;

    private final int PAGE_SIZE = 10; // 페이지당 노출 개수 고정

    // 포스트맨 규격에 맞춰 특정 지역의 카테고리별 관광지 목록을 10개씩 조회하는 비즈니스 메서드
    // @param lDongRegnCd 법정동 시도 코드 (예: 인천=28, 서울=11 등)
    // @param pageNo 요청할 페이지 번호
    public TourResponseListDto getTourListByRegion(String lDongRegnCd, int pageNo) {
        try {
            // 1. UriComponentsBuilder로 코드 직관화 및 가독성 극대화 (Double Encoding 방지 자동 지원)
            URI targetUri = UriComponentsBuilder.fromHttpUrl("https://apis.data.go.kr/B551011/KorService2/areaBasedList2")
                .queryParam("serviceKey", serviceKey)
                .queryParam("numOfRows", 10)
                .queryParam("pageNo", pageNo)
                .queryParam("MobileOS", "ETC")
                .queryParam("MobileApp", "AppTest")
                .queryParam("_type", "json")
                .queryParam("arrange", "C")
                .queryParam("contentTypeId", "12")
                .queryParam("lDongRegnCd", lDongRegnCd)
                .queryParam("lclsSystm1", "NA")
                .queryParam("lclsSystm2", "NA04")
                .queryParam("lclsSystm3", "NA040500")
                .build(true) // true를 넣어주면 기존 인코딩된 serviceKey가 깨지지 않고 그대로 유지됩니다.
                .toUri();

            System.out.println("▶ [API Request URI] : " + targetUri);

            Map<String, Object> response = restTemplate.getForObject(targetUri, Map.class);
            if (response == null) return new TourResponseListDto(Collections.emptyList(), true);

            // 1. 공공데이터 응답 파싱 및 totalCount 추출용 구조 진입
            Map<String, Object> resMap = (Map<String, Object>) response.get("response");
            if (resMap == null) return new TourResponseListDto(Collections.emptyList(), true);

            Map<String, Object> bodyMap = (Map<String, Object>) resMap.get("body");
            if (bodyMap == null) return new TourResponseListDto(Collections.emptyList(), true);

            // 💡 2. 외부 API가 준 전체 데이터 개수 확인 (isLast 판별용 변수)
            int totalCount = 0;
            try {
                if (bodyMap.get("totalCount") != null) {
                    totalCount = Integer.parseInt(String.valueOf(bodyMap.get("totalCount")));
                }
            } catch (Exception e) {
                System.err.println("▶ [totalCount 파싱 실패] 기본값 0으로 대체합니다.");
            }

            List<TourDto> tourList = parseTourDtoList(response);

            // 💡 [수정] totalCount가 없거나 0일 때를 대비해 가져온 리스트의 크기로 한 번 더 방어
            boolean isLast = (pageNo * PAGE_SIZE) >= totalCount || tourList.size() < PAGE_SIZE || tourList.isEmpty();

            return new TourResponseListDto(tourList, isLast);

        } catch (Exception e) {
            System.err.println("❌ [TourService Error] 예외 발생: " + e.getMessage());
            e.printStackTrace();
            return new TourResponseListDto(Collections.emptyList(), true);
        }
    }

    // 외부 API가 리턴한 복잡한 JSON(Map) 구조에서 핵심 알맹이만 꺼내 자바 객체(TourDto)로 변환하는 헬퍼 메서드
    @SuppressWarnings("unchecked")
    private List<TourDto> parseTourDtoList(Map<String, Object> response) {
        try {
            if (response == null) return Collections.emptyList();

            Map<String, Object> resMap = (Map<String, Object>) response.get("response");
            if (resMap == null) return Collections.emptyList();

            Map<String, Object> bodyMap = (Map<String, Object>) resMap.get("body");
            if (bodyMap == null || bodyMap.get("items") == null || "".equals(bodyMap.get("items"))) {
                return Collections.emptyList();
            }

            Map<String, Object> itemsMap = (Map<String, Object>) bodyMap.get("items");
            Object itemObject = itemsMap.get("item");
            if (itemObject == null) return Collections.emptyList();

            List<Map<String, Object>> itemList = new ArrayList<>();

            // 💡 단건(Map)과 다건(List) 구조 완벽 방어
            if (itemObject instanceof List) {
                itemList = (List<Map<String, Object>>) itemObject;
            } else if (itemObject instanceof Map) {
                itemList.add((Map<String, Object>) itemObject);
            }

            return itemList.stream()
                    .map(item -> new TourDto(
                            // 💡 형변환 대신 String.valueOf()를 사용하면 Integer나 null이 들어와도 안전하게 처리됩니다.
                            item.get("title") != null ? String.valueOf(item.get("title")) : "정보 없음",
                            item.get("firstimage") != null ? String.valueOf(item.get("firstimage")) : "",
                            item.get("addr1") != null ? String.valueOf(item.get("addr1")) : "주소 정보 없음",
                            item.get("contentid") != null ? String.valueOf(item.get("contentid")) : ""
                    ))
                    .collect(Collectors.toList());

        } catch (Exception e) {
            System.err.println("▶ [JSON 파싱 중 에러 발생] 사유: " + e.getMessage());
            e.printStackTrace();
            return Collections.emptyList();
        }
    }
}