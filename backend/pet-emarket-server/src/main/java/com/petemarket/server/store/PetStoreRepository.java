package com.petemarket.server.store;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PetStoreRepository extends JpaRepository<PetStore, Long> {
    List<PetStore> findByStatusOrderByRatingDesc(StoreStatus status);

    List<PetStore> findByOwnerUserIdOrderByRatingDesc(Long ownerUserId);

    long countByStatus(StoreStatus status);

    boolean existsByIdAndOwnerUserId(Long id, Long ownerUserId);
}
