-- ProjectKu 数据库结构补齐与索引优化脚本
-- 适用场景：已有数据库升级。新库建议直接执行 init_db.sql。
-- 通过 information_schema 判断索引是否存在，避免重复执行时报 Duplicate key name。

SET NAMES utf8mb4;

-- ----------------------------
-- 1. 补齐项目代码实际使用但旧库可能缺失的表
-- ----------------------------

CREATE TABLE IF NOT EXISTS `notifications` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `type` varchar(32) NOT NULL COMMENT '通知类型',
  `title` varchar(255) NOT NULL COMMENT '标题',
  `content` text COMMENT '内容',
  `related_id` varchar(64) DEFAULT NULL COMMENT '关联业务ID',
  `is_read` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否已读: 0-否, 1-是',
  `read_time` datetime DEFAULT NULL COMMENT '阅读时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_user_create_time` (`user_id`, `create_time`),
  KEY `idx_user_read` (`user_id`, `is_read`),
  KEY `idx_related_id` (`related_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户通知表';

CREATE TABLE IF NOT EXISTS `admin_permissions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `code` varchar(64) NOT NULL COMMENT '权限编码',
  `name` varchar(128) NOT NULL COMMENT '权限名称',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_admin_permission_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后台权限表';

CREATE TABLE IF NOT EXISTS `admin_role_permissions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `role` varchar(32) NOT NULL COMMENT '角色',
  `permission_code` varchar(64) NOT NULL COMMENT '权限编码',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_permission` (`role`, `permission_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后台角色权限表';

CREATE TABLE IF NOT EXISTS `admin_operation_logs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `admin_id` bigint(20) DEFAULT NULL COMMENT '管理员ID',
  `admin_account` varchar(64) DEFAULT NULL COMMENT '管理员账号',
  `role` varchar(32) DEFAULT NULL COMMENT '角色',
  `permission_code` varchar(64) DEFAULT NULL COMMENT '权限编码',
  `method` varchar(16) NOT NULL COMMENT 'HTTP方法',
  `path` varchar(255) NOT NULL COMMENT '请求路径',
  `action` varchar(128) DEFAULT NULL COMMENT '操作说明',
  `status` varchar(16) NOT NULL COMMENT 'SUCCESS/FAILED',
  `duration_ms` bigint(20) DEFAULT NULL COMMENT '耗时毫秒',
  `error_message` varchar(512) DEFAULT NULL COMMENT '错误信息',
  `ip` varchar(64) DEFAULT NULL COMMENT '客户端IP',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_admin_create_time` (`admin_id`, `create_time`),
  KEY `idx_permission_create_time` (`permission_code`, `create_time`),
  KEY `idx_status_create_time` (`status`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后台操作日志';

-- ----------------------------
-- 2. 补齐旧库可能缺失的后台字段
-- ----------------------------

DROP PROCEDURE IF EXISTS add_column_if_missing;
DELIMITER //
CREATE PROCEDURE add_column_if_missing(
  IN p_table_name VARCHAR(64),
  IN p_column_name VARCHAR(64),
  IN p_ddl TEXT
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = p_table_name
      AND COLUMN_NAME = p_column_name
  ) THEN
    SET @ddl_sql = p_ddl;
    PREPARE ddl_stmt FROM @ddl_sql;
    EXECUTE ddl_stmt;
    DEALLOCATE PREPARE ddl_stmt;
  END IF;
END//
DELIMITER ;

CALL add_column_if_missing('users', 'avatar',
  'ALTER TABLE users ADD COLUMN avatar varchar(512) DEFAULT NULL COMMENT ''头像'' AFTER nickname');
CALL add_column_if_missing('users', 'role',
  'ALTER TABLE users ADD COLUMN role varchar(32) NOT NULL DEFAULT ''USER'' COMMENT ''角色: USER, ADMIN'' AFTER avatar');
CALL add_column_if_missing('users', 'status',
  'ALTER TABLE users ADD COLUMN status tinyint(4) NOT NULL DEFAULT ''1'' COMMENT ''状态: 0-禁用, 1-启用'' AFTER role');
CALL add_column_if_missing('orders', 'logistics_company',
  'ALTER TABLE orders ADD COLUMN logistics_company varchar(128) DEFAULT NULL COMMENT ''物流公司'' AFTER address_id');
CALL add_column_if_missing('orders', 'logistics_no',
  'ALTER TABLE orders ADD COLUMN logistics_no varchar(128) DEFAULT NULL COMMENT ''物流单号'' AFTER logistics_company');
CALL add_column_if_missing('aftersales', 'admin_remark',
  'ALTER TABLE aftersales ADD COLUMN admin_remark varchar(512) DEFAULT NULL COMMENT ''管理员备注'' AFTER status');

-- ----------------------------
-- 3. 针对真实查询模式添加可重复执行的索引
-- ----------------------------

DROP PROCEDURE IF EXISTS add_index_if_missing;
DELIMITER //
CREATE PROCEDURE add_index_if_missing(
  IN p_table_name VARCHAR(64),
  IN p_index_name VARCHAR(64),
  IN p_ddl TEXT
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = p_table_name
      AND INDEX_NAME = p_index_name
  ) THEN
    SET @ddl_sql = p_ddl;
    PREPARE ddl_stmt FROM @ddl_sql;
    EXECUTE ddl_stmt;
    DEALLOCATE PREPARE ddl_stmt;
  END IF;
END//
DELIMITER ;

CALL add_index_if_missing('categories', 'idx_parent_id',
  'ALTER TABLE categories ADD INDEX idx_parent_id (parent_id, id)');

CALL add_index_if_missing('users', 'uk_account',
  'ALTER TABLE users ADD UNIQUE INDEX uk_account (account)');
CALL add_index_if_missing('users', 'idx_role_status_create_time',
  'ALTER TABLE users ADD INDEX idx_role_status_create_time (role, status, create_time)');
CALL add_index_if_missing('users', 'idx_status_create_time',
  'ALTER TABLE users ADD INDEX idx_status_create_time (status, create_time)');

CALL add_index_if_missing('products', 'idx_category_id',
  'ALTER TABLE products ADD INDEX idx_category_id (category_id)');
CALL add_index_if_missing('products', 'idx_status',
  'ALTER TABLE products ADD INDEX idx_status (status)');
CALL add_index_if_missing('products', 'idx_create_time',
  'ALTER TABLE products ADD INDEX idx_create_time (create_time)');
CALL add_index_if_missing('products', 'idx_status_create_time',
  'ALTER TABLE products ADD INDEX idx_status_create_time (status, create_time)');
CALL add_index_if_missing('products', 'idx_category_status_create_time',
  'ALTER TABLE products ADD INDEX idx_category_status_create_time (category_id, status, create_time)');
CALL add_index_if_missing('products', 'idx_status_stock',
  'ALTER TABLE products ADD INDEX idx_status_stock (status, stock)');
CALL add_index_if_missing('products', 'ft_name_description',
  'ALTER TABLE products ADD FULLTEXT INDEX ft_name_description (name, description) WITH PARSER ngram');

CALL add_index_if_missing('product_media', 'idx_product_id',
  'ALTER TABLE product_media ADD INDEX idx_product_id (product_id)');
CALL add_index_if_missing('product_media', 'idx_product_sort',
  'ALTER TABLE product_media ADD INDEX idx_product_sort (product_id, sort_order, id)');

CALL add_index_if_missing('product_skus', 'idx_product_id',
  'ALTER TABLE product_skus ADD INDEX idx_product_id (product_id)');

CALL add_index_if_missing('user_addresses', 'idx_user_id',
  'ALTER TABLE user_addresses ADD INDEX idx_user_id (user_id)');
CALL add_index_if_missing('user_addresses', 'idx_user_default_create',
  'ALTER TABLE user_addresses ADD INDEX idx_user_default_create (user_id, is_default, create_time)');

CALL add_index_if_missing('orders', 'uk_order_no',
  'ALTER TABLE orders ADD UNIQUE INDEX uk_order_no (order_no)');
CALL add_index_if_missing('orders', 'idx_user_create_time',
  'ALTER TABLE orders ADD INDEX idx_user_create_time (user_id, create_time)');
CALL add_index_if_missing('orders', 'idx_status_create_time',
  'ALTER TABLE orders ADD INDEX idx_status_create_time (status, create_time)');
CALL add_index_if_missing('orders', 'idx_create_time',
  'ALTER TABLE orders ADD INDEX idx_create_time (create_time)');

CALL add_index_if_missing('order_items', 'idx_order_id',
  'ALTER TABLE order_items ADD INDEX idx_order_id (order_id)');
CALL add_index_if_missing('order_items', 'idx_product_id',
  'ALTER TABLE order_items ADD INDEX idx_product_id (product_id)');

CALL add_index_if_missing('cart_items', 'idx_user_id',
  'ALTER TABLE cart_items ADD INDEX idx_user_id (user_id)');
CALL add_index_if_missing('cart_items', 'idx_user_create_time',
  'ALTER TABLE cart_items ADD INDEX idx_user_create_time (user_id, create_time)');
CALL add_index_if_missing('cart_items', 'idx_user_product_sku',
  'ALTER TABLE cart_items ADD INDEX idx_user_product_sku (user_id, product_id, sku_id)');
CALL add_index_if_missing('cart_items', 'idx_user_checked',
  'ALTER TABLE cart_items ADD INDEX idx_user_checked (user_id, checked)');

CALL add_index_if_missing('payments', 'uk_trade_id',
  'ALTER TABLE payments ADD UNIQUE INDEX uk_trade_id (trade_id)');
CALL add_index_if_missing('payments', 'idx_order_id',
  'ALTER TABLE payments ADD INDEX idx_order_id (order_id)');
CALL add_index_if_missing('payments', 'idx_order_create_time',
  'ALTER TABLE payments ADD INDEX idx_order_create_time (order_id, create_time)');

CALL add_index_if_missing('coupons', 'uk_code',
  'ALTER TABLE coupons ADD UNIQUE INDEX uk_code (code)');
CALL add_index_if_missing('coupons', 'idx_user_id',
  'ALTER TABLE coupons ADD INDEX idx_user_id (user_id)');
CALL add_index_if_missing('coupons', 'idx_user_status_time',
  'ALTER TABLE coupons ADD INDEX idx_user_status_time (user_id, status, start_time, end_time)');

CALL add_index_if_missing('aftersales', 'idx_user_id',
  'ALTER TABLE aftersales ADD INDEX idx_user_id (user_id)');
CALL add_index_if_missing('aftersales', 'idx_order_id',
  'ALTER TABLE aftersales ADD INDEX idx_order_id (order_id)');
CALL add_index_if_missing('aftersales', 'idx_user_create_time',
  'ALTER TABLE aftersales ADD INDEX idx_user_create_time (user_id, create_time)');
CALL add_index_if_missing('aftersales', 'idx_status_create_time',
  'ALTER TABLE aftersales ADD INDEX idx_status_create_time (status, create_time)');

CALL add_index_if_missing('reviews', 'idx_product_id',
  'ALTER TABLE reviews ADD INDEX idx_product_id (product_id)');
CALL add_index_if_missing('reviews', 'idx_user_id',
  'ALTER TABLE reviews ADD INDEX idx_user_id (user_id)');
CALL add_index_if_missing('reviews', 'idx_order_id',
  'ALTER TABLE reviews ADD INDEX idx_order_id (order_id)');
CALL add_index_if_missing('reviews', 'idx_product_create_time',
  'ALTER TABLE reviews ADD INDEX idx_product_create_time (product_id, create_time)');
CALL add_index_if_missing('reviews', 'idx_user_product_order_create',
  'ALTER TABLE reviews ADD INDEX idx_user_product_order_create (user_id, product_id, order_id, create_time)');

CALL add_index_if_missing('favorites', 'uk_user_product',
  'ALTER TABLE favorites ADD UNIQUE INDEX uk_user_product (user_id, product_id)');
CALL add_index_if_missing('favorites', 'idx_user_id',
  'ALTER TABLE favorites ADD INDEX idx_user_id (user_id)');
CALL add_index_if_missing('favorites', 'idx_product_id',
  'ALTER TABLE favorites ADD INDEX idx_product_id (product_id)');
CALL add_index_if_missing('favorites', 'idx_user_create_time',
  'ALTER TABLE favorites ADD INDEX idx_user_create_time (user_id, create_time)');

CALL add_index_if_missing('notifications', 'idx_user_id',
  'ALTER TABLE notifications ADD INDEX idx_user_id (user_id)');
CALL add_index_if_missing('notifications', 'idx_user_create_time',
  'ALTER TABLE notifications ADD INDEX idx_user_create_time (user_id, create_time)');
CALL add_index_if_missing('notifications', 'idx_user_read',
  'ALTER TABLE notifications ADD INDEX idx_user_read (user_id, is_read)');
CALL add_index_if_missing('notifications', 'idx_related_id',
  'ALTER TABLE notifications ADD INDEX idx_related_id (related_id)');

CALL add_index_if_missing('admin_operation_logs', 'idx_admin_create_time',
  'ALTER TABLE admin_operation_logs ADD INDEX idx_admin_create_time (admin_id, create_time)');
CALL add_index_if_missing('admin_operation_logs', 'idx_permission_create_time',
  'ALTER TABLE admin_operation_logs ADD INDEX idx_permission_create_time (permission_code, create_time)');
CALL add_index_if_missing('admin_operation_logs', 'idx_status_create_time',
  'ALTER TABLE admin_operation_logs ADD INDEX idx_status_create_time (status, create_time)');

-- ----------------------------
-- 4. 商品 SKU 数据修复与约束
-- ----------------------------

UPDATE product_skus SET attrs = '{"轴体":"樱桃银轴","背光":"RGB"}' WHERE product_id = 35 AND attrs = '{"轴体":"樱桃银轴","RGB背光"}';
UPDATE product_skus SET attrs = '{"轴体":"樱桃青轴","版本":"白色版"}' WHERE product_id = 35 AND attrs = '{"轴体":"樱桃青轴","白色版"}';
UPDATE product_skus SET attrs = '{"颜色":"粉色","版本":"限量版"}' WHERE product_id = 36 AND attrs = '{"颜色":"粉色","限量版"}';
UPDATE product_skus SET attrs = '{"轴体":"绿轴","背光":"RGB","颜色":"黑色"}' WHERE product_id = 40 AND attrs = '{"轴体":"绿轴","RGB背光","颜色":"黑色"}';
UPDATE product_skus SET attrs = '{"轴体":"黄轴","背光":"RGB","颜色":"白色"}' WHERE product_id = 40 AND attrs = '{"轴体":"黄轴","RGB背光","颜色":"白色"}';
UPDATE product_skus SET attrs = '{"轴体":"橙轴","背光":"无","颜色":"黑色"}' WHERE product_id = 40 AND attrs = '{"轴体":"橙轴","无背光","颜色":"黑色"}';
UPDATE product_skus SET attrs = '{"容量":"100L","颜色":"白色","移动方式":"带轮"}' WHERE product_id = 82 AND attrs = '{"容量":"100L","颜色":"白色","带轮"}';
UPDATE product_skus SET attrs = '{"规格":"6卷装","层数":"3层","厚度":"加厚"}' WHERE product_id = 87 AND attrs = '{"规格":"6卷装","层数":"3层","加厚"}';
UPDATE product_skus SET attrs = '{"材质":"丁腈","尺寸":"M码","数量":"100只","厚度":"加厚"}' WHERE product_id = 88 AND attrs = '{"材质":"丁腈","尺寸":"M码","数量":"100只","加厚"}';
UPDATE product_skus SET attrs = '{"层数":"2层","颜色":"银色","配件":"带挂钩"}' WHERE product_id = 89 AND attrs = '{"层数":"2层","颜色":"银色","带挂钩"}';
UPDATE product_skus SET attrs = '{"材质":"木浆棉","数量":"30片","厚度":"加厚"}' WHERE product_id = 93 AND attrs = '{"材质":"木浆棉","数量":"30片","加厚"}';
UPDATE product_skus SET attrs = '{"材质":"竹纤维","数量":"40片","清洁方式":"可水洗"}' WHERE product_id = 93 AND attrs = '{"材质":"竹纤维","数量":"40片","可水洗"}';
UPDATE product_skus SET attrs = '{"颜色":"米色","尺寸":"30cm","安装方式":"无痕钉"}' WHERE product_id = 94 AND attrs = '{"颜色":"米色","尺寸":"30cm","无痕钉"}';
UPDATE product_skus SET attrs = '{"颜色":"灰色","尺寸":"40cm","安装方式":"挂钩式"}' WHERE product_id = 94 AND attrs = '{"颜色":"灰色","尺寸":"40cm","挂钩式"}';
UPDATE product_skus SET attrs = '{"颜色":"蓝色","尺寸":"50cm","安装方式":"吸盘式"}' WHERE product_id = 94 AND attrs = '{"颜色":"蓝色","尺寸":"50cm","吸盘式"}';
UPDATE product_skus SET attrs = '{"类型":"电动","供电":"充电式","适用":"玻璃"}' WHERE product_id = 98 AND attrs = '{"类型":"电动","充电式","适用玻璃"}';
UPDATE product_skus SET attrs = '{"规格":"30ml","肤质":"敏感肌","防晒类型":"物理防晒"}' WHERE product_id = 105 AND attrs = '{"规格":"30ml","肤质":"敏感肌","物理防晒"}';
UPDATE product_skus SET attrs = '{"规格":"500g","发质":"干枯","版本":"沙龙级"}' WHERE product_id = 114 AND attrs = '{"规格":"500g","发质":"干枯","沙龙级"}';
UPDATE product_skus SET attrs = '{"规格":"100g","发质":"染烫","版本":"旅行装"}' WHERE product_id = 114 AND attrs = '{"规格":"100g","发质":"染烫","旅行装"}';
UPDATE product_skus SET attrs = '{"香型":"无花果+雪松","规格":"100g×4","包装":"礼盒装"}' WHERE product_id = 120 AND attrs = '{"香型":"无花果+雪松","规格":"100g×4","礼盒装"}';
UPDATE product_skus SET attrs = '{"规格":"400g","口味":"原味","包装":"礼盒装"}' WHERE product_id = 125 AND attrs = '{"规格":"400g","口味":"原味","礼盒装"}';
UPDATE product_skus SET attrs = '{"规格":"600g","口味":"巧克力味","包装":"礼盒装"}' WHERE product_id = 125 AND attrs = '{"规格":"600g","口味":"巧克力味","礼盒装"}';
UPDATE product_skus SET attrs = '{"规格":"800g","口味":"混合口味","包装":"铁盒装"}' WHERE product_id = 125 AND attrs = '{"规格":"800g","口味":"混合口味","铁盒装"}';
UPDATE product_skus SET attrs = '{"口味":"锡兰","规格":"12瓶×200ml","包装":"家庭装"}' WHERE product_id = 130 AND attrs = '{"口味":"锡兰","规格":"12瓶×200ml","家庭装"}';
UPDATE product_skus SET attrs = '{"颜色":"蓝色","尺寸":"200×150cm","适用季节":"四季通用"}' WHERE product_id = 146 AND attrs = '{"颜色":"蓝色","尺寸":"200×150cm","四季通用"}';

UPDATE product_skus SET attrs = '{}' WHERE attrs IS NULL OR TRIM(attrs) = '';
ALTER TABLE product_skus MODIFY attrs varchar(512) NOT NULL DEFAULT '{}' COMMENT '规格属性 (JSON字符串)';

CALL add_index_if_missing('product_skus', 'uk_product_attrs',
  'ALTER TABLE product_skus ADD UNIQUE INDEX uk_product_attrs (product_id, attrs)');

DROP PROCEDURE IF EXISTS add_check_if_missing;
DELIMITER //
CREATE PROCEDURE add_check_if_missing(
  IN p_table_name VARCHAR(64),
  IN p_constraint_name VARCHAR(64),
  IN p_ddl TEXT
)
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
      AND TABLE_NAME = p_table_name
      AND CONSTRAINT_NAME = p_constraint_name
  ) THEN
    SET @ddl_sql = p_ddl;
    PREPARE ddl_stmt FROM @ddl_sql;
    EXECUTE ddl_stmt;
    DEALLOCATE PREPARE ddl_stmt;
  END IF;
END//
DELIMITER ;

SET @existing_sku_attrs_check := (
  SELECT CHECK_CLAUSE
  FROM information_schema.CHECK_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND CONSTRAINT_NAME = 'chk_product_skus_attrs_json'
  LIMIT 1
);
SET @drop_sku_attrs_check_sql := IF(
  @existing_sku_attrs_check IS NOT NULL AND LOWER(REPLACE(@existing_sku_attrs_check, ' ', '')) <> 'json_valid(`attrs`)andjson_type(`attrs`)=''object''',
  'ALTER TABLE product_skus DROP CHECK chk_product_skus_attrs_json',
  'SELECT 1'
);
PREPARE stmt FROM @drop_sku_attrs_check_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CALL add_check_if_missing('product_skus', 'chk_product_skus_attrs_json',
  'ALTER TABLE product_skus ADD CONSTRAINT chk_product_skus_attrs_json CHECK (JSON_VALID(attrs) AND JSON_TYPE(attrs) = ''OBJECT'')');

DROP PROCEDURE IF EXISTS add_check_if_missing;

CALL add_column_if_missing('cart_items', 'sku_key',
  'ALTER TABLE cart_items ADD COLUMN sku_key bigint(20) GENERATED ALWAYS AS (IFNULL(sku_id, 0)) STORED COMMENT ''规格唯一键'' AFTER sku_id');

DROP TEMPORARY TABLE IF EXISTS tmp_duplicate_cart_items;
CREATE TEMPORARY TABLE tmp_duplicate_cart_items AS
SELECT MIN(id) AS keep_id, user_id, product_id, COALESCE(sku_id, 0) AS sku_key, SUM(quantity) AS total_quantity
FROM cart_items
GROUP BY user_id, product_id, COALESCE(sku_id, 0)
HAVING COUNT(*) > 1;

UPDATE cart_items c
JOIN tmp_duplicate_cart_items d ON c.id = d.keep_id
SET c.quantity = d.total_quantity, c.update_time = NOW();

DELETE c
FROM cart_items c
JOIN tmp_duplicate_cart_items d
  ON c.user_id = d.user_id
 AND c.product_id = d.product_id
 AND COALESCE(c.sku_id, 0) = d.sku_key
WHERE c.id <> d.keep_id;

CALL add_index_if_missing('cart_items', 'uk_user_product_sku',
  'ALTER TABLE cart_items ADD UNIQUE INDEX uk_user_product_sku (user_id, product_id, sku_key)');

-- ----------------------------
-- 5. 补齐后台基础数据
-- ----------------------------

UPDATE `users` SET `role` = 'USER' WHERE `role` IS NULL OR `role` = '';
UPDATE `users` SET `status` = 1 WHERE `status` IS NULL;

INSERT INTO `users`(`account`, `password`, `nickname`, `role`, `status`, `create_time`, `update_time`)
VALUES ('admin@example.com', '0192023a7bbd73250516f069df18b500', '平台管理员', 'ADMIN', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE `role` = 'ADMIN', `status` = 1, `update_time` = NOW();

INSERT INTO `admin_permissions`(`code`, `name`) VALUES
('DASHBOARD_VIEW', '查看工作台'),
('PRODUCT_MANAGE', '管理商品'),
('CATEGORY_MANAGE', '管理分类'),
('ORDER_MANAGE', '管理订单'),
('AFTERSALE_MANAGE', '管理售后'),
('USER_MANAGE', '管理用户'),
('OPERATION_LOG_VIEW', '查看操作日志')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT INTO `admin_role_permissions`(`role`, `permission_code`)
SELECT 'ADMIN', `code` FROM `admin_permissions`
ON DUPLICATE KEY UPDATE `permission_code` = VALUES(`permission_code`);

DROP PROCEDURE IF EXISTS add_check_if_missing;
DROP PROCEDURE IF EXISTS add_index_if_missing;
DROP PROCEDURE IF EXISTS add_column_if_missing;
