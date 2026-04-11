-- 用户地址表


DROP TABLE IF EXISTS `user_addresses`;
CREATE TABLE `user_addresses` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `receiver` varchar(64) NOT NULL COMMENT '收件人',
  `phone` varchar(32) NOT NULL COMMENT '联系电话',
  `region` varchar(128) NOT NULL COMMENT '所在地区(省市区)',
  `detail` varchar(255) NOT NULL COMMENT '详细地址',
  `is_default` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否默认地址: 0-否, 1-是',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户收货地址表';
