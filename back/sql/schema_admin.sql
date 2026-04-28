-- Admin platform migration for existing ProjectKu databases.
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

UPDATE users SET role = 'USER' WHERE role IS NULL OR role = '';
UPDATE users SET status = 1 WHERE status IS NULL;

INSERT INTO users(account, password, nickname, role, status, create_time, update_time)
VALUES ('admin@example.com', '0192023a7bbd73250516f069df18b500', '平台管理员', 'ADMIN', 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE role = 'ADMIN', status = 1, update_time = NOW();
