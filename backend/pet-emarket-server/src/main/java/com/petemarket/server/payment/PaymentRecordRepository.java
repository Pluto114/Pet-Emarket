package com.petemarket.server.payment;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PaymentRecordRepository extends JpaRepository<PaymentRecord, Long> {
    List<PaymentRecord> findAllByOrderByCreatedAtDesc();

    List<PaymentRecord> findByUserIdOrderByCreatedAtDesc(Long userId);

    Optional<PaymentRecord> findByOrderIdAndType(Long orderId, PaymentType type);
}
