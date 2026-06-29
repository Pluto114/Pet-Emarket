package com.petemarket.server.loyalty;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PointLedgerRepository extends JpaRepository<PointLedger, Long> {
    List<PointLedger> findAllByOrderByCreatedAtDesc();

    List<PointLedger> findByUserIdOrderByCreatedAtDesc(Long userId);

    Optional<PointLedger> findByOrderIdAndType(Long orderId, PointLedgerType type);
}
