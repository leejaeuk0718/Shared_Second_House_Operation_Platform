package com.busanit401.spring_back.domain.repository;

import com.busanit401.spring_back.domain.RouteSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface RouteSessionRepository extends JpaRepository<RouteSession, Long> {
    // 유저별 이동경로 세션 이력 (최신순)
    List<RouteSession> findByUserIdOrderByStartedAtDesc(Long userId);

    // 유저별 + 시작 시각이 기간 내인 세션 (시간순) — 예약 기간 경로 조회용
    List<RouteSession> findByUserIdAndStartedAtBetweenOrderByStartedAtAsc(
            Long userId, LocalDateTime from, LocalDateTime to);
}