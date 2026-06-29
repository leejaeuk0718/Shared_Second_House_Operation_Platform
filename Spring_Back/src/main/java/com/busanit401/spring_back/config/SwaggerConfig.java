package com.busanit401.spring_back.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("세컨하우스 플랫폼 - 배달 서비스 API 명세서")
                        .description("식재료 배달 및 주문 관리 백엔드 API 명세서입니다.")
                        .version("v1.0.0"));
    }
}


