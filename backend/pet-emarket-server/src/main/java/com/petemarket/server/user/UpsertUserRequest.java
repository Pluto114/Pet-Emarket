package com.petemarket.server.user;

public record UpsertUserRequest(
        String username,
        String password,
        String displayName,
        String phone,
        String email,
        UserRole role,
        MemberLevel memberLevel,
        AccountStatus status
) {
}
