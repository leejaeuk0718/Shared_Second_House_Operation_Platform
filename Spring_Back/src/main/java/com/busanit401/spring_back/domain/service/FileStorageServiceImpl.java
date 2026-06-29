package com.busanit401.spring_back.domain.service;

import lombok.extern.log4j.Log4j2;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.UUID;

@Log4j2
@Service
public class FileStorageServiceImpl implements FileStorageService {

    // ⚠️ [TODO] 고도화 시 S3 연동으로 교체 예정 (현재 서버 로컬 저장)
    private static final String UPLOAD_DIR = System.getProperty("user.dir") + "/uploads/";

    // ── 파일 업로드 → 저장 후 URL 반환 ───────────────────────
    // 처리 순서:
    //   1. uploads/ 폴더 없으면 생성
    //   2. UUID 파일명 생성 → 로컬 저장
    //   3. 프론트 접근 가능한 URL 반환 (/uploads/{fileName})
    @Override
    public String upload(MultipartFile file) throws IOException {
        File uploadDir = new File(UPLOAD_DIR);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename();
        File dest = new File(UPLOAD_DIR + fileName);
        file.transferTo(dest);

        log.info("✅ [FileStorageService] 파일 저장 완료 → fileName: {}", fileName);
        return "/uploads/" + fileName;
    }
}

/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : com.busanit401.spring_back.domain.service.FileStorageServiceImpl
 * 역할  : 파일 저장 비즈니스 로직 (로컬 저장 → URL 반환)
 * 사용처 : StayAccommodationController, StayStoryController
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - upload(file) : UUID 파일명 생성 → /uploads/ 에 저장 → URL 반환
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * upload(file)
 *   → uploads/ 폴더 확인/생성
 *   → UUID + 원본파일명 으로 파일명 생성
 *   → transferTo() 로 로컬 저장
 *   → /uploads/{fileName} URL 반환
 * ----------------------------------------------------------------------------------
 * [주의사항 / 참고]
 * ⚠️ [TODO] 현재 서버 로컬(/uploads) 저장 → 고도화 시 S3 연동으로 교체 예정
 *    → 교체 시 이 파일만 수정하면 됨 (컨트롤러 변경 불필요)
 * ==================================================================================
 */
