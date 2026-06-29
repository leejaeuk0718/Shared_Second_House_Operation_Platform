package com.busanit401.spring_back;

import com.busanit401.spring_back.domain.entity.GuestChatMessage;
import com.busanit401.spring_back.domain.entity.GuestChatRoom;
import com.busanit401.spring_back.domain.repository.GuestChatMessageRepository;
import com.busanit401.spring_back.domain.repository.GuestChatRoomRepository;
import com.busanit401.spring_back.domain.service.GuestChatService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GuestChatServiceTest {

    @Mock
    private GuestChatRoomRepository guestChatRoomRepository;

    @Mock
    private GuestChatMessageRepository guestChatMessageRepository;

    @InjectMocks
    private GuestChatService guestChatService;

    @Test
    @DisplayName("getOrCreateChatRoom - 기존 채팅방이 없으면 새로 생성해서 반환한다")
    void getOrCreateChatRoom_createNewRoom() {
        // given
        Long accommodationId = 1L;
        String roomName = "1번 하우스";

        when(guestChatRoomRepository.findByHouseId(accommodationId)).thenReturn(Optional.empty());
        when(guestChatRoomRepository.save(any(GuestChatRoom.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // when
        GuestChatRoom result = guestChatService.getOrCreateChatRoom(accommodationId, roomName);

        // then
        assertThat(result).isNotNull();
        assertThat(result.getHouseId()).isEqualTo(accommodationId);
        assertThat(result.getRoomName()).isEqualTo("1번 하우스 채팅방");
        verify(guestChatRoomRepository, times(1)).save(any(GuestChatRoom.class));
    }

    @Test
    @DisplayName("getOrCreateChatRoom - 기존 채팅방이 이미 존재하면 새로 만들지 않고 기존 방을 반환한다")
    void getOrCreateChatRoom_returnExistingRoom() {
        // given
        Long accommodationId = 1L;
        GuestChatRoom existingRoom = GuestChatRoom.builder()
                .houseId(accommodationId)
                .roomName("기존 채팅방")
                .build();

        when(guestChatRoomRepository.findByHouseId(accommodationId)).thenReturn(Optional.of(existingRoom));

        // when
        GuestChatRoom result = guestChatService.getOrCreateChatRoom(accommodationId, "새로운 이름");

        // then
        assertThat(result).isNotNull();
        assertThat(result.getRoomName()).isEqualTo("기존 채팅방");
        verify(guestChatRoomRepository, never()).save(any(GuestChatRoom.class)); // save가 호출되지 않아야 함
    }

    @Test
    @DisplayName("getOrCreateChatRoom - 숙소 ID가 null로 들어오면 IllegalArgumentException이 발생한다")
    void getOrCreateChatRoom_throwsExceptionWhenIdIsNull() {
        // when & then
        assertThatThrownBy(() -> guestChatService.getOrCreateChatRoom(null, "테스트 방"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("숙소 ID는 필수입니다.");
    }

    @Test
    @DisplayName("getChatRoom - 채팅방이 존재하지 않는 하우스 ID로 조회 시 예외가 발생한다")
    void getChatRoom_throwsExceptionWhenNotFound() {
        // given
        Long invalidHouseId = 999L;
        when(guestChatRoomRepository.findByHouseId(invalidHouseId)).thenReturn(Optional.empty());

        // when & then
        assertThatThrownBy(() -> guestChatService.getChatRoom(invalidHouseId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("해당 하우스의 채팅방이 존재하지 않습니다.");
    }

    @Test
    @DisplayName("saveMessage - 입력된 본문과 보낸이 정보를 토대로 메시지를 정상 저장한다")
    void saveMessage_success() {
        // given
        Long chatRoomId = 10L;
        GuestChatRoom chatRoom = GuestChatRoom.builder().houseId(1L).roomName("테스트방").build();

        when(guestChatRoomRepository.findById(chatRoomId)).thenReturn(Optional.of(chatRoom));
        when(guestChatMessageRepository.save(any(GuestChatMessage.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // when
        GuestChatMessage savedMessage = guestChatService.saveMessage(chatRoomId, 1L, "넥스트 테스트", "안녕하세요");

        // then
        assertThat(savedMessage).isNotNull();
        assertThat(savedMessage.getGuestChatRoom()).isEqualTo(chatRoom);
        assertThat(savedMessage.getSenderName()).isEqualTo("넥스트 테스트");
        assertThat(savedMessage.getMessageContent()).isEqualTo("안녕하세요");
    }
}