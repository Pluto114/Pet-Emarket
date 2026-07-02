package com.petemarket.server.store;

import com.petemarket.server.common.BusinessException;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRole;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import org.springframework.http.HttpStatus;
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
    public List<StoreResponse> listAllStores() {
        return storeRepository.findAll().stream()
                .map(store -> StoreResponse.from(store, null))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<StoreResponse> listManagedStores(UserAccount user) {
        if (user.getRole() == UserRole.ADMIN) {
            return listAllStores();
        }
        return storeRepository.findByOwnerUserIdOrderByRatingDesc(user.getId()).stream()
                .map(store -> StoreResponse.from(store, null))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<Long> managedStoreIds(UserAccount user) {
        if (user.getRole() == UserRole.ADMIN) {
            return storeRepository.findAll().stream().map(PetStore::getId).toList();
        }
        if (user.getRole() != UserRole.MERCHANT) {
            return List.of();
        }
        return storeRepository.findByOwnerUserIdOrderByRatingDesc(user.getId()).stream()
                .map(PetStore::getId)
                .toList();
    }

    @Transactional(readOnly = true)
    public StoreResponse get(Long id) {
        return StoreResponse.from(find(id), null);
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

    @Transactional
    public StoreResponse create(UpsertStoreRequest request, UserAccount actor) {
        PetStore store = new PetStore();
        apply(store, request);
        store.setOwnerUserId(resolveOwnerUserId(request, actor));
        storeRepository.save(store);
        return StoreResponse.from(store, null);
    }

    @Transactional
    public StoreResponse update(Long id, UpsertStoreRequest request, UserAccount actor) {
        PetStore store = find(id);
        requireStoreOwner(actor, store);
        apply(store, request);
        if (actor.getRole() == UserRole.ADMIN) {
            store.setOwnerUserId(request.ownerUserId());
        }
        return StoreResponse.from(store, null);
    }

    @Transactional
    public void delete(Long id, UserAccount actor) {
        PetStore store = find(id);
        requireStoreOwner(actor, store);
        storeRepository.delete(store);
    }

    @Transactional(readOnly = true)
    public boolean canManageStore(UserAccount actor, Long storeId) {
        if (actor == null) {
            return false;
        }
        if (actor.getRole() == UserRole.ADMIN) {
            return true;
        }
        return actor.getRole() == UserRole.MERCHANT
                && storeId != null
                && storeRepository.existsByIdAndOwnerUserId(storeId, actor.getId());
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

    private PetStore find(Long id) {
        return storeRepository.findById(id)
                .orElseThrow(() -> new BusinessException("200404", "Store not found", HttpStatus.NOT_FOUND));
    }

    private void apply(PetStore store, UpsertStoreRequest request) {
        store.setName(request.name());
        store.setAddress(request.address());
        store.setCity(request.city());
        store.setDistrict(request.district());
        store.setLongitude(request.longitude());
        store.setLatitude(request.latitude());
        store.setPhone(defaultText(request.phone(), ""));
        store.setBusinessHours(defaultText(request.businessHours(), "09:00-21:00"));
        store.setRating(request.rating() == null ? 5.0 : Math.min(5.0, Math.max(0.0, request.rating())));
        store.setStatus(request.status() == null ? StoreStatus.OPEN : request.status());
        store.setFeatureTags(defaultText(request.featureTags(), ""));
        store.setAmapPoiId(defaultText(request.amapPoiId(), ""));
    }

    private Long resolveOwnerUserId(UpsertStoreRequest request, UserAccount actor) {
        if (actor.getRole() == UserRole.MERCHANT) {
            return actor.getId();
        }
        return request.ownerUserId();
    }

    private void requireStoreOwner(UserAccount actor, PetStore store) {
        if (actor.getRole() == UserRole.ADMIN) {
            return;
        }
        if (actor.getRole() == UserRole.MERCHANT && actor.getId().equals(store.getOwnerUserId())) {
            return;
        }
        throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
