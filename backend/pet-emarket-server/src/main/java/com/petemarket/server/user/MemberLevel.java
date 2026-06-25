package com.petemarket.server.user;

import java.math.BigDecimal;

public enum MemberLevel {
    NORMAL(BigDecimal.ZERO),
    VIP(new BigDecimal("0.05")),
    SVIP(new BigDecimal("0.10"));

    private final BigDecimal discountRate;

    MemberLevel(BigDecimal discountRate) {
        this.discountRate = discountRate;
    }

    public BigDecimal discountRate() {
        return discountRate;
    }
}
