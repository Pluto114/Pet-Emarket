package com.petemarket.server.product;

import java.math.BigDecimal;

public record UpsertProductRequest(
        Long storeId,
        String name,
        ProductType type,
        String category,
        BigDecimal price,
        Integer stock,
        ProductStatus status,
        String coverUrl,
        String description,
        String petCode,
        String breed,
        String healthStatus,
        String vaccineCertNo,
        String quarantineCertNo,
        String traceSource
) {
}
