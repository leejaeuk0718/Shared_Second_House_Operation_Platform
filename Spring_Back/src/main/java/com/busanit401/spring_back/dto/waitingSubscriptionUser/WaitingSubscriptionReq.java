package com.busanit401.spring_back.dto.waitingSubscriptionUser;

import com.busanit401.spring_back.domain.entity.StayAccommodation;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.util.List;

@Getter
@NoArgsConstructor
public class WaitingSubscriptionReq {

    @NotNull(message = "숙소 ID를 입력해주세요.")
    private Long accommodationId;

    @Min(value = 1, message = "구독 기간은 최소 1개월입니다.")
    @Max(value = 12, message = "구독 기간은 최대 12개월입니다.")
    private int durationMonths;

    // 초대할 멤버 아이디 또는 이메일 목록
    private List<String> memberIdentifiers;

    // [날짜 검증 추가] 희망 구독 시작일 — 오늘 이후만 허용, null 불가
    @NotNull(message = "희망 시작일을 입력해주세요.")
    @FutureOrPresent(message = "시작일은 오늘 이후여야 합니다.")
    private LocalDate startDate;
}
