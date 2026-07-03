CREATE TABLE user_account (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    password_hash VARCHAR(120) NOT NULL,
    display_name VARCHAR(80) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(128),
    role VARCHAR(20) NOT NULL DEFAULT 'CUSTOMER',
    member_level VARCHAR(20) NOT NULL DEFAULT 'NORMAL',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    points_balance INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

CREATE TABLE pet_store (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(64) NOT NULL,
    district VARCHAR(64) NOT NULL,
    longitude DOUBLE NOT NULL,
    latitude DOUBLE NOT NULL,
    phone VARCHAR(32),
    business_hours VARCHAR(64),
    rating DOUBLE NOT NULL DEFAULT 5.0,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    feature_tags VARCHAR(500),
    amap_poi_id VARCHAR(64),
    owner_user_id BIGINT,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

CREATE TABLE product (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    store_id BIGINT NOT NULL DEFAULT 1,
    name VARCHAR(128) NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'GOODS',
    category VARCHAR(64) NOT NULL DEFAULT 'General',
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    cover_url VARCHAR(255),
    description VARCHAR(2000),
    pet_code VARCHAR(64),
    breed VARCHAR(64),
    health_status VARCHAR(64),
    vaccine_cert_no VARCHAR(128),
    quarantine_cert_no VARCHAR(128),
    trace_source VARCHAR(255),
    audit_status VARCHAR(20) NOT NULL DEFAULT 'NOT_REQUIRED',
    audit_remark VARCHAR(500),
    audited_by BIGINT,
    audited_at TIMESTAMP NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT ck_product_price_non_negative CHECK (price >= 0),
    CONSTRAINT ck_product_stock_non_negative CHECK (stock >= 0)
);

CREATE TABLE product_audit_request (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    remark VARCHAR(500),
    created_by BIGINT,
    reviewed_by BIGINT,
    reviewed_at TIMESTAMP NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

CREATE TABLE cart_item (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

CREATE TABLE pet_order (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(64) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL,
    status INT NOT NULL DEFAULT 0,
    status_name VARCHAR(40) NOT NULL DEFAULT 'WAIT_PAY',
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    pay_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    payment_no VARCHAR(64),
    paid_at TIMESTAMP NULL,
    reward_points INT NOT NULL DEFAULT 0,
    points_reversed BOOLEAN NOT NULL DEFAULT FALSE,
    receiver VARCHAR(80),
    phone VARCHAR(20),
    address_detail VARCHAR(255),
    review_rating INT,
    review_content VARCHAR(1000),
    refund_reason VARCHAR(500),
    refund_audit_status VARCHAR(40),
    refund_rollback_status INT,
    audit_remark VARCHAR(500),
    inventory_restored BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    CONSTRAINT ck_order_amount_non_negative CHECK (total_amount >= 0 AND pay_amount >= 0 AND discount_amount >= 0)
);

CREATE TABLE order_item (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT,
    store_id BIGINT,
    product_name VARCHAR(128),
    product_type VARCHAR(20),
    category VARCHAR(64),
    unit_price DECIMAL(10,2),
    quantity INT,
    subtotal DECIMAL(10,2),
    live_pet_snapshot VARCHAR(1000),
    CONSTRAINT fk_order_item_order FOREIGN KEY (order_id) REFERENCES pet_order(id) ON DELETE CASCADE
);

CREATE TABLE order_status_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    from_status INT,
    to_status INT,
    to_status_name VARCHAR(40),
    operator_role VARCHAR(40),
    reason VARCHAR(500),
    created_at TIMESTAMP NULL,
    CONSTRAINT fk_order_status_log_order FOREIGN KEY (order_id) REFERENCES pet_order(id) ON DELETE CASCADE
);

CREATE TABLE payment_record (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_no VARCHAR(64) NOT NULL UNIQUE,
    order_id BIGINT NOT NULL,
    order_no VARCHAR(64) NOT NULL,
    user_id BIGINT NOT NULL,
    type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',
    amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    channel VARCHAR(32) NOT NULL DEFAULT 'DEMO_BALANCE',
    remark VARCHAR(500),
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP NULL
);

CREATE TABLE point_ledger (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL,
    order_no VARCHAR(64) NOT NULL,
    type VARCHAR(32) NOT NULL,
    points INT NOT NULL,
    balance_after INT NOT NULL,
    remark VARCHAR(500),
    created_at TIMESTAMP NULL,
    CONSTRAINT ck_point_ledger_balance_non_negative CHECK (balance_after >= 0)
);

CREATE TABLE user_behavior (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_name VARCHAR(128) NOT NULL,
    category VARCHAR(64) NOT NULL,
    product_type VARCHAR(32) NOT NULL,
    store_id BIGINT,
    behavior_type VARCHAR(20) NOT NULL,
    weight DOUBLE NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    scene VARCHAR(40),
    created_at TIMESTAMP NULL
);

CREATE TABLE shipping_address (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    receiver VARCHAR(80) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    province VARCHAR(64),
    city VARCHAR(64),
    district VARCHAR(64),
    detail VARCHAR(255) NOT NULL,
    default_address BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

CREATE TABLE media_asset (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(128) NOT NULL,
    media_type VARCHAR(20) NOT NULL DEFAULT 'IMAGE',
    url VARCHAR(500) NOT NULL,
    cover_url VARCHAR(500),
    product_id BIGINT,
    description VARCHAR(1000),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    audit_remark VARCHAR(500),
    created_by BIGINT,
    audited_by BIGINT,
    audited_at TIMESTAMP NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

CREATE TABLE merchant_application (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    store_name VARCHAR(128) NOT NULL,
    city VARCHAR(64) NOT NULL,
    district VARCHAR(64) NOT NULL,
    address VARCHAR(255) NOT NULL,
    longitude DOUBLE NOT NULL,
    latitude DOUBLE NOT NULL,
    contact_name VARCHAR(80),
    contact_phone VARCHAR(32),
    business_license_no VARCHAR(80),
    reason VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    audit_remark VARCHAR(500),
    audited_by BIGINT,
    audited_at TIMESTAMP NULL,
    store_id BIGINT,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);

CREATE INDEX idx_user_account_username ON user_account(username);
CREATE INDEX idx_user_account_role ON user_account(role);
CREATE INDEX idx_pet_store_owner ON pet_store(owner_user_id);
CREATE INDEX idx_pet_store_amap_poi ON pet_store(amap_poi_id);
CREATE INDEX idx_product_store_id ON product(store_id);
CREATE INDEX idx_product_category ON product(category);
CREATE INDEX idx_product_type ON product(type);
CREATE INDEX idx_product_status ON product(status);
CREATE INDEX idx_cart_item_user_id ON cart_item(user_id);
CREATE INDEX idx_cart_item_user_product ON cart_item(user_id, product_id);
CREATE INDEX idx_pet_order_user_id ON pet_order(user_id);
CREATE INDEX idx_pet_order_status ON pet_order(status);
CREATE INDEX idx_pet_order_order_no ON pet_order(order_no);
CREATE INDEX idx_order_item_order_id ON order_item(order_id);
CREATE INDEX idx_order_item_store ON order_item(store_id);
CREATE INDEX idx_order_status_log_order_id ON order_status_log(order_id);
CREATE INDEX idx_payment_record_order_id ON payment_record(order_id);
CREATE INDEX idx_payment_record_payment_no ON payment_record(payment_no);
CREATE INDEX idx_point_ledger_user_id ON point_ledger(user_id);
CREATE INDEX idx_user_behavior_user_id ON user_behavior(user_id);
CREATE INDEX idx_user_behavior_product_id ON user_behavior(product_id);
CREATE INDEX idx_user_behavior_type ON user_behavior(behavior_type);
CREATE INDEX idx_shipping_address_user_id ON shipping_address(user_id);
CREATE INDEX idx_media_asset_product_id ON media_asset(product_id);
CREATE INDEX idx_media_asset_status ON media_asset(status);
CREATE INDEX idx_merchant_application_user ON merchant_application(user_id);
CREATE INDEX idx_merchant_application_status ON merchant_application(status);
