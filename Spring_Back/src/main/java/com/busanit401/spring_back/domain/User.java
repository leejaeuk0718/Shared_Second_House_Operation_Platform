package com.busanit401.spring_back.domain;

import com.busanit401.spring_back.dto.user.SocialUserRequest;
import com.busanit401.spring_back.dto.user.UserReq;
import com.busanit401.spring_back.enums.Role;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.ArrayList;
import java.util.List;


@Entity
@Getter
@NoArgsConstructor
@Builder
@AllArgsConstructor
@Table(name = "user")
public class User extends BaseTimeEntity {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long id;

    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY)
    @Builder.Default
    private List<SubscriptionsUser> subscriptions = new ArrayList<>();

    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY)
    @Builder.Default
    private List<WaitingSubscriptionUser> waitingSubscriptionUsers = new ArrayList<>();


    @Column(name = "user_name", nullable = false, unique = true)
    private String username;

    @Column(name = "password", nullable = false)
    private String password;

    @Column(name = "email", nullable = false)
    private String email;

    @Column(name = "nick_name", nullable = false, unique = true)
    private String nickname;

    @Column(name = "phone_number", nullable = true)
    private String phoneNumber;


    @Column(name = "role", nullable = false)
    @Enumerated(EnumType.STRING)
    private Role role;


    //비지니스 로직
    public void update(String username, String nickname) {
        this.username = username;
        this.nickname = nickname;
    }


    //비지니스 로직
    public void updatePassword(String password) {
        this.password = password;
    }


    public static User from(SocialUserRequest userRequest, BCryptPasswordEncoder passwordEncoder) {
        return User.builder()
                .username(userRequest.getUsername())
                .password(passwordEncoder.encode(userRequest.getPassword()))
                .nickname(userRequest.getNickname())
                .email(userRequest.getEmail())
                .role(Role.SOCIAL)
                .build();
    }


    public static User from(UserReq request, String encodedPassword
    ) {
        return User.builder()
                .username(request.getUsername())
                .password(encodedPassword)
                .email(request.getEmail())
                .nickname(request.getNickname())
                .phoneNumber(request.getPhoneNumber())
                .role(Role.User)
                .build();
    }




}
