package com.busanit401.spring_back.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;

@Data
public class OrderRequestDto {
    @JsonProperty("user_id")
    private Long userId;

    @JsonProperty("total_amount")
    private Long totalAmount;

    @JsonProperty("delivery_address")
    private String deliveryAddress;

    private List<OrderItemDto> items;
}
