package com.busanit401.spring_back.controller;

import com.busanit401.spring_back.domain.entity.GuestChatMessage;
import com.busanit401.spring_back.domain.entity.GuestChatRoom;
import com.busanit401.spring_back.domain.service.GuestChatService;
import io.swagger.v3.oas.annotations.Operation;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Log4j2
@RestController
@RequestMapping("/api/guest/chat")
@RequiredArgsConstructor
public class GuestChatController {

    private final GuestChatService guestChatService;

    /**
     * 1. 특정 하우스의 채팅방 정보 및 ID 조회 API (방이 없으면 안전하게 자동 생성 후 반환)
     * GET http://localhost:8080/api/guest/chat/room/{houseId}
     */
    @GetMapping("/room/{houseId}")
    @Operation(summary = "채팅방 번호 조회 (미존재 시 자동 생성)")
    public ResponseEntity<GuestChatRoom> getRoomInfo(@PathVariable("houseId") Long houseId) {
        log.info("[API GET] 채팅방 정보 조회 요청 - 하우스 ID: {}", houseId);

        // 💡 getChatRoom 대신 getOrCreateChatRoom을 활용하여 런타임 에러 방지 및 안전성 확보
        GuestChatRoom chatRoom = guestChatService.getOrCreateChatRoom(houseId, houseId + "번 하우스");

        return ResponseEntity.ok(chatRoom);
    }

    /**
     * 2. 특정 채팅방의 과거 메시지 내역 조회 API (화면 진입 시 호출)
     * GET http://localhost:8080/api/guest/chat/history/{chatRoomId}
     */
    @GetMapping("/history/{chatRoomId}")
    @Operation(summary = "과거 채팅 내역 불러오기")
    public ResponseEntity<List<GuestChatMessage>> getChatHistory(@PathVariable("chatRoomId") Long chatRoomId) {
        log.info("[API GET] 과거 대화 내역 조회 요청 - 채팅방 ID: {}", chatRoomId);
        List<GuestChatMessage> history = guestChatService.getChatHistory(chatRoomId);
        return ResponseEntity.ok(history);
    }
}