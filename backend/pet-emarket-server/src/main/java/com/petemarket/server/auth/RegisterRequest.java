package com.petemarket.server.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Email;

public record RegisterRequest(
        @NotBlank String username,
        @NotBlank String password,
        String displayName,
        String phone,
        @NotBlank @Email String email,
        @NotBlank String emailCode
) {
}
