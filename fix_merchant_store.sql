-- ==========================================
-- 商家店铺数据修复脚本
-- 在 IDEA 的 Database 控制台中执行
-- 步骤：在 IDEA 中右键 pet_emarket 数据库 → Jump to Query Console
--       粘贴全部内容，Ctrl+Enter 执行
-- ==========================================

-- 第一步：查看所有用户（找到你的商家账号的 ID）
SELECT id, username, display_name, role FROM user_account;

-- 第二步：查看已有店铺
SELECT id, name, owner_user_id, city, status FROM pet_store;

-- 第三步：查看入驻申请
SELECT id, user_id, store_name, status FROM merchant_application;
