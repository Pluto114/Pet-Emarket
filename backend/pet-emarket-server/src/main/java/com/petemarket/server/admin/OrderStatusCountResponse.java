package com.petemarket.server.admin;

public record OrderStatusCountResponse(
        Integer status,
        String statusName,
        long count
) {
}
