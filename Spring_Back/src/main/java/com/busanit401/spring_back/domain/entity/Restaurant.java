package com.busanit401.spring_back.domain.entity;

import com.busanit401.spring_back.domain.BaseTimeEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * 구글 Places에서 읽어온 주변 맛집을 저장하는 엔티티 (테이블 {@code sh_restaurant}).
 *
 * <p>어느 숙소({@code sh_stay_accommodation}) 부근인지를 FK로 들고 있다. 같은 맛집이
 * 여러 숙소 부근일 수 있어, 중복 판단은 (accommodation_id, place_id) 조합으로 한다 —
 * 같은 숙소에서 같은 맛집을 다시 읽어오면 새로 넣지 않고 변동 필드를 갱신(upsert)한다.
 */
@Entity
@Table(name = "sh_restaurant",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_sh_restaurant_acc_place",
                columnNames = {"accommodation_id", "place_id"}))
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@ToString(exclude = "accommodation")
public class Restaurant extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "restaurant_id")
    private Long id;

    /** 어느 숙소 부근인지 (FK). */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "accommodation_id", nullable = false)
    private StayAccommodation accommodation;

    /** 구글 place id (숙소별 자연키, 중복 판단 기준). */
    @Column(name = "place_id", nullable = false, length = 300)
    private String placeId;

    @Column(nullable = false, length = 200)
    private String name;                 // displayName.text

    @Column(length = 100)
    private String primaryType;          // primaryType (예: japanese_restaurant)

    @Column(length = 50)
    private String phoneNumber;          // nationalPhoneNumber

    private Double latitude;             // location.latitude
    private Double longitude;            // location.longitude

    @Column(columnDefinition = "TEXT")
    private String googleMapsUri;        // googleMapsUri

    // regularOpeningHours.weekdayDescriptions — 줄바꿈(\n)으로 합쳐 저장, 조회 시 split
    @Column(columnDefinition = "TEXT")
    private String weekdayDescriptions;

    /** 인기도 순위 (구글 응답 순서, 0이 가장 인기). 조회 정렬/랜덤 선별에 사용. */
    @Column(name = "popularity_rank")
    private Integer popularityRank;

    /** 같은 (숙소, placeId)를 다시 읽어왔을 때 변동 필드만 갱신 (upsert의 update 경로). */
    public void update(String name, String primaryType, String phoneNumber,
                       Double latitude, Double longitude, String googleMapsUri,
                       String weekdayDescriptions, Integer popularityRank) {
        this.name = name;
        this.primaryType = primaryType;
        this.phoneNumber = phoneNumber;
        this.latitude = latitude;
        this.longitude = longitude;
        this.googleMapsUri = googleMapsUri;
        this.weekdayDescriptions = weekdayDescriptions;
        this.popularityRank = popularityRank;
    }
}