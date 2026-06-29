package com.busanit401.spring_back.domain;

import com.busanit401.spring_back.dto.waitingSubscriptionUser.WaitingSubscriptionReq;
import com.busanit401.spring_back.enums.SubscriptionStatus;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Getter
@NoArgsConstructor
@Builder
@AllArgsConstructor
@Table(name = "subscriptions_user")
public class SubscriptionsUser extends BaseTimeEntity {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "subscription_id")
    private Long id;

    // 대표 유저 (결제자)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // 숙소 팀원 파트 연동 (나중에 교체)
    @Column(name = "accommodation_id", nullable = false)
    private Long accommodationId;

    @Column(name = "duration_months", nullable = false)
    private int durationMonths;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private SubscriptionStatus status;

    @OneToOne(mappedBy = "subscriptionsUser", fetch = FetchType.LAZY)
    private Payment payment;

    // 멤버 리스트 (APPROVED된 멤버들)
    @OneToMany(mappedBy = "subscriptionsUser", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<WaitingSubscriptionUser> members = new ArrayList<>();



    // 구독 승인 (관리자)
    public void approve() {
        this.status = SubscriptionStatus.ACTIVE;
    }

    // 구독 반려 (관리자)
    public void reject() {
        this.status = SubscriptionStatus.CANCELLED;
    }

    // 구독 취소
    public void cancel() {
        this.status = SubscriptionStatus.CANCELLED;
    }

    // 구독 만료
    public void expire() {
        this.status = SubscriptionStatus.EXPIRED;
    }

    // 구독 신청 생성 (대표가 신청할 때)
    public static SubscriptionsUser create(User leader, WaitingSubscriptionReq req) {
        // [날짜 검증 추가] 시작일을 신청 당일(now) 대신 사용자가 입력한 희망 시작일로 설정
        return SubscriptionsUser.builder()
                .user(leader)
                .accommodationId(req.getAccommodationId())
                .durationMonths(req.getDurationMonths())
                .startDate(req.getStartDate())
                .endDate(req.getStartDate().plusMonths(req.getDurationMonths()))
                .status(SubscriptionStatus.PENDING)
                .build();
    }
}