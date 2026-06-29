package com.busanit401.spring_back.domain.entity;

import com.busanit401.spring_back.domain.BaseTimeEntity;
import com.busanit401.spring_back.dto.StayStoryRequestDto;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "sh_stay_story")
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@ToString
public class StayStory extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "story_id")
    private Long id;

    // 어떤 숙소의 스토리인지 (FK)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "accommodation_id", nullable = false)
    private StayAccommodation stayAccommodation;

    @Column(nullable = false)
    private Integer orderNum;       // 표시 순서 (1, 2, 3, 4)

    @Column(nullable = false, length = 100)
    private String title;           // 스토리 제목

    @Column(columnDefinition = "TEXT")
    private String content;         // 스토리 본문 텍스트

    @Column(length = 500)
    private String imageUrl;        // 스토리 이미지 1장

    // ── 스토리 이미지 URL 저장 비즈니스 메서드 ───────────────
    public void updateImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    // ── 스토리 수정 비즈니스 메서드 (@Setter 대신 사용) ──────
    public void update(StayStoryRequestDto dto) {
        this.orderNum = dto.getOrderNum();
        this.title = dto.getTitle();
        this.content = dto.getContent();
        this.imageUrl = dto.getImageUrl();
    }
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.entity.StayStory
 * 역할  : 숙소 스토리 엔티티 (DB 테이블: sh_stay_story)
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - StayAccommodation.java      : 숙소 (N:1, LAZY)
 * - StayStoryRequestDto.java    : 수정 요청 DTO (update() 인자)
 * - StayStoryServiceImpl.java   : update() 호출
 * ----------------------------------------------------------------------------------
 * [필드 요약]
 * - orderNum : 표시 순서 (1~4) → 프론트 스토리 섹션 순서 결정
 * - imageUrl : 스토리 이미지 1장 URL
 * ----------------------------------------------------------------------------------
 * [비즈니스 메서드]
 * - update(dto) : 스토리 정보 일괄 수정 (@Setter 대신 사용)
 * ==================================================================================
 */