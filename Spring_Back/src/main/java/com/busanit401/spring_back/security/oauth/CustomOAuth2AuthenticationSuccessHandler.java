package com.busanit401.spring_back.security.oauth;

import com.busanit401.spring_back.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@RequiredArgsConstructor
@Component
public class CustomOAuth2AuthenticationSuccessHandler implements AuthenticationSuccessHandler {

    private final JwtUtil jwtUtil;

    private static final String FRONTEND_URL = "http://localhost:3000"; // 프론트 주소

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response, Authentication authentication) throws IOException {
        String jwt = jwtUtil.generateToken(authentication.getName());

        String encodedToken = URLEncoder.encode(jwt, StandardCharsets.UTF_8);
        String redirectUrl = FRONTEND_URL + "/oauth2/redirect?token=" + encodedToken;

        response.sendRedirect(redirectUrl);
    }
}