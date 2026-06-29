package com.petemarket.server.loyalty;

import java.time.Instant;

public record PointLedgerResponse(
        Long id,
        Long userId,
        Long orderId,
        String orderNo,
        PointLedgerType type,
        Integer points,
        Integer balanceAfter,
        String remark,
        Instant createdAt
) {
    public static PointLedgerResponse from(PointLedger ledger) {
        return new PointLedgerResponse(
                ledger.getId(),
                ledger.getUserId(),
                ledger.getOrderId(),
                ledger.getOrderNo(),
                ledger.getType(),
                ledger.getPoints(),
                ledger.getBalanceAfter(),
                ledger.getRemark(),
                ledger.getCreatedAt()
        );
    }
}
