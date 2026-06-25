package com.petemarket.server.auth;

import com.petemarket.server.user.UserResponse;

public record AuthResponse(String token, UserResponse user) {
}
