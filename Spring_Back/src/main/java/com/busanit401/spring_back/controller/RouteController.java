package com.busanit401.spring_back.controller;

import com.busanit401.spring_back.domain.service.RouteService;
import com.busanit401.spring_back.dto.RoutePointDTO;
import com.busanit401.spring_back.dto.RouteSessionDTO;
import com.busanit401.spring_back.dto.RouteSessionDetailDTO;
import com.busanit401.spring_back.security.auth.CustomUserDetails;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Tag(name = "Controller - 🗺️ 이동경로 추적 API", description = "플러터 앱에서 백그라운드로 수집한 위치 좌표를 세션 단위로 저장/조회")
@RestController
@RequestMapping("/api/routes")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class RouteController {

    private final RouteService routeService;

    @Operation(summary = "📱 [Flutter] 추적 시작 (세션 생성)",
            description = "이동경로 추적을 시작할 때 호출. 새 세션을 만들고 sessionId를 반환한다. 유저는 JWT에서 획득한다.")
    @PostMapping("/sessions")
    public ResponseEntity<Map<String, Object>> startSession(
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        // 토큰이 없거나 무효하면 principal이 null → NPE(500) 대신 명확히 401 반환
        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("success", false, "message", "로그인이 필요합니다."));
        }
        Long sessionId = routeService.startSession(userDetails.getId());
        return ResponseEntity.ok(Map.of("success", true, "sessionId", sessionId));
    }

    @Operation(summary = "📱 [Flutter] 좌표 묶음 저장",
            description = "백그라운드 서비스가 버퍼링한 좌표 배열을 세션에 append 한다.")
    @PostMapping("/sessions/{sessionId}/points")
    public ResponseEntity<Map<String, Object>> addPoints(
            @Parameter(description = "추적 세션 id", example = "1")
            @PathVariable Long sessionId,
            @RequestBody List<RoutePointDTO> points) {

        int saved = routeService.addPoints(sessionId, points);
        return ResponseEntity.ok(Map.of("success", true, "saved", saved));
    }

    @Operation(summary = "📱 [Flutter] 추적 종료",
            description = "추적을 멈출 때 호출. 세션의 종료 시각을 기록한다.")
    @PostMapping("/sessions/{sessionId}/end")
    public ResponseEntity<Map<String, Object>> endSession(
            @Parameter(description = "추적 세션 id", example = "1")
            @PathVariable Long sessionId) {

        routeService.endSession(sessionId);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @Operation(summary = "📱 [Flutter] 세션 좌표 조회 (폴리라인용)",
            description = "한 세션의 좌표를 측정 시각 오름차순으로 반환한다. 지도에 선으로 그리는 데 사용.")
    @GetMapping("/sessions/{sessionId}/points")
    public ResponseEntity<List<RoutePointDTO>> getPoints(
            @Parameter(description = "추적 세션 id", example = "1")
            @PathVariable Long sessionId) {

        return ResponseEntity.ok(routeService.getPoints(sessionId));
    }

    @Operation(summary = "📱 [Flutter] 세션 이력 조회",
            description = "유저의 이동경로 세션 목록을 최신순으로 반환한다. 유저는 JWT에서 획득한다.")
    @GetMapping("/sessions")
    public ResponseEntity<List<RouteSessionDTO>> getSessions(
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        if (userDetails == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(routeService.getSessions(userDetails.getId()));
    }

    @Operation(summary = "💻 [Next.js] 기간별 경로 조회 (세션+좌표 묶음)",
            description = "예약 기간 등 from~to 날짜 범위에 시작된 세션과 각 좌표를 한 번에 반환한다. 유저는 JWT에서 획득한다.")
    @GetMapping("/sessions/detail")
    public ResponseEntity<List<RouteSessionDetailDTO>> getSessionsWithPoints(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Parameter(description = "시작 날짜 (yyyy-MM-dd)", example = "2026-06-01")
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @Parameter(description = "종료 날짜 (yyyy-MM-dd, 포함)", example = "2026-06-30")
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {

        return ResponseEntity.ok(routeService.getSessionsWithPoints(userDetails.getId(), from, to));
    }
}