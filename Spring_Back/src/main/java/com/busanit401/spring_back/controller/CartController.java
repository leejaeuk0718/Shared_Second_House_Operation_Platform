package com.busanit401.spring_back.controller;

import com.busanit401.spring_back.domain.service.CartService;
import com.busanit401.spring_back.dto.CartRequestDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/cart")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CartController {

    private final CartService cartService;

    // CartController.java에 추가
    @GetMapping("/list")
    public ResponseEntity<?> getCartList() {
        // 1004L 사용자의 장바구니 목록을 가져오는 서비스 메서드 호출
        var cartItems = cartService.getCartList(1004L);
        return ResponseEntity.ok(cartItems);
    }

    // 장바구니 추가
    @PostMapping("/add")
    public ResponseEntity<Map<String, String>> addToCart(@RequestBody CartRequestDto request) {
        // userId는 1004로 고정 (추후 세션/토큰 도입 시 변경)
        cartService.addCart(1004L, request.getProductId(), request.getQuantity());

        return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "상품이 장바구니에 성공적으로 담겼습니다."
        ));
    }
}