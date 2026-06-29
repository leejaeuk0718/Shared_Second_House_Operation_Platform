package com.busanit401.spring_back.domain.repository;

import com.busanit401.spring_back.domain.SubscriptionsUser;
import com.busanit401.spring_back.enums.SubscriptionStatus;
import com.busanit401.spring_back.domain.repository.custom.SubscriptionsUserRepositoryCustom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface SubscriptionsUserRepository extends JpaRepository<SubscriptionsUser, Long>, SubscriptionsUserRepositoryCustom {

    // 특정 유저의 특정 구독 조회 (취소 시 사용)
    Optional<SubscriptionsUser> findByIdAndUserId(Long subscriptionId, Long userId);

    // 특정 유저의 전체 구독 목록
    List<SubscriptionsUser> findAllByUserId(Long userId);

    // 상태별 구독 목록 (관리자 페이지)
    List<SubscriptionsUser> findAllByStatus(SubscriptionStatus status);

    // 같은 숙소 중복 구독 체크
    boolean existsByUserIdAndAccommodationIdAndStatus(Long userId, Long accommodationId, SubscriptionStatus status);

    // [날짜 검증 추가] 날짜 겹침 구독 조회 — apply() 신청 시 사용 (save() 전 호출이라 자기 자신 제외 불필요)
    // 겹침 조건: existStart < newEnd AND existEnd > newStart (경계 이어지는 날짜는 겹침 아님)
    @Query("""
        SELECT s FROM SubscriptionsUser s
        WHERE s.accommodationId = :accommodationId
          AND s.status IN :statuses
          AND s.startDate < :newEnd
          AND s.endDate > :newStart
    """)
    List<SubscriptionsUser> findOverlappingSubscriptions(
        @Param("accommodationId") Long accommodationId,
        @Param("newStart") LocalDate newStart,
        @Param("newEnd") LocalDate newEnd,
        @Param("statuses") List<SubscriptionStatus> statuses
    );

    // [날짜 검증 추가] 날짜 겹침 구독 조회 — approve() 승인 시 사용 (자기 자신도 PENDING이라 excludeId로 제외)
    @Query("""
        SELECT s FROM SubscriptionsUser s
        WHERE s.accommodationId = :accommodationId
          AND s.id != :excludeId
          AND s.status IN :statuses
          AND s.startDate < :newEnd
          AND s.endDate > :newStart
    """)
    List<SubscriptionsUser> findOverlappingSubscriptionsExcluding(
        @Param("accommodationId") Long accommodationId,
        @Param("excludeId") Long excludeId,
        @Param("newStart") LocalDate newStart,
        @Param("newEnd") LocalDate newEnd,
        @Param("statuses") List<SubscriptionStatus> statuses
    );

    // [날짜 검증 추가] 특정 숙소의 구독 목록 — 프론트 사용 불가 기간 표시용 API에서 사용
    @Query("""
        SELECT s FROM SubscriptionsUser s
        WHERE s.accommodationId = :accommodationId
          AND s.status IN :statuses
    """)
    List<SubscriptionsUser> findByAccommodationIdAndStatusIn(
        @Param("accommodationId") Long accommodationId,
        @Param("statuses") List<SubscriptionStatus> statuses
    );
}