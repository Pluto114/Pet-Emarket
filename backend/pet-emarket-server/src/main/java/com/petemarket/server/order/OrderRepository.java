package com.petemarket.server.order;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<PetOrder, Long> {
    List<PetOrder> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<PetOrder> findAllByOrderByCreatedAtDesc();
}
