package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.domain.entity.GuestChatMessage;
import com.busanit401.spring_back.domain.entity.GuestChatRoom;
import com.busanit401.spring_back.domain.repository.GuestChatMessageRepository;
import com.busanit401.spring_back.domain.repository.GuestChatRoomRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Log4j2
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class GuestChatService {

    private final GuestChatRoomRepository guestChatRoomRepository;
    private final GuestChatMessageRepository guestChatMessageRepository;

    @Transactional
    public GuestChatRoom getOrCreateChatRoom(Long accommodationId, String roomName) {
        if (accommodationId == null) {
            log.error("❌ 채팅방 생성 실패: accommodationId가 null입니다.");
            throw new IllegalArgumentException("숙소 ID는 필수입니다.");
        }

        // 💡 엔티티 내부 필드명(houseId)에 맞춰 findByHouseId로 통일하여 정합성 확보
        return guestChatRoomRepository.findByHouseId(accommodationId)
                .orElseGet(() -> {
                    log.info("🆕 [{}]번 숙소의 채팅방이 없어 신규 개설합니다.", accommodationId);

                    GuestChatRoom newRoom = GuestChatRoom.builder()
                            .houseId(accommodationId)
                            .roomName(roomName + " 채팅방")
                            .build();

                    return guestChatRoomRepository.save(newRoom);
                });
    }

    // 게스트가 채팅방 입장 시점 호출: 단순히 기존 방을 조회
    public GuestChatRoom getChatRoom(Long houseId) {
        return guestChatRoomRepository.findByHouseId(houseId)
                .orElseThrow(() -> {
                    log.info("[⚠️ 게스트 채팅] 채팅방이 존재하지 않음 - 요청된 하우스 ID: {}", houseId);
                    return new IllegalArgumentException("해당 하우스의 채팅방이 존재하지 않습니다. 하우스 ID: " + houseId);
                });
    }

    // 채팅방 입장 성공 시 과거 메시지 내역 조회
    public List<GuestChatMessage> getChatHistory(Long guestChatRoomId) {
        return guestChatMessageRepository.findByGuestChatRoomIdOrderBySentAtAsc(guestChatRoomId);
    }

    // 실시간으로 수신된 메시지 DB 저장
    @Transactional
    public GuestChatMessage saveMessage(Long chatRoomId, Long senderId, String senderName, String content) {
        log.info("💾 DB 저장 시도 -> room: {}, senderId: {}, name: {}, content: {}",
                chatRoomId, senderId, senderName, content);
        GuestChatRoom chatRoom = guestChatRoomRepository.findById(chatRoomId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 게스트 채팅방입니다. ID: " + chatRoomId));

        GuestChatMessage chatMessage = GuestChatMessage.builder()
                .guestChatRoom(chatRoom)
                .senderId(senderId)
                .senderName(senderName)
                .messageContent(content)
                .build();

        return guestChatMessageRepository.save(chatMessage);
    }
}