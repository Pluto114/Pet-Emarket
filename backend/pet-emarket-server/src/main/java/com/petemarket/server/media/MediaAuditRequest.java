package com.petemarket.server.media;

import jakarta.validation.constraints.NotNull;

public record MediaAuditRequest(
        @NotNull Boolean approved,
        String remark
) {
}
