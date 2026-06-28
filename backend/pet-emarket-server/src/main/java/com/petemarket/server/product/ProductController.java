package com.petemarket.server.product;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.BusinessException;
import com.petemarket.server.common.PageData;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {
    private final ProductService productService;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping
    public ApiResponse<PageData<ProductResponse>> list(@RequestParam(required = false) String keyword,
                                                       @RequestParam(required = false) ProductType type,
                                                       @RequestParam(required = false) ProductStatus status) {
        return ApiResponse.ok(PageData.of(productService.list(keyword, type, status)));
    }

    @GetMapping("/live-pet-audits")
    public ApiResponse<PageData<ProductResponse>> listLivePetAudits(@AuthenticationPrincipal UserAccount currentUser,
                                                                    @RequestParam(required = false) ProductAuditStatus auditStatus) {
        requireProductManager(currentUser);
        return ApiResponse.ok(PageData.of(productService.listLivePetAudits(auditStatus)));
    }

    @GetMapping("/{id}")
    public ApiResponse<ProductResponse> get(@PathVariable Long id) {
        return ApiResponse.ok(productService.get(id));
    }

    @PostMapping
    public ApiResponse<ProductResponse> create(@AuthenticationPrincipal UserAccount currentUser,
                                               @Valid @RequestBody UpsertProductRequest request) {
        requireProductManager(currentUser);
        return ApiResponse.ok(productService.create(request), "product created");
    }

    @PutMapping("/{id}")
    public ApiResponse<ProductResponse> update(@AuthenticationPrincipal UserAccount currentUser,
                                               @PathVariable Long id,
                                               @Valid @RequestBody UpsertProductRequest request) {
        requireProductManager(currentUser);
        return ApiResponse.ok(productService.update(id, request), "product updated");
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@AuthenticationPrincipal UserAccount currentUser, @PathVariable Long id) {
        requireProductManager(currentUser);
        productService.delete(id);
        return ApiResponse.ok(null, "product deleted");
    }

    @PutMapping("/{id}/audit")
    public ApiResponse<ProductResponse> audit(@AuthenticationPrincipal UserAccount currentUser,
                                              @PathVariable Long id,
                                              @Valid @RequestBody ProductAuditRequest request) {
        requireProductManager(currentUser);
        return ApiResponse.ok(productService.auditLivePet(id, request.approved(), request.remark(), currentUser.getId()), "product audited");
    }

    private void requireProductManager(UserAccount user) {
        if (user == null || (user.getRole() != UserRole.ADMIN && user.getRole() != UserRole.MERCHANT)) {
            throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
        }
    }
}
