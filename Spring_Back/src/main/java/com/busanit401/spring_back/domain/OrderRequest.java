package com.busanit401.spring_back.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class OrderRequest {
    private Long userId;
    private String deliveryAddress;
    private int totalAmount;
    private List<CartItemRequest> items;
}