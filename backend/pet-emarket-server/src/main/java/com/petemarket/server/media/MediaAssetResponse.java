package com.petemarket.server.media;

import java.time.Instant;

public record MediaAssetResponse(
        Long id,
        String title,
        MediaType mediaType,
        String url,
        String coverUrl,
        Long productId,
        String description,
        MediaStatus status,
        String auditRemark,
        Long createdBy,
        Long auditedBy,
        Instant auditedAt,
        Instant createdAt,
        Instant updatedAt
) {
    public static MediaAssetResponse from(MediaAsset asset) {
        return new MediaAssetResponse(
                asset.getId(),
                asset.getTitle(),
                asset.getMediaType(),
                asset.getUrl(),
                asset.getCoverUrl(),
                asset.getProductId(),
                asset.getDescription(),
                asset.getStatus(),
                asset.getAuditRemark(),
                asset.getCreatedBy(),
                asset.getAuditedBy(),
                asset.getAuditedAt(),
                asset.getCreatedAt(),
                asset.getUpdatedAt()
        );
    }
}
