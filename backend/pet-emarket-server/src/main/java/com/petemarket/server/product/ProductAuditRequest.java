package com.petemarket.server.product;

import jakarta.validation.constraints.NotNull;

public record ProductAuditRequest(
        @NotNull Boolean approved,
        String remark
) {
}
