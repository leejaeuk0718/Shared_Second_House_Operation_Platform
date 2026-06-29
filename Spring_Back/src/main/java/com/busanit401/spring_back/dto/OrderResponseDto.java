package com.busanit401.spring_back.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class OrderResponseDto {
    private Long order_id;        // DB 컬럼명과 일치
    private Long user_id;
    private String delivery_address;
    private Integer total_amount;
    private String status;
}