package com.petemarket.server.order;

public enum OrderStatus {
    WAIT_PAY(0, "已下单/待支付"),
    WAIT_SHIP(1, "已支付/待发货"),
    WAIT_RECEIVE(2, "已发货/待收货"),
    WAIT_REVIEW(3, "已收货/待评价"),
    FINISHED(4, "已评价/完成"),
    CANCELED(-1, "取消订单"),
    REFUND_APPLIED(-2, "申请退单"),
    REFUND_SUCCESS(-3, "退单成功"),
    ADMIN_REFUND(-4, "管理员直接退单");

    private final int code;
    private final String label;

    OrderStatus(int code, String label) {
        this.code = code;
        this.label = label;
    }

    public int code() {
        return code;
    }

    public String label() {
        return label;
    }

    public static OrderStatus fromCode(int code) {
        for (OrderStatus status : values()) {
            if (status.code == code) {
                return status;
            }
        }
        throw new IllegalArgumentException("Unknown order status: " + code);
    }
}
