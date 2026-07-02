package com.petemarket.server.merchant;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.BusinessException;
import com.petemarket.server.common.PageData;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/merchant/applications")
public class MerchantApplicationController {
    private final MerchantApplicationService applicationService;

    public MerchantApplicationController(MerchantApplicationService applicationService) {
        this.applicationService = applicationService;
    }

    @PostMapping
    public ApiResponse<MerchantApplicationResponse> submit(@AuthenticationPrincipal UserAccount currentUser,
                                                           @Valid @RequestBody MerchantApplicationRequest request) {
        return ApiResponse.ok(applicationService.submit(currentUser, request), "merchant application submitted");
    }

    @GetMapping("/me")
    public ApiResponse<PageData<MerchantApplicationResponse>> mine(@AuthenticationPrincipal UserAccount currentUser) {
        return ApiResponse.ok(PageData.of(applicationService.listMine(currentUser)));
    }

    @GetMapping
    public ApiResponse<PageData<MerchantApplicationResponse>> list(@AuthenticationPrincipal UserAccount currentUser,
                                                                   @RequestParam(required = false) MerchantApplicationStatus status) {
        requireAdmin(currentUser);
        return ApiResponse.ok(PageData.of(applicationService.listAll(status)));
    }

    @PutMapping("/{id}/audit")
    public ApiResponse<MerchantApplicationResponse> audit(@AuthenticationPrincipal UserAccount currentUser,
                                                          @PathVariable Long id,
                                                          @RequestBody MerchantAuditRequest request) {
        requireAdmin(currentUser);
        return ApiResponse.ok(applicationService.audit(id, request, currentUser), "merchant application audited");
    }

    private void requireAdmin(UserAccount user) {
        if (user == null || user.getRole() != UserRole.ADMIN) {
            throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
        }
    }
}
