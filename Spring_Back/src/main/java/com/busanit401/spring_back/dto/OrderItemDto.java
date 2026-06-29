package com.busanit401.spring_back.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class OrderItemDto {
    @JsonProperty("product_id")
    private Long productId;

    @JsonProperty("quantity")
    private int quantity;

    @JsonProperty("price")
    private Long price;
}