package com.busanit401.spring_back.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;


@Getter
@AllArgsConstructor
public class TourDto {
        private String title;       // 관광지명
        private String firstimage;  // 썸네일 이미지 URL
        private String addr1;       // 주소
        private String contentid;   // 상세 조회를 위한 ID
    }

    // AttractionResponse 지역별 관광 데이터를 담을 dto