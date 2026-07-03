package com.petemarket.server.order;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface OrderRepository extends JpaRepository<PetOrder, Long> {
    List<PetOrder> findByUserIdOrderByCreatedAtDesc(Long userId);

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
}
