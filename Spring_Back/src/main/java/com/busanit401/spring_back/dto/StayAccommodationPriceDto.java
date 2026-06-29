package com.busanit401.spring_back.dto;

import com.busanit401.spring_back.domain.entity.StayAccommodationPrice;
import lombok.*;

@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class StayAccommodationPriceDto {

    private Long id;                // 가격 구간 ID
    private Integer minMonths;      // 최소 계약 월 수
    private Integer maxMonths;      // 최대 계약 월 수 (null이면 제한 없음)
    private Double discountRate;    // 할인율 (예: 0.0, 0.07, 0.15)

    // ── Entity → DTO 변환 메서드 ──────────────────────────────
    public static StayAccommodationPriceDto from(StayAccommodationPrice price) {
        return StayAccommodationPriceDto.builder()
                .id(price.getId())
                .minMonths(price.getMinMonths())
                .maxMonths(price.getMaxMonths())
                .discountRate(price.getDiscountRate())
                .build();
    }
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.dto.StayAccommodationPriceDto
 * 역할  : 공통 할인율 구간 응답 DTO
 * 사용처 : StayAccommodationResponseDto.prices 리스트 안에 포함되어 응답
 * ----------------------------------------------------------------------------------
 * [파일 흐름]
 * StayAccommodationPrice 엔티티 → from() → 이 DTO
 * → StayAccommodationResponseDto.prices 리스트에 포함 → 프론트 응답
 * 프론트에서 개월수 선택 → 이 DTO의 discountRate 로 월세 자동 계산
 * ----------------------------------------------------------------------------------
 * [정적 메서드]
 * - from(price) : StayAccommodationPrice Entity → 이 DTO 변환
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * - 월세(monthlyPrice)는 StayAccommodationResponseDto 에 있음
 * - discountRate 적용: 월세 × (1 - discountRate) = 실제 청구 금액
 * ==================================================================================
 */