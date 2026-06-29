package com.busanit401.spring_back.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
// 🚨 팀 DB 규칙: 테이블명 앞에 sh_ 접두사
@Table(name = "sh_route_point")
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@ToString
public class RoutePoint {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long pointId;

    // 어떤 추적 세션의 좌표인지 (단순 FK 컬럼 — 기존 DeliveryOrder.userId 스타일과 동일)
    @Column(nullable = false)
    private Long sessionId;

    @Column(nullable = false)
    private double lat;

    @Column(nullable = false)
    private double lng;

    // 기기에서 위치가 측정된 시각 (서버 도착 시각과 구분)
    private LocalDateTime recordedAt;

    @PrePersist
    public void prePersist() {
        if (this.recordedAt == null) {
            this.recordedAt = LocalDateTime.now();
        }
    }
}