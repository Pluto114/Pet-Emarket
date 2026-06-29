package com.petemarket.server.address;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.PageData;
import com.petemarket.server.user.UserAccount;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/addresses")
public class ShippingAddressController {
    private final ShippingAddressService shippingAddressService;

    public ShippingAddressController(ShippingAddressService shippingAddressService) {
        this.shippingAddressService = shippingAddressService;
    }

    @GetMapping
    public ApiResponse<PageData<ShippingAddressResponse>> list(@AuthenticationPrincipal UserAccount currentUser) {
        return ApiResponse.ok(PageData.of(shippingAddressService.list(currentUser.getId())));
    }

    @PostMapping
    public ApiResponse<ShippingAddressResponse> create(@AuthenticationPrincipal UserAccount currentUser,
                                                       @Valid @RequestBody UpsertShippingAddressRequest request) {
        return ApiResponse.ok(shippingAddressService.create(currentUser.getId(), request), "address created");
    }

    @PutMapping("/{id}")
    public ApiResponse<ShippingAddressResponse> update(@AuthenticationPrincipal UserAccount currentUser,
                                                       @PathVariable Long id,
                                                       @Valid @RequestBody UpsertShippingAddressRequest request) {
        return ApiResponse.ok(shippingAddressService.update(currentUser.getId(), id, request), "address updated");
    }

    @PutMapping("/{id}/default")
    public ApiResponse<ShippingAddressResponse> setDefault(@AuthenticationPrincipal UserAccount currentUser,
                                                           @PathVariable Long id) {
        return ApiResponse.ok(shippingAddressService.setDefault(currentUser.getId(), id), "address defaulted");
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@AuthenticationPrincipal UserAccount currentUser, @PathVariable Long id) {
        shippingAddressService.delete(currentUser.getId(), id);
        return ApiResponse.ok(null, "address deleted");
    }
}
