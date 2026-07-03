package com.petemarket.server.store;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.BusinessException;
import com.petemarket.server.common.PageData;
import com.petemarket.server.product.ProductResponse;
import com.petemarket.server.product.ProductService;
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
@RequestMapping("/api/v1/stores")
public class StoreController {
    private final StoreService storeService;
    private final ProductService productService;

    public StoreController(StoreService storeService, ProductService productService) {
        this.storeService = storeService;
        this.productService = productService;
    }

    @GetMapping
    public ApiResponse<PageData<StoreResponse>> list(@AuthenticationPrincipal UserAccount currentUser,
                                                      @RequestParam(required = false) String keyword,
                                                      @RequestParam(required = false) String city,
                                                      @RequestParam(required = false) String status) {
        return ApiResponse.ok(PageData.of(storeService.listFiltered(isStoreManager(currentUser) ? currentUser : null, keyword, city, status)));
    }

    @GetMapping("/{id}")
    public ApiResponse<StoreResponse> get(@PathVariable Long id) {
        return ApiResponse.ok(storeService.get(id));
    }

    @GetMapping("/{id}/products")
    public ApiResponse<PageData<ProductResponse>> storeProducts(@PathVariable Long id) {
        return ApiResponse.ok(PageData.of(productService.listByStore(id)));
    }

    @GetMapping("/nearby")
    public ApiResponse<PageData<StoreResponse>> nearby(@RequestParam double longitude,
                                                       @RequestParam double latitude,
                                                       @RequestParam(defaultValue = "10") double radiusKm,
                                                       @RequestParam(required = false) String keyword) {
        return ApiResponse.ok(PageData.of(storeService.nearby(longitude, latitude, radiusKm, keyword)));
    }

    @PostMapping
    public ApiResponse<StoreResponse> create(@AuthenticationPrincipal UserAccount currentUser,
                                             @Valid @RequestBody UpsertStoreRequest request) {
        requireStoreManager(currentUser);
        return ApiResponse.ok(storeService.create(request, currentUser), "store created");
    }

    @PutMapping("/{id}")
    public ApiResponse<StoreResponse> update(@AuthenticationPrincipal UserAccount currentUser,
                                             @PathVariable Long id,
                                             @Valid @RequestBody UpsertStoreRequest request) {
        requireStoreManager(currentUser);
        return ApiResponse.ok(storeService.update(id, request, currentUser), "store updated");
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@AuthenticationPrincipal UserAccount currentUser, @PathVariable Long id) {
        requireStoreManager(currentUser);
        storeService.delete(id, currentUser);
        return ApiResponse.ok(null, "store deleted");
    }

    private void requireStoreManager(UserAccount user) {
        if (!isStoreManager(user)) {
            throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
        }
    }

    private boolean isStoreManager(UserAccount user) {
        return user != null && (user.getRole() == UserRole.ADMIN || user.getRole() == UserRole.MERCHANT);
    }
}
