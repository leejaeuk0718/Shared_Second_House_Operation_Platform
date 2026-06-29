package com.busanit401.spring_back.dto.waitingSubscriptionUser;

import com.busanit401.spring_back.domain.WaitingSubscriptionUser;
import com.busanit401.spring_back.enums.MemberRole;
import com.busanit401.spring_back.enums.MemberStatus;
import lombok.Builder;
import lombok.Getter;
import java.time.LocalDateTime;

@Getter
@Builder
public class WaitingSubscriptionResp {

    private Long waitingId;
    private Long subscriptionId;
    private Long userId;
    private String username;
    private Long accommodationId;
    private MemberRole memberRole;
    private MemberStatus status;
    private LocalDateTime requestedAt;
    private LocalDateTime respondedAt;

    public static WaitingSubscriptionResp from(WaitingSubscriptionUser waiting) {
        return WaitingSubscriptionResp.builder()
                .waitingId(waiting.getId())
                .accommodationId(waiting.getSubscriptionsUser().getAccommodationId())  // 추가
                .subscriptionId(waiting.getSubscriptionsUser().getId())
                .userId(waiting.getUser().getId())
                .username(waiting.getUser().getUsername())
                .memberRole(waiting.getMemberRole())
                .status(waiting.getStatus())
                .requestedAt(waiting.getRequestedAt())
                .respondedAt(waiting.getRespondedAt())
                .build();
    }
}
