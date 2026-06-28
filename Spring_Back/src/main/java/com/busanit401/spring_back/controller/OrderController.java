package com.busanit401.spring_back.controller;

import com.busanit401.spring_back.domain.Order;
import com.busanit401.spring_back.domain.service.OrderService;
import com.busanit401.spring_back.dto.OrderRequestDto;
import com.busanit401.spring_back.dto.OrderResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class OrderController {

    private final OrderService orderService;

    // POST: 주문 생성
    @PostMapping
    public ResponseEntity<?> placeOrder(@RequestBody OrderRequestDto orderRequest) {
        try {
            Long orderId = orderService.createOrder(orderRequest);
            return ResponseEntity.ok(Map.of("success", true, "orderId", orderId));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    } // <-- 이 닫는 중괄호가 반드시 있어야 합니다.

    // GET: 주문 목록 조회
    @GetMapping("/admin")
    public ResponseEntity<List<OrderResponseDto>> getAdminOrders() {
        List<Order> orders = orderService.getAllOrders();
        // 엔티티를 DTO로 변환하는 안전한 매핑
        List<OrderResponseDto> dtos = orders.stream().map(o ->
                OrderResponseDto.builder()
                        .order_id(o.getOrderId())
                        .user_id(o.getUserId())
                        .delivery_address(o.getDeliveryAddress())
                        .total_amount(o.getTotalAmount())
                        .status(o.getStatus())
                        .build()
        ).toList();
        return ResponseEntity.ok(dtos);
    }
}