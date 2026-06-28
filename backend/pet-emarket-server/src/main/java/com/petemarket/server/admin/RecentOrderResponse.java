package com.petemarket.server.admin;

import java.math.BigDecimal;
import java.time.Instant;

public record RecentOrderResponse(
        Long id,
        String orderNo,
        Long userId,
        Integer status,
        String statusName,
        BigDecimal payAmount,
        Instant createdAt
) {
}
