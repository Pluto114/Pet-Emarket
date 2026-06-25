package com.petemarket.server.order;

public record OrderActionRequest(
        String reason,
        Integer rating,
        String content,
        Boolean approved,
        Integer rollbackStatus,
        String auditRemark
) {
}
