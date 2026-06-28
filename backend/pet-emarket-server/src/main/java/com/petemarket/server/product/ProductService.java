package com.petemarket.server.product;

import com.petemarket.server.common.BusinessException;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProductService {
    private final ProductRepository productRepository;

    public ProductService(ProductRepository productRepository) {
        this.productRepository = productRepository;
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
        return products.stream()
                .filter(product -> type == null || product.getType() == type)
                .filter(product -> status == null || product.getStatus() == status)
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

    @Transactional
    public ProductResponse create(UpsertProductRequest request) {
        Product product = new Product();
        apply(product, request);
        productRepository.save(product);
        return ProductResponse.from(product);
    }

    @Transactional
    public ProductResponse update(Long id, UpsertProductRequest request) {
        Product product = find(id);
        apply(product, request);
        return ProductResponse.from(product);
    }

    @Transactional
    public void delete(Long id) {
        productRepository.delete(find(id));
    }

    @Transactional
    public ProductResponse auditLivePet(Long id, boolean approved, String remark, Long auditorId) {
        Product product = find(id);
        if (product.getType() != ProductType.PET_LIVE) {
            throw new BusinessException("200400", "Only live pet products require audit");
        }
        product.setAuditStatus(approved ? ProductAuditStatus.APPROVED : ProductAuditStatus.REJECTED);
        product.setStatus(approved ? ProductStatus.ON_SALE : ProductStatus.OFF_SALE);
        product.setAuditRemark(defaultText(remark, approved ? "Audit approved" : "Audit rejected"));
        product.setAuditedBy(auditorId);
        product.setAuditedAt(Instant.now());
        return ProductResponse.from(product);
    }

    public Product find(Long id) {
        return productRepository.findById(id)
                .orElseThrow(() -> new BusinessException("200404", "Product not found", HttpStatus.NOT_FOUND));
    }

    private void apply(Product product, UpsertProductRequest request) {
        product.setStoreId(request.storeId() == null ? 1L : request.storeId());
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

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
