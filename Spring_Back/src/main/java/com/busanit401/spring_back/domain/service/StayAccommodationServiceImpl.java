package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.domain.entity.StayAccommodation;
import com.busanit401.spring_back.domain.repository.StayAccommodationPriceRepository;
import com.busanit401.spring_back.domain.repository.StayAccommodationRepository;
import com.busanit401.spring_back.exception.BusinessException;
import com.busanit401.spring_back.exception.ErrorCode;
import com.busanit401.spring_back.dto.StayAccommodationPriceDto;
import com.busanit401.spring_back.dto.StayAccommodationRequestDto;
import com.busanit401.spring_back.dto.StayAccommodationResponseDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Log4j2
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StayAccommodationServiceImpl implements StayAccommodationService {

    private final StayAccommodationRepository accommodationRepository;
    private final StayAccommodationPriceRepository priceRepository;

    // ── 공통 할인율 구간 목록 조회 (내부 전용) ───────────────
    // 목록/상세/등록/수정 응답 시 prices 리스트에 포함되어 반환
    private List<StayAccommodationPriceDto> getCommonPrices() {
        return priceRepository.findAll().stream()
                .map(StayAccommodationPriceDto::from)
                .collect(Collectors.toList());
    }

    // ── 숙소 목록 조회 (검색 + 페이징) ──────────────────────
    @Override
    public Page<StayAccommodationResponseDto> getAccommodations(String keyword, Pageable pageable) {
        log.info("✅ [StayAccommodationService] 숙소 목록 조회 → keyword: {}, page: {}", keyword, pageable.getPageNumber());
        List<StayAccommodationPriceDto> prices = getCommonPrices();
        Page<StayAccommodation> page = (keyword == null || keyword.isBlank())
                // 검색어가 없는 경우 전체 숙소 페이징
                ? accommodationRepository.findAll(pageable)
                // 검색어가 있는 경우
                : accommodationRepository.findByNameContainingIgnoreCase(keyword, pageable);
        // 엔티티 구조를 DTO 구조로 변환
        Page<StayAccommodationResponseDto> result = page.map(a -> StayAccommodationResponseDto.from(a, prices));
        log.info("✅ [StayAccommodationService] 숙소 목록 조회 완료 → {}개 / 전체 {}페이지", result.getNumberOfElements(), result.getTotalPages());
        return result;
    }

    // ── 숙소 상세 조회 ────────────────────────────────────────
    // 단건 조회 + 공통 할인율 함께 반환
    @Override
    public StayAccommodationResponseDto getAccommodation(Long id) {
        log.info("✅ [StayAccommodationService] 숙소 상세 조회 → id: {}", id);
        StayAccommodation accommodation = accommodationRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.STAY_ACCOMMODATION_NOT_FOUND, " id: " + id));
        List<StayAccommodationPriceDto> prices = getCommonPrices();
        log.info("✅ [StayAccommodationService] 숙소 상세 조회 완료 → name: {}", accommodation.getName());
        return StayAccommodationResponseDto.from(accommodation, prices);
    }

    // ── 숙소 등록 (관리자) ────────────────────────────────────
    // DTO → Entity 변환 후 저장, 할인율 포함한 응답 반환
    @Override
    @Transactional
    public StayAccommodationResponseDto createAccommodation(StayAccommodationRequestDto requestDto) {
        log.info("✅ [StayAccommodationService] 숙소 등록 시작 → name: {}", requestDto.getName());
        StayAccommodation accommodation = StayAccommodation.builder()
                .name(requestDto.getName())
                .address(requestDto.getAddress())
                .description(requestDto.getDescription())
                .imageUrl(requestDto.getImageUrl())
                .amenities(requestDto.getAmenities())
                .monthlyPrice(requestDto.getMonthlyPrice())
                .roomCount(requestDto.getRoomCount())
                .bathroomCount(requestDto.getBathroomCount())
                .floorCount(requestDto.getFloorCount())
                .parkingCount(requestDto.getParkingCount())
                .landArea(requestDto.getLandArea())
                .buildingArea(requestDto.getBuildingArea())
                .latitude(requestDto.getLatitude())
                .longitude(requestDto.getLongitude())
                .status(requestDto.getStatus())
                .build();
        StayAccommodation saved = accommodationRepository.save(accommodation);
        List<StayAccommodationPriceDto> prices = getCommonPrices();
        log.info("✅ [StayAccommodationService] 숙소 등록 완료 → id: {}", saved.getId());
        return StayAccommodationResponseDto.from(saved, prices);
    }

    // ── 숙소 수정 (관리자) ────────────────────────────────────
    // 조회 → update() 비즈니스 메서드로 필드 일괄 수정 → 저장
    @Override
    @Transactional
    public StayAccommodationResponseDto updateAccommodation(Long id, StayAccommodationRequestDto requestDto) {
        log.info("✅ [StayAccommodationService] 숙소 수정 시작 → id: {}", id);
        StayAccommodation accommodation = accommodationRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.STAY_ACCOMMODATION_NOT_FOUND, " id: " + id));
        accommodation.update(requestDto);
        StayAccommodation saved = accommodationRepository.save(accommodation);
        List<StayAccommodationPriceDto> prices = getCommonPrices();
        log.info("✅ [StayAccommodationService] 숙소 수정 완료 → id: {}", id);
        return StayAccommodationResponseDto.from(saved, prices);
    }

    // ── 숙소 이미지 URL 저장 (관리자) ────────────────────────
    // 이미지 업로드 후 반환된 URL 목록(쉼표 구분)을 imageUrl 필드에 저장
    @Override
    @Transactional
    public void updateImageUrl(Long id, String imageUrl) {
        log.info("✅ [StayAccommodationService] 숙소 이미지 URL 저장 → id: {}", id);
        StayAccommodation accommodation = accommodationRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.STAY_ACCOMMODATION_NOT_FOUND, " id: " + id));
        accommodation.updateImageUrl(imageUrl);
        log.info("✅ [StayAccommodationService] 숙소 이미지 URL 저장 완료 → id: {}", id);
    }

    // ── 숙소 삭제 (관리자) ────────────────────────────────────
    // 존재 여부 확인 후 삭제 (CascadeType.ALL → 예약/스토리 함께 삭제됨)
    @Override
    @Transactional
    public void deleteAccommodation(Long id) {
        log.info("✅ [StayAccommodationService] 숙소 삭제 시작 → id: {}", id);
        accommodationRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.STAY_ACCOMMODATION_NOT_FOUND, " id: " + id));
        accommodationRepository.deleteById(id);
        log.info("✅ [StayAccommodationService] 숙소 삭제 완료 → id: {}", id);
    }
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.service.StayAccommodationServiceImpl
 * 역할  : 숙소 비즈니스 로직 (목록/상세/등록/수정/삭제)
 * 사용처 : StayAccommodationController
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - StayAccommodationRepository.java      : 숙소 DB 조회/저장/삭제
 * - StayAccommodationPriceRepository.java : 공통 할인율 구간 조회
 * - StayAccommodationRequestDto.java      : 등록/수정 요청 DTO
 * - StayAccommodationResponseDto.java     : 응답 DTO (할인율 포함)
 * - StayAccommodationPriceDto.java        : 할인율 구간 DTO
 * - StayAccommodation.java               : 숙소 엔티티 (update() 메서드)
 * - StayAccommodationService.java        : 인터페이스
 * - ErrorCode.java                       : 예외 코드 (STAY_ACCOMMODATION_NOT_FOUND)
 * ----------------------------------------------------------------------------------
 * [변경 이력]
 * - 최초 작성 : 숙소 기본 CRUD, RuntimeException 사용
 * - 변경       : RuntimeException → BusinessException 으로 교체 (ErrorCode 연동)
 *               공통 할인율 테이블 분리 (StayAccommodationPrice)
 *               → 응답 DTO에 prices 리스트 포함하도록 변경
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - getAccommodations()                 : 숙소 목록 조회 (할인율 포함)
 * - getAccommodation(id)                : 숙소 상세 조회 (할인율 포함)
 * - createAccommodation(requestDto)     : 숙소 등록
 * - updateAccommodation(id, requestDto) : 숙소 수정 (update() 비즈니스 메서드)
 * - deleteAccommodation(id)             : 숙소 삭제 (Cascade → 예약/스토리 함께 삭제)
 * - getCommonPrices() [private]         : 공통 할인율 구간 조회 (내부 전용)
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * [목록] getAccommodations() → findAll() → DTO 변환 + 할인율 포함 → 반환
 * [상세] getAccommodation(id) → findById() → DTO 변환 + 할인율 포함 → 반환
 * [등록] createAccommodation() → builder() → save() → DTO 변환 → 반환
 * [수정] updateAccommodation() → findById() → update() → save() → 반환
 * [삭제] deleteAccommodation() → findById() 존재 확인 → deleteById()
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * - 숙소 삭제 시 CascadeType.ALL 로 StayReservation, StayStory 함께 삭제됨
 * - 할인율(prices)은 숙소별이 아닌 공통 테이블(sh_stay_accommodation_price) 에서 조회
 * ==================================================================================
 */