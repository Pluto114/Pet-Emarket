package com.petemarket.server.product;

import com.petemarket.server.common.BusinessException;
import com.petemarket.server.order.OrderRepository;
import com.petemarket.server.store.StoreService;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRole;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProductService {
    private final ProductRepository productRepository;
    private final StoreService storeService;
    private final OrderRepository orderRepository;

    public ProductService(ProductRepository productRepository,
                          StoreService storeService,
                          OrderRepository orderRepository) {
        this.productRepository = productRepository;
        this.storeService = storeService;
        this.orderRepository = orderRepository;
    }

    @Transactional(readOnly = true)
    public List<ProductResponse> list(String keyword, ProductType type, ProductStatus status) {
        List<Product> products;
        if (keyword == null || keyword.isBlank()) {
            products = productRepository.findAll();
        } else {
            products = productRepository.findByNameContainingIgnoreCaseOrCategoryContainingIgnoreCaseOrDescriptionContainingIgnoreCase(
                    keyword,
                    keyword,
                    keyword
            );
        }
        ProductStatus effectiveStatus = status == null ? ProductStatus.ON_SALE : status;
        return products.stream()
                .filter(product -> type == null || product.getType() == type)
                .filter(product -> product.getStatus() == effectiveStatus)
                .filter(product -> product.getStock() != null && product.getStock() > 0)
                .map(ProductResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ProductResponse> listManaged(UserAccount actor, String keyword, ProductType type, ProductStatus status) {
        List<Long> storeIds = storeService.managedStoreIds(actor);
        if (storeIds.isEmpty()) {
            return List.of();
        }
        return filteredProducts(productRepository.findByStoreIdIn(storeIds), keyword, type, status).stream()
                .map(ProductResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ProductResponse> listLivePetAudits(ProductAuditStatus auditStatus) {
        List<Product> products = auditStatus == null
                ? productRepository.findByType(ProductType.PET_LIVE)
                : productRepository.findByTypeAndAuditStatus(ProductType.PET_LIVE, auditStatus);
        return products.stream().map(ProductResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public ProductResponse get(Long id) {
        return ProductResponse.from(find(id));
    }

    @Transactional(readOnly = true)
    public List<ProductReviewResponse> reviews(Long id) {
        Product product = find(id);
        return orderRepository.findReviewedOrdersByProductId(product.getId()).stream()
                .map(ProductReviewResponse::from)
                .toList();
    }

    @Transactional
    public ProductResponse create(UpsertProductRequest request, UserAccount actor) {
        Long storeId = request.storeId() == null ? defaultManagedStoreId(actor) : request.storeId();
        requireCanManageStore(actor, storeId);
        Product product = new Product();
        apply(product, request, storeId);
        productRepository.save(product);
        return ProductResponse.from(product);
    }

    @Transactional
    public ProductResponse update(Long id, UpsertProductRequest request, UserAccount actor) {
        Product product = find(id);
        requireCanManageStore(actor, product.getStoreId());
        Long targetStoreId = request.storeId() == null ? product.getStoreId() : request.storeId();
        requireCanManageStore(actor, targetStoreId);
        apply(product, request, targetStoreId);
        return ProductResponse.from(product);
    }

    @Transactional
    public void delete(Long id, UserAccount actor) {
        Product product = find(id);
        requireCanManageStore(actor, product.getStoreId());
        productRepository.delete(product);
    }

    @Transactional
    public ProductResponse auditLivePet(Long id, boolean approved, String remark, Long auditorId) {
        Product product = find(id);
        if (product.getType() != ProductType.PET_LIVE) {
            throw new BusinessException("200400", "Only live pet products require audit");
        }
        product.setAuditStatus(approved ? ProductAuditStatus.APPROVED : ProductAuditStatus.REJECTED);
        product.setStatus(approved && product.getStock() != null && product.getStock() > 0
                ? ProductStatus.ON_SALE
                : ProductStatus.OFF_SALE);
        product.setAuditRemark(defaultText(remark, approved ? "Audit approved" : "Audit rejected"));
        product.setAuditedBy(auditorId);
        product.setAuditedAt(Instant.now());
        return ProductResponse.from(product);
    }

    public Product find(Long id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new BusinessException("200404", "Product not found", HttpStatus.NOT_FOUND));
    }

    private List<Product> filteredProducts(List<Product> products, String keyword, ProductType type, ProductStatus status) {
        String normalized = keyword == null ? "" : keyword.trim().toLowerCase();
        return products.stream()
                .filter(product -> normalized.isBlank()
                        || product.getName().toLowerCase().contains(normalized)
                        || product.getCategory().toLowerCase().contains(normalized)
                        || defaultText(product.getDescription(), "").toLowerCase().contains(normalized))
                .filter(product -> type == null || product.getType() == type)
                .filter(product -> status == null || product.getStatus() == status)
                .toList();
    }

    private void apply(Product product, UpsertProductRequest request, Long storeId) {
        product.setStoreId(storeId);
        product.setName(request.name());
        product.setType(request.type() == null ? ProductType.GOODS : request.type());
        product.setCategory(defaultText(request.category(), "General"));
        product.setPrice(request.price() == null ? BigDecimal.ZERO : request.price());
        product.setStock(request.stock() == null ? 0 : Math.max(0, request.stock()));
        product.setStatus(request.status() == null ? ProductStatus.DRAFT : request.status());
        product.setCoverUrl(defaultText(request.coverUrl(), ""));
        product.setDescription(defaultText(request.description(), ""));
        product.setPetCode(defaultText(request.petCode(), ""));
        product.setBreed(defaultText(request.breed(), ""));
        product.setHealthStatus(defaultText(request.healthStatus(), ""));
        product.setVaccineCertNo(defaultText(request.vaccineCertNo(), ""));
        product.setQuarantineCertNo(defaultText(request.quarantineCertNo(), ""));
        product.setTraceSource(defaultText(request.traceSource(), ""));
        if (product.getType() == ProductType.PET_LIVE && product.getStock() > 1) {
            product.setStock(1);
        }
        applyAuditDefaults(product);
        enforceStockStatus(product);
    }

    private void enforceStockStatus(Product product) {
        if (product.getStock() == null || product.getStock() <= 0) {
            product.setStock(0);
            product.setStatus(ProductStatus.OFF_SALE);
        }
    }

    private void applyAuditDefaults(Product product) {
        if (product.getType() != ProductType.PET_LIVE) {
            product.setAuditStatus(ProductAuditStatus.NOT_REQUIRED);
            product.setAuditRemark("");
            product.setAuditedBy(null);
            product.setAuditedAt(null);
            return;
        }
        if (product.getAuditStatus() == ProductAuditStatus.APPROVED) {
            return;
        }
        if (product.getAuditStatus() == null || product.getAuditStatus() == ProductAuditStatus.NOT_REQUIRED) {
            product.setAuditStatus(ProductAuditStatus.PENDING);
        }
        if (product.getAuditStatus() == ProductAuditStatus.PENDING) {
            product.setStatus(ProductStatus.DRAFT);
        }
        if (product.getAuditStatus() == ProductAuditStatus.REJECTED) {
            product.setStatus(ProductStatus.OFF_SALE);
        }
    }

    private Long defaultManagedStoreId(UserAccount actor) {
        List<Long> storeIds = storeService.managedStoreIds(actor);
        if (storeIds.isEmpty()) {
            throw new BusinessException("200400", "Merchant has no store yet", HttpStatus.BAD_REQUEST);
        }
        return storeIds.get(0);
    }

    private void requireCanManageStore(UserAccount actor, Long storeId) {
        if (actor.getRole() == UserRole.ADMIN) {
            return;
        }
        if (actor.getRole() == UserRole.MERCHANT && storeService.canManageStore(actor, storeId)) {
            return;
        }
        throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
