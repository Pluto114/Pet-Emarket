package com.petemarket.server.product;

import com.petemarket.server.order.PetOrder;
import java.time.Instant;

public record ProductReviewResponse(
        Long orderId,
        String orderNo,
        Long userId,
        Integer rating,
        String content,
        Instant reviewedAt
) {
    public static ProductReviewResponse from(PetOrder order) {
        return new ProductReviewResponse(
                order.getId(),
                order.getOrderNo(),
                order.getUserId(),
                order.getReviewRating(),
                order.getReviewContent() == null ? "" : order.getReviewContent(),
                order.getUpdatedAt()
        );
    }
}
