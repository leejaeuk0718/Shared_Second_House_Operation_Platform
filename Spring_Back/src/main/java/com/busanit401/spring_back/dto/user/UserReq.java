package com.busanit401.spring_back.dto.user;

import com.busanit401.spring_back.enums.Role;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@Builder
@AllArgsConstructor
public class UserReq {

    @NotBlank(message = "아이디는 필수 입력 값입니다.")
    @Pattern(regexp = "^[a-zA-Z0-9]{4,20}$", message = "아이디는 특수문자를 제외한 4~20자 사이로 입력해주세요.")
    private String username;

    @NotBlank(message = "비밀번호는 필수 입력 값입니다.")
//    @Range(min = 8, max = 16, message = "비밀번호는 8~16자 사이로 입력해주세요.", groups = RangeGroups.class)
    @Pattern(regexp = "^(?=.*[a-zA-Z])(?=.*\\d)(?=.*[@#$%^&+=!])(?!.*\\s).{8,16}$", message = "비밀번호는 영문, 숫자, 특수문자(2개) 모두 포함해주세요.")
    private String password;

    @NotBlank(message = "닉네임은 필수 입력 값입니다.")
    @Pattern(regexp = "^[가-힣a-zA-Z0-9]{2,10}$", message = "닉네임은 2~10자의 한글, 영문, 숫자만 입력해주세요.")
    private String nickname;

    @NotBlank(message = "이메일은 필수 입력 값입니다.")
    @Pattern(regexp = "\\w+@\\w+\\.\\w+(\\.\\w+)?", message = "이메일 형식이 올바르지 않습니다.")
    private String email;

    @NotBlank(message = "휴대폰 번호는 필수 입력 값입니다.")
    @Pattern(regexp = "^01(?:0|1|[6-9])[0-9]{7,8}$", message = "올바른 휴대폰 번호 형식이 아닙니다.")
    private String phoneNumber;


    public static UserReq from(UserInfo userInfo){
        return UserReq.builder()
                .username(userInfo.getUsername())
                .password(userInfo.getPassword())
                .nickname(userInfo.getNickname())
                .email(userInfo.getEmail())
                .phoneNumber(userInfo.getPhoneNumber())
                .build();
    }


}
