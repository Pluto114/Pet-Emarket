package com.petemarket.server.behavior;

import jakarta.validation.constraints.NotNull;

public record TrackBehaviorRequest(
        @NotNull Long productId,
        @NotNull UserBehaviorType behaviorType,
        String scene,
        Integer quantity
) {
}
