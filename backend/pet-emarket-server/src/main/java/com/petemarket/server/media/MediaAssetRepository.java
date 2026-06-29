package com.petemarket.server.media;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MediaAssetRepository extends JpaRepository<MediaAsset, Long> {
    List<MediaAsset> findByStatusOrderByCreatedAtDesc(MediaStatus status);

    long countByStatus(MediaStatus status);
}
