package com.petemarket.server.user;

import jakarta.validation.constraints.NotBlank;

public record UpsertUserRequest(
        @NotBlank String username,
        String password,
        String displayName,
        String phone,
        String email,
        UserRole role,
        MemberLevel memberLevel,
        AccountStatus status
) {
}
