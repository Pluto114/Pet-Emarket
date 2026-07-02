package com.petemarket.server.order;

import java.math.BigDecimal;

public record OrderItemResponse(
        Long id,
        Long productId,
        Long storeId,
        String productName,
        String productType,
        String category,
        BigDecimal unitPrice,
        Integer quantity,
        BigDecimal subtotal,
        String livePetSnapshot
) {
    public static OrderItemResponse from(OrderItem item) {
        return new OrderItemResponse(
                item.getId(),
                item.getProductId(),
                item.getStoreId(),
                item.getProductName(),
                item.getProductType(),
                item.getCategory(),
                item.getUnitPrice(),
                item.getQuantity(),
                item.getSubtotal(),
                item.getLivePetSnapshot()
        );
    }
}
