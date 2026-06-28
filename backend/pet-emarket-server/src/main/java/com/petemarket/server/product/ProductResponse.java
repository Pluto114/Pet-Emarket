package com.petemarket.server.product;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

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
        ProductAuditStatus auditStatus,
        String auditRemark,
        Long auditedBy,
        Instant auditedAt,
        Map<String, Object> livePet,
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
                product.getAuditStatus(),
                product.getAuditRemark(),
                product.getAuditedBy(),
                product.getAuditedAt(),
                livePet(product),
                product.getCreatedAt(),
                product.getUpdatedAt()
        );
    }

    private static Map<String, Object> livePet(Product product) {
        if (product.getType() != ProductType.PET_LIVE) {
            return null;
        }
        return Map.of(
                "petCode", defaultText(product.getPetCode()),
                "breed", defaultText(product.getBreed()),
                "healthStatus", defaultText(product.getHealthStatus()),
                "vaccineCertNo", defaultText(product.getVaccineCertNo()),
                "quarantineCertNo", defaultText(product.getQuarantineCertNo()),
                "traceSource", defaultText(product.getTraceSource()),
                "auditStatus", product.getAuditStatus() == null ? ProductAuditStatus.PENDING.name() : product.getAuditStatus().name()
        );
    }

    private static String defaultText(String value) {
        return value == null ? "" : value;
    }
}
