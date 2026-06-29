package com.busanit401.spring_back.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 한 추적 세션 + 그 세션의 좌표 전체를 함께 담는 DTO.
 * 웹(Next.js) 예약별 경로 지도에서 N+1 호출 없이 한 번에 받기 위함.
 */
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class RouteSessionDetailDTO {
    private Long sessionId;
    private LocalDateTime startedAt;
    private LocalDateTime endedAt;
    private List<RoutePointDTO> points;
}