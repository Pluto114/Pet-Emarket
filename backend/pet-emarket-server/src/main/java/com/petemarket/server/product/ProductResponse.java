package com.petemarket.server.product;

import java.math.BigDecimal;
import java.time.Instant;

public record ProductResponse(
        Long id,
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
        String traceSource,
        Instant createdAt,
        Instant updatedAt
) {
    public static ProductResponse from(Product product) {
        return new ProductResponse(
                product.getId(),
                product.getStoreId(),
                product.getName(),
                product.getType(),
                product.getCategory(),
                product.getPrice(),
                product.getStock(),
                product.getStatus(),
                product.getCoverUrl(),
                product.getDescription(),
                product.getPetCode(),
                product.getBreed(),
                product.getHealthStatus(),
                product.getVaccineCertNo(),
                product.getQuarantineCertNo(),
                product.getTraceSource(),
                product.getCreatedAt(),
                product.getUpdatedAt()
        );
    }
}
