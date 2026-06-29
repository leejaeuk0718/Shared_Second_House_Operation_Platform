package com.busanit401.spring_back.domain.service;

import com.busanit401.spring_back.domain.User;
import com.busanit401.spring_back.dto.user.PasswordUpdateReq;
import com.busanit401.spring_back.dto.user.UserReq;
import com.busanit401.spring_back.dto.user.UserResp;
import com.busanit401.spring_back.dto.user.UserSimpleReq;
import com.busanit401.spring_back.exception.CustomException;
import com.busanit401.spring_back.exception.ErrorCode;
import com.busanit401.spring_back.exception.UserNotFoundException;
import com.busanit401.spring_back.domain.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
@Slf4j
public class UserService {

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder encoder;

    /**
     * 회원가입
     */
    @Transactional
    public UserResp createUser(UserReq request) {
        validateDuplicateUser(request);

        String encodedPassword =
                encoder.encode(request.getPassword());

        User user = User.from(request,encodedPassword);

        User savedUser = userRepository.save(user);

        log.info("회원가입 성공 : {}", savedUser.getUsername());

        return UserResp.from(savedUser);
    }

    /**
     * 회원 조회
     */
    public UserResp getUser(Long userId) {
        return UserResp.from(findUser(userId));
    }


    /**
     * 회원정보 수정
     */
    @Transactional
    public void updateUser(Long userId, UserSimpleReq request) {

        log.info("updateUser 시작");

        User user = findUser(userId);

        log.info("기존 username = {}", user.getUsername());

        user.update(
                request.getUsername(),
                request.getNickname()
        );

        log.info("변경 완료");
    }

    @Transactional
    public void updatePassword(Long userId, PasswordUpdateReq request
    ) {
        User user = findUser(userId);
        if (!encoder.matches(request.getCurrentPassword(), user.getPassword()
        )) {
            throw new CustomException(ErrorCode.INVALID_PASSWORD);
        }
        user.updatePassword(encoder.encode(request.getNewPassword()));
    }

    /**
     * 회원 탈퇴
     */
    @Transactional
    public void deleteUser(Long userId) {
        User user = findUser(userId);
        userRepository.delete(user);

        log.info("회원 탈퇴 : {}", userId);
    }

    /**
     * 중복 검사
     */
    private void validateDuplicateUser(UserReq request) {

        if(userRepository.existsByEmail(request.getEmail())){
            throw new CustomException(
                    ErrorCode.DUPLICATE_EMAIL
            );
        }

        if(userRepository.existsByUsername(request.getUsername())){
            throw new CustomException(
                    ErrorCode.DUPLICATE_USERNAME
            );
        }

        if(userRepository.existsByNickname(request.getNickname())){
            throw new CustomException(
                    ErrorCode.DUPLICATE_NICKNAME
            );
        }
    }

    private User findUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(UserNotFoundException::new);
    }

    public boolean existsByEmail(String email) {
        return userRepository.existsByEmail(email);
    }
}