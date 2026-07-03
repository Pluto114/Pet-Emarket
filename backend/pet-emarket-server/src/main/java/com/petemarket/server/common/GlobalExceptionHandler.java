package com.petemarket.server.common;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Void>> handleBusiness(BusinessException exception) {
        return ResponseEntity
                .status(exception.getStatus())
                .body(ApiResponse.fail(exception.getCode(), exception.getMessage()));
    }

    @ExceptionHandler({MethodArgumentNotValidException.class, BindException.class})
    public ResponseEntity<ApiResponse<Void>> handleValidation(Exception exception) {
        String message = "请求参数不正确";
        FieldError fieldError = null;
        if (exception instanceof MethodArgumentNotValidException validException) {
            fieldError = validException.getBindingResult().getFieldError();
        } else if (exception instanceof BindException bindException) {
            fieldError = bindException.getBindingResult().getFieldError();
        }
        if (fieldError != null) {
            message = switch (fieldError.getField()) {
                case "email" -> "请输入有效邮箱地址";
                case "username" -> "请输入用户名";
                case "password" -> "请输入密码";
                case "emailCode" -> "请输入邮箱验证码";
                default -> "请求参数不正确：" + fieldError.getField();
            };
        }
        return ResponseEntity
                .badRequest()
                .body(ApiResponse.fail("500400", message));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnexpected(Exception exception) {
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.fail("500000", exception.getMessage()));
    }
}
