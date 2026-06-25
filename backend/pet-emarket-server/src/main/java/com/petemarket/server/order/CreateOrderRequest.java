package com.petemarket.server.order;

import java.util.List;

public record CreateOrderRequest(AddressSnapshot addressSnapshot, List<Long> cartItemIds) {
}
