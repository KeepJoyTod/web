-- 支付记录表

DROP TABLE IF EXISTS `payments`;
CREATE TABLE `payments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) NOT NULL COMMENT '关联的订单ID',
  `trade_id` varchar(64) NOT NULL COMMENT '支付流水号(网关交易号)',
  `channel` varchar(32) NOT NULL COMMENT '支付渠道: alipay, wechat, stripe',
  `amount` decimal(10,2) NOT NULL COMMENT '支付金额',
  `status` varchar(32) NOT NULL DEFAULT 'PENDING' COMMENT '支付状态: PENDING, SUCCESS, FAILED',
  `paid_at` datetime DEFAULT NULL COMMENT '实际支付完成时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_trade_id` (`trade_id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付记录表';
