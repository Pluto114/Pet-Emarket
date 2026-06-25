package com.petemarket.server.common;

import java.time.Instant;
import java.util.UUID;

public record ApiResponse<T>(
        boolean success,
        String code,
        String message,
        T data,
        String traceId,
        long timestamp
) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, "000000", "success", data, traceId(), Instant.now().toEpochMilli());
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return new ApiResponse<>(true, "000000", message, data, traceId(), Instant.now().toEpochMilli());
    }

    public static ApiResponse<Void> fail(String code, String message) {
        return new ApiResponse<>(false, code, message, null, traceId(), Instant.now().toEpochMilli());
    }

    private static String traceId() {
        return UUID.randomUUID().toString().replace("-", "");
    }
}
