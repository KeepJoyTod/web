-- 营销与售后表


-- ----------------------------
-- Table structure for coupons
-- ----------------------------
DROP TABLE IF EXISTS `coupons`;
CREATE TABLE `coupons` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL COMMENT '所属用户ID',
  `code` varchar(64) NOT NULL COMMENT '优惠券码',
  `name` varchar(128) NOT NULL COMMENT '优惠券名称',
  `type` varchar(32) NOT NULL COMMENT '类型: full_reduction(满减), discount(折扣)',
  `min_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '最低消费金额',
  `discount_amount` decimal(10,2) NOT NULL COMMENT '优惠/抵扣金额',
  `status` varchar(32) NOT NULL DEFAULT 'VALID' COMMENT '状态: VALID(可用), USED(已使用), EXPIRED(已过期)',
  `start_time` datetime NOT NULL COMMENT '生效时间',
  `end_time` datetime NOT NULL COMMENT '失效时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户优惠券表';

-- ----------------------------
-- Table structure for aftersales
-- ----------------------------
DROP TABLE IF EXISTS `aftersales`;
CREATE TABLE `aftersales` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `order_id` bigint(20) NOT NULL COMMENT '关联订单ID',
  `type` varchar(32) NOT NULL COMMENT '售后类型: refund_only(仅退款), return_refund(退货退款)',
  `reason` varchar(255) NOT NULL COMMENT '申请原因',
  `status` varchar(32) NOT NULL DEFAULT 'SUBMITTED' COMMENT '状态: SUBMITTED(已提交), PROCESSING(处理中), COMPLETED(已完成), CANCELLED(已取消)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='售后申请表';
