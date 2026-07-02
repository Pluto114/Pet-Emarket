package com.petemarket.server.auth;

public record EmailCodeResponse(
        String email,
        int expiresInSeconds,
        String devCode
) {
}
