package com.busanit401.spring_back.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "sh_order_item")
@Getter
@Setter  // 💡 빌더 외에도 일반 관리를 위해 Setter 추가
@Builder
@AllArgsConstructor
@NoArgsConstructor
@ToString(exclude = {"order", "product"})
public class OrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "order_item_id")
    private Long orderItemId;

    // 💡 FetchType.LAZY 설정과 관계 매핑을 명확히 하여 롬복 빌더가 정확히 인지하도록 세팅
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    @Column(nullable = false)
    private int quantity;

    @Column(nullable = false)
    private int price;
}