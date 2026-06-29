package com.busanit401.spring_back.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class RoutePointDTO {
    private double lat;
    private double lng;
    // 기기 측정 시각 (없으면 서버에서 현재 시각으로 채움)
    private LocalDateTime recordedAt;
}