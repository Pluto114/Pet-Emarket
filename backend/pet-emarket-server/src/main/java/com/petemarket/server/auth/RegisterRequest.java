package com.petemarket.server.auth;

import jakarta.validation.constraints.NotBlank;

public record RegisterRequest(
        @NotBlank String username,
        @NotBlank String password,
        String displayName,
        String phone,
        String email
) {
}
