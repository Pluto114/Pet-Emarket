package com.petemarket.server.cart;

import com.petemarket.server.product.Product;
import com.petemarket.server.product.ProductResponse;
import java.math.BigDecimal;

public record CartItemResponse(
        Long id,
        Long productId,
        Integer quantity,
        BigDecimal subtotal,
        ProductResponse product
) {
    public static CartItemResponse from(CartItem item, Product product) {
        BigDecimal subtotal = product.getPrice().multiply(BigDecimal.valueOf(item.getQuantity()));
        return new CartItemResponse(item.getId(), item.getProductId(), item.getQuantity(), subtotal, ProductResponse.from(product));
    }
}
