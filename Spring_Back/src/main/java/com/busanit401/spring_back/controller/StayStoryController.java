package com.busanit401.spring_back.controller;

import com.busanit401.spring_back.domain.service.FileStorageService;
import com.busanit401.spring_back.domain.service.StayStoryService;
import com.busanit401.spring_back.dto.StayStoryRequestDto;
import com.busanit401.spring_back.dto.StayStoryResponseDto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

import java.util.List;

@Log4j2
@RestController
@RequestMapping("/api/stay/stories")
@RequiredArgsConstructor
@Tag(name = "Stay Story", description = "숙소 스토리 관리 API")
public class StayStoryController {

    private final StayStoryService storyService;
    private final FileStorageService fileStorageService;

    // ── 숙소별 스토리 목록 조회 (표시 순서대로) ───────────────
    @GetMapping("/{accommodationId}")
    @Operation(summary = "숙소별 스토리 목록 조회", description = "숙소 ID로 스토리 목록을 순서대로 조회합니다.")
    public ResponseEntity<List<StayStoryResponseDto>> getStories(@PathVariable Long accommodationId) {
        log.info("✅ [StayStoryController] 숙소별 스토리 목록 조회 → accommodationId: {}", accommodationId);
        return ResponseEntity.ok(storyService.getStories(accommodationId));
    }

    // ── 스토리 등록 (관리자) ──────────────────────────────────
    @PostMapping
    @Operation(summary = "스토리 등록", description = "숙소 스토리를 등록합니다. (관리자)")
    public ResponseEntity<StayStoryResponseDto> createStory(@RequestBody StayStoryRequestDto requestDto) {
        log.info("✅ [StayStoryController] 스토리 등록 → accommodationId: {}", requestDto.getAccommodationId());
        return ResponseEntity.ok(storyService.createStory(requestDto));
    }

    // ── 스토리 수정 (관리자) ──────────────────────────────────
    @PutMapping("/{id}")
    @Operation(summary = "스토리 수정", description = "숙소 스토리를 수정합니다. (관리자)")
    public ResponseEntity<StayStoryResponseDto> updateStory(
            @PathVariable Long id,
            @RequestBody StayStoryRequestDto requestDto) {
        log.info("✅ [StayStoryController] 스토리 수정 → id: {}", id);
        return ResponseEntity.ok(storyService.updateStory(id, requestDto));
    }

    // ── 스토리 삭제 (관리자) ──────────────────────────────────
    @DeleteMapping("/{id}")
    @Operation(summary = "스토리 삭제", description = "숙소 스토리를 삭제합니다. (관리자)")
    public ResponseEntity<Void> deleteStory(@PathVariable Long id) {
        log.info("✅ [StayStoryController] 스토리 삭제 → id: {}", id);
        storyService.deleteStory(id);
        return ResponseEntity.noContent().build();
    }

    // ── 스토리 이미지 업로드 (관리자) ────────────────────────
    @PostMapping(value = "/{id}/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "스토리 이미지 업로드", description = "스토리 이미지를 업로드하고 imageUrl을 자동 저장합니다. (관리자)")
    public ResponseEntity<String> uploadStoryImage(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file) throws IOException {
        log.info("✅ [StayStoryController] 스토리 이미지 업로드 → storyId: {}", id);
        String imageUrl = fileStorageService.upload(file);
        storyService.updateImageUrl(id, imageUrl);
        log.info("✅ [StayStoryController] 스토리 이미지 업로드 완료 → imageUrl: {}", imageUrl);
        return ResponseEntity.ok(imageUrl);
    }
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.controller.StayStoryController
 * 역할  : 숙소 스토리 REST API 엔드포인트 (요청 수신 → Service 호출 → 응답 반환)
 * 사용처 : 프론트(Next.js) 숙소 상세 페이지 [섹션6] 스토리 표시
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - StayStoryService.java      : 비즈니스 로직 인터페이스
 * - StayStoryServiceImpl.java  : 비즈니스 로직 구현체
 * - StayStoryRequestDto.java   : 스토리 등록/수정 요청 DTO
 * - StayStoryResponseDto.java  : 스토리 응답 DTO
 * ----------------------------------------------------------------------------------
 * [API 목록]
 * - GET    /api/stay/stories/{accommodationId} : 숙소별 스토리 목록 조회 (순서대로)
 * - POST   /api/stay/stories                   : 스토리 등록 (관리자)
 * - PUT    /api/stay/stories/{id}              : 스토리 수정 (관리자)
 * - DELETE /api/stay/stories/{id}              : 스토리 삭제 (관리자)
 * - POST   /api/stay/stories/{id}/images       : 스토리 이미지 업로드 + imageUrl 자동 저장 (관리자)
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * [조회] GET    → getStories(accommodationId)       → Service → orderNum 순 목록 반환
 * [등록] POST   → createStory(requestDto)           → Service → 숙소 확인 → 저장
 * [수정] PUT    → updateStory(id, requestDto)       → Service → 조회 → update() → 반환
 * [삭제] DELETE → deleteStory(id)                   → Service → 존재 확인 → 삭제
 * [이미지] POST → uploadStoryImage(id, file)        → UUID 파일명 → 로컬 저장 → imageUrl 자동 저장 → URL 반환
 * ==================================================================================
 */