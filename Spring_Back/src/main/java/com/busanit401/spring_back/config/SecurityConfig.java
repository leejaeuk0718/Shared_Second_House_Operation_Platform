package com.busanit401.spring_back.config;

import com.busanit401.spring_back.security.auth.JwtAuthenticationFilter;
import com.busanit401.spring_back.security.auth.JwtFilter;
import com.busanit401.spring_back.domain.service.TokenBlacklistService;
import com.busanit401.spring_back.security.oauth.CustomOAuth2AuthenticationSuccessHandler;
import com.busanit401.spring_back.security.oauth.CustomOAuth2UserService;
import com.busanit401.spring_back.util.JwtUtil;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.security.servlet.PathRequest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityCustomizer;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;


import java.util.Arrays;
import java.util.Collections;
import java.util.List;


@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
@Slf4j
public class SecurityConfig {

    private final JwtFilter jwtFilter;
    private final TokenBlacklistService tokenBlacklistService;
    private final JwtUtil jwtUtil;
    private final CustomOAuth2UserService customOAuth2UserService;
    private final CustomOAuth2AuthenticationSuccessHandler customOAuth2AuthenticationSuccessHandler;

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration configuration) throws Exception {
        return configuration.getAuthenticationManager();
    }

    @Bean
    public WebSecurityCustomizer webSecurityCustomizer() {
        return (web) -> web.ignoring()
                .requestMatchers(PathRequest.toStaticResources().atCommonLocations());
    }


    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        configuration.setExposedHeaders(Collections.singletonList("Authorization"));
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        AuthenticationManager authenticationManager = authenticationManager(http.getSharedObject(AuthenticationConfiguration.class));
        JwtAuthenticationFilter jwtAuthenticationFilter = new JwtAuthenticationFilter(authenticationManager, tokenBlacklistService, jwtUtil);

        http.csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(session -> session            // 추가 — JWT는 무상태여야 함
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )
                .formLogin(AbstractHttpConfigurer::disable)        // 추가 — 기본 로그인 폼/리다이렉트 비활성화
                .httpBasic(AbstractHttpConfigurer::disable)        // 추가 — 기본 인증 팝업 비활성화
                .exceptionHandling(exceptions -> exceptions
                        .authenticationEntryPoint((request, response, authException) -> {
                            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                            response.setContentType("application/json;charset=UTF-8");
                            response.getWriter().write("{\"error\": \"Unauthorized\", \"message\": \"인증이 필요합니다.\"}");
                        })
                )
                .authorizeHttpRequests(requests -> requests

                        .requestMatchers(HttpMethod.POST, "/api/users").permitAll()
                        // 🔒 로그인 필수 — 챗봇 / 구글맵(주변 맛집) / 이동경로 트래킹
                        // (아래 "/api/**" permitAll 보다 위에 둬야 먼저 매칭되어 인증이 강제됨)
                        .requestMatchers("/api/chatBot/**", "/api/places/**", "/api/routes/**").authenticated()
                        .requestMatchers(
                                "/",
                                "/swagger-ui/**",
                                "/swagger-ui.html",
                                "/v3/api-docs/**",
                                "/swagger-resources/**",
                                "/webjars/**",

                                "/oauth2/**",
                                "/login/**",

                                // 숙소 목록 조회, 숙소 상세 조회
                                "/api/stay/accommodations",
                                "/api/stay/accommodations/",
                                "/api/stay/stories/",
                                "/api/places/",
                                "/uploads/",

                                // 게스트 채팅
                                "/ws-guest-chat/**",
                                "/api/guest/chat/**",

                                // 관광지 리스트
                                "/api/tours/**",

                                "/ws/**",
                                "/api/users/find-username",
                                "/api/users/find-password",
                                "/api/users/google-login",
                                "/api/users/kakao-login",
                                "/api/users/refresh-token",

//                                // test용 전체 통과 경로
//                                "/api/**",

                                "/uploads/**",

                                "/app/**",
                                "/topic/**"
                        ).permitAll()
                        .anyRequest().authenticated()
                )
                .oauth2Login(oauth -> oauth
                                .userInfoEndpoint(userInfo -> userInfo
                                        .userService(customOAuth2UserService)
                                )
                                .successHandler(customOAuth2AuthenticationSuccessHandler)
                        // defaultSuccessUrl 제거 — successHandler가 리다이렉트 담당
                );
        http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
