package com.busanit401.spring_back.dto;

import lombok.*;

@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class StayStoryRequestDto {

    private Long accommodationId;   // 어떤 숙소의 스토리인지
    private Integer orderNum;       // 표시 순서 (1, 2, 3, 4)
    private String title;           // 스토리 제목
    private String content;         // 스토리 본문 텍스트
    private String imageUrl;        // 스토리 이미지 URL 1장
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.dto.StayStoryRequestDto
 * 역할  : 스토리 등록/수정 요청 DTO (프론트 관리자 화면 → Controller → Service)
 * 사용처 : StayStoryController (createStory, updateStory)
 * ----------------------------------------------------------------------------------
 * [파일 흐름]
 * 관리자 스토리 등록/수정 → POST/PUT /api/stay/stories → 이 DTO 수신
 * → createStory() : builder() 로 Entity 변환 후 저장
 * → updateStory() : StayStory.update(dto) 로 수정
 * ==================================================================================
 */