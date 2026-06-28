package com.petemarket.server.admin;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record AdminDashboardResponse(
        long userCount,
        long activeUserCount,
        long merchantCount,
        long productCount,
        long onSaleProductCount,
        long livePetCount,
        long pendingLivePetAuditCount,
        long storeCount,
        long openStoreCount,
        long orderCount,
        long refundPendingCount,
        BigDecimal totalPayAmount,
        List<OrderStatusCountResponse> orderStatusDistribution,
        List<TopProductResponse> topProducts,
        List<RecentOrderResponse> recentOrders,
        Instant generatedAt
) {
}
