package com.petemarket.server.merchant;

public record MerchantAuditRequest(
        Boolean approved,
        String remark
) {
}
