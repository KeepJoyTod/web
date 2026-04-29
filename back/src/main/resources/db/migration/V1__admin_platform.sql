-- Admin platform baseline migration.
-- Default admin account: admin@example.com / admin123

SET NAMES utf8mb4;

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

DROP PROCEDURE IF EXISTS add_column_if_missing;

CREATE TABLE IF NOT EXISTS admin_permissions (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  code varchar(64) NOT NULL COMMENT '权限编码',
  name varchar(128) NOT NULL COMMENT '权限名称',
  create_time datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_admin_permission_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后台权限表';

CREATE TABLE IF NOT EXISTS admin_role_permissions (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  role varchar(32) NOT NULL COMMENT '角色',
  permission_code varchar(64) NOT NULL COMMENT '权限编码',
  create_time datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_role_permission (role, permission_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后台角色权限表';

CREATE TABLE IF NOT EXISTS admin_operation_logs (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  admin_id bigint(20) DEFAULT NULL COMMENT '管理员ID',
  admin_account varchar(64) DEFAULT NULL COMMENT '管理员账号',
  role varchar(32) DEFAULT NULL COMMENT '角色',
  permission_code varchar(64) DEFAULT NULL COMMENT '权限编码',
  method varchar(16) NOT NULL COMMENT 'HTTP方法',
  path varchar(255) NOT NULL COMMENT '请求路径',
  action varchar(128) DEFAULT NULL COMMENT '操作说明',
  status varchar(16) NOT NULL COMMENT 'SUCCESS/FAILED',
  duration_ms bigint(20) DEFAULT NULL COMMENT '耗时毫秒',
  error_message varchar(512) DEFAULT NULL COMMENT '错误信息',
  ip varchar(64) DEFAULT NULL COMMENT '客户端IP',
  create_time datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_admin_create_time (admin_id, create_time),
  KEY idx_permission_create_time (permission_code, create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后台操作日志';

INSERT INTO admin_permissions(code, name) VALUES
('DASHBOARD_VIEW', '查看工作台'),
('PRODUCT_MANAGE', '管理商品'),
('CATEGORY_MANAGE', '管理分类'),
('ORDER_MANAGE', '管理订单'),
('AFTERSALE_MANAGE', '管理售后'),
('USER_MANAGE', '管理用户'),
('OPERATION_LOG_VIEW', '查看操作日志')
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO admin_role_permissions(role, permission_code)
SELECT 'ADMIN', code FROM admin_permissions
ON DUPLICATE KEY UPDATE permission_code = VALUES(permission_code);

UPDATE users SET role = 'USER' WHERE role IS NULL OR role = '';
UPDATE users SET status = 1 WHERE status IS NULL;

INSERT INTO users(account, password, nickname, role, status, create_time, update_time)
VALUES ('admin@example.com', '$2b$10$.3nrUPeS6ozqZbQcLCSlreusNsph6VidxNZSrQwciuzSUbn5G3sg.', '平台管理员', 'ADMIN', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE role = 'ADMIN', status = 1, update_time = NOW();
