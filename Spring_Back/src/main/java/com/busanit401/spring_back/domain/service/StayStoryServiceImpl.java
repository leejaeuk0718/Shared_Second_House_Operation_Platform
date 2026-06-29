package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.domain.entity.StayAccommodation;
import com.busanit401.spring_back.domain.entity.StayStory;
import com.busanit401.spring_back.domain.repository.StayAccommodationRepository;
import com.busanit401.spring_back.domain.repository.StayStoryRepository;
import com.busanit401.spring_back.dto.StayStoryRequestDto;
import com.busanit401.spring_back.dto.StayStoryResponseDto;
import com.busanit401.spring_back.exception.BusinessException;
import com.busanit401.spring_back.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Log4j2
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StayStoryServiceImpl implements StayStoryService {

    private final StayStoryRepository storyRepository;
    private final StayAccommodationRepository accommodationRepository;

    // ── 숙소별 스토리 목록 조회 (표시 순서대로) ───────────────
    // orderNum 오름차순 정렬 → 프론트 스토리 섹션 순서 보장
    @Override
    public List<StayStoryResponseDto> getStories(Long accommodationId) {
        log.info("✅ [StayStoryService] 스토리 목록 조회 → accommodationId: {}", accommodationId);
        List<StayStoryResponseDto> result = storyRepository
                .findByStayAccommodationIdOrderByOrderNumAsc(accommodationId).stream()
                .map(StayStoryResponseDto::from)
                .collect(Collectors.toList());
        log.info("✅ [StayStoryService] 스토리 목록 조회 완료 → 총 {}개", result.size());
        return result;
    }

    // ── 스토리 등록 (관리자) ──────────────────────────────────
    // 숙소 존재 확인 → DTO → Entity 변환 후 저장
    @Override
    @Transactional
    public StayStoryResponseDto createStory(StayStoryRequestDto requestDto) {
        log.info("✅ [StayStoryService] 스토리 등록 시작 → accommodationId: {}", requestDto.getAccommodationId());
        StayAccommodation accommodation = accommodationRepository.findById(requestDto.getAccommodationId())
                .orElseThrow(() -> new BusinessException(ErrorCode.STAY_ACCOMMODATION_NOT_FOUND, " id: " + requestDto.getAccommodationId()));

        StayStory story = StayStory.builder()
                .stayAccommodation(accommodation)
                .orderNum(requestDto.getOrderNum())
                .title(requestDto.getTitle())
                .content(requestDto.getContent())
                .imageUrl(requestDto.getImageUrl())
                .build();

        StayStoryResponseDto result = StayStoryResponseDto.from(storyRepository.save(story));
        log.info("✅ [StayStoryService] 스토리 등록 완료 → id: {}", result.getId());
        return result;
    }

    // ── 스토리 수정 (관리자) ──────────────────────────────────
    // 조회 → update() 비즈니스 메서드로 필드 일괄 수정 → 저장
    @Override
    @Transactional
    public StayStoryResponseDto updateStory(Long id, StayStoryRequestDto requestDto) {
        log.info("✅ [StayStoryService] 스토리 수정 시작 → id: {}", id);
        StayStory story = storyRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.STAY_STORY_NOT_FOUND, " id: " + id));

        story.update(requestDto);

        StayStoryResponseDto result = StayStoryResponseDto.from(storyRepository.save(story));
        log.info("✅ [StayStoryService] 스토리 수정 완료 → id: {}", id);
        return result;
    }

    // ── 스토리 이미지 URL 저장 (관리자) ──────────────────────
    // 이미지 업로드 후 반환된 URL을 imageUrl 필드에 저장
    @Override
    @Transactional
    public void updateImageUrl(Long id, String imageUrl) {
        log.info("✅ [StayStoryService] 스토리 이미지 URL 저장 → id: {}", id);
        StayStory story = storyRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.STAY_STORY_NOT_FOUND, " id: " + id));
        story.updateImageUrl(imageUrl);
        log.info("✅ [StayStoryService] 스토리 이미지 URL 저장 완료 → id: {}", id);
    }

    // ── 스토리 삭제 (관리자) ──────────────────────────────────
    // 존재 여부 확인 후 삭제
    @Override
    @Transactional
    public void deleteStory(Long id) {
        log.info("✅ [StayStoryService] 스토리 삭제 시작 → id: {}", id);
        storyRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.STAY_STORY_NOT_FOUND, " id: " + id));
        storyRepository.deleteById(id);
        log.info("✅ [StayStoryService] 스토리 삭제 완료 → id: {}", id);
    }
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.service.StayStoryServiceImpl
 * 역할  : 숙소 스토리 비즈니스 로직 (조회/등록/수정/삭제)
 * 사용처 : StayStoryController
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - StayStoryRepository.java           : 스토리 DB 조회/저장/삭제
 * - StayAccommodationRepository.java   : 숙소 존재 확인용 조회
 * - StayStoryRequestDto.java           : 등록/수정 요청 DTO
 * - StayStoryResponseDto.java          : 응답 DTO (from() 정적 메서드)
 * - StayStory.java                     : 스토리 엔티티 (update() 메서드)
 * - StayStoryService.java              : 인터페이스
 * - ErrorCode.java                     : 예외 코드 (STAY_STORY_NOT_FOUND 등)
 * ----------------------------------------------------------------------------------
 * [변경 이력]
 * - 최초 작성 : 스토리 기본 CRUD, RuntimeException 사용
 * - 변경       : RuntimeException → BusinessException 으로 교체 (ErrorCode 연동)
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - getStories(accommodationId) : 숙소별 스토리 목록 조회 (orderNum 오름차순)
 * - createStory(requestDto)     : 스토리 등록 (숙소 존재 확인 → 저장)
 * - updateStory(id, requestDto) : 스토리 수정 (update() 비즈니스 메서드)
 * - deleteStory(id)             : 스토리 삭제 (존재 확인 → 삭제)
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * [조회] getStories(accommodationId) → findByStayAccommodationIdOrderByOrderNumAsc() → DTO 변환
 * [등록] createStory() → 숙소 findById() → builder() → save() → DTO 반환
 * [수정] updateStory() → findById() → update() → save() → DTO 반환
 * [삭제] deleteStory() → findById() 존재 확인 → deleteById()
 * ==================================================================================
 */

