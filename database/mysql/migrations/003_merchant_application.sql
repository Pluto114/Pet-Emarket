-- =====================================================================
-- Pet-Emarket Database Schema
-- Migration 003: Merchant Applications and Store Ownership
-- =====================================================================

ALTER TABLE pet_store ADD COLUMN owner_user_id BIGINT;
ALTER TABLE order_item ADD COLUMN store_id BIGINT;

CREATE TABLE IF NOT EXISTS merchant_application (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id              BIGINT       NOT NULL,
    store_name           VARCHAR(128) NOT NULL,
    city                 VARCHAR(64)  NOT NULL,
    district             VARCHAR(64)  NOT NULL,
    address              VARCHAR(255) NOT NULL,
    longitude            DOUBLE       NOT NULL,
    latitude             DOUBLE       NOT NULL,
    contact_name         VARCHAR(80),
    contact_phone        VARCHAR(32),
    business_license_no  VARCHAR(80),
    reason               VARCHAR(500),
    status               VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    audit_remark         VARCHAR(500),
    audited_by           BIGINT,
    audited_at           TIMESTAMP,
    store_id             BIGINT,
    created_at           TIMESTAMP,
    updated_at           TIMESTAMP
);

CREATE INDEX idx_pet_store_owner ON pet_store(owner_user_id);
CREATE INDEX idx_order_item_store ON order_item(store_id);
CREATE INDEX idx_merchant_application_user ON merchant_application(user_id);
CREATE INDEX idx_merchant_application_status ON merchant_application(status);
