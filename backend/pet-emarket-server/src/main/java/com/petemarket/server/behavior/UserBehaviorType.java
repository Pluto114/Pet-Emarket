package com.petemarket.server.behavior;

public enum UserBehaviorType {
    VIEW(0.3),
    FAVORITE(0.5),
    CART(0.7),
    PURCHASE(1.0),
    REVIEW(1.2);

    private final double weight;

    UserBehaviorType(double weight) {
        this.weight = weight;
    }

    public double weight() {
        return weight;
    }
}
