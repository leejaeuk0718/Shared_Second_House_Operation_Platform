package com.busanit401.spring_back.domain.service;

import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

public interface FileStorageService {

    // ── 파일 업로드 → 저장 후 접근 가능한 URL 반환 ───────────
    String upload(MultipartFile file) throws IOException;
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.service.FileStorageService
 * 역할  : 파일 저장 서비스 인터페이스 (공통 파일 업로드 처리)
 * 구현체 : FileStorageServiceImpl
 * 사용처 : StayAccommodationController, StayStoryController
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - upload(file) : 파일 저장 후 접근 가능한 URL 반환 (/uploads/{fileName})
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * ⚠️ [TODO] 현재 서버 로컬(/uploads) 저장 → 고도화 시 S3 연동으로 교체 예정
 *    → 교체 시 FileStorageServiceImpl 만 수정하면 됨 (컨트롤러 변경 불필요)
 * ==================================================================================
 */
