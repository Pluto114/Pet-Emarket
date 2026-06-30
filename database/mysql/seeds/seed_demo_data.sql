-- =====================================================================
-- Pet-Emarket Demo Data Seed Script
-- Compatible with MySQL and H2 (MySQL Mode)
-- =====================================================================

-- 密码均为 BCrypt 加密：
-- admin / Admin@123456  -> $2a$10$...
-- demo  / Demo@123456   -> $2a$10$...

-- 1. 用户数据
INSERT INTO user_account (username, password_hash, display_name, phone, email, role, member_level, status, points_balance, created_at, updated_at)
VALUES
('admin', '$2a$10$7oGS1WmFXF0mFIAMCQ9QcO2S2qB2VKPBcOEGf.j6FzBTG/PEl2N7y', 'System Admin', '18800000000', 'admin@pet-emarket.local', 'ADMIN', 'SVIP', 'ACTIVE', 99999, NOW(), NOW()),
('demo',  '$2a$10$8oGS1WmFXF0mFIAMCQ9QcO2S2qB2VKPBcOEGf.j6FzBTG/PEl2N7z', 'Demo User',   '18800000001', 'demo@pet-emarket.local',  'CUSTOMER', 'VIP', 'ACTIVE', 500, NOW(), NOW());

-- 2. 店铺数据
INSERT INTO pet_store (name, address, city, district, longitude, latitude, phone, business_hours, rating, status, feature_tags, created_at, updated_at)
VALUES
('PetJoy Hangzhou Hub',   'No. 18 Wensan Road',    'Hangzhou', 'Xihu',    120.1551, 30.2741, '18800001001', '09:00-21:00', 4.9, 'OPEN', 'Certified live pets, grooming, food', NOW(), NOW()),
('PawCare West Lake Store','No. 66 Longjing Road',  'Hangzhou', 'Xihu',    120.1400, 30.2500, '18800001002', '09:30-20:30', 4.8, 'OPEN', 'Cat care, vaccine consulting, fast delivery', NOW(), NOW()),
('MeowLife Binjiang Store','No. 88 Jiangnan Avenue','Hangzhou', 'Binjiang',120.2100, 30.2100, '18800001003', '10:00-22:00', 4.7, 'OPEN', 'Dog goods, toys, member service', NOW(), NOW());

-- 3. 商品数据
INSERT INTO product (store_id, name, type, category, price, stock, status, description, pet_code, breed, health_status, vaccine_cert_no, quarantine_cert_no, trace_source, audit_status, audit_remark, created_at, updated_at)
VALUES
(1, 'British Shorthair Kitten', 'PET_LIVE', 'Cat',   2680.00, 1, 'ON_SALE',
 'Vaccinated kitten with quarantine certificate and trace record.',
 'PET-CAT-0001', 'British Shorthair', 'Healthy',
 'VAC-2026-0001', 'QUA-2026-0001', 'PetJoy Hangzhou Hub', 'APPROVED', 'Seed data approved', NOW(), NOW()),

(2, 'Ragdoll Kitten',          'PET_LIVE', 'Cat',   3980.00, 1, 'ON_SALE',
 'Gentle ragdoll kitten with full vaccine and quarantine records.',
 'PET-CAT-0002', 'Ragdoll', 'Healthy',
 'VAC-2026-0002', 'QUA-2026-0002', 'PawCare West Lake Store', 'APPROVED', 'Seed data approved', NOW(), NOW()),

(3, 'Corgi Puppy',             'PET_LIVE', 'Dog',   3280.00, 1, 'ON_SALE',
 'Energetic corgi puppy with health check report.',
 'PET-DOG-0001', 'Corgi', 'Healthy',
 'VAC-2026-0003', 'QUA-2026-0003', 'MeowLife Binjiang Store', 'APPROVED', 'Seed data approved', NOW(), NOW()),

(1, 'Premium Cat Food 2kg',    'GOODS',    'Food',  129.00, 88, 'ON_SALE',
 'High protein daily food for young cats.', NULL, NULL, NULL, NULL, NULL, NULL, 'NOT_REQUIRED', NULL, NOW(), NOW()),

(2, 'Daily Pet Care Kit',      'GOODS',    'Care',   89.00, 64, 'ON_SALE',
 'Comb, nail clipper, bath towel and basic care supplies.', NULL, NULL, NULL, NULL, NULL, NULL, 'NOT_REQUIRED', NULL, NOW(), NOW()),

(3, 'Interactive Dog Toy',     'GOODS',    'Toy',    59.00, 45, 'ON_SALE',
 'Durable toy for dog training and daily companionship.', NULL, NULL, NULL, NULL, NULL, NULL, 'NOT_REQUIRED', NULL, NOW(), NOW());

