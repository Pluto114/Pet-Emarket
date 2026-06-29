package com.petemarket.server.behavior;

import java.time.Instant;

public record UserBehaviorResponse(
        Long id,
        Long userId,
        Long productId,
        String productName,
        String category,
        String productType,
        Long storeId,
        UserBehaviorType behaviorType,
        Double weight,
        Integer quantity,
        String scene,
        Instant createdAt
) {
    public static UserBehaviorResponse from(UserBehavior behavior) {
        return new UserBehaviorResponse(
                behavior.getId(),
                behavior.getUserId(),
                behavior.getProductId(),
                behavior.getProductName(),
                behavior.getCategory(),
                behavior.getProductType(),
                behavior.getStoreId(),
                behavior.getBehaviorType(),
                behavior.getWeight(),
                behavior.getQuantity(),
                behavior.getScene(),
                behavior.getCreatedAt()
        );
    }
}
