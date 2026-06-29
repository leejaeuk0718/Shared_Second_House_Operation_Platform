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
public class RouteSessionDTO {
    private Long sessionId;
    private Long userId;
    private LocalDateTime startedAt;
    private LocalDateTime endedAt;
}