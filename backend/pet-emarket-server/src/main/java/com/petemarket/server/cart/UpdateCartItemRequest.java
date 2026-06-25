package com.petemarket.server.cart;

import jakarta.validation.constraints.NotNull;

public record UpdateCartItemRequest(@NotNull Integer quantity) {
}