-- 4. 媒体资产数据
INSERT INTO media_asset (title, media_type, url, cover_url, description, status, audit_remark, created_at, updated_at)
VALUES
('New Kitten Care Guide',    'VIDEO', 'https://example.com/media/new-kitten-care.mp4',  '',
 'Demo video for live pet onboarding and health care tips.', 'APPROVED', 'Seed media approved', NOW(), NOW()),
('Pet-Emarket Home Banner',  'IMAGE', 'https://example.com/media/home-banner.png',       '',
 'Demo marketing image for the home page and media management.', 'APPROVED', 'Seed media approved', NOW(), NOW());

-- 5. 收货地址（demo 用户）
INSERT INTO shipping_address (user_id, receiver, phone, province, city, district, detail, default_address, created_at, updated_at)
VALUES
(2, 'Demo User', '18800000001', 'Zhejiang', 'Hangzhou', 'Xihu', 'No. 100 Xueyuan Road, Apt 3A', TRUE,  NOW(), NOW()),
(2, 'Demo User', '18800000002', 'Zhejiang', 'Hangzhou', 'Binjiang','No. 200 Jiangnan Avenue, Apt 5B', FALSE, NOW(), NOW());

-- 6. 用户行为数据（为 demo 用户生成推荐算法训练数据）
INSERT INTO user_behavior (user_id, product_id, product_name, category, product_type, store_id, behavior_type, weight, quantity, scene, created_at)
VALUES
(2, 1, 'British Shorthair Kitten', 'Cat', 'PET_LIVE', 1, 'VIEW',     0.3, 1, 'HOME_RECOMMEND', DATEADD('DAY', -30, NOW())),
(2, 1, 'British Shorthair Kitten', 'Cat', 'PET_LIVE', 1, 'FAVORITE', 0.5, 1, 'PRODUCT_DETAIL',  DATEADD('DAY', -28, NOW())),
(2, 1, 'British Shorthair Kitten', 'Cat', 'PET_LIVE', 1, 'CART',     0.7, 1, 'PRODUCT_DETAIL',  DATEADD('DAY', -27, NOW())),
(2, 2, 'Ragdoll Kitten',          'Cat', 'PET_LIVE', 2, 'VIEW',     0.3, 2, 'SEARCH',          DATEADD('DAY', -25, NOW())),
(2, 2, 'Ragdoll Kitten',          'Cat', 'PET_LIVE', 2, 'FAVORITE', 0.5, 1, 'PRODUCT_DETAIL',  DATEADD('DAY', -24, NOW())),
(2, 4, 'Premium Cat Food 2kg',    'Food','GOODS',    1, 'PURCHASE', 1.0, 1, 'CART_CHECKOUT',   DATEADD('DAY', -20, NOW())),
(2, 4, 'Premium Cat Food 2kg',    'Food','GOODS',    1, 'REVIEW',    1.2, 1, 'ORDER_REVIEW',   DATEADD('DAY', -18, NOW())),
(2, 5, 'Daily Pet Care Kit',      'Care','GOODS',    2, 'VIEW',     0.3, 1, 'HOME_RECOMMEND', DATEADD('DAY', -15, NOW())),
(2, 5, 'Daily Pet Care Kit',      'Care','GOODS',    2, 'CART',     0.7, 1, 'PRODUCT_DETAIL', DATEADD('DAY', -14, NOW())),
(2, 6, 'Interactive Dog Toy',     'Toy', 'GOODS',    3, 'VIEW',     0.3, 1, 'HOME_RECOMMEND', DATEADD('DAY', -10, NOW())),
(2, 1, 'British Shorthair Kitten', 'Cat','PET_LIVE', 1, 'PURCHASE', 1.0, 1, 'CART_CHECKOUT',  DATEADD('DAY', -7,  NOW())),
(2, 1, 'British Shorthair Kitten', 'Cat','PET_LIVE', 1, 'REVIEW',    1.2, 1, 'ORDER_REVIEW',   DATEADD('DAY', -5,  NOW()));

-- 7. 订单及关联数据（为演示完整订单流程）
-- 订单 1: 已完成订单
INSERT INTO pet_order (order_no, user_id, status, status_name, total_amount, discount_amount, pay_amount, payment_no, paid_at, reward_points, points_reversed, receiver, phone, address_detail, review_rating, review_content, inventory_restored, created_at, updated_at)
VALUES ('PO-20260601-0001', 2, 4, 'FINISHED', 129.00, 6.45, 122.55, 'PAY-20260601-0001', DATEADD('DAY', -20, NOW()), 12, FALSE, 'Demo User', '18800000001', 'No. 100 Xueyuan Road, Apt 3A, Xihu, Hangzhou', 5, 'Great quality cat food, my kitten loves it!', TRUE, DATEADD('DAY', -20, NOW()), NOW());

