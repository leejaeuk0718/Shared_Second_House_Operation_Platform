package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.domain.RoutePoint;
import com.busanit401.spring_back.domain.RouteSession;
import com.busanit401.spring_back.domain.repository.RoutePointRepository;
import com.busanit401.spring_back.domain.repository.RouteSessionRepository;
import com.busanit401.spring_back.dto.RoutePointDTO;
import com.busanit401.spring_back.dto.RouteSessionDTO;
import com.busanit401.spring_back.dto.RouteSessionDetailDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 🗺️ 사용자 이동경로 추적 서비스
 * - 추적 세션(RouteSession) 생성/종료
 * - 기기에서 올라온 좌표(RoutePoint) 묶음 저장
 * - 폴리라인용 좌표 조회 / 세션 이력 조회
 */
@Service
@RequiredArgsConstructor
@Transactional
public class RouteService {

    private final RouteSessionRepository sessionRepository;
    private final RoutePointRepository pointRepository;

    /** 추적 시작 — 새 세션 생성 후 sessionId 반환 */
    public Long startSession(Long userId) {
        RouteSession session = RouteSession.builder()
                .userId(userId)
                .build();
        return sessionRepository.save(session).getSessionId();
    }

    /** 좌표 묶음 저장 (배터리·네트워크 절약을 위해 앱에서 버퍼링 후 묶어 전송) */
    public int addPoints(Long sessionId, List<RoutePointDTO> points) {
        // 존재하지 않는 세션이면 예외
        sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("해당 추적 세션이 존재하지 않습니다. ID: " + sessionId));

        List<RoutePoint> entities = points.stream()
                .map(p -> RoutePoint.builder()
                        .sessionId(sessionId)
                        .lat(p.getLat())
                        .lng(p.getLng())
                        .recordedAt(p.getRecordedAt())
                        .build())
                .collect(Collectors.toList());

        pointRepository.saveAll(entities);
        return entities.size();
    }

    /** 추적 종료 — endedAt 기록 */
    public void endSession(Long sessionId) {
        RouteSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("해당 추적 세션이 존재하지 않습니다. ID: " + sessionId));
        session.end();
    }

    /** 폴리라인용 — 한 세션의 좌표를 측정 시각 오름차순으로 */
    @Transactional(readOnly = true)
    public List<RoutePointDTO> getPoints(Long sessionId) {
        return pointRepository.findBySessionIdOrderByRecordedAtAsc(sessionId).stream()
                .map(p -> RoutePointDTO.builder()
                        .lat(p.getLat())
                        .lng(p.getLng())
                        .recordedAt(p.getRecordedAt())
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * 기간 내 세션 + 각 세션의 좌표를 함께 반환 (웹 예약별 경로 지도용).
     * from/to는 날짜이며 [from 00:00 ~ to 23:59:59] 범위로 본다.
     */
    @Transactional(readOnly = true)
    public List<RouteSessionDetailDTO> getSessionsWithPoints(Long userId, LocalDate from, LocalDate to) {
        return sessionRepository
                .findByUserIdAndStartedAtBetweenOrderByStartedAtAsc(
                        userId, from.atStartOfDay(), to.plusDays(1).atStartOfDay())
                .stream()
                .map(s -> RouteSessionDetailDTO.builder()
                        .sessionId(s.getSessionId())
                        .startedAt(s.getStartedAt())
                        .endedAt(s.getEndedAt())
                        .points(getPoints(s.getSessionId()))
                        .build())
                .collect(Collectors.toList());
    }

    /** 유저별 추적 세션 이력 (최신순) */
    @Transactional(readOnly = true)
    public List<RouteSessionDTO> getSessions(Long userId) {
        return sessionRepository.findByUserIdOrderByStartedAtDesc(userId).stream()
                .map(s -> RouteSessionDTO.builder()
                        .sessionId(s.getSessionId())
                        .userId(s.getUserId())
                        .startedAt(s.getStartedAt())
                        .endedAt(s.getEndedAt())
                        .build())
                .collect(Collectors.toList());
    }
}