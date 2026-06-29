package com.busanit401.spring_back.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class CartResponseDto {
    private Long cartId;      // 장바구니 항목 고유 ID
    private Long userId;      // 사용자 ID (예: 1004)
    private Long productId;   // 상품 고유 ID
    private String name;      // 상품 이름 (예: 프리미엄 바비큐 세트)
    private int price;        // 상품 단가
    private int quantity;     // 장바구니에 담은 수량
}