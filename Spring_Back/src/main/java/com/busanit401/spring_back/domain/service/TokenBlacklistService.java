package com.busanit401.spring_back.domain.service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class TokenBlacklistService {

    private final RedisTemplate<String, Object> redisTemplate;
    private static final String BLACKLIST_PREFIX = "blacklist:";

    public void addToBlacklist(String token, long expirationTime) {
        //opsForValue는 스트링으로 넣는다는 뜻
        redisTemplate.opsForValue().set(BLACKLIST_PREFIX + token, true, expirationTime, TimeUnit.MILLISECONDS); //테이블과 컬럼 개념이 없기때문에 앞에 prefix로 구분해주고 값을 true 넣고, 만료시간과 만료시간 단위를 넣어주면 자동으로 만료시간 후 정리됨
    }

    public boolean isBlacklisted(String token) {
        Boolean isBlacklisted = (Boolean) redisTemplate.opsForValue().get(BLACKLIST_PREFIX + token);
        return isBlacklisted != null && isBlacklisted;
    }
}