package com.petemarket.server.merchant;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MerchantApplicationRepository extends JpaRepository<MerchantApplication, Long> {
    List<MerchantApplication> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<MerchantApplication> findByStatusOrderByCreatedAtDesc(MerchantApplicationStatus status);

    List<MerchantApplication> findAllByOrderByCreatedAtDesc();

    boolean existsByUserIdAndStatus(Long userId, MerchantApplicationStatus status);
}
