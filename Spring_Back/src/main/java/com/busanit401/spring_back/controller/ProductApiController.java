package com.busanit401.spring_back.controller;


import com.busanit401.spring_back.domain.service.ProductService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ProductApiController {

    private final ProductService productService;

    // 상품 목록 조회
    @GetMapping("/products")
    public ResponseEntity<?> getProductList() {
        return ResponseEntity.ok(productService.findAllProducts());
    }
}