-- =====================================================================
-- Pet-Emarket Database Schema
-- Migration 002: Order State Log & Additional Constraints
-- =====================================================================

-- 订单状态日志表（如果不在 001 中已创建）
-- 已在 001_init_schema.sql 中包含，此脚本仅为兼容旧版本的分步迁移

-- 补充外键约束（H2 兼容写法）
ALTER TABLE order_item ADD CONSTRAINT fk_order_item_order
    FOREIGN KEY (order_id) REFERENCES pet_order(id) ON DELETE CASCADE;

ALTER TABLE order_status_log ADD CONSTRAINT fk_order_status_log_order
    FOREIGN KEY (order_id) REFERENCES pet_order(id) ON DELETE CASCADE;

-- 补充 check 约束
-- 订单金额非负（H2 支持 CHECK）
ALTER TABLE pet_order ADD CONSTRAINT ck_order_amount_non_negative
    CHECK (total_amount >= 0 AND pay_amount >= 0 AND discount_amount >= 0);

-- 积分非负
ALTER TABLE point_ledger ADD CONSTRAINT ck_point_ledger_balance_non_negative
    CHECK (balance_after >= 0);

-- 商品价格非负
ALTER TABLE product ADD CONSTRAINT ck_product_price_non_negative
    CHECK (price >= 0);

-- 商品库存非负
ALTER TABLE product ADD CONSTRAINT ck_product_stock_non_negative
    CHECK (stock >= 0);
