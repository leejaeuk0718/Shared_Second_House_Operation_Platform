package com.busanit401.spring_back.dto.user;

import com.busanit401.spring_back.enums.Role;
import com.busanit401.spring_back.security.oauth.OAuth2UserInfo;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SocialUserRequest {


    private String username;
    private String password;
    private String nickname;
    private String email;
    private Role role;

    public static SocialUserRequest from(OAuth2UserInfo userInfo, String resolvedNickname) {
        return SocialUserRequest.builder()
                .username(userInfo.getProvider() + "_" + userInfo.getProviderId())
                .password(UUID.randomUUID().toString()) // null → 랜덤 문자열
                .nickname(resolvedNickname) // 중복 체크를 마친 닉네임을 외부에서 받음
                .email(userInfo.getEmail())
                .role(Role.SOCIAL)
                .build();
    }
}
