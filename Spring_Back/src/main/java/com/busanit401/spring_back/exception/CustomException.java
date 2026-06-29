package com.busanit401.spring_back.exception;

public class CustomException extends BusinessException {

    public CustomException(ErrorCode errorCode) {
        super(errorCode);
    }
}