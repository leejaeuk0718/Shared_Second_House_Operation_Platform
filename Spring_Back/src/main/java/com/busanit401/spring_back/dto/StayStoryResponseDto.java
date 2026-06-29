package com.busanit401.spring_back.dto;

import com.busanit401.spring_back.domain.entity.StayStory;
import lombok.*;

@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class StayStoryResponseDto {

    private Long id;                // 스토리 ID
    private Integer orderNum;       // 표시 순서 (1, 2, 3, 4)
    private String title;           // 스토리 제목
    private String content;         // 스토리 본문 텍스트
    private String imageUrl;        // 스토리 이미지 URL 1장

    // ── Entity → DTO 변환 메서드 ──────────────────────────────
    public static StayStoryResponseDto from(StayStory story) {
        return StayStoryResponseDto.builder()
                .id(story.getId())
                .orderNum(story.getOrderNum())
                .title(story.getTitle())
                .content(story.getContent())
                .imageUrl(story.getImageUrl())
                .build();
    }
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.dto.StayStoryResponseDto
 * 역할  : 스토리 응답 DTO (Service → Controller → 프론트)
 * 사용처 : StayStoryServiceImpl (getStories, createStory, updateStory)
 * ----------------------------------------------------------------------------------
 * [파일 흐름]
 * StayStory 엔티티 → from() → 이 DTO → 프론트 응답
 * 사용 화면: 숙소 상세 페이지 [섹션6] 스토리 01~04 표시
 * ----------------------------------------------------------------------------------
 * [정적 메서드]
 * - from(story) : StayStory Entity → 이 DTO 변환
 * ==================================================================================
 */