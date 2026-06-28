package com.petemarket.server.recommendation;

import com.petemarket.server.product.ProductResponse;
import java.util.List;

public record RecommendationResponse(
        ProductResponse product,
        double score,
        String strategy,
        List<String> reasons,
        double itemCfScore,
        double markovScore,
        double hotScore,
        double distanceScore,
        double stockScore
) {
}
