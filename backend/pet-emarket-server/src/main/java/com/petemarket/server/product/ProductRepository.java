package com.petemarket.server.product;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductRepository extends JpaRepository<Product, Long> {
    List<Product> findByStatus(ProductStatus status);

    List<Product> findByStoreId(Long storeId);

    List<Product> findByStoreIdIn(List<Long> storeIds);

    List<Product> findByType(ProductType type);

    List<Product> findByTypeAndAuditStatus(ProductType type, ProductAuditStatus auditStatus);

    long countByType(ProductType type);

    long countByTypeAndAuditStatus(ProductType type, ProductAuditStatus auditStatus);

    long countByStatus(ProductStatus status);

    List<Product> findByNameContainingIgnoreCaseOrCategoryContainingIgnoreCaseOrDescriptionContainingIgnoreCase(
            String name,
            String category,
            String description
    );
}
