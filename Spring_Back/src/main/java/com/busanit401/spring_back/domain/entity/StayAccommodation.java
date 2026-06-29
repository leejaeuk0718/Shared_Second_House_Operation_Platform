package com.busanit401.spring_back.domain.entity;

import com.busanit401.spring_back.domain.BaseTimeEntity;
import com.busanit401.spring_back.domain.SubscriptionsUser;
import com.busanit401.spring_back.dto.StayAccommodationRequestDto;
import com.busanit401.spring_back.enums.StayAccommodationStatus;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "sh_stay_accommodation")
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@ToString
public class StayAccommodation extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "accommodation_id")
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;            // 숙소명 (예: 속초 반달)

    @Column(nullable = false, length = 200)
    private String address;         // 주소

    @Column(columnDefinition = "TEXT")
    private String description;     // 숙소 설명

    @Column(columnDefinition = "TEXT")
    private String imageUrl;        // 이미지 URL 목록 (쉼표 구분, 프론트에서 split 처리)
    // TODO [고도화]: 이미지 파일 업로드 → S3 연동으로 교체

    @Column(columnDefinition = "TEXT")
    private String amenities;       // 구성용품 (쉼표 구분, 프론트에서 split 후 react-icons 매핑)

    @Column(nullable = false)
    private Integer monthlyPrice;   // 숙소별 월세 (할인율은 공통 테이블에서 관리)

    @Column(nullable = false)
    private Integer roomCount;      // 방 수

    @Column(nullable = false)
    private Integer bathroomCount;  // 화장실 수

    @Column(nullable = false)
    private Integer floorCount;     // 층수

    private Integer parkingCount;   // 주차 가능 대수
    private Double landArea;        // 대지면적 (평)
    private Double buildingArea;    // 건물면적 (평)

    private Double latitude;        // 위도 (지도 표시용)
    private Double longitude;       // 경도 (지도 표시용)

    // Enum을 DB에 문자열("AVAILABLE", "MAINTENANCE")로 저장
    // EnumType.ORDINAL(숫자) 대신 STRING 사용 → 가독성 및 안전성 확보
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StayAccommodationStatus status; // AVAILABLE(예약 가능) / MAINTENANCE(점검 중)


    @Builder.Default
    @OneToMany(mappedBy = "stayAccommodation", cascade = CascadeType.ALL)
    private List<StayReservation> reservations = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "stayAccommodation", cascade = CascadeType.ALL)
    private List<StayStory> stories = new ArrayList<>();

    // ── 숙소 이미지 URL 저장 비즈니스 메서드 ─────────────────
    public void updateImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    // ── 숙소 정보 수정 비즈니스 메서드 (@Setter 대신 사용) ───
    public void update(StayAccommodationRequestDto dto) {
        this.name = dto.getName();
        this.address = dto.getAddress();
        this.description = dto.getDescription();
        this.imageUrl = dto.getImageUrl();
        this.amenities = dto.getAmenities();
        this.monthlyPrice = dto.getMonthlyPrice();
        this.roomCount = dto.getRoomCount();
        this.bathroomCount = dto.getBathroomCount();
        this.floorCount = dto.getFloorCount();
        this.parkingCount = dto.getParkingCount();
        this.landArea = dto.getLandArea();
        this.buildingArea = dto.getBuildingArea();
        this.latitude = dto.getLatitude();
        this.longitude = dto.getLongitude();
        this.status = dto.getStatus();
    }
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.entity.StayAccommodation
 * 역할  : 숙소 엔티티 (DB 테이블: sh_stay_accommodation)
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - StayReservation.java              : 예약 (1:N, CascadeType.ALL)
 * - StayStory.java                    : 스토리 (1:N, CascadeType.ALL)
 * - StayAccommodationRequestDto.java  : 등록/수정 요청 DTO (update() 인자)
 * - StayAccommodationStatus.java      : 상태 Enum (AVAILABLE / MAINTENANCE)
 * ----------------------------------------------------------------------------------
 * [필드 요약]
 * - imageUrl  : 이미지 URL 목록 (쉼표 구분) → 프론트에서 split(",") 후 사용
 * - amenities : 구성용품 (쉼표 구분) → 프론트에서 split 후 react-icons 매핑
 * - monthlyPrice : 숙소별 월세 (할인율은 공통 테이블 StayAccommodationPrice 에서 관리)
 * ----------------------------------------------------------------------------------
 * [비즈니스 메서드]
 * - update(dto) : 숙소 정보 일괄 수정 (@Setter 대신 사용)
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * - 숙소 삭제 시 CascadeType.ALL 로 StayReservation, StayStory 함께 삭제됨
 * - EnumType.STRING 사용 → DB에 "AVAILABLE", "MAINTENANCE" 문자열로 저장
 * ==================================================================================
 */