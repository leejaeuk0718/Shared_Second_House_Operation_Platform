package com.busanit401.spring_back.controller;

import com.busanit401.spring_back.domain.service.TourService;
import com.busanit401.spring_back.dto.TourDto;
import com.busanit401.spring_back.dto.TourResponseListDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collections;
import java.util.List;

@RestController // JSON 형태로 데이터를 반환하는 REST API 컨트롤러 선언
@RequestMapping("/api/tours") // 이 컨트롤러의 모든 API 기본 주소 경로 설정 (/api/tours)
@RequiredArgsConstructor
public class TourController {

    private final TourService tourService;

    /**
     * 💡 Next.js 프런트엔드 규격에 맞춰 마지막 페이지 여부(isLast)와 데이터(tours)를 응답할 객체
     */
    @Getter
    @AllArgsConstructor
    public static class tourService {
        private List<TourDto> tours;
        private boolean isLast;
    }

    /**
     * 특정 지역 코드 기반으로 관광지 리스트를 페이징 조회하는 API Endpoint
     * URL: GET http://localhost:8080/api/tours?lDongRegnCd=26&pageNo=1
     */
    @GetMapping
    @Operation(summary = "관광지 리스트 조회", description = "지역 코드와 페이지 번호를 받아 관광지 목록과 마지막 페이지 여부를 반환합니다.")
    public ResponseEntity<tourService> getTourList(
            @Parameter(description = "법정동 시도 코드 (예: 부산=26)") @RequestParam("lDongRegnCd") String lDongRegnCd,
            @Parameter(description = "조회할 페이지 번호") @RequestParam(value = "pageNo", defaultValue = "1") int pageNo) {

        // 1. 서비스로부터 이미 완성된 TourResponseListDto 객체를 받아옵니다.
        TourResponseListDto result = tourService.getTourListByRegion(lDongRegnCd, pageNo);

        // 안전장치: 결과 객체 자체가 null일 경우 즉시 빈 배열과 마지막 페이지 표시(true) 반환
        if (result == null) {
            return ResponseEntity.ok(new tourService(Collections.emptyList(), true));
        }

        // 2. DTO 내부에 담긴 순수 관광지 리스트(tours) 추출
        List<TourDto> tours = result.getTours();
        if (tours == null) {
            tours = Collections.emptyList();
        }

        // 3. 🛠️ 오류 수정: 서비스가 이미 계산해 둔 isLast 값을 그대로 가져옵니다.
        boolean isLast = result.isLast();

        // 4. Next.js가 스크롤을 제어할 수 있도록 최적화된 구조로 포장하여 반환
        return ResponseEntity.ok(new tourService(tours, isLast));
    }
}

/*
 * 특정 지역 코드 기반으로 관광지 리스트를 10개씩 페이징 조회하는 API Endpoint
 * 예시 URL: GET http://localhost:8080/api/tours?lDongRegnCd=26&pageNo=1
 *
 * @param lDongRegnCd 클라이언트 카테고리 선택으로 들어올 법정동 시도 코드 (예: 부산=26, 인천=28)
 * @param pageNo      조회할 페이지 번호 (보내지 않을 경우 기본값 11페이지로 지정)
 * @return 200 OK 상태코드와 함께 10개의 정제된 관광지 DTO 리스트 반환
 */