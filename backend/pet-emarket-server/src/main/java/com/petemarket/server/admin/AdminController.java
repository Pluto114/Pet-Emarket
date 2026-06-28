package com.petemarket.server.admin;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.BusinessException;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRole;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {
    private final AdminDashboardService dashboardService;

    public AdminController(AdminDashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/dashboard")
    public ApiResponse<AdminDashboardResponse> dashboard(@AuthenticationPrincipal UserAccount currentUser) {
        requireAdminOrMerchant(currentUser);
        return ApiResponse.ok(dashboardService.dashboard());
    }

    private void requireAdminOrMerchant(UserAccount user) {
        if (user == null || (user.getRole() != UserRole.ADMIN && user.getRole() != UserRole.MERCHANT)) {
            throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
        }
    }
}
