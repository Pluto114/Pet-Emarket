package com.petemarket.server.admin;

import java.math.BigDecimal;

public record TopProductResponse(
        Long productId,
        String productName,
        String category,
        long quantity,
        BigDecimal amount
) {
}
