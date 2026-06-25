package com.petemarket.server.order;

import java.time.Instant;

public record OrderStatusLogResponse(
        Long id,
        Integer fromStatus,
        Integer toStatus,
        String toStatusName,
        String operatorRole,
        String reason,
        Instant createdAt
) {
    public static OrderStatusLogResponse from(OrderStatusLog log) {
        return new OrderStatusLogResponse(
                log.getId(),
                log.getFromStatus(),
                log.getToStatus(),
                log.getToStatusName(),
                log.getOperatorRole(),
                log.getReason(),
                log.getCreatedAt()
        );
    }
}
