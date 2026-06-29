package com.busanit401.spring_back.domain.repository;

import com.busanit401.spring_back.domain.entity.GuestChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface GuestChatRoomRepository extends JpaRepository<GuestChatRoom, Long> {
    // 하우스 상품의 채팅방 찾기
    Optional<GuestChatRoom> findByHouseId(Long houseId);
}