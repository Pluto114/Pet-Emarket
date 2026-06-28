package com.petemarket.server.store;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record UpsertStoreRequest(
        @NotBlank String name,
        @NotBlank String address,
        @NotBlank String city,
        @NotBlank String district,
        @NotNull @DecimalMin("-180.0") @DecimalMax("180.0") Double longitude,
        @NotNull @DecimalMin("-90.0") @DecimalMax("90.0") Double latitude,
        String phone,
        String businessHours,
        Double rating,
        StoreStatus status,
        String featureTags
) {
}
