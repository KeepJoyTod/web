-- 数据库索引优化脚本
-- 1. 为 products 表添加 category_id 索引和 status 索引
-- 2. 为 products 表添加针对 name 和 description 的全文索引 (支持中文搜索)
-- 3. 为 orders 表添加 user_id 索引

-- 优化 products 表
ALTER TABLE `products` ADD INDEX `idx_category_id` (`category_id`);
ALTER TABLE `products` ADD INDEX `idx_status` (`status`);
ALTER TABLE `products` ADD INDEX `idx_create_time` (`create_time`);
-- 添加全文索引，使用 ngram 分词器以支持中文搜索
ALTER TABLE `products` ADD FULLTEXT INDEX `ft_name_description` (`name`, `description`) WITH PARSER ngram;

-- 优化 orders 表
ALTER TABLE `orders` ADD INDEX `idx_user_create_time` (`user_id`, `create_time`);
