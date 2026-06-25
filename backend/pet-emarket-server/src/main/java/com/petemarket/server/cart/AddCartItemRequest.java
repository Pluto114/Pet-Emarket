package com.petemarket.server.cart;

import jakarta.validation.constraints.NotNull;

public record AddCartItemRequest(@NotNull Long productId, Integer quantity) {
}
