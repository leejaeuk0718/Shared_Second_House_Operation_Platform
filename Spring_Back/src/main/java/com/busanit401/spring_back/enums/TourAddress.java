package com.busanit401.spring_back.enums;

import java.util.Arrays;

public enum TourAddress {
    SEOUL("서울", "11"),
    BUSAN("부산", "26"),
    DAEGU("대구", "27"),
    INCHEON("인천", "28"),
    GWANGJU("광주", "29"),
    DAEJEON("대전", "30"),
    ULSAN("울산", "31"),
    SEJONG("세종", "36"),
    GYEONGGI("경기", "41"),
    GANGWON("강원", "51"),
    CHUNGBUK("충북", "43"),
    CHUNGNAM("충남", "44"),
    JEONBUK("전북", "52"),
    JEONNAM("전남", "46"),
    GYEONGBUK("경북", "47"),
    GYEONGNAM("경남", "48"),
    JEJU("제주", "50"); // 제주특별자치도 대응 필요

    private final String keyword;
    private final String code;

    TourAddress(String keyword, String code) {
        this.keyword = keyword;
        this.code = code;
    }

    public static String getRegionCode(String address) {
        if (address == null || address.isBlank()) {
            throw new IllegalArgumentException("주소 정보가 올바르지 않습니다.");
        }

        // 공백 기준 첫 단어 추출 (예: "강원도", "강원특별자치도", "제주특별자치도")
        String siDo = address.split(" ")[0];

        return Arrays.stream(TourAddress.values())
                .filter(tourAddress ->
                        // 1. siDo가 "강원도"일 때 Enum의 "강원"을 포함하는지 검사
                        siDo.contains(tourAddress.keyword)
                                // 2. 풀 네임으로 들어올 경우들을 위한 예외 매핑 통합 처리
                                || (tourAddress == CHUNGBUK && siDo.contains("충청북도"))
                                || (tourAddress == CHUNGNAM && siDo.contains("충청남도"))
                                || (tourAddress == JEONBUK && (siDo.contains("전라북도") || siDo.contains("전북특별자치도")))
                                || (tourAddress == JEONNAM && siDo.contains("전라남도"))
                                || (tourAddress == GYEONGBUK && siDo.contains("경상북도"))
                                || (tourAddress == GYEONGNAM && siDo.contains("경상남도"))
                                || (tourAddress == JEJU && siDo.contains("제주특별자치도")) // 💡 제주도 예외 필수 추가
                )
                .map(tourAddress -> tourAddress.code)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("지원하지 않는 시/도 주소 형식입니다: " + siDo));
    }
}