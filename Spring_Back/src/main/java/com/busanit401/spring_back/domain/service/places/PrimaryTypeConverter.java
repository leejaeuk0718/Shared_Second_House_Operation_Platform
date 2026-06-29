package com.busanit401.spring_back.domain.service.places;

import java.util.Map;

/**
 * 구글 Places의 primaryType 코드(예: "korean_restaurant")를 한글 표시명("한식")으로 변환.
 * sync → DB 저장 시점에 적용해, 저장되는 primaryType 값 자체를 한글로 둔다.
 */
public final class PrimaryTypeConverter {

    private static final String DEFAULT = "식당";

    private static final Map<String, String> TYPE_KO = Map.ofEntries(
            Map.entry("korean_restaurant", "한식 식당"),
            Map.entry("japanese_restaurant", "일식 식당"),
            Map.entry("chinese_restaurant", "중식 식당"),
            Map.entry("asian_restaurant", "동남아 음식 식당"),
            Map.entry("cafe", "카페"),
            Map.entry("coffee_shop", "커피숍"),
            Map.entry("bakery", "빵집"),
            Map.entry("ice_cream_shop", "아이스크림 가게"),
            Map.entry("western_restaurant", "양식 식당"),
            Map.entry("italian_restaurant", "이탈리아 음식 식당"),
            Map.entry("pizza_restaurant", "피자 전문점"),
            Map.entry("hamburger_restaurant", "수제버거"),
            Map.entry("steak_house", "스테이크 하우스"),
            Map.entry("barbecue_restaurant", "고깃집"),
            Map.entry("fast_food_restaurant", "패스트푸드"),
            Map.entry("bar", "술집"),
            Map.entry("pub", "호프"),
            Map.entry("wine_bar", "와인바"),
            Map.entry("brewery", "수제맥주집"),
            Map.entry("restaurant", "식당"),
            Map.entry("meal_takeaway", "포장 전문점"),
            Map.entry("meal_delivery", "배달 전문점"));

    private PrimaryTypeConverter() {
    }

    /** 코드 → 한글 표시명. 맵에 없거나 null이면 '식당'으로 방어. */
    public static String toKorean(String type) {
        return TYPE_KO.getOrDefault(type, DEFAULT);
    }
}