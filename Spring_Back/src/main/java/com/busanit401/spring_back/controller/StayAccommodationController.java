package com.busanit401.spring_back.controller;

import com.busanit401.spring_back.domain.service.FileStorageService;
import com.busanit401.spring_back.domain.service.StayAccommodationService;
import com.busanit401.spring_back.dto.StayAccommodationRequestDto;
import com.busanit401.spring_back.dto.StayAccommodationResponseDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Log4j2
@RestController
@RequestMapping("/api/stay/accommodations")
@RequiredArgsConstructor
@Tag(name = "Stay Accommodation", description = "숙소 관리 API")
public class StayAccommodationController {

    private final StayAccommodationService accommodationService;
    private final FileStorageService fileStorageService;

    // ── 숙소 목록 조회 (검색 + 페이징) ──────────────────────
    @GetMapping
    @Operation(summary = "숙소 목록 조회", description = "숙소 목록을 검색·페이징하여 조회합니다. ?keyword=&page=0&size=6")
    public ResponseEntity<Page<StayAccommodationResponseDto>> getAccommodations(
            @RequestParam(required = false) String keyword,
            @PageableDefault(size = 6) Pageable pageable) {
        log.info("✅ [StayAccommodationController] 숙소 목록 조회 → keyword: {}", keyword);
        return ResponseEntity.ok(accommodationService.getAccommodations(keyword, pageable));
    }

    // ── 숙소 상세 조회 ────────────────────────────────────────
    @GetMapping("/{id}")
    @Operation(summary = "숙소 상세 조회", description = "숙소 ID로 상세 정보를 조회합니다.")
    public ResponseEntity<StayAccommodationResponseDto> getAccommodation(@PathVariable Long id) {
        log.info("✅ [StayAccommodationController] 숙소 상세 조회 → id: {}", id);
        return ResponseEntity.ok(accommodationService.getAccommodation(id));
    }

    // ── 숙소 등록 (관리자) ────────────────────────────────────
    @PostMapping
    @Operation(summary = "숙소 등록", description = "새로운 숙소를 등록합니다. (관리자)")
    public ResponseEntity<StayAccommodationResponseDto> createAccommodation(
            @RequestBody StayAccommodationRequestDto requestDto) {
        log.info("✅ [StayAccommodationController] 숙소 등록 → name: {}", requestDto.getName());
        return ResponseEntity.ok(accommodationService.createAccommodation(requestDto));
    }

    // ── 숙소 수정 (관리자) ────────────────────────────────────
    @PutMapping("/{id}")
    @Operation(summary = "숙소 수정", description = "숙소 정보를 수정합니다. (관리자)")
    public ResponseEntity<StayAccommodationResponseDto> updateAccommodation(
            @PathVariable Long id,
            @RequestBody StayAccommodationRequestDto requestDto) {
        log.info("✅ [StayAccommodationController] 숙소 수정 → id: {}", id);
        return ResponseEntity.ok(accommodationService.updateAccommodation(id, requestDto));
    }

    // ── 숙소 이미지 업로드 (관리자) ──────────────────────────
    @PostMapping(value = "/{id}/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "숙소 이미지 업로드", description = "숙소 이미지를 업로드하고 imageUrl을 자동 저장합니다. (관리자)")
    public ResponseEntity<List<String>> uploadImages(
            @PathVariable Long id,
            @RequestParam("files") List<MultipartFile> files) throws IOException {
        log.info("✅ [StayAccommodationController] 숙소 이미지 업로드 → id: {}, 파일 수: {}", id, files.size());
        List<String> imageUrls = new ArrayList<>();
        for (MultipartFile file : files) {
            imageUrls.add(fileStorageService.upload(file));
        }
        accommodationService.updateImageUrl(id, String.join(",", imageUrls));
        log.info("✅ [StayAccommodationController] 숙소 이미지 업로드 완료 → 총 {}개", imageUrls.size());
        return ResponseEntity.ok(imageUrls);
    }

    // ── 숙소 삭제 (관리자) ────────────────────────────────────
    @DeleteMapping("/{id}")
    @Operation(summary = "숙소 삭제", description = "숙소를 삭제합니다. (관리자)")
    public ResponseEntity<Void> deleteAccommodation(@PathVariable Long id) {
        log.info("✅ [StayAccommodationController] 숙소 삭제 → id: {}", id);
        accommodationService.deleteAccommodation(id);
        return ResponseEntity.noContent().build();
    }
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.controller.StayAccommodationController
 * 역할  : 숙소 REST API 엔드포인트 (요청 수신 → Service 호출 → 응답 반환)
 * 사용처 : 프론트(Next.js), 앱(Flutter)
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - StayAccommodationService.java      : 비즈니스 로직 인터페이스
 * - StayAccommodationServiceImpl.java  : 비즈니스 로직 구현체
 * - StayAccommodationRequestDto.java   : 숙소 등록/수정 요청 DTO
 * - StayAccommodationResponseDto.java  : 숙소 응답 DTO (할인율 포함)
 * ----------------------------------------------------------------------------------
 * [API 목록]
 * - GET    /api/stay/accommodations             : 숙소 목록 조회
 * - GET    /api/stay/accommodations/{id}        : 숙소 상세 조회
 * - POST   /api/stay/accommodations             : 숙소 등록 (관리자)
 * - PUT    /api/stay/accommodations/{id}        : 숙소 수정 (관리자)
 * - DELETE /api/stay/accommodations/{id}        : 숙소 삭제 (관리자)
 * - POST   /api/stay/accommodations/{id}/images : 숙소 이미지 업로드 + imageUrl 자동 저장 (관리자)
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * [목록] GET    → getAccommodations()             → Service → 전체 목록 + 할인율 반환
 * [상세] GET    → getAccommodation(id)            → Service → 단건 + 할인율 반환
 * [등록] POST   → createAccommodation(requestDto) → Service → 저장 후 반환
 * [수정] PUT    → updateAccommodation(id, dto)    → Service → 조회 → update() → 반환
 * [삭제] DELETE → deleteAccommodation(id)         → Service → 존재 확인 → 삭제
 * [이미지] POST → uploadImages(id, files)         → FileStorageService → 파일 저장 → imageUrl 자동 저장 → URL 목록 반환
 * ==================================================================================
 */