package com.petemarket.server.media;

import jakarta.validation.constraints.NotBlank;

public record UpsertMediaAssetRequest(
        @NotBlank String title,
        MediaType mediaType,
        @NotBlank String url,
        String coverUrl,
        Long productId,
        String description,
        MediaStatus status,
        String auditRemark
) {
}
