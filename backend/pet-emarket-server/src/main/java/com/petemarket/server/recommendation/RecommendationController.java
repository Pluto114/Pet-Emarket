package com.petemarket.server.recommendation;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.PageData;
import com.petemarket.server.user.UserAccount;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RecommendationController {
    private final RecommendationService recommendationService;

    public RecommendationController(RecommendationService recommendationService) {
        this.recommendationService = recommendationService;
    }

    @GetMapping({"/api/v1/recommendations", "/api/v1/recommend"})
    public ApiResponse<PageData<RecommendationResponse>> recommend(
            @AuthenticationPrincipal UserAccount currentUser,
            @RequestParam(required = false) String scene,
            @RequestParam(required = false) Long lastProductId,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false) Integer limit,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Double longitude,
            @RequestParam(required = false) Double latitude) {
        return ApiResponse.ok(PageData.of(recommendationService.recommend(
                currentUser,
                scene,
                lastProductId,
                page,
                limit,
                category,
                longitude,
                latitude
        )));
    }
}