package com.petemarket.server.product;

import com.petemarket.server.common.BusinessException;
import java.math.BigDecimal;
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
    public List<ProductResponse> list(String keyword) {
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
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
