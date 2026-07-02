package com.petemarket.server.merchant;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record MerchantApplicationRequest(
        @NotBlank String storeName,
        @NotBlank String city,
        @NotBlank String district,
        @NotBlank String address,
        @NotNull @DecimalMin("-180.0") @DecimalMax("180.0") Double longitude,
        @NotNull @DecimalMin("-90.0") @DecimalMax("90.0") Double latitude,
        String contactName,
        String contactPhone,
        String businessLicenseNo,
        String reason
) {
}
