package com.busanit401.spring_back.domain.entity;

import com.busanit401.spring_back.domain.BaseTimeEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "sh_stay_accommodation_price")
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@ToString
public class StayAccommodationPrice extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "price_id")
    private Long id;

    // accommodationId 제거 → 공통 할인율 테이블로 변경
    // monthlyPrice 제거 → StayAccommodation으로 이동

    @Column(nullable = false)
    private Integer minMonths;      // 최소 계약 월 수

    private Integer maxMonths;      // 최대 계약 월 수 (null이면 제한 없음)

    @Column(nullable = false)
    private Double discountRate;    // 할인율 (예: 1-1개월 : 0.0, 3-5개월 : 0.07, 6개월이상 : 0.15)
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.entity.StayAccommodationPrice
 * 역할  : 공통 할인율 구간 엔티티 (DB 테이블: sh_stay_accommodation_price)
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - StayAccommodationPriceRepository.java : 전체 조회 (findAll)
 * - StayAccommodationPriceDto.java        : 응답 DTO 변환
 * - StayAccommodationServiceImpl.java     : getCommonPrices() 에서 사용
 * ----------------------------------------------------------------------------------
 * [필드 요약]
 * - minMonths   : 최소 계약 월 수
 * - maxMonths   : 최대 계약 월 수 (null 이면 상한 없음 → "6개월 이상" 구간)
 * - discountRate : 할인율 (0.0 = 0%, 0.07 = 7%, 0.15 = 15%)
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * - 숙소별 가격이 아닌 공통 테이블 → 모든 숙소에 동일한 할인율 구간 적용
 * - 프론트에서 개월수 선택 시 이 테이블의 구간과 매칭하여 월세 자동 계산
 * ==================================================================================
 */