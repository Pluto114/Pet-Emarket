package com.petemarket.server.address;

import jakarta.validation.constraints.NotBlank;

public record UpsertShippingAddressRequest(
        @NotBlank String receiver,
        @NotBlank String phone,
        String province,
        String city,
        String district,
        @NotBlank String detail,
        Boolean defaultAddress
) {
}
