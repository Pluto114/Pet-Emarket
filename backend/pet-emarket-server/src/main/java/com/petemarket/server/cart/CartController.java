package com.petemarket.server.cart;

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
@RequestMapping("/api/v1/cart/items")
public class CartController {
    private final CartService cartService;

    public CartController(CartService cartService) {
        this.cartService = cartService;
    }

    @GetMapping
    public ApiResponse<PageData<CartItemResponse>> list(@AuthenticationPrincipal UserAccount currentUser) {
        return ApiResponse.ok(PageData.of(cartService.list(currentUser.getId())));
    }

    @PostMapping
    public ApiResponse<CartItemResponse> add(@AuthenticationPrincipal UserAccount currentUser,
                                             @Valid @RequestBody AddCartItemRequest request) {
        return ApiResponse.ok(cartService.add(currentUser.getId(), request), "cart item added");
    }

    @PutMapping("/{id}")
    public ApiResponse<CartItemResponse> update(@AuthenticationPrincipal UserAccount currentUser,
                                                @PathVariable Long id,
                                                @Valid @RequestBody UpdateCartItemRequest request) {
        return ApiResponse.ok(cartService.update(currentUser.getId(), id, request), "cart item updated");
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@AuthenticationPrincipal UserAccount currentUser, @PathVariable Long id) {
        cartService.delete(currentUser.getId(), id);
        return ApiResponse.ok(null, "cart item deleted");
    }
}
