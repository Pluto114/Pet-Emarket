package com.petemarket.server.address;

import java.time.Instant;

public record ShippingAddressResponse(
        Long id,
        Long userId,
        String receiver,
        String phone,
        String province,
        String city,
        String district,
        String detail,
        Boolean defaultAddress,
        Instant createdAt,
        Instant updatedAt
) {
    public static ShippingAddressResponse from(ShippingAddress address) {
        return new ShippingAddressResponse(
                address.getId(),
                address.getUserId(),
                address.getReceiver(),
                address.getPhone(),
                address.getProvince(),
                address.getCity(),
                address.getDistrict(),
                address.getDetail(),
                address.getDefaultAddress(),
                address.getCreatedAt(),
                address.getUpdatedAt()
        );
    }
}
