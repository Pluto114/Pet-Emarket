package com.petemarket.server.user;

import java.time.Instant;

public record UserResponse(
        Long id,
        String username,
        String displayName,
        String phone,
        String email,
        UserRole role,
        MemberLevel memberLevel,
        AccountStatus status,
        Instant createdAt,
        Instant updatedAt
) {
    public static UserResponse from(UserAccount user) {
        return new UserResponse(
                user.getId(),
                user.getUsername(),
                user.getDisplayName(),
                user.getPhone(),
                user.getEmail(),
                user.getRole(),
                user.getMemberLevel(),
                user.getStatus(),
                user.getCreatedAt(),
                user.getUpdatedAt()
        );
    }
}
