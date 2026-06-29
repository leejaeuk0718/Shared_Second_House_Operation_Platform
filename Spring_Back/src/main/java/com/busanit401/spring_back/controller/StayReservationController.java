package com.busanit401.spring_back.controller;

import com.busanit401.spring_back.domain.service.StayReservationService;
import com.busanit401.spring_back.dto.StayReservationRequestDto;
import com.busanit401.spring_back.dto.StayReservationResponseDto;
import com.busanit401.spring_back.security.auth.CustomUserDetails;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Log4j2
@RestController
@RequestMapping("/api/stay/reservations")
@RequiredArgsConstructor
@Tag(name = "Stay Reservation", description = "숙소 예약 관리 API")
public class StayReservationController {

    private final StayReservationService reservationService;

    // ── 내 예약 목록 조회 ─────────────────────────────────────
    @GetMapping
    @Operation(summary = "내 예약 목록 조회", description = "로그인한 유저의 예약 목록을 조회합니다.")
    public ResponseEntity<List<StayReservationResponseDto>> getReservations(
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        log.info("✅ [StayReservationController] 내 예약 목록 조회 → userId: {}", userDetails.getId());
        return ResponseEntity.ok(reservationService.getReservations(userDetails.getId()));
    }

    // ── 예약 생성 ─────────────────────────────────────────────
    @PostMapping
    @Operation(summary = "예약 생성", description = "숙소를 예약합니다.")
    public ResponseEntity<StayReservationResponseDto> createReservation(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody StayReservationRequestDto requestDto) {
        log.info("✅ [StayReservationController] 예약 생성 → userId: {}", userDetails.getId());
        return ResponseEntity.ok(reservationService.createReservation(userDetails.getId(), requestDto));
    }

    // ── 숙소별 확정 예약 목록 조회 (달력 비활성 날짜용) ──────
    @GetMapping("/accommodation/{accommodationId}")
    @Operation(summary = "숙소별 예약 목록 조회", description = "해당 숙소의 CONFIRMED 예약 목록을 조회합니다. (달력 비활성 날짜 표시용)")
    public ResponseEntity<List<StayReservationResponseDto>> getReservationsByAccommodation(
            @PathVariable Long accommodationId) {
        log.info("✅ [StayReservationController] 숙소별 예약 목록 조회 → accommodationId: {}", accommodationId);
        return ResponseEntity.ok(reservationService.getReservationsByAccommodation(accommodationId));
    }

    // ── [관리자] 전체 예약 목록 조회 ──────────────────────────
    @GetMapping("/admin/all")
    @Operation(summary = "[관리자] 전체 예약 목록 조회", description = "전체 예약 목록을 조회합니다. userId 파라미터가 있으면 해당 유저만 필터링합니다. (관리자 전용)")
    public ResponseEntity<List<StayReservationResponseDto>> getAllReservations(
            @RequestParam(required = false) Long userId) {
        log.info("✅ [StayReservationController] 전체 예약 목록 조회 (관리자) → userId: {}", userId);
        return ResponseEntity.ok(reservationService.getAllReservations(userId));
    }

    // ── 예약 취소 ─────────────────────────────────────────────
    @PatchMapping("/{id}/cancel")
    @Operation(summary = "예약 취소", description = "예약을 취소합니다.")
    public ResponseEntity<Boolean> cancelReservation(
            @PathVariable Long id,
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        log.info("✅ [StayReservationController] 예약 취소 → reservationId: {}, userId: {}", id, userDetails.getId());
        reservationService.cancelReservation(id, userDetails.getId());
        return ResponseEntity.ok(true);
    }
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.controller.StayReservationController
 * 역할  : 숙소 예약 REST API 엔드포인트 (요청 수신 → Service 호출 → 응답 반환)
 * 사용처 : 프론트(Next.js), 앱(Flutter)
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - StayReservationService.java        : 비즈니스 로직 인터페이스
 * - StayReservationServiceImpl.java    : 비즈니스 로직 구현체
 * - StayReservationRequestDto.java     : 예약 생성 요청 DTO
 * - StayReservationResponseDto.java    : 예약 응답 DTO
 * - CustomUserDetails.java             : 로그인 유저 정보 (@AuthenticationPrincipal)
 * ----------------------------------------------------------------------------------
 * [API 목록]
 * - GET    /api/stay/reservations                        : 내 예약 목록 조회
 * - POST   /api/stay/reservations                        : 예약 생성
 * - GET    /api/stay/reservations/accommodation/{id}     : 숙소별 확정 예약 목록 조회
 * - PATCH  /api/stay/reservations/{id}/cancel            : 예약 취소
 * - GET    /api/stay/reservations/admin/all              : [관리자] 전체 예약 목록 조회 (userId 파라미터로 필터링 가능)
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * [조회] GET  → getReservations(userDetails)               → Service → 정렬된 목록 반환
 * [생성] POST → createReservation(userDetails, requestDto) → Service → 중복체크 → 저장 → 반환
 * [달력] GET  → getReservationsByAccommodation(id)         → Service → CONFIRMED 목록 반환
 * [취소] PATCH → cancelReservation(id, userDetails)        → Service → 본인 확인 → CANCELLED
 * [관리자] GET → getAllReservations(userId?)                → Service → 전체 or 유저별 목록 시작일 내림차순 반환
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * - 모든 userId는 @AuthenticationPrincipal CustomUserDetails.getId() 로 서버에서 획득
 * - 프론트에서 userId 파라미터 전달 불필요 (SecurityConfig에서 인증 보장)
 * - cancelReservation은 true(Boolean) 반환 (204 No Content 대신 200 + JSON 으로 fetch 파싱 오류 방지)
 * ==================================================================================
 */