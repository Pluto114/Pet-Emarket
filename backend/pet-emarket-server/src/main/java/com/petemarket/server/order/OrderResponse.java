package com.petemarket.server.order;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record OrderResponse(
        Long id,
        String orderNo,
        Long userId,
        Integer status,
        String statusName,
        BigDecimal totalAmount,
        BigDecimal discountAmount,
        BigDecimal payAmount,
        String receiver,
        String phone,
        String addressDetail,
        Integer reviewRating,
        String reviewContent,
        String refundReason,
        String refundAuditStatus,
        Integer refundRollbackStatus,
        String auditRemark,
        Boolean inventoryRestored,
        Instant createdAt,
        Instant updatedAt,
        List<OrderItemResponse> items,
        List<OrderStatusLogResponse> statusLogs
) {
    public static OrderResponse from(PetOrder order) {
        return new OrderResponse(
                order.getId(),
                order.getOrderNo(),
                order.getUserId(),
                order.getStatus(),
                order.getStatusName(),
                order.getTotalAmount(),
                order.getDiscountAmount(),
                order.getPayAmount(),
                order.getReceiver(),
                order.getPhone(),
                order.getAddressDetail(),
                order.getReviewRating(),
                order.getReviewContent(),
                order.getRefundReason(),
                order.getRefundAuditStatus(),
                order.getRefundRollbackStatus(),
                order.getAuditRemark(),
                order.getInventoryRestored(),
                order.getCreatedAt(),
                order.getUpdatedAt(),
                order.getItems().stream().map(OrderItemResponse::from).toList(),
                order.getStatusLogs().stream().map(OrderStatusLogResponse::from).toList()
        );
    }
}
