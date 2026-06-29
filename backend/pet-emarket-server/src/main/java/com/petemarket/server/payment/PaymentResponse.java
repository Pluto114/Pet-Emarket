package com.petemarket.server.payment;

import java.math.BigDecimal;
import java.time.Instant;

public record PaymentResponse(
        Long id,
        String paymentNo,
        Long orderId,
        String orderNo,
        Long userId,
        PaymentType type,
        PaymentStatus status,
        BigDecimal amount,
        String channel,
        String remark,
        Instant paidAt,
        Instant createdAt
) {
    public static PaymentResponse from(PaymentRecord record) {
        return new PaymentResponse(
                record.getId(),
                record.getPaymentNo(),
                record.getOrderId(),
                record.getOrderNo(),
                record.getUserId(),
                record.getType(),
                record.getStatus(),
                record.getAmount(),
                record.getChannel(),
                record.getRemark(),
                record.getPaidAt(),
                record.getCreatedAt()
        );
    }
}
