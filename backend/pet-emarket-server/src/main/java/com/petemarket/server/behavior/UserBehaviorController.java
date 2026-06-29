package com.petemarket.server.behavior;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.PageData;
import com.petemarket.server.user.UserAccount;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/behaviors")
public class UserBehaviorController {
    private final UserBehaviorService userBehaviorService;

    public UserBehaviorController(UserBehaviorService userBehaviorService) {
        this.userBehaviorService = userBehaviorService;
    }

    @GetMapping
    public ApiResponse<PageData<UserBehaviorResponse>> list(@AuthenticationPrincipal UserAccount currentUser) {
        return ApiResponse.ok(PageData.of(userBehaviorService.list(currentUser)));
    }

    @PostMapping
    public ApiResponse<UserBehaviorResponse> track(@AuthenticationPrincipal UserAccount currentUser,
                                                   @Valid @RequestBody TrackBehaviorRequest request) {
        return ApiResponse.ok(userBehaviorService.track(currentUser, request), "behavior tracked");
    }
}
