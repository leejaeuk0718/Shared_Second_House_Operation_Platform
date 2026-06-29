package com.busanit401.spring_back.security.oauth;

import com.busanit401.spring_back.domain.User;
import com.busanit401.spring_back.dto.user.SocialUserRequest;
import com.busanit401.spring_back.domain.repository.UserRepository;
import com.busanit401.spring_back.security.auth.CustomUserDetails;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Service
@Transactional
@RequiredArgsConstructor
public class CustomOAuth2UserService extends DefaultOAuth2UserService {

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    @Override
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User oAuth2User = super.loadUser(userRequest);

        String registrationId = userRequest.getClientRegistration().getRegistrationId();
        Map<String, Object> attributes = oAuth2User.getAttributes();

        OAuth2UserInfo userInfo = getOAuth2UserInfo(registrationId, attributes);

        String username = userInfo.getProvider() + "_" + userInfo.getProviderId();

        User user = userRepository.findByUsername(username)
                .orElseGet(() -> {
                    String nickname = generateUniqueNickname(userInfo.getName());
                    User newUser = User.from(SocialUserRequest.from(userInfo, nickname), passwordEncoder);
                    return userRepository.save(newUser);
                });

        return new CustomUserDetails(user, attributes);
    }

    /**
     * 닉네임이 이미 존재하면 숫자를 붙여서 고유한 닉네임을 만든다.
     * 예: "이재욱" 중복 시 "이재욱1", "이재욱2" ...
     */
    private String generateUniqueNickname(String baseName) {
        String nickname = baseName;
        int suffix = 1;
        while (userRepository.existsByNickname(nickname)) {
            nickname = baseName + suffix;
            suffix++;
        }
        return nickname;
    }

    private OAuth2UserInfo getOAuth2UserInfo(String registrationId, Map<String, Object> attributes) {
        if (registrationId.equals("google")) {
            return new GoogleUserInfo(attributes);
        } else if (registrationId.equals("naver")) {
            return new NaverUserInfo((Map<String, Object>) attributes.get("response"));
        } else {
            throw new OAuth2AuthenticationException("Unsupported provider: " + registrationId);
        }
    }
}