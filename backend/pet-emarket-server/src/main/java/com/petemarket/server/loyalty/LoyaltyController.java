package com.petemarket.server.loyalty;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.PageData;
import com.petemarket.server.user.UserAccount;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/points/ledgers")
public class LoyaltyController {
    private final LoyaltyService loyaltyService;

    public LoyaltyController(LoyaltyService loyaltyService) {
        this.loyaltyService = loyaltyService;
    }

    @GetMapping
    public ApiResponse<PageData<PointLedgerResponse>> list(@AuthenticationPrincipal UserAccount currentUser) {
        return ApiResponse.ok(PageData.of(loyaltyService.list(currentUser)));
    }
}