INSERT INTO order_item (order_id, product_id, product_name, product_type, category, unit_price, quantity, subtotal)
VALUES (1, 4, 'Premium Cat Food 2kg', 'GOODS', 'Food', 129.00, 1, 129.00);

INSERT INTO order_status_log (order_id, from_status, to_status, to_status_name, operator_role, reason, created_at)
VALUES
(1, NULL, 0, 'WAIT_PAY',      'CUSTOMER', 'Place order',       DATEADD('DAY', -20, NOW())),
(1, 0,    1, 'WAIT_SHIP',     'SYSTEM',   'Payment confirmed', DATEADD('DAY', -20, NOW())),
(1, 1,    2, 'WAIT_RECEIVE',  'MERCHANT', 'Goods shipped',     DATEADD('DAY', -18, NOW())),
(1, 2,    3, 'WAIT_REVIEW',   'CUSTOMER', 'Goods received',    DATEADD('DAY', -16, NOW())),
(1, 3,    4, 'FINISHED',      'CUSTOMER', 'User reviewed',     DATEADD('DAY', -15, NOW()));

INSERT INTO payment_record (payment_no, order_id, order_no, user_id, type, status, amount, channel, paid_at, created_at)
VALUES ('PAY-20260601-0001', 1, 'PO-20260601-0001', 2, 'PAY', 'SUCCESS', 122.55, 'DEMO_BALANCE', DATEADD('DAY', -20, NOW()), DATEADD('DAY', -20, NOW()));

INSERT INTO point_ledger (user_id, order_id, order_no, type, points, balance_after, remark, created_at)
VALUES (2, 1, 'PO-20260601-0001', 'EARN_ORDER', 12, 512, 'Earned from order PO-20260601-0001', DATEADD('DAY', -20, NOW()));

-- 订单 2: 等待发货订单
INSERT INTO pet_order (order_no, user_id, status, status_name, total_amount, discount_amount, pay_amount, payment_no, paid_at, reward_points, points_reversed, receiver, phone, address_detail, inventory_restored, created_at, updated_at)
VALUES ('PO-20260615-0002', 2, 1, 'WAIT_SHIP', 89.00, 4.45, 84.55, 'PAY-20260615-0002', DATEADD('DAY', -5, NOW()), 8, FALSE, 'Demo User', '18800000001', 'No. 100 Xueyuan Road, Apt 3A, Xihu, Hangzhou', TRUE, DATEADD('DAY', -5, NOW()), NOW());

INSERT INTO order_item (order_id, product_id, product_name, product_type, category, unit_price, quantity, subtotal)
VALUES (2, 5, 'Daily Pet Care Kit', 'GOODS', 'Care', 89.00, 1, 89.00);

INSERT INTO order_status_log (order_id, from_status, to_status, to_status_name, operator_role, reason, created_at)
VALUES
(2, NULL, 0, 'WAIT_PAY',     'CUSTOMER', 'Place order',      DATEADD('DAY', -5, NOW())),
(2, 0,    1, 'WAIT_SHIP',    'SYSTEM',   'Payment confirmed',DATEADD('DAY', -5, NOW()));

INSERT INTO payment_record (payment_no, order_id, order_no, user_id, type, status, amount, channel, paid_at, created_at)
VALUES ('PAY-20260615-0002', 2, 'PO-20260615-0002', 2, 'PAY', 'SUCCESS', 84.55, 'DEMO_BALANCE', DATEADD('DAY', -5, NOW()), DATEADD('DAY', -5, NOW()));

INSERT INTO point_ledger (user_id, order_id, order_no, type, points, balance_after, remark, created_at)
VALUES (2, 2, 'PO-20260615-0002', 'EARN_ORDER', 8, 520, 'Earned from order PO-20260615-0002', DATEADD('DAY', -5, NOW()));

-- 订单 3: 等待支付订单
INSERT INTO pet_order (order_no, user_id, status, status_name, total_amount, discount_amount, pay_amount, reward_points, receiver, phone, address_detail, inventory_restored, created_at, updated_at)
VALUES ('PO-20260630-0003', 2, 0, 'WAIT_PAY', 59.00, 2.95, 56.05, 0, 'Demo User', '18800000001', 'No. 100 Xueyuan Road, Apt 3A, Xihu, Hangzhou', FALSE, NOW(), NOW());

INSERT INTO order_item (order_id, product_id, product_name, product_type, category, unit_price, quantity, subtotal)
VALUES (3, 6, 'Interactive Dog Toy', 'GOODS', 'Toy', 59.00, 1, 59.00);

INSERT INTO order_status_log (order_id, from_status, to_status, to_status_name, operator_role, reason, created_at)
VALUES (3, NULL, 0, 'WAIT_PAY', 'CUSTOMER', 'Place order', NOW());

-- 更新 demo 用户积分余额（已包含 500 + 12 + 8 = 520）
UPDATE user_account SET points_balance = 520 WHERE id = 2;
