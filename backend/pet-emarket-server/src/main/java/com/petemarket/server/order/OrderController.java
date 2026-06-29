package com.petemarket.server.order;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.PageData;
import com.petemarket.server.user.UserAccount;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {
    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @GetMapping
    public ApiResponse<PageData<OrderResponse>> list(@AuthenticationPrincipal UserAccount currentUser) {
        return ApiResponse.ok(PageData.of(orderService.list(currentUser)));
    }

    @PostMapping
    public ApiResponse<OrderResponse> create(@AuthenticationPrincipal UserAccount currentUser,
                                             @RequestBody(required = false) CreateOrderRequest request) {
        CreateOrderRequest safeRequest = request == null ? new CreateOrderRequest(null, null, null) : request;
        return ApiResponse.ok(orderService.create(currentUser, safeRequest), "order created");
    }

    @GetMapping("/{id}")
    public ApiResponse<OrderResponse> get(@AuthenticationPrincipal UserAccount currentUser, @PathVariable Long id) {
        return ApiResponse.ok(orderService.get(currentUser, id));
    }

    @PutMapping("/{id}/{action}")
    public ApiResponse<OrderResponse> operate(@AuthenticationPrincipal UserAccount currentUser,
                                              @PathVariable Long id,
                                              @PathVariable String action,
                                              @RequestBody(required = false) OrderActionRequest request) {
        OrderActionRequest safeRequest = request == null ? new OrderActionRequest(null, null, null, null, null, null) : request;
        return ApiResponse.ok(orderService.operate(currentUser, id, action, safeRequest), "order updated");
    }
}
