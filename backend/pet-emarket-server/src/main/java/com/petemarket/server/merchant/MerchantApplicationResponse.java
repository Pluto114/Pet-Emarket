package com.petemarket.server.merchant;

import java.time.Instant;

public record MerchantApplicationResponse(
        Long id,
        Long userId,
        String storeName,
        String city,
        String district,
        String address,
        Double longitude,
        Double latitude,
        String contactName,
        String contactPhone,
        String businessLicenseNo,
        String reason,
        MerchantApplicationStatus status,
        String auditRemark,
        Long auditedBy,
        Instant auditedAt,
        Long storeId,
        Instant createdAt,
        Instant updatedAt
) {
    public static MerchantApplicationResponse from(MerchantApplication application) {
        return new MerchantApplicationResponse(
                application.getId(),
                application.getUserId(),
                application.getStoreName(),
                application.getCity(),
                application.getDistrict(),
                application.getAddress(),
                application.getLongitude(),
                application.getLatitude(),
                application.getContactName(),
                application.getContactPhone(),
                application.getBusinessLicenseNo(),
                application.getReason(),
                application.getStatus(),
                application.getAuditRemark(),
                application.getAuditedBy(),
                application.getAuditedAt(),
                application.getStoreId(),
                application.getCreatedAt(),
                application.getUpdatedAt()
        );
    }
}
