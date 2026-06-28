package com.petemarket.server.store;

import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class StoreService {
    private static final double EARTH_RADIUS_KM = 6371.0088;
    private static final double MAX_RADIUS_KM = 100.0;

    private final PetStoreRepository storeRepository;

    public StoreService(PetStoreRepository storeRepository) {
        this.storeRepository = storeRepository;
    }

    @Transactional(readOnly = true)
    public List<StoreResponse> listOpenStores() {
        return storeRepository.findByStatusOrderByRatingDesc(StoreStatus.OPEN).stream()
                .map(store -> StoreResponse.from(store, null))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<StoreResponse> nearby(double longitude, double latitude, double radiusKm, String keyword) {
        double normalizedRadius = Math.min(Math.max(radiusKm, 0.1), MAX_RADIUS_KM);
        String normalizedKeyword = keyword == null ? "" : keyword.trim().toLowerCase(Locale.ROOT);

        return storeRepository.findByStatusOrderByRatingDesc(StoreStatus.OPEN).stream()
                .filter(store -> matchesKeyword(store, normalizedKeyword))
                .map(store -> StoreResponse.from(
                        store,
                        round(distanceKm(longitude, latitude, store.getLongitude(), store.getLatitude()))
                ))
                .filter(store -> store.distanceKm() <= normalizedRadius)
                .sorted(Comparator.comparing(StoreResponse::distanceKm)
                        .thenComparing(Comparator.comparing(StoreResponse::rating).reversed()))
                .toList();
    }

    public double distanceToStoreKm(PetStore store, double longitude, double latitude) {
        return round(distanceKm(longitude, latitude, store.getLongitude(), store.getLatitude()));
    }

    private boolean matchesKeyword(PetStore store, String keyword) {
        if (keyword.isBlank()) {
            return true;
        }
        String searchable = (store.getName() + " " + store.getCity() + " " + store.getDistrict()
                + " " + store.getAddress() + " " + store.getFeatureTags()).toLowerCase(Locale.ROOT);
        return searchable.contains(keyword);
    }

    private double distanceKm(double lon1, double lat1, double lon2, double lat2) {
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_KM * c;
    }

    private double round(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
