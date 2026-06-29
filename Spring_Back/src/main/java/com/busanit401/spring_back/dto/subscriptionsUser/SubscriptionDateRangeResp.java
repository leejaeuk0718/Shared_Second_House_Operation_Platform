package com.busanit401.spring_back.dto.subscriptionsUser;

import com.busanit401.spring_back.domain.SubscriptionsUser;
import com.busanit401.spring_back.enums.SubscriptionStatus;
import lombok.Builder;
import lombok.Getter;
import java.time.LocalDate;

// [날짜 검증 추가] 프론트 사용 불가 기간 표시용 응답 DTO — 개인정보 미포함, 날짜+상태만 반환
@Getter
@Builder
public class SubscriptionDateRangeResp {

    private LocalDate startDate;
    private LocalDate endDate;
    private SubscriptionStatus status;

    public static SubscriptionDateRangeResp from(SubscriptionsUser entity) {
        return SubscriptionDateRangeResp.builder()
                .startDate(entity.getStartDate())
                .endDate(entity.getEndDate())
                .status(entity.getStatus())
                .build();
    }
}
