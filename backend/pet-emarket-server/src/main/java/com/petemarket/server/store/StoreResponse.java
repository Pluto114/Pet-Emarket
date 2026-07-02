package com.petemarket.server.store;

import java.time.Instant;

public record StoreResponse(
        Long id,
        String name,
        String address,
        String city,
        String district,
        Double longitude,
        Double latitude,
        String phone,
        String businessHours,
        Double rating,
        StoreStatus status,
        String featureTags,
        String amapPoiId,
        Double distanceKm,
        Instant createdAt,
        Instant updatedAt
) {
    public static StoreResponse from(PetStore store, Double distanceKm) {
        return new StoreResponse(
                store.getId(),
                store.getName(),
                store.getAddress(),
                store.getCity(),
                store.getDistrict(),
                store.getLongitude(),
                store.getLatitude(),
                store.getPhone(),
                store.getBusinessHours(),
                store.getRating(),
                store.getStatus(),
                store.getFeatureTags(),
                store.getAmapPoiId(),
                distanceKm,
                store.getCreatedAt(),
                store.getUpdatedAt()
        );
    }
}
