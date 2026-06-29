package com.busanit401.spring_back.dto;

import com.busanit401.spring_back.enums.StayAccommodationStatus;
import lombok.*;

@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class StayAccommodationRequestDto {

    private String name;            // 숙소명
    private String address;         // 주소
    private String description;     // 숙소 설명
    private String imageUrl;        // 이미지 URL 목록 (쉼표 구분)
    private String amenities;       // 구성용품 (쉼표 구분)

    private Integer monthlyPrice;   // 숙소별 월세

    private Integer roomCount;      // 방 수
    private Integer bathroomCount;  // 화장실 수
    private Integer floorCount;     // 층수
    private Integer parkingCount;   // 주차 가능 대수

    private Double landArea;        // 대지면적 (평)
    private Double buildingArea;    // 건물면적 (평)

    private Double latitude;        // 위도
    private Double longitude;       // 경도

    private StayAccommodationStatus status; // AVAILABLE / MAINTENANCE
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.dto.StayAccommodationRequestDto
 * 역할  : 숙소 등록/수정 요청 DTO (프론트 관리자 화면 → Controller → Service)
 * 사용처 : StayAccommodationController (createAccommodation, updateAccommodation)
 * ----------------------------------------------------------------------------------
 * [파일 흐름]
 * 관리자 숙소 등록/수정 → POST/PUT /api/stay/accommodations → 이 DTO 수신
 * → createAccommodation() : builder() 로 Entity 변환 후 저장
 * → updateAccommodation() : StayAccommodation.update(dto) 로 수정
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * - imageUrl, amenities : 쉼표 구분 문자열로 전달 → DB에 TEXT 로 저장
 * ==================================================================================
 */