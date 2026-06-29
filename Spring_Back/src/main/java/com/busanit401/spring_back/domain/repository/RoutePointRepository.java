package com.busanit401.spring_back.domain.repository;

import com.busanit401.spring_back.domain.RoutePoint;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface RoutePointRepository extends JpaRepository<RoutePoint, Long> {
    // 한 세션의 좌표를 측정 시각 오름차순으로 (폴리라인 그리기용)
    List<RoutePoint> findBySessionIdOrderByRecordedAtAsc(Long sessionId);
}