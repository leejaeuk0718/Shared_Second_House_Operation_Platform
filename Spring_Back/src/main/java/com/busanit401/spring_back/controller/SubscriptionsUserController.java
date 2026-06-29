package com.busanit401.spring_back.controller;

import com.busanit401.spring_back.dto.subscriptionsUser.SubscriptionDateRangeResp;
import com.busanit401.spring_back.dto.subscriptionsUser.SubscriptionSearchCondition;
import com.busanit401.spring_back.dto.subscriptionsUser.SubscriptionsUserResp;
import com.busanit401.spring_back.domain.service.SubscriptionsUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/subscriptions")
@RequiredArgsConstructor
public class SubscriptionsUserController {

    private final SubscriptionsUserService subscriptionsUserService;

    // 내 구독 목록 조회
    @GetMapping("/my/{userId}")
    public ResponseEntity<List<SubscriptionsUserResp>> getMySubscriptions(
            @PathVariable Long userId) {
        return ResponseEntity.ok(subscriptionsUserService.getMySubscriptions(userId));
    }

    // 구독 상세 조회
    @GetMapping("/{subscriptionId}")
    public ResponseEntity<SubscriptionsUserResp> getSubscription(
            @PathVariable Long subscriptionId) {
        return ResponseEntity.ok(subscriptionsUserService.getSubscription(subscriptionId));
    }

    // 구독 취소 (대표만 가능)
    @DeleteMapping("/{subscriptionId}/{userId}")
    public ResponseEntity<SubscriptionsUserResp> cancel(
            @PathVariable Long subscriptionId,
            @PathVariable Long userId) {
        return ResponseEntity.ok(subscriptionsUserService.cancel(subscriptionId, userId));
    }

    // 관리자 - 구독 승인
    @PutMapping("/admin/{subscriptionId}/approve")
    public ResponseEntity<SubscriptionsUserResp> approve(
            @PathVariable Long subscriptionId) {
        return ResponseEntity.ok(subscriptionsUserService.approve(subscriptionId));
    }

    // 관리자 - 구독 반려
    @PutMapping("/admin/{subscriptionId}/reject")
    public ResponseEntity<SubscriptionsUserResp> reject(
            @PathVariable Long subscriptionId) {
        return ResponseEntity.ok(subscriptionsUserService.reject(subscriptionId));
    }

    // 관리자 - 복합 조건 검색
    @GetMapping("/admin/search")
    public ResponseEntity<List<SubscriptionsUserResp>> searchByCondition(
            SubscriptionSearchCondition condition) {
        return ResponseEntity.ok(subscriptionsUserService.searchByCondition(condition));
    }

    // [날짜 검증 추가] 특정 숙소의 사용 중인 구독 기간 목록 — 프론트 사용 불가 기간 표시용 (인증 불필요)
    @GetMapping("/accommodation/{accommodationId}")
    public ResponseEntity<List<SubscriptionDateRangeResp>> getSubscriptionsByAccommodation(
            @PathVariable Long accommodationId) {
        return ResponseEntity.ok(subscriptionsUserService.getSubscriptionsByAccommodation(accommodationId));
    }
}