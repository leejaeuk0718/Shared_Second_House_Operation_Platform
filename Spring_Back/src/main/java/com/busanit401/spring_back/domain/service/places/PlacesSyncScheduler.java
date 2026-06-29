package com.busanit401.spring_back.domain.service.places;

import com.busanit401.spring_back.domain.entity.StayAccommodation;
import com.busanit401.spring_back.domain.repository.StayAccommodationRepository;
import com.busanit401.spring_back.domain.service.PlacesService;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 전체 숙소 기준 주변 맛집 자동 동기화 스케줄러.
 *
 * <p>실행 시점:
 * <ul>
 *   <li>서버 기동 직후 1회 (ApplicationReadyEvent)</li>
 *   <li>매주 월요일 새벽 4시 (KST)</li>
 * </ul>
 *
 * <p>좌표 있는 숙소만 각각 독립 트랜잭션으로 sync 한다 — 한 숙소가 실패해도 나머지는 계속 진행.
 * (per-accommodation 트랜잭션을 위해 같은 빈 내부 호출이 아닌 PlacesService 프록시를 통해 호출)
 */
@Log4j2
@Component
@RequiredArgsConstructor
public class PlacesSyncScheduler {

    /** 자동 동기화 반경(m). */
    private static final int RADIUS = 2000;
    /** 자동 동기화 개수(최대 20). */
    private static final int LIMIT = 20;

    private final StayAccommodationRepository accommodationRepository;
    private final PlacesService placesService;

    /** 서버 기동 직후 1회 동기화. */
    @EventListener(ApplicationReadyEvent.class)
    public void onStartup() {
        log.info("서버 기동 - 전체 숙소 주변 맛집 동기화 시작");
//        syncAll();
    }

    /** 매주 월요일 새벽 4시(KST) 동기화. */
    @Scheduled(cron = "0 0 4 ? * MON", zone = "Asia/Seoul")
    public void weekly() {
        log.info("주간 스케줄 - 전체 숙소 주변 맛집 동기화 시작");
        syncAll();
    }

    private void syncAll() {
        List<StayAccommodation> accommodations = accommodationRepository.findAll();
        int ok = 0;
        int skipped = 0;
        int failed = 0;
        for (StayAccommodation acc : accommodations) {
            if (acc.getLatitude() == null || acc.getLongitude() == null) {
                skipped++;   // 좌표 없는 숙소는 대상 제외
                continue;
            }
            try {
                placesService.syncNearbyRestaurants(acc.getId(), RADIUS, LIMIT);
                ok++;
            } catch (Exception e) {
                failed++;
                log.warn("맛집 동기화 실패 - accommodationId: {}, 원인: {}", acc.getId(), e.getMessage());
            }
        }
        log.info("전체 숙소 주변 맛집 동기화 완료 - 성공 {}건, 좌표없음 {}건, 실패 {}건", ok, skipped, failed);
    }
}