package com.busanit401.spring_back.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
// 🚨 팀 DB 규칙: 테이블명 앞에 sh_ 접두사
@Table(name = "sh_route_session")
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@ToString
public class RouteSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long sessionId;

    @Column(nullable = false)
    private Long userId;

    private LocalDateTime startedAt;

    private LocalDateTime endedAt;

    @PrePersist
    public void prePersist() {
        if (this.startedAt == null) {
            this.startedAt = LocalDateTime.now();
        }
    }

    /** 추적 종료 시각 기록 */
    public void end() {
        this.endedAt = LocalDateTime.now();
    }
}