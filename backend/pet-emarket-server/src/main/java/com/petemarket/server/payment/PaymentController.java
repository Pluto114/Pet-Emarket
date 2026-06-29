package com.petemarket.server.payment;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.PageData;
import com.petemarket.server.user.UserAccount;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {
    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @GetMapping
    public ApiResponse<PageData<PaymentResponse>> list(@AuthenticationPrincipal UserAccount currentUser) {
        return ApiResponse.ok(PageData.of(paymentService.list(currentUser)));
    }
}
