package com.busanit401.spring_back.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;


@Getter
@AllArgsConstructor
public class TourResponseListDto {
        private List<TourDto> tours; // 관광지 리스트
        private boolean isLast;       // 마지막 페이지 여부
}