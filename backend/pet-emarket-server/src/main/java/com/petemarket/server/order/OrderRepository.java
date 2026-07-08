package com.petemarket.server.order;

import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface OrderRepository extends JpaRepository<PetOrder, Long> {

    @Query(value = "SELECT * FROM pet_order WHERE user_id = :userId ORDER BY created_at DESC", nativeQuery = true)
    List<PetOrder> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId);

    @Query(value = "SELECT * FROM pet_order ORDER BY created_at DESC", nativeQuery = true)
    List<PetOrder> findAllByOrderByCreatedAtDesc();

    @Query("""
            select distinct orderEntity
            from PetOrder orderEntity
            join orderEntity.items item
            where item.productId = :productId
              and orderEntity.reviewRating is not null
            order by orderEntity.updatedAt desc
            """)
    List<PetOrder> findReviewedOrdersByProductId(@Param("productId") Long productId);

    List<PetOrder> findByStatusAndPaymentDeadlineBefore(Integer status, Instant deadline);
}
