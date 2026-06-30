// =====================================================================
// Pet-Emarket MongoDB — Store Geo-location Indexes
// =====================================================================

// 切换到 pet_emarket 数据库
use pet_emarket;

// ---------- 1. 店铺地理位置索引（2dsphere） ----------
// 用于 LBS 附近店铺搜索：db.stores.find({ location: { $nearSphere: { $geometry: { type: "Point", coordinates: [lng, lat] }, $maxDistance: 5000 } } })
db.stores.createIndex(
  { location: "2dsphere" },
  { name: "idx_store_geo_2dsphere" }
);

// ---------- 2. 店铺状态索引 ----------
// 用于按状态筛选：db.stores.find({ status: "OPEN" })
db.stores.createIndex(
  { status: 1 },
  { name: "idx_store_status" }
);

// ---------- 3. 城市索引 ----------
// 用于按城市分组查询：db.stores.find({ city: "Hangzhou" })
db.stores.createIndex(
  { city: 1 },
  { name: "idx_store_city" }
);

// ---------- 4. 复合索引（城市 + 状态） ----------
db.stores.createIndex(
  { city: 1, status: 1 },
  { name: "idx_store_city_status" }
);

print("✓ Store geo-indexes created successfully.");
