package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.domain.Cart;
import com.busanit401.spring_back.domain.Product;
import com.busanit401.spring_back.domain.repository.CartRepository;
import com.busanit401.spring_back.domain.repository.ProductRepository;
import com.busanit401.spring_back.dto.CartResponseDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class CartService {

    private final CartRepository cartRepository;
    private final ProductRepository productRepository;

    // 장바구니 목록 조회
    public List<CartResponseDto> getCartList(Long userId) {
        return cartRepository.findByUserId(userId).stream().map(cart -> {
            CartResponseDto dto = new CartResponseDto();
            dto.setCartId(cart.getCartId());
            dto.setUserId(cart.getUserId());
            if (cart.getProduct() != null) {
                dto.setProductId(cart.getProduct().getProductId());
                dto.setName(cart.getProduct().getName());
                dto.setPrice(cart.getProduct().getPrice());
            }
            dto.setQuantity(cart.getQuantity());
            return dto;
        }).collect(Collectors.toList());
    }

    // 장바구니에 담기
    public void addCart(Long userId, Long productId, int quantity) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("상품이 존재하지 않습니다."));

        Cart cart = new Cart();
        cart.setUserId(userId);
        cart.setProduct(product);
        cart.setQuantity(quantity);
        cartRepository.save(cart);
    }
}
