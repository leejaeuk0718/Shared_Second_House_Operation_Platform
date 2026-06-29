package com.busanit401.spring_back.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class AppConfig {

    @Bean // 스프링 컨테이너에 RestTemplate을 빈(Bean)으로 등록
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}