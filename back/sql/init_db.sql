-- --------------------------------------------------
-- ProjectKu 数据库完整初始化脚本（修复版）
-- 包含所有表结构、基础数据、商品、订单等
-- --------------------------------------------------

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- 1. 创建类目表（新增）
-- ----------------------------
CREATE TABLE `categories` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL COMMENT '类目名称',
  `parent_id` bigint(20) DEFAULT '0' COMMENT '父类目ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品类目表';

-- ----------------------------
-- 2. 创建其他表结构
-- ----------------------------

-- 用户表
CREATE TABLE `users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `account` varchar(64) NOT NULL COMMENT '账号(邮箱/手机号)',
  `password` varchar(255) NOT NULL COMMENT '密码',
  `nickname` varchar(64) DEFAULT NULL COMMENT '昵称',
  `avatar` varchar(512) DEFAULT NULL COMMENT '头像',
  `role` varchar(32) NOT NULL DEFAULT 'USER' COMMENT '角色: USER, ADMIN',
  `status` tinyint(4) NOT NULL DEFAULT '1' COMMENT '状态: 0-禁用, 1-启用',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_account` (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 商品表 (SPU)
CREATE TABLE `products` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `category_id` bigint(20) DEFAULT NULL COMMENT '类目ID',
  `name` varchar(255) NOT NULL COMMENT '商品名称',
  `description` text COMMENT '商品描述',
  `tags` varchar(255) DEFAULT NULL COMMENT '标签 (逗号分隔或JSON)',
  `rating` decimal(3,1) DEFAULT 4.5 COMMENT '评分',
  `sold` int(11) DEFAULT 0 COMMENT '已售数量',
  `activity_label` varchar(255) DEFAULT NULL COMMENT '活动标签',
  `original_price` decimal(10,2) DEFAULT NULL COMMENT '原价',
  `price` decimal(10,2) NOT NULL COMMENT '基础展示价格',
  `stock` int(11) NOT NULL DEFAULT '0' COMMENT '基础库存',
  `status` tinyint(4) NOT NULL DEFAULT '1' COMMENT '状态: 0-下架, 1-上架',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_status` (`status`),
  KEY `idx_create_time` (`create_time`),
  FULLTEXT KEY `ft_name_description` (`name`, `description`) WITH PARSER ngram
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品表';

-- 商品媒体表 (轮播图)
CREATE TABLE `product_media` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `product_id` bigint(20) NOT NULL,
  `url` varchar(512) NOT NULL COMMENT '图片URL',
  `sort_order` int(11) DEFAULT '0' COMMENT '排序',
  PRIMARY KEY (`id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品媒体表';

-- 商品 SKU 表 (规格)
CREATE TABLE `product_skus` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `product_id` bigint(20) NOT NULL,
  `attrs` varchar(512) DEFAULT '{}' COMMENT '规格属性 (JSON字符串)',
  `price` decimal(10,2) NOT NULL COMMENT '该规格价格',
  `stock` int(11) NOT NULL DEFAULT '0' COMMENT '该规格库存',
  PRIMARY KEY (`id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品规格表';

-- 用户收货地址表
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

-- 订单表
CREATE TABLE `orders` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `order_no` varchar(64) NOT NULL COMMENT '订单号',
  `total_amount` decimal(10,2) NOT NULL COMMENT '总金额',
  `pay_amount` decimal(10,2) NOT NULL COMMENT '支付金额',
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态: 0-待支付, 1-已支付, 2-已发货, 3-已完成, 4-已取消',
  `address_id` bigint(20) DEFAULT NULL COMMENT '收货地址ID',
  `logistics_company` varchar(128) DEFAULT NULL COMMENT '物流公司',
  `logistics_no` varchar(128) DEFAULT NULL COMMENT '物流单号',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_create_time` (`user_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

-- 订单明细表
CREATE TABLE `order_items` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) NOT NULL COMMENT '订单ID',
  `product_id` bigint(20) NOT NULL COMMENT '商品ID',
  `sku_id` bigint(20) DEFAULT NULL COMMENT '规格ID',
  `product_name` varchar(255) NOT NULL COMMENT '商品名称',
  `product_image` varchar(512) DEFAULT NULL COMMENT '商品图片',
  `price` decimal(10,2) NOT NULL COMMENT '购买时价格',
  `quantity` int(11) NOT NULL COMMENT '购买数量',
  `total_amount` decimal(10,2) NOT NULL COMMENT '总金额',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单明细表';

-- 购物车明细表
CREATE TABLE `cart_items` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `product_id` bigint(20) NOT NULL COMMENT '商品ID',
  `sku_id` bigint(20) DEFAULT NULL COMMENT '规格ID',
  `quantity` int(11) NOT NULL DEFAULT '1' COMMENT '数量',
  `checked` tinyint(4) NOT NULL DEFAULT '1' COMMENT '是否选中: 0-否, 1-是',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='购物车明细表';

-- 支付记录表
CREATE TABLE `payments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) NOT NULL COMMENT '关联的订单ID',
  `trade_id` varchar(64) NOT NULL COMMENT '支付流水号',
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

-- 用户优惠券表
CREATE TABLE `coupons` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL COMMENT '所属用户ID',
  `code` varchar(64) NOT NULL COMMENT '优惠券码',
  `name` varchar(128) NOT NULL COMMENT '优惠券名称',
  `type` varchar(32) NOT NULL COMMENT '类型: full_reduction(满减), discount(折扣)',
  `min_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '最低消费金额',
  `discount_amount` decimal(10,2) NOT NULL COMMENT '优惠金额',
  `status` varchar(32) NOT NULL DEFAULT 'VALID' COMMENT '状态: VALID, USED, EXPIRED',
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL,
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户优惠券表';

-- 售后申请表
CREATE TABLE `aftersales` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `order_id` bigint(20) NOT NULL,
  `order_item_id` varchar(128) DEFAULT NULL COMMENT '订单项ID',
  `qty` int(11) DEFAULT '1' COMMENT '申请数量',
  `evidence` text COMMENT '凭证图片 (JSON数组)',
  `type` varchar(32) NOT NULL COMMENT '售后类型',
  `reason` varchar(255) NOT NULL,
  `status` varchar(32) NOT NULL DEFAULT 'SUBMITTED',
  `admin_remark` varchar(512) DEFAULT NULL COMMENT '管理员备注',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='售后申请表';

-- 商品评价表
CREATE TABLE `reviews` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `order_id` bigint(20) DEFAULT NULL COMMENT '关联订单ID',
  `product_id` bigint(20) NOT NULL COMMENT '商品ID',
  `rating` int(11) NOT NULL DEFAULT '5' COMMENT '评分 (1-5)',
  `content` text COMMENT '评价内容',
  `images` varchar(1024) DEFAULT NULL COMMENT '图片列表 (JSON数组字符串)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品评价表';

-- 商品收藏表
CREATE TABLE `favorites` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `product_id` bigint(20) NOT NULL COMMENT '商品ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_product` (`user_id`, `product_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品收藏表';

-- ----------------------------
-- 3. 初始数据填充
-- ----------------------------

-- 3.1 类目数据
INSERT INTO `categories` (`id`, `name`) VALUES
(1, '手机'),
(2, '电脑/办公'),
(3, '家电'),
(4, '数码配件'),
(5, '家居收纳'),
(6, '美妆个护'),
(7, '食品生鲜'),
(8, '运动户外');

-- 3.2 用户数据
INSERT INTO `users`(`account`, `password`, `nickname`, `role`, `status`) VALUES 
('admin@example.com','0192023a7bbd73250516f069df18b500','平台管理员','ADMIN',1),
('user@example.com','e10adc3949ba59abbe56e057f20f883e','测试用户','USER',1),
('alice@example.com','e10adc3949ba59abbe56e057f20f883e','Alice','USER',1);

-- 3.3 商品数据（手机类，1-20）
INSERT INTO `products`(`category_id`, `name`, `description`, `tags`, `price`, `stock`, `status`) VALUES
(1,'iPhone 15 Pro 128G','A17 Pro 芯片，旗舰性能','["旗舰"]',7999.00,100,1),
(1,'iPhone 15 128G','A16 芯片，性能均衡','["性价比"]',5999.00,120,1),
(1,'Xiaomi 14 Pro 12+256G','徕卡光学，旗舰影像','["旗舰"]',4999.00,200,1),
(1,'Redmi K70 12+256G','性能强悍，价格亲民','["性价比"]',2299.00,300,1),
(1,'HUAWEI Mate X5','折叠旗舰，大屏体验','["折叠屏"]',12999.00,50,1),
(1,'OPPO Find N3','折叠轻薄，旗舰体验','["折叠屏"]',9999.00,60,1),
(1,'MagSafe 原装充电器','配件','["配件"]',329.00,500,1),
(1,'Type-C 充电线 1m','配件','["配件"]',39.00,1000,1),
(1,'荣耀 Magic6 Pro','骁龙8 Gen3 旗舰','["旗舰"]',6499.00,120,1),
(1,'realme GT Neo','高性价比游戏手机','["性价比"]',1999.00,220,1),
(1,'vivo X100','自研影像旗舰','["旗舰"]',5299.00,140,1),
(1,'一加 Ace','高性能高性价比','["性价比"]',2399.00,240,1),
(1,'小米 折叠屏 Mix Fold','折叠大屏','["折叠屏"]',7999.00,70,1),
(1,'三星 Galaxy Z Fold','折叠标杆','["折叠屏"]',12999.00,40,1),
(1,'苹果 原装耳机 Type-C','配件','["配件"]',149.00,600,1),
(1,'Anker 65W 氮化镓充电器','配件','["配件"]',199.00,300,1),
(1,'iQOO 12','电竞旗舰性能','["旗舰"]',4199.00,180,1),
(1,'Redmi Note 13','超高性价比','["性价比"]',1299.00,800,1),
(1,'荣耀 X50','均衡之选','["性价比"]',1599.00,500,1),
(1,'OPPO Reno 旗舰版','影像旗舰','["旗舰"]',4599.00,160,1);

-- 商品数据（电脑/外设类，21-40）
INSERT INTO `products`(`category_id`, `name`, `description`, `tags`, `price`, `stock`, `status`) VALUES
(2,'MacBook Air 13 M3 16G','轻薄便携，续航出众','["轻薄本"]',9999.00,50,1),
(2,'ThinkPad X1 Carbon','高可靠商务轻薄','["轻薄本"]',12999.00,30,1),
(2,'ROG 枪神 笔记本','高刷电竞游戏本','["游戏本"]',14999.00,20,1),
(2,'联想 拯救者 Y7000','高性价比游戏本','["游戏本"]',6999.00,80,1),
(2,'Dell U2723QE 27\" 4K','Type-C 一线通','["显示器"]',3999.00,25,1),
(2,'LG 34WP65C 34\" 曲面','沉浸式超宽','["显示器"]',3299.00,20,1),
(2,'罗技 MX Master 3s','人体工学鼠标','["外设"]',599.00,200,1),
(2,'Keychron K2 键盘','机械键盘','["外设"]',499.00,150,1),
(2,'华为 MateBook X','金属轻薄','["轻薄本"]',7999.00,40,1),
(2,'小米 Pro 16','性能轻薄','["轻薄本"]',6499.00,60,1),
(2,'雷神 911','实惠游戏本','["游戏本"]',5699.00,90,1),
(2,'外星人 m15','旗舰电竞','["游戏本"]',17999.00,15,1),
(2,'明基 PD2705U 4K','设计师显示器','["显示器"]',2999.00,25,1),
(2,'群晖 NAS DS220+','数据存储','["外设"]',2999.00,35,1),
(2,'海盗船 K70 键盘','外设','["外设"]',899.00,60,1),
(2,'罗技 G Pro X Superlight','电竞鼠标','["外设"]',899.00,70,1),
(2,'惠普 星14','轻薄本','["轻薄本"]',4799.00,120,1),
(2,'微星 GF66','高性价比游戏本','["游戏本"]',6299.00,70,1),
(2,'AOC 27G2 144Hz','电竞显示器','["显示器"]',1299.00,100,1),
(2,'雷蛇 黑寡妇','外设','["外设"]',799.00,60,1);

-- 商品数据（家电类，41-60）
INSERT INTO `products`(`category_id`, `name`, `description`, `tags`, `price`, `stock`, `status`) VALUES
(3,'海尔 纤诺 洗衣机','大容量变频','["冰洗"]',3299.00,40,1),
(3,'美的 风冷 冰箱','多门风冷','["冰洗"]',4599.00,35,1),
(3,'戴森 V12 吸尘器','强劲吸力','["清洁"]',3999.00,30,1),
(3,'石头 扫拖机器人','激光导航','["清洁"]',2599.00,50,1),
(3,'苏泊尔 炒锅','不粘锅具','["厨房"]',399.00,200,1),
(3,'九阳 破壁机','多功能','["厨房"]',899.00,120,1),
(3,'飞科 电动牙刷','清洁口腔','["个护"]',199.00,300,1),
(3,'飞利浦 电吹风','恒温护发','["个护"]',299.00,220,1),
(3,'格力 空调 1.5P','一级能效','["冰洗"]',3899.00,25,1),
(3,'小米 空气净化器','滤除PM2.5','["清洁"]',799.00,110,1),
(3,'美的 洗碗机','嵌入式','["厨房"]',3699.00,28,1),
(3,'松下 电动剃须刀','三刀头','["个护"]',599.00,180,1),
(3,'添可 吸拖一体机','高效清洁','["清洁"]',2499.00,40,1),
(3,'苏泊尔 电饭煲','智能预约','["厨房"]',499.00,140,1),
(3,'美的 干衣机','快速烘干','["冰洗"]',2999.00,22,1),
(3,'莱克 吸尘器','无线便携','["清洁"]',1299.00,60,1),
(3,'小熊 榨汁机','厨房小电','["厨房"]',199.00,250,1),
(3,'飞科 理发器','个护','["个护"]',129.00,260,1),
(3,'博朗 牙刷','个护','["个护"]',399.00,90,1),
(3,'云鲸 扫拖机器人','清洁','["清洁"]',4599.00,18,1);

-- 商品数据（数码配件类，61-80）
INSERT INTO `products`(`category_id`, `name`, `description`, `tags`, `price`, `stock`, `status`) VALUES
(4,'索尼 WH-1000XM5','旗舰降噪耳机','["耳机"]',2599.00,60,1),
(4,'AirPods Pro 2','主动降噪','["耳机"]',1999.00,90,1),
(4,'JBL Live Pro','真无线耳机','["耳机"]',799.00,120,1),
(4,'Anker 65W 充电器','氮化镓快充','["充电"]',199.00,300,1),
(4,'倍思 充电宝 20000mAh','大容量','["充电"]',169.00,400,1),
(4,'闪迪 至尊高速 128G','U3 存储卡','["存储"]',129.00,500,1),
(4,'三星 EVO 256G','高速存储卡','["存储"]',299.00,260,1),
(4,'Apple Watch SE','智能手表','["智能穿戴"]',2199.00,80,1),
(4,'华为 Watch 4','长续航手表','["智能穿戴"]',2499.00,70,1),
(4,'小米 手环 8 Pro','智能手环','["智能穿戴"]',399.00,600,1),
(4,'索尼 LinkBuds','开放式耳机','["耳机"]',1199.00,90,1),
(4,'绿联 氮化镓 100W','快充','["充电"]',299.00,150,1),
(4,'西数 SSD 1TB','高速固态','["存储"]',599.00,80,1),
(4,'东芝 U盘 128G','存储','["存储"]',79.00,700,1),
(4,'佳明 Forerunner','运动手表','["智能穿戴"]',2599.00,50,1),
(4,'Beats Studio Buds','无线耳机','["耳机"]',1099.00,100,1),
(4,'南孚 充电套装','充电','["充电"]',129.00,300,1),
(4,'海康 TF 256G','存储卡','["存储"]',169.00,400,1),
(4,'OPPO Watch','智能穿戴','["智能穿戴"]',1299.00,80,1),
(4,'索尼 WF-1000XM5','旗舰真无线','["耳机"]',1699.00,70,1);

-- 商品数据（家居收纳类，81-100）
INSERT INTO `products`(`category_id`, `name`, `description`, `tags`, `price`, `stock`, `status`) VALUES
(5,'抽屉式收纳盒','桌面收纳','["收纳"]',69.00,500,1),
(5,'衣物整理箱','大容量','["收纳"]',89.00,400,1),
(5,'北欧风抱枕','舒适家居','["家居"]',49.00,600,1),
(5,'落地台灯','氛围灯','["家居"]',199.00,200,1),
(5,'晨光 中性笔 12支','顺滑书写','["文具"]',19.90,1000,1),
(5,'得力 活页本','学习办公','["文具"]',29.90,800,1),
(5,'厨房纸巾 6卷','强吸水','["清洁耗材"]',19.90,900,1),
(5,'一次性手套 100只','清洁防护','["清洁耗材"]',14.90,1200,1),
(5,'多功能置物架','家居','["家居"]',129.00,300,1),
(5,'密封保鲜盒','厨房收纳','["收纳"]',39.90,700,1),
(5,'梳齿书签套装','文具','["文具"]',9.90,900,1),
(5,'抽绳垃圾袋 3卷','清洁耗材','["清洁耗材"]',12.90,1500,1),
(5,'懒人抹布','清洁耗材','["清洁耗材"]',9.90,1600,1),
(5,'墙面置物袋','收纳','["收纳"]',29.90,600,1),
(5,'防滑衣架 20只','家居','["家居"]',19.90,1200,1),
(5,'极简闹钟','家居','["家居"]',49.90,500,1),
(5,'高光修正带','文具','["文具"]',6.90,1000,1),
(5,'擦窗器','清洁耗材','["清洁耗材"]',39.90,400,1),
(5,'桌面理线器','收纳','["收纳"]',9.90,900,1),
(5,'便签便利贴','文具','["文具"]',4.90,1000,1);

-- 商品数据（美妆个护类，101-120）
INSERT INTO `products`(`category_id`, `name`, `description`, `tags`, `price`, `stock`, `status`) VALUES
(6,'温和保湿洁面乳','氨基酸配方，清洁同时不紧绷','["护肤"]',79.00,300,1),
(6,'深层补水爽肤水','二次清洁，舒缓干燥','["护肤"]',99.00,260,1),
(6,'修护精华液','添加神经酰胺，修护屏障','["护肤"]',219.00,180,1),
(6,'水润保湿面霜','长效锁水，适合秋冬使用','["护肤"]',169.00,200,1),
(6,'清爽防晒乳 SPF50+','日常通勤防晒','["护肤"]',129.00,220,1),
(6,'丝绒雾面口红','显白不拔干，多色可选','["彩妆"]',139.00,400,1),
(6,'水润气垫粉底','轻薄服帖，自然遮瑕','["彩妆"]',189.00,250,1),
(6,'防水眉笔','细芯顺滑，持久不晕染','["彩妆"]',59.00,500,1),
(6,'纤长睫毛膏','根根分明，不易结块','["彩妆"]',99.00,320,1),
(6,'高光修容盘','修饰轮廓，提亮气色','["彩妆"]',159.00,180,1),
(6,'柔顺修护洗发水','针对干枯毛躁发质','["洗护"]',69.00,420,1),
(6,'顺滑护发素','减少打结，提升光泽','["洗护"]',59.00,380,1),
(6,'氨基酸沐浴露','温和清洁，全肤质适用','["洗护"]',49.00,450,1),
(6,'深度滋养发膜','一周一次集中护理','["洗护"]',89.00,260,1),
(6,'旅行装洗护套装','适合短途出行携带','["洗护"]',39.00,600,1),
(6,'花果香淡香水','清新甜美日常香','["香氛"]',269.00,160,1),
(6,'木质麝香香水','沉稳木质调，适合通勤','["香氛"]',329.00,140,1),
(6,'室内藤条香薰','净化异味，营造氛围','["香氛"]',129.00,220,1),
(6,'车载夹式香氛','长效留香，驾驶更愉悦','["香氛"]',79.00,300,1),
(6,'香氛蜡烛礼盒','多种香型可选','["香氛"]',199.00,180,1);

-- 商品数据（食品生鲜类，121-140）
INSERT INTO `products`(`category_id`, `name`, `description`, `tags`, `price`, `stock`, `status`) VALUES
(7,'每日坚果 750g','混合坚果，独立小包装','["零食"]',89.00,400,1),
(7,'海盐薯片 8连包','轻薄脆爽，追剧必备','["零食"]',29.90,800,1),
(7,'和风鱿鱼丝','高蛋白小零食','["零食"]',19.90,600,1),
(7,'冻干草莓脆','水果冻干，不添加色素','["零食"]',35.90,300,1),
(7,'黄油曲奇礼盒','下午茶点心','["零食"]',49.90,260,1),
(7,'挂耳咖啡 20袋','阿拉比卡咖啡豆，中度烘焙','["咖啡茶饮"]',69.00,300,1),
(7,'精品咖啡豆 500g','浅烘焙，适合手冲','["咖啡茶饮"]',89.00,220,1),
(7,'锡兰红茶 礼盒装','产地直采，口感清爽','["咖啡茶饮"]',59.00,260,1),
(7,'茉莉花茶 250g','茉莉花窨制绿茶','["咖啡茶饮"]',49.00,280,1),
(7,'浓缩奶茶液 6瓶装','冷水冲泡即可饮用','["咖啡茶饮"]',39.90,320,1),
(7,'东北大米 10kg','颗粒饱满，新米香甜','["粮油"]',89.00,500,1),
(7,'五常稻花香 5kg','认证产区大米','["粮油"]',79.00,380,1),
(7,'非转菜籽油 5L','冷榨工艺，少油烟','["粮油"]',69.90,260,1),
(7,'橄榄调和油 2L','适合凉拌与煎炒','["粮油"]',59.90,280,1),
(7,'高筋小麦粉 5kg','适合烘焙与面食','["粮油"]',49.90,320,1),
(7,'速冻手工水饺 1.5kg','猪肉白菜口味','["生鲜冷冻"]',49.90,260,1),
(7,'冷冻鸡翅中 1kg','气调保鲜，家庭囤货','["生鲜冷冻"]',39.90,280,1),
(7,'雪花肥牛片 500g','适合火锅与炒菜','["生鲜冷冻"]',59.90,220,1),
(7,'去壳虾仁 400g','速冻锁鲜，简单烹饪','["生鲜冷冻"]',49.90,240,1),
(7,'冷冻披萨 半成品','烤箱加热即可食用','["生鲜冷冻"]',29.90,260,1);

-- 商品数据（运动户外类，141-160）
INSERT INTO `products`(`category_id`, `name`, `description`, `tags`, `price`, `stock`, `status`) VALUES
(8,'减震跑步鞋 男款','适合日常慢跑训练','["跑步"]',399.00,260,1),
(8,'轻量跑步鞋 女款','透气网面，舒适脚感','["跑步"]',369.00,240,1),
(8,'专业跑步短袖','速干面料，排汗透气','["跑步"]',129.00,320,1),
(8,'运动压缩裤','支撑肌群，减少疲劳','["跑步"]',199.00,200,1),
(8,'夜跑反光臂包','可放手机与钥匙','["跑步"]',59.00,360,1),
(8,'双人帐篷 防雨款','三季适用，搭建方便','["露营"]',599.00,180,1),
(8,'便携折叠椅','户外露营休闲必备','["露营"]',129.00,260,1),
(8,'户外野营灯','USB 充电，多档亮度','["露营"]',99.00,280,1),
(8,'保温野餐壶 1.5L','长效保温保冷','["露营"]',89.00,220,1),
(8,'钛合金野餐餐具套装','轻便耐用','["露营"]',149.00,200,1),
(8,'家用哑铃套装 20kg','可调节重量','["健身"]',299.00,220,1),
(8,'瑜伽垫 加厚款','高回弹材质，防滑耐磨','["健身"]',129.00,320,1),
(8,'跳绳 轴承款','适合燃脂训练','["健身"]',59.00,360,1),
(8,'阻力带 5件套','力量训练辅助','["健身"]',79.00,280,1),
(8,'家用引体向上器','免打孔安装','["健身"]',199.00,180,1),
(8,'公路自行车 入门款','铝合金车架，适合通勤','["骑行"]',1999.00,80,1),
(8,'山地车 21速','适合户外越野','["骑行"]',1699.00,90,1),
(8,'骑行头盔 一体成型','轻量防护','["骑行"]',199.00,260,1),
(8,'骑行手套 透气款','掌心减震垫','["骑行"]',79.00,300,1),
(8,'自行车码表','记录速度与里程','["骑行"]',129.00,220,1);

-- 补充商品（避免与前面重复，修改名称，161-170）
INSERT INTO `products`(`category_id`, `name`, `description`, `tags`, `price`, `stock`, `status`) VALUES
(1,'iPhone 14 128G','苹果智能手机，A15 仿生，支持 5G','["手机"]',5999.00,50,1),
(1,'Xiaomi 14 256G','小米旗舰手机，徕卡影像','["手机"]',4299.00,120,1),
(2,'MacBook Air 13 M3 16G (新款)','轻薄本，日常学习办公优选','["轻薄本"]',9999.00,30,1),
(2,'ThinkPad X1 Carbon (Gen 11)','专业商务本，高可靠性','["轻薄本"]',12999.00,18,1),
(3,'戴森 V12 吸尘器 (Absolute)','强劲吸力，全屋清洁','["清洁"]',3999.00,40,1),
(3,'米家扫拖机器人','激光导航，自动回充','["清洁"]',1799.00,80,1),
(4,'索尼 WH-1000XM5 (银)','旗舰降噪耳机，舒适佩戴','["耳机"]',2599.00,60,1),
(4,'AirPods Pro 2 (USB-C)','主动降噪，通透模式','["耳机"]',1999.00,90,1),
(5,'Dell U2723QE 27" 4K (升级版)','Type-C 一线通，IPS 面板','["显示器"]',3999.00,25,1),
(5,'LG 34WP65C 34" 曲面 (新款)','超宽曲面，沉浸体验','["显示器"]',3299.00,20,1);

-- 3.4 地址数据
INSERT INTO `user_addresses`(`user_id`, `receiver`, `phone`, `region`, `detail`, `is_default`)
VALUES (1,'张三','13800000000','北京','朝阳区建国路 88 号',1);

-- 3.5 优惠券数据
INSERT INTO `coupons`(`user_id`, `code`, `name`, `type`, `min_amount`, `discount_amount`, `status`, `start_time`, `end_time`)
VALUES (1,'NEW300','新客满5000-300','full_reduction',5000.00,300.00,'VALID', NOW() - INTERVAL 1 DAY, NOW() + INTERVAL 30 DAY);

-- 3.6 模拟订单（使用唯一商品 iPhone 15 Pro，避免名称重复）
-- 先获取地址ID（用户1的默认地址）
SET @addr_id = (SELECT id FROM user_addresses WHERE user_id=1 LIMIT 1);
-- 插入订单
INSERT INTO `orders`(`user_id`, `order_no`, `total_amount`, `pay_amount`, `status`, `address_id`)
VALUES (1,'A20260405001',7999.00,7999.00,1, @addr_id);
-- 获取刚插入的订单ID
SET @order_id = LAST_INSERT_ID();
-- 获取商品ID（iPhone 15 Pro）
SET @product_id = (SELECT id FROM products WHERE name='iPhone 15 Pro 128G' LIMIT 1);
-- 插入订单明细
INSERT INTO `order_items`(`order_id`, `product_id`, `product_name`, `product_image`, `price`, `quantity`, `total_amount`)
VALUES (@order_id, @product_id, 'iPhone 15 Pro 128G', '/product_1.jpg', 7999.00, 1, 7999.00);
-- 插入支付记录
INSERT INTO `payments`(`order_id`, `trade_id`, `channel`, `amount`, `status`, `paid_at`)
VALUES (@order_id, 'T20260405001', 'alipay', 7999.00, 'SUCCESS', NOW());

-- 可选：添加商品媒体

INSERT INTO `product_media` (`product_id`, `url`, `sort_order`) VALUES
(1, '/product_1.jpg', 1),
(2, '/product_2.jpg', 1),
(3, '/product_3.jpg', 1),
(4, '/product_4.jpg', 1),
(5, '/product_5.jpg', 1),
(6, '/product_6.jpg', 1),
(7, '/product_7.jpg', 1),
(8, '/product_8.jpg', 1),
(9, '/product_9.jpg', 1),
(10, '/product_10.jpg', 1),
(11, '/product_11.jpg', 1),
(12, '/product_12.jpg', 1),
(13, '/product_13.jpg', 1),
(14, '/product_14.jpg', 1),
(15, '/product_15.jpg', 1),
(16, '/product_16.jpg', 1),
(17, '/product_17.jpg', 1),
(18, '/product_18.jpg', 1),
(19, '/product_19.jpg', 1),
(20, '/product_20.jpg', 1),
(21, '/product_21.jpg', 1),
(22, '/product_22.jpg', 1),
(23, '/product_23.jpg', 1),
(24, '/product_24.jpg', 1),
(25, '/product_25.jpg', 1),
(26, '/product_26.jpg', 1),
(27, '/product_27.jpg', 1),
(28, '/product_28.jpg', 1),
(29, '/product_29.jpg', 1),
(30, '/product_30.jpg', 1),
(31, '/product_31.jpg', 1),
(32, '/product_32.jpg', 1),
(33, '/product_33.jpg', 1),
(34, '/product_34.jpg', 1),
(35, '/product_35.jpg', 1),
(36, '/product_36.jpg', 1),
(37, '/product_37.jpg', 1),
(38, '/product_38.jpg', 1),
(39, '/product_39.jpg', 1),
(40, '/product_40.jpg', 1),
(41, '/product_41.jpg', 1),
(42, '/product_42.jpg', 1),
(43, '/product_43.jpg', 1),
(44, '/product_44.jpg', 1),
(45, '/product_45.jpg', 1),
(46, '/product_46.jpg', 1),
(47, '/product_47.jpg', 1),
(48, '/product_48.jpg', 1),
(49, '/product_49.jpg', 1),
(50, '/product_50.jpg', 1),
(51, '/product_51.jpg', 1),
(52, '/product_52.jpg', 1),
(53, '/product_53.jpg', 1),
(54, '/product_54.jpg', 1),
(55, '/product_55.jpg', 1),
(56, '/product_56.jpg', 1),
(57, '/product_57.jpg', 1),
(58, '/product_58.jpg', 1),
(59, '/product_59.jpg', 1),
(60, '/product_60.jpg', 1),
(61, '/product_61.jpg', 1),
(62, '/product_62.jpg', 1),
(63, '/product_63.jpg', 1),
(64, '/product_64.jpg', 1),
(65, '/product_65.jpg', 1),
(66, '/product_66.jpg', 1),
(67, '/product_67.jpg', 1),
(68, '/product_68.jpg', 1),
(69, '/product_69.jpg', 1),
(70, '/product_70.jpg', 1),
(71, '/product_71.jpg', 1),
(72, '/product_72.jpg', 1),
(73, '/product_73.jpg', 1),
(74, '/product_74.jpg', 1),
(75, '/product_75.jpg', 1),
(76, '/product_76.jpg', 1),
(77, '/product_77.jpg', 1),
(78, '/product_78.jpg', 1),
(79, '/product_79.jpg', 1),
(80, '/product_80.jpg', 1),
(81, '/product_81.jpg', 1),
(82, '/product_82.jpg', 1),
(83, '/product_83.jpg', 1),
(84, '/product_84.jpg', 1),
(85, '/product_85.jpg', 1),
(86, '/product_86.jpg', 1),
(87, '/product_87.jpg', 1),
(88, '/product_88.jpg', 1),
(89, '/product_89.jpg', 1),
(90, '/product_90.jpg', 1),
(91, '/product_91.jpg', 1),
(92, '/product_92.jpg', 1),
(93, '/product_93.jpg', 1),
(94, '/product_94.jpg', 1),
(95, '/product_95.jpg', 1),
(96, '/product_96.jpg', 1),
(97, '/product_97.jpg', 1),
(98, '/product_98.jpg', 1),
(99, '/product_99.jpg', 1),
(100, '/product_100.jpg', 1),
(101, '/product_101.jpg', 1),
(102, '/product_102.jpg', 1),
(103, '/product_103.jpg', 1),
(104, '/product_104.jpg', 1),
(105, '/product_105.jpg', 1),
(106, '/product_106.jpg', 1),
(107, '/product_107.jpg', 1),
(108, '/product_108.jpg', 1),
(109, '/product_109.jpg', 1),
(110, '/product_110.jpg', 1),
(111, '/product_111.jpg', 1),
(112, '/product_112.jpg', 1),
(113, '/product_113.jpg', 1),
(114, '/product_114.jpg', 1),
(115, '/product_115.jpg', 1),
(116, '/product_116.jpg', 1),
(117, '/product_117.jpg', 1),
(118, '/product_118.jpg', 1),
(119, '/product_119.jpg', 1),
(120, '/product_120.jpg', 1),
(121, '/product_121.jpg', 1),
(122, '/product_122.jpg', 1),
(123, '/product_123.jpg', 1),
(124, '/product_124.jpg', 1),
(125, '/product_125.jpg', 1),
(126, '/product_126.jpg', 1),
(127, '/product_127.jpg', 1),
(128, '/product_128.jpg', 1),
(129, '/product_129.jpg', 1),
(130, '/product_130.jpg', 1),
(131, '/product_131.jpg', 1),
(132, '/product_132.jpg', 1),
(133, '/product_133.jpg', 1),
(134, '/product_134.jpg', 1),
(135, '/product_135.jpg', 1),
(136, '/product_136.jpg', 1),
(137, '/product_137.jpg', 1),
(138, '/product_138.jpg', 1),
(139, '/product_139.jpg', 1),
(140, '/product_140.jpg', 1),
(141, '/product_141.jpg', 1),
(142, '/product_142.jpg', 1),
(143, '/product_143.jpg', 1),
(144, '/product_144.jpg', 1),
(145, '/product_145.jpg', 1),
(146, '/product_146.jpg', 1),
(147, '/product_147.jpg', 1),
(148, '/product_148.jpg', 1),
(149, '/product_149.jpg', 1),
(150, '/product_150.jpg', 1),
(151, '/product_151.jpg', 1),
(152, '/product_152.jpg', 1),
(153, '/product_153.jpg', 1),
(154, '/product_154.jpg', 1),
(155, '/product_155.jpg', 1),
(156, '/product_156.jpg', 1),
(157, '/product_157.jpg', 1),
(158, '/product_158.jpg', 1),
(159, '/product_159.jpg', 1),
(160, '/product_160.jpg', 1),
(161, '/product_161.jpg', 1),
(162, '/product_162.jpg', 1),
(163, '/product_163.jpg', 1),
(164, '/product_164.jpg', 1),
(165, '/product_165.jpg', 1),
(166, '/product_166.jpg', 1),
(167, '/product_167.jpg', 1),
(168, '/product_168.jpg', 1),
(169, '/product_169.jpg', 1),
(170, '/product_170.jpg', 1),
(1, '/product_1_2.jpg', 1),
(2, '/product_2_2.jpg', 1),
(3, '/product_3_2.jpg', 1),
(4, '/product_4_2.jpg', 1),
(5, '/product_5_2.jpg', 1),
(6, '/product_6_2.jpg', 1),
(7, '/product_7_2.jpg', 1),
(8, '/product_8_2.jpg', 1),
(9, '/product_9_2.jpg', 1),
(10, '/product_10_2.jpg', 1),
(11, '/product_11_2.jpg', 1),
(12, '/product_12_2.jpg', 1),
(13, '/product_13_2.jpg', 1),
(14, '/product_14_2.jpg', 1),
(15, '/product_15_2.jpg', 1),
(16, '/product_16_2.jpg', 1),
(17, '/product_17_2.jpg', 1),
(18, '/product_18_2.jpg', 1),
(19, '/product_19_2.jpg', 1),
(20, '/product_20_2.jpg', 1),
(21, '/product_21_2.jpg', 1),
(22, '/product_22_2.jpg', 1),
(23, '/product_23_2.jpg', 1),
(24, '/product_24_2.jpg', 1),
(25, '/product_25_2.jpg', 1),
(26, '/product_26_2.jpg', 1),
(27, '/product_27_2.jpg', 1),
(28, '/product_28_2.jpg', 1),
(29, '/product_29_2.jpg', 1),
(30, '/product_30_2.jpg', 1),
(31, '/product_31_2.jpg', 1),
(32, '/product_32_2.jpg', 1),
(33, '/product_33_2.jpg', 1),
(34, '/product_34_2.jpg', 1),
(35, '/product_35_2.jpg', 1),
(36, '/product_36_2.jpg', 1),
(37, '/product_37_2.jpg', 1),
(38, '/product_38_2.jpg', 1),
(39, '/product_39_2.jpg', 1),
(40, '/product_40_2.jpg', 1),
(41, '/product_41_2.jpg', 1),
(42, '/product_42_2.jpg', 1),
(43, '/product_43_2.jpg', 1),
(44, '/product_44_2.jpg', 1),
(45, '/product_45_2.jpg', 1),
(46, '/product_46_2.jpg', 1),
(47, '/product_47_2.jpg', 1),
(48, '/product_48_2.jpg', 1),
(49, '/product_49_2.jpg', 1),
(50, '/product_50_2.jpg', 1),
(51, '/product_51_2.jpg', 1),
(52, '/product_52_2.jpg', 1),
(53, '/product_53_2.jpg', 1),
(54, '/product_54_2.jpg', 1),
(55, '/product_55_2.jpg', 1),
(56, '/product_56_2.jpg', 1),
(57, '/product_57_2.jpg', 1),
(58, '/product_58_2.jpg', 1),
(59, '/product_59_2.jpg', 1),
(60, '/product_60_2.jpg', 1),
(61, '/product_61_2.jpg', 1),
(62, '/product_62_2.jpg', 1),
(63, '/product_63_2.jpg', 1),
(64, '/product_64_2.jpg', 1),
(65, '/product_65_2.jpg', 1),
(66, '/product_66_2.jpg', 1),
(67, '/product_67_2.jpg', 1),
(68, '/product_68_2.jpg', 1),
(69, '/product_69_2.jpg', 1),
(70, '/product_70_2.jpg', 1),
(71, '/product_71_2.jpg', 1),
(72, '/product_72_2.jpg', 1),
(73, '/product_73_2.jpg', 1),
(74, '/product_74_2.jpg', 1),
(75, '/product_75_2.jpg', 1),
(76, '/product_76_2.jpg', 1),
(77, '/product_77_2.jpg', 1),
(78, '/product_78_2.jpg', 1),
(79, '/product_79_2.jpg', 1),
(80, '/product_80_2.jpg', 1),
(81, '/product_81_2.jpg', 1),
(82, '/product_82_2.jpg', 1),
(83, '/product_83_2.jpg', 1),
(84, '/product_84_2.jpg', 1),
(85, '/product_85_2.jpg', 1),
(86, '/product_86_2.jpg', 1),
(87, '/product_87_2.jpg', 1),
(88, '/product_88_2.jpg', 1),
(89, '/product_89_2.jpg', 1),
(90, '/product_90_2.jpg', 1),
(91, '/product_91_2.jpg', 1),
(92, '/product_92_2.jpg', 1),
(93, '/product_93_2.jpg', 1),
(94, '/product_94_2.jpg', 1),
(95, '/product_95_2.jpg', 1),
(96, '/product_96_2.jpg', 1),
(97, '/product_97_2.jpg', 1),
(98, '/product_98_2.jpg', 1),
(99, '/product_99_2.jpg', 1),
(100, '/product_100_2.jpg', 1),
(101, '/product_101_2.jpg', 1),
(102, '/product_102_2.jpg', 1),
(103, '/product_103_2.jpg', 1),
(104, '/product_104_2.jpg', 1),
(105, '/product_105_2.jpg', 1),
(106, '/product_106_2.jpg', 1),
(107, '/product_107_2.jpg', 1),
(108, '/product_108_2.jpg', 1),
(109, '/product_109_2.jpg', 1),
(110, '/product_110_2.jpg', 1),
(111, '/product_111_2.jpg', 1),
(112, '/product_112_2.jpg', 1),
(113, '/product_113_2.jpg', 1),
(114, '/product_114_2.jpg', 1),
(115, '/product_115_2.jpg', 1),
(116, '/product_116_2.jpg', 1),
(117, '/product_117_2.jpg', 1),
(118, '/product_118_2.jpg', 1),
(119, '/product_119_2.jpg', 1),
(120, '/product_120_2.jpg', 1),
(121, '/product_121_2.jpg', 1),
(122, '/product_122_2.jpg', 1),
(123, '/product_123_2.jpg', 1),
(124, '/product_124_2.jpg', 1),
(125, '/product_125_2.jpg', 1),
(126, '/product_126_2.jpg', 1),
(127, '/product_127_2.jpg', 1),
(128, '/product_128_2.jpg', 1),
(129, '/product_129_2.jpg', 1),
(130, '/product_130_2.jpg', 1),
(131, '/product_131_2.jpg', 1),
(132, '/product_132_2.jpg', 1),
(133, '/product_133_2.jpg', 1),
(134, '/product_134_2.jpg', 1),
(135, '/product_135_2.jpg', 1),
(136, '/product_136_2.jpg', 1),
(137, '/product_137_2.jpg', 1),
(138, '/product_138_2.jpg', 1),
(139, '/product_139_2.jpg', 1),
(140, '/product_140_2.jpg', 1),
(141, '/product_141_2.jpg', 1),
(142, '/product_142_2.jpg', 1),
(143, '/product_143_2.jpg', 1),
(144, '/product_144_2.jpg', 1),
(145, '/product_145_2.jpg', 1),
(146, '/product_146_2.jpg', 1),
(147, '/product_147_2.jpg', 1),
(148, '/product_148_2.jpg', 1),
(149, '/product_149_2.jpg', 1),
(150, '/product_150_2.jpg', 1),
(151, '/product_151_2.jpg', 1),
(152, '/product_152_2.jpg', 1),
(153, '/product_153_2.jpg', 1),
(154, '/product_154_2.jpg', 1),
(155, '/product_155_2.jpg', 1),
(156, '/product_156_2.jpg', 1),
(157, '/product_157_2.jpg', 1),
(158, '/product_158_2.jpg', 1),
(159, '/product_159_2.jpg', 1),
(160, '/product_160_2.jpg', 1),
(161, '/product_161_2.jpg', 1),
(162, '/product_162_2.jpg', 1),
(163, '/product_163_2.jpg', 1),
(164, '/product_164_2.jpg', 1),
(165, '/product_165_2.jpg', 1),
(166, '/product_166_2.jpg', 1),
(167, '/product_167_2.jpg', 1),
(168, '/product_168_2.jpg', 1),
(169, '/product_169_2.jpg', 1),
(170, '/product_170_2.jpg', 1);

-- ======================================================
-- 为商品 1~30 各添加 3 条额外规格变体（确保每个商品至少有 4 条 SKU）
-- ======================================================

INSERT INTO `product_skus` (`product_id`, `attrs`, `price`, `stock`) VALUES

-- 1. iPhone 15 Pro 128G
(1, '{"容量":"256GB","颜色":"原色钛金属"}', 8999.00, 80),
(1, '{"容量":"512GB","颜色":"白色钛金属"}', 10999.00, 50),
(1, '{"容量":"1TB","颜色":"黑色钛金属"}', 12999.00, 30),

-- 2. iPhone 15 128G
(2, '{"容量":"256GB","颜色":"粉色"}', 6999.00, 70),
(2, '{"容量":"512GB","颜色":"绿色"}', 8999.00, 40),
(2, '{"容量":"128GB","颜色":"黄色"}', 5999.00, 60),

-- 3. Xiaomi 14 Pro 12+256G
(3, '{"内存":"16GB","存储":"512GB","颜色":"黑色"}', 5599.00, 80),
(3, '{"内存":"16GB","存储":"1TB","颜色":"白色"}', 6599.00, 50),
(3, '{"内存":"12GB","存储":"256GB","颜色":"青色"}', 4999.00, 100),

-- 4. Redmi K70 12+256G
(4, '{"内存":"16GB","存储":"512GB","颜色":"黑色"}', 2799.00, 120),
(4, '{"内存":"12GB","存储":"256GB","颜色":"白色"}', 2299.00, 150),
(4, '{"内存":"8GB","存储":"128GB","颜色":"蓝色"}', 1899.00, 200),

-- 5. HUAWEI Mate X5
(5, '{"内存":"16GB","存储":"512GB","颜色":"羽砂黑"}', 14999.00, 30),
(5, '{"内存":"16GB","存储":"1TB","颜色":"青山黛"}', 16999.00, 20),
(5, '{"内存":"12GB","存储":"256GB","颜色":"星河蓝"}', 12999.00, 40),

-- 6. OPPO Find N3
(6, '{"内存":"16GB","存储":"512GB","颜色":"赤壁丹霞"}', 10999.00, 30),
(6, '{"内存":"16GB","存储":"1TB","颜色":"千山绿"}', 11999.00, 20),
(6, '{"内存":"12GB","存储":"256GB","颜色":"月海银"}', 9999.00, 50),

-- 7. MagSafe 原装充电器
(7, '{"套装":"含1米线"}', 329.00, 300),
(7, '{"套装":"含2米线"}', 399.00, 200),
(7, '{"颜色":"午夜色"}', 329.00, 250),

-- 8. Type-C 充电线 1m
(8, '{"长度":"2m","颜色":"黑色"}', 49.00, 600),
(8, '{"长度":"1.5m","颜色":"白色"}', 39.00, 800),
(8, '{"材质":"编织线","长度":"1m"}', 59.00, 400),

-- 9. 荣耀 Magic6 Pro
(9, '{"内存":"16GB","存储":"512GB","颜色":"绒黑色"}', 7499.00, 60),
(9, '{"内存":"16GB","存储":"1TB","颜色":"祁连雪"}', 8499.00, 40),
(9, '{"内存":"12GB","存储":"256GB","颜色":"麦浪绿"}', 6499.00, 80),

-- 10. realme GT Neo
(10, '{"内存":"12GB","存储":"256GB","颜色":"勒芒"}', 2299.00, 100),
(10, '{"内存":"16GB","存储":"512GB","颜色":"银石"}', 2699.00, 80),
(10, '{"内存":"8GB","存储":"128GB","颜色":"黑薄荷"}', 1999.00, 150),

-- 11. vivo X100
(11, '{"内存":"16GB","存储":"512GB","颜色":"星迹蓝"}', 5899.00, 70),
(11, '{"内存":"16GB","存储":"1TB","颜色":"落日橙"}', 6599.00, 50),
(11, '{"内存":"12GB","存储":"256GB","颜色":"白月光"}', 5299.00, 100),

-- 12. 一加 Ace
(12, '{"内存":"16GB","存储":"512GB","颜色":"回响"}', 2799.00, 120),
(12, '{"内存":"12GB","存储":"256GB","颜色":"冰河蓝"}', 2399.00, 150),
(12, '{"内存":"8GB","存储":"128GB","颜色":"黑森"}', 1999.00, 200),

-- 13. 小米折叠屏 Mix Fold
(13, '{"内存":"16GB","存储":"512GB","颜色":"月影黑"}', 8999.00, 40),
(13, '{"内存":"16GB","存储":"1TB","颜色":"星耀金"}', 9999.00, 30),
(13, '{"内存":"12GB","存储":"256GB","颜色":"陶瓷白"}', 7999.00, 50),

-- 14. 三星 Galaxy Z Fold
(14, '{"内存":"16GB","存储":"512GB","颜色":"幻影黑"}', 13999.00, 25),
(14, '{"内存":"16GB","存储":"1TB","颜色":"冰萃蓝"}', 15999.00, 15),
(14, '{"内存":"12GB","存储":"256GB","颜色":"浅粉色"}', 12999.00, 30),

-- 15. 苹果 原装耳机 Type-C
(15, '{"版本":"MagSafe充电盒"}', 199.00, 300),
(15, '{"颜色":"白色","版本":"有线充电盒"}', 149.00, 400),
(15, '{"版本":"无线充电盒"}', 179.00, 250),

-- 16. Anker 65W 氮化镓充电器
(16, '{"功率":"100W","接口":"2C1A","颜色":"白色"}', 299.00, 150),
(16, '{"功率":"65W","接口":"2C","颜色":"黑色"}', 199.00, 200),
(16, '{"功率":"30W","接口":"1C","颜色":"蓝色"}', 129.00, 300),

-- 17. iQOO 12
(17, '{"内存":"16GB","存储":"512GB","颜色":"传奇版"}', 4699.00, 90),
(17, '{"内存":"16GB","存储":"1TB","颜色":"赛道版"}', 5199.00, 60),
(17, '{"内存":"12GB","存储":"256GB","颜色":"燃途"}', 4199.00, 120),

-- 18. Redmi Note 13
(18, '{"内存":"8GB","存储":"256GB","颜色":"星沙白"}', 1499.00, 400),
(18, '{"内存":"12GB","存储":"512GB","颜色":"子夜黑"}', 1799.00, 300),
(18, '{"内存":"6GB","存储":"128GB","颜色":"时光蓝"}', 1199.00, 500),

-- 19. 荣耀 X50
(19, '{"内存":"12GB","存储":"256GB","颜色":"雨后初晴"}', 1899.00, 250),
(19, '{"内存":"16GB","存储":"512GB","颜色":"典雅黑"}', 2199.00, 180),
(19, '{"内存":"8GB","存储":"128GB","颜色":"燃橙色"}', 1599.00, 300),

-- 20. OPPO Reno 旗舰版
(20, '{"内存":"16GB","存储":"512GB","颜色":"暮光紫"}', 5199.00, 80),
(20, '{"内存":"16GB","存储":"1TB","颜色":"月海银"}', 5899.00, 60),
(20, '{"内存":"12GB","存储":"256GB","颜色":"星钻黑"}', 4599.00, 100),

-- 21. MacBook Air 13 M3 16G
(21, '{"内存":"16GB","硬盘":"512GB","颜色":"银色"}', 10999.00, 40),
(21, '{"内存":"24GB","硬盘":"1TB","颜色":"深空灰"}', 13999.00, 25),
(21, '{"内存":"8GB","硬盘":"256GB","颜色":"午夜色"}', 8999.00, 30),

-- 22. ThinkPad X1 Carbon
(22, '{"内存":"16GB","硬盘":"512GB","颜色":"黑色"}', 12999.00, 20),
(22, '{"内存":"32GB","硬盘":"1TB","颜色":"灰色"}', 16999.00, 10),
(22, '{"内存":"8GB","硬盘":"256GB","颜色":"黑色"}', 10999.00, 25),

-- 23. ROG 枪神 笔记本
(23, '{"内存":"32GB","显卡":"RTX 4080","硬盘":"1TB"}', 18999.00, 15),
(23, '{"内存":"64GB","显卡":"RTX 4090","硬盘":"2TB"}', 26999.00, 5),
(23, '{"内存":"16GB","显卡":"RTX 4070","硬盘":"512GB"}', 14999.00, 20),

-- 24. 联想 拯救者 Y7000
(24, '{"内存":"16GB","显卡":"RTX 4060","硬盘":"1TB"}', 7999.00, 40),
(24, '{"内存":"32GB","显卡":"RTX 4070","硬盘":"1TB"}', 9499.00, 30),
(24, '{"内存":"8GB","显卡":"RTX 3050","硬盘":"512GB"}', 6299.00, 50),

-- 25. Dell U2723QE 27" 4K
(25, '{"尺寸":"27英寸","套装":"带USB-C线"}', 3999.00, 20),
(25, '{"尺寸":"32英寸","型号":"U3223QE"}', 5999.00, 15),
(25, '{"尺寸":"27英寸","颜色":"银色"}', 3999.00, 25),

-- 26. LG 34WP65C 34" 曲面
(26, '{"尺寸":"34英寸","曲率":"1800R"}', 3299.00, 15),
(26, '{"尺寸":"40英寸","曲率":"1800R"}', 4999.00, 10),
(26, '{"尺寸":"34英寸","颜色":"黑色"}', 3299.00, 20),

-- 27. 罗技 MX Master 3s
(27, '{"颜色":"石墨灰"}', 599.00, 120),
(27, '{"颜色":"白色"}', 599.00, 100),
(27, '{"颜色":"粉色"}', 599.00, 80),

-- 28. Keychron K2 键盘
(28, '{"轴体":"红轴","键帽":"白色"}', 499.00, 70),
(28, '{"轴体":"茶轴","键帽":"黑色"}', 499.00, 80),
(28, '{"轴体":"青轴","键帽":"RGB背光"}', 549.00, 60),

-- 29. 华为 MateBook X
(29, '{"内存":"16GB","硬盘":"1TB","颜色":"深空灰"}', 8999.00, 30),
(29, '{"内存":"32GB","硬盘":"1TB","颜色":"皓月银"}', 9999.00, 20),
(29, '{"内存":"16GB","硬盘":"512GB","颜色":"樱语粉"}', 7999.00, 25),

-- 30. 小米 Pro 16
(30, '{"内存":"16GB","硬盘":"1TB","显卡":"集显"}', 6499.00, 40),
(30, '{"内存":"32GB","硬盘":"1TB","显卡":"RTX 3050"}', 7999.00, 30),
(30, '{"内存":"16GB","硬盘":"512GB","颜色":"灰色"}', 5999.00, 50),



-- 31. 雷神 911（游戏本）
(31, '{"内存":"16GB","显卡":"RTX 4060","硬盘":"512GB"}', 6299.00, 40),
(31, '{"内存":"32GB","显卡":"RTX 4070","硬盘":"1TB"}', 7999.00, 20),
(31, '{"内存":"8GB","显卡":"RTX 3050","硬盘":"512GB"}', 5699.00, 50),

-- 32. 外星人 m15（旗舰电竞）
(32, '{"内存":"32GB","显卡":"RTX 4080","硬盘":"1TB"}', 19999.00, 10),
(32, '{"内存":"64GB","显卡":"RTX 4090","硬盘":"2TB"}', 25999.00, 5),
(32, '{"内存":"16GB","显卡":"RTX 4070","硬盘":"512GB"}', 17999.00, 15),

-- 33. 明基 PD2705U 4K（设计师显示器）
(33, '{"尺寸":"27英寸","颜色":"灰色","接口":"Type-C"}', 2999.00, 20),
(33, '{"尺寸":"32英寸","型号":"PD3205U"}', 4599.00, 10),
(33, '{"套装":"带遮光罩","尺寸":"27英寸"}', 3299.00, 15),

-- 34. 群晖 NAS DS220+（存储）
(34, '{"硬盘位":"2盘位","标配":"无硬盘"}', 2999.00, 30),
(34, '{"套装":"含4TB红盘×2"}', 4499.00, 20),
(34, '{"内存":"升级6GB","硬盘位":"2盘位"}', 3199.00, 15),

-- 35. 海盗船 K70 键盘（外设）
(35, '{"轴体":"樱桃红轴","颜色":"黑色"}', 899.00, 50),
(35, '{"轴体":"樱桃银轴","RGB背光"}', 999.00, 40),
(35, '{"轴体":"樱桃青轴","白色版"}', 899.00, 30),

-- 36. 罗技 G Pro X Superlight（电竞鼠标）
(36, '{"颜色":"黑色","重量":"63g"}', 899.00, 60),
(36, '{"颜色":"白色","重量":"63g"}', 899.00, 50),
(36, '{"颜色":"粉色","限量版"}', 999.00, 20),

-- 37. 惠普 星14（轻薄本）
(37, '{"内存":"16GB","硬盘":"512GB","颜色":"银色"}', 4999.00, 60),
(37, '{"内存":"8GB","硬盘":"256GB","颜色":"金色"}', 4499.00, 80),
(37, '{"内存":"16GB","硬盘":"1TB","颜色":"粉色"}', 5499.00, 40),

-- 38. 微星 GF66（游戏本）
(38, '{"内存":"16GB","显卡":"RTX 3060","硬盘":"512GB"}', 6499.00, 50),
(38, '{"内存":"32GB","显卡":"RTX 3070","硬盘":"1TB"}', 7999.00, 30),
(38, '{"内存":"8GB","显卡":"GTX 1650","硬盘":"512GB"}', 5699.00, 60),

-- 39. AOC 27G2 144Hz（电竞显示器）
(39, '{"尺寸":"27英寸","刷新率":"144Hz","颜色":"黑色"}', 1299.00, 80),
(39, '{"尺寸":"24英寸","刷新率":"165Hz","颜色":"黑色"}', 999.00, 100),
(39, '{"尺寸":"27英寸","刷新率":"240Hz","颜色":"红色"}', 1699.00, 40),

-- 40. 雷蛇 黑寡妇（键盘）
(40, '{"轴体":"绿轴","RGB背光","颜色":"黑色"}', 799.00, 50),
(40, '{"轴体":"黄轴","RGB背光","颜色":"白色"}', 799.00, 40),
(40, '{"轴体":"橙轴","无背光","颜色":"黑色"}', 699.00, 60),



-- 41. 海尔 纤诺 洗衣机
(41, '{"容量":"10kg","颜色":"银色","能效":"一级"}', 3499.00, 30),
(41, '{"容量":"12kg","颜色":"白色","能效":"一级"}', 3999.00, 20),
(41, '{"型号":"纤诺尊享版","颜色":"金色"}', 4299.00, 15),

-- 42. 美的 风冷 冰箱
(42, '{"容量":"456L","颜色":"灰色","门体":"十字对开"}', 4899.00, 25),
(42, '{"容量":"510L","颜色":"银色","门体":"对开"}', 5599.00, 20),
(42, '{"容量":"400L","颜色":"白色","门体":"三门"}', 4299.00, 30),

-- 43. 戴森 V12 吸尘器
(43, '{"版本":"全配件版","颜色":"金色"}', 4599.00, 20),
(43, '{"版本":"宠物版","颜色":"紫色"}', 4199.00, 25),
(43, '{"版本":"标准版","颜色":"红色"}', 3999.00, 30),

-- 44. 石头 扫拖机器人
(44, '{"型号":"G10S","集尘":"自动"}', 3999.00, 30),
(44, '{"型号":"T8 Plus","集尘":"手动"}', 2599.00, 40),
(44, '{"型号":"G20","集尘":"自动","水箱":"热风烘干"}', 4999.00, 20),

-- 45. 苏泊尔 炒锅
(45, '{"直径":"30cm","材质":"不粘","颜色":"黑色"}', 399.00, 150),
(45, '{"直径":"32cm","材质":"不锈钢","颜色":"银"}', 499.00, 120),
(45, '{"套装":"炒锅+锅盖","直径":"30cm"}', 449.00, 100),

-- 46. 九阳 破壁机
(46, '{"容量":"1.2L","颜色":"白色","功能":"冷热双打"}', 899.00, 100),
(46, '{"容量":"1.5L","颜色":"灰色","功能":"自动清洗"}', 1099.00, 80),
(46, '{"容量":"1L","颜色":"粉色","功能":"迷你版"}', 699.00, 120),

-- 47. 飞科 电动牙刷
(47, '{"型号":"FT7105","颜色":"白色","刷头":"2支"}', 199.00, 200),
(47, '{"型号":"FT7106","颜色":"黑色","刷头":"4支"}', 249.00, 150),
(47, '{"型号":"FT7108","颜色":"粉色","刷头":"2支","模式":"5档"}', 299.00, 100),

-- 48. 飞利浦 电吹风
(48, '{"功率":"1800W","颜色":"白色","负离子":"有"}', 299.00, 150),
(48, '{"功率":"2200W","颜色":"黑色","负离子":"有","风嘴":"集风嘴"}', 399.00, 100),
(48, '{"功率":"1600W","颜色":"粉色","负离子":"无"}', 249.00, 180),

-- 49. 格力 空调 1.5P
(49, '{"匹数":"1.5P","能效":"新一级","颜色":"白色"}', 3899.00, 20),
(49, '{"匹数":"2P","能效":"一级","颜色":"金色"}', 4899.00, 15),
(49, '{"匹数":"1P","能效":"三级","颜色":"白色"}', 3299.00, 25),

-- 50. 小米 空气净化器
(50, '{"型号":"4 Pro","适用面积":"45㎡","颜色":"白色"}', 999.00, 80),
(50, '{"型号":"4 Lite","适用面积":"35㎡","颜色":"白色"}', 699.00, 100),
(50, '{"型号":"4 Max","适用面积":"80㎡","颜色":"白色"}', 1499.00, 50),

-- 51. 美的 洗碗机
(51, '{"容量":"13套","安装方式":"嵌入式","颜色":"黑色"}', 3999.00, 20),
(51, '{"容量":"10套","安装方式":"台式","颜色":"白色"}', 3299.00, 30),
(51, '{"容量":"15套","安装方式":"独立式","颜色":"银色"}', 4599.00, 15),

-- 52. 松下 电动剃须刀
(52, '{"型号":"ES-LV74","刀头":"5刀头","颜色":"黑色"}', 599.00, 120),
(52, '{"型号":"ES-LV9C","刀头":"6刀头","颜色":"金色"}', 899.00, 80),
(52, '{"型号":"ES-RT34","刀头":"3刀头","颜色":"蓝色"}', 399.00, 150),

-- 53. 添可 吸拖一体机
(53, '{"型号":"Floor One S5","水箱":"0.8L","颜色":"白色"}', 2899.00, 30),
(53, '{"型号":"Floor One S7","水箱":"1.0L","颜色":"黑色"}', 3499.00, 20),
(53, '{"型号":"Floor One S3","水箱":"0.6L","颜色":"灰色"}', 2499.00, 40),

-- 54. 苏泊尔 电饭煲
(54, '{"容量":"4L","内胆":"球釜","颜色":"金色"}', 499.00, 100),
(54, '{"容量":"5L","内胆":"球釜","颜色":"黑色"}', 599.00, 80),
(54, '{"容量":"3L","内胆":"不粘","颜色":"白色"}', 399.00, 120),

-- 55. 美的 干衣机
(55, '{"容量":"9kg","烘干方式":"热泵","颜色":"白色"}', 3299.00, 15),
(55, '{"容量":"10kg","烘干方式":"热泵","颜色":"银色"}', 3799.00, 10),
(55, '{"容量":"7kg","烘干方式":"排气式","颜色":"灰色"}', 2499.00, 20),

-- 56. 莱克 吸尘器
(56, '{"型号":"M10","功率":"350W","颜色":"蓝色"}', 1299.00, 40),
(56, '{"型号":"M12","功率":"450W","颜色":"红色"}', 1699.00, 30),
(56, '{"型号":"M8","功率":"250W","颜色":"白色"}', 999.00, 50),

-- 57. 小熊 榨汁机
(57, '{"容量":"0.6L","颜色":"黄色","功能":"榨汁+搅拌"}', 199.00, 200),
(57, '{"容量":"1L","颜色":"绿色","功能":"原汁机"}', 299.00, 150),
(57, '{"容量":"0.4L","颜色":"粉色","功能":"便携"}', 149.00, 250),

-- 58. 飞科 理发器
(58, '{"型号":"FC5808","颜色":"黑色","限位梳":"4个"}', 129.00, 200),
(58, '{"型号":"FC5908","颜色":"白色","限位梳":"6个"}', 169.00, 150),
(58, '{"型号":"FC5708","颜色":"银色","限位梳":"3个","续航":"90分钟"}', 199.00, 100),

-- 59. 博朗 牙刷
(59, '{"型号":"D100","颜色":"白色","刷头":"1支"}', 399.00, 80),
(59, '{"型号":"D300","颜色":"黑色","刷头":"2支","模式":"3种"}', 599.00, 60),
(59, '{"型号":"D500","颜色":"粉色","刷头":"2支","模式":"5种"}', 799.00, 40),

-- 60. 云鲸 扫拖机器人
(60, '{"型号":"J2","自动换水":"否","颜色":"白色"}', 3999.00, 15),
(60, '{"型号":"J3","自动换水":"是","颜色":"白色"}', 4599.00, 10),
(60, '{"型号":"J1","自动换水":"否","颜色":"黑色"}', 2999.00, 20),


-- 61. 索尼 WH-1000XM5
(61, '{"颜色":"黑色","版本":"标准版"}', 2599.00, 40),
(61, '{"颜色":"铂金银","版本":"商务版"}', 2699.00, 30),
(61, '{"颜色":"蓝色","版本":"限量版"}', 2799.00, 20),

-- 62. AirPods Pro 2
(62, '{"颜色":"白色","充电盒":"MagSafe"}', 1999.00, 60),
(62, '{"颜色":"白色","充电盒":"USB-C"}', 1899.00, 70),
(62, '{"刻字":"个性化","充电盒":"无线"}', 2099.00, 30),

-- 63. JBL Live Pro
(63, '{"颜色":"黑色","降噪":"主动"}', 799.00, 80),
(63, '{"颜色":"白色","降噪":"主动"}', 799.00, 70),
(63, '{"颜色":"蓝色","降噪":"被动"}', 699.00, 60),

-- 64. Anker 65W 充电器
(64, '{"功率":"65W","接口":"2C1A","颜色":"白色"}', 199.00, 200),
(64, '{"功率":"100W","接口":"3C1A","颜色":"黑色"}', 299.00, 150),
(64, '{"功率":"30W","接口":"1C","颜色":"蓝色"}', 129.00, 250),

-- 65. 倍思 充电宝 20000mAh
(65, '{"容量":"20000mAh","颜色":"黑色","快充":"22.5W"}', 169.00, 300),
(65, '{"容量":"30000mAh","颜色":"白色","快充":"65W"}', 249.00, 200),
(65, '{"容量":"10000mAh","颜色":"粉色","快充":"18W"}', 99.00, 400),

-- 66. 闪迪 至尊高速 128G
(66, '{"容量":"128GB","读取速度":"120MB/s"}', 129.00, 400),
(66, '{"容量":"256GB","读取速度":"150MB/s"}', 199.00, 300),
(66, '{"容量":"64GB","读取速度":"100MB/s"}', 89.00, 500),

-- 67. 三星 EVO 256G
(67, '{"容量":"256GB","速度":"U3","颜色":"红色"}', 299.00, 200),
(67, '{"容量":"512GB","速度":"U3","颜色":"蓝色"}', 499.00, 150),
(67, '{"容量":"128GB","速度":"U1","颜色":"白色"}', 199.00, 250),

-- 68. Apple Watch SE
(68, '{"尺寸":"40mm","颜色":"银色","表带":"运动"}', 2199.00, 50),
(68, '{"尺寸":"44mm","颜色":"深空灰","表带":"尼龙"}', 2399.00, 40),
(68, '{"尺寸":"40mm","颜色":"金色","表带":"皮质"}', 2299.00, 30),

-- 69. 华为 Watch 4
(69, '{"尺寸":"46mm","颜色":"黑色","表带":"氟橡胶"}', 2499.00, 50),
(69, '{"尺寸":"46mm","颜色":"棕色","表带":"真皮"}', 2599.00, 40),
(69, '{"尺寸":"46mm","颜色":"钛银","表带":"金属"}', 2799.00, 30),

-- 70. 小米 手环 8 Pro
(70, '{"颜色":"黑色","表带":"硅胶"}', 399.00, 400),
(70, '{"颜色":"白色","表带":"编织"}', 399.00, 350),
(70, '{"颜色":"粉色","表带":"皮质"}', 429.00, 300),

-- 71. 索尼 LinkBuds
(71, '{"颜色":"白色","形态":"开放式"}', 1199.00, 60),
(71, '{"颜色":"黑色","形态":"开放式"}', 1199.00, 50),
(71, '{"颜色":"灰色","形态":"开放式","降噪":"无"}', 1099.00, 40),

-- 72. 绿联 氮化镓 100W
(72, '{"功率":"100W","接口":"4C","颜色":"黑色"}', 299.00, 100),
(72, '{"功率":"65W","接口":"2C1A","颜色":"白色"}', 199.00, 150),
(72, '{"功率":"140W","接口":"3C1A","颜色":"灰色"}', 399.00, 80),

-- 73. 西数 SSD 1TB
(73, '{"容量":"1TB","接口":"NVMe","速度":"3500MB/s"}', 599.00, 60),
(73, '{"容量":"2TB","接口":"NVMe","速度":"3500MB/s"}', 999.00, 40),
(73, '{"容量":"500GB","接口":"SATA","速度":"560MB/s"}', 399.00, 80),

-- 74. 东芝 U盘 128G
(74, '{"容量":"128GB","接口":"USB3.0","颜色":"白色"}', 79.00, 600),
(74, '{"容量":"256GB","接口":"USB3.2","颜色":"黑色"}', 129.00, 400),
(74, '{"容量":"64GB","接口":"USB3.0","颜色":"红色"}', 49.00, 800),

-- 75. 佳明 Forerunner
(75, '{"型号":"255","尺寸":"42mm","颜色":"黑色"}', 2599.00, 30),
(75, '{"型号":"265","尺寸":"46mm","颜色":"白色"}', 2999.00, 20),
(75, '{"型号":"955","尺寸":"47mm","颜色":"太阳能版"}', 3999.00, 15),

-- 76. Beats Studio Buds
(76, '{"颜色":"黑色","降噪":"主动"}', 1099.00, 80),
(76, '{"颜色":"白色","降噪":"主动"}', 1099.00, 70),
(76, '{"颜色":"红色","降噪":"主动"}', 1099.00, 60),

-- 77. 南孚 充电套装
(77, '{"规格":"5号×4","充电器":"智能"}', 129.00, 250),
(77, '{"规格":"7号×4","充电器":"普通"}', 99.00, 300),
(77, '{"规格":"混合装(5号+7号)","充电器":"快充"}', 159.00, 200),

-- 78. 海康 TF 256G
(78, '{"容量":"256GB","速度":"C10","适用":"监控"}', 169.00, 350),
(78, '{"容量":"128GB","速度":"U3","适用":"手机"}', 99.00, 400),
(78, '{"容量":"512GB","速度":"U3","适用":"行车记录仪"}', 299.00, 200),

-- 79. OPPO Watch
(79, '{"尺寸":"41mm","颜色":"黑色","表带":"硅胶"}', 1299.00, 60),
(79, '{"尺寸":"46mm","颜色":"银色","表带":"皮质"}', 1499.00, 50),
(79, '{"尺寸":"41mm","颜色":"粉色","表带":"编织"}', 1299.00, 40),

-- 80. 索尼 WF-1000XM5
(80, '{"颜色":"黑色","降噪":"旗舰"}', 1699.00, 50),
(80, '{"颜色":"铂金银","降噪":"旗舰"}', 1699.00, 40),
(80, '{"颜色":"蓝色","降噪":"旗舰","无线充":"支持"}', 1799.00, 30),

-- 81. 抽屉式收纳盒
(81, '{"尺寸":"小号","颜色":"白色","材质":"塑料"}', 69.00, 400),
(81, '{"尺寸":"中号","颜色":"灰色","材质":"塑料"}', 89.00, 350),
(81, '{"尺寸":"大号","颜色":"透明","材质":"PP"}', 109.00, 300),

-- 82. 衣物整理箱
(82, '{"容量":"30L","颜色":"蓝色","折叠":"可折叠"}', 89.00, 350),
(82, '{"容量":"50L","颜色":"灰色","折叠":"不可折叠"}', 119.00, 300),
(82, '{"容量":"100L","颜色":"白色","带轮"}', 159.00, 250),

-- 83. 北欧风抱枕
(83, '{"颜色":"灰色","形状":"方形","填充":"PP棉"}', 49.00, 500),
(83, '{"颜色":"蓝色","形状":"圆形","填充":"羽绒"}', 69.00, 400),
(83, '{"颜色":"粉色","形状":"方形","填充":"记忆棉"}', 59.00, 450),

-- 84. 落地台灯
(84, '{"颜色":"黑色","高度":"150cm","调光":"三档"}', 199.00, 150),
(84, '{"颜色":"白色","高度":"120cm","调光":"无极"}', 179.00, 180),
(84, '{"颜色":"金色","高度":"150cm","调光":"遥控"}', 249.00, 120),

-- 85. 晨光 中性笔 12支
(85, '{"颜色":"黑色","笔尖":"0.5mm","包装":"12支盒装"}', 19.90, 800),
(85, '{"颜色":"红色","笔尖":"0.38mm","包装":"12支盒装"}', 19.90, 750),
(85, '{"颜色":"蓝色","笔尖":"0.7mm","包装":"12支盒装"}', 19.90, 700),

-- 86. 得力 活页本
(86, '{"尺寸":"A5","颜色":"黑色","页数":"80页"}', 29.90, 600),
(86, '{"尺寸":"B5","颜色":"蓝色","页数":"100页"}', 39.90, 500),
(86, '{"尺寸":"A4","颜色":"白色","页数":"120页"}', 49.90, 400),

-- 87. 厨房纸巾 6卷
(87, '{"规格":"6卷装","层数":"2层","吸水":"强"}', 19.90, 700),
(87, '{"规格":"12卷装","层数":"3层","吸水":"超强"}', 35.90, 500),
(87, '{"规格":"6卷装","层数":"3层","加厚"}', 24.90, 600),

-- 88. 一次性手套 100只
(88, '{"材质":"PE","尺寸":"均码","数量":"100只"}', 14.90, 1000),
(88, '{"材质":"TPE","尺寸":"L码","数量":"200只"}', 29.90, 800),
(88, '{"材质":"丁腈","尺寸":"M码","数量":"100只","加厚"}', 24.90, 600),

-- 89. 多功能置物架
(89, '{"层数":"3层","颜色":"黑色","材质":"碳钢"}', 129.00, 250),
(89, '{"层数":"4层","颜色":"白色","材质":"不锈钢"}', 159.00, 200),
(89, '{"层数":"2层","颜色":"银色","带挂钩"}', 99.00, 300),

-- 90. 密封保鲜盒
(90, '{"容量":"500ml","颜色":"透明","材质":"玻璃"}', 39.90, 600),
(90, '{"容量":"1L","颜色":"蓝色","材质":"塑料"}', 49.90, 500),
(90, '{"容量":"2L","颜色":"红色","材质":"玻璃"}', 69.90, 400),

-- 91. 梳齿书签套装
(91, '{"材质":"金属","颜色":"金色","数量":"3枚"}', 9.90, 800),
(91, '{"材质":"木质","颜色":"原木","数量":"5枚"}', 12.90, 700),
(91, '{"材质":"塑料","颜色":"彩色","数量":"10枚"}', 15.90, 600),

-- 92. 抽绳垃圾袋 3卷
(92, '{"容量":"45L","数量":"3卷45只","颜色":"黑色"}', 12.90, 1200),
(92, '{"容量":"60L","数量":"3卷45只","颜色":"灰色"}', 15.90, 1000),
(92, '{"容量":"30L","数量":"5卷75只","颜色":"白色"}', 18.90, 1100),

-- 93. 懒人抹布
(93, '{"材质":"无纺布","数量":"50片","规格":"干湿两用"}', 9.90, 1300),
(93, '{"材质":"木浆棉","数量":"30片","加厚"}', 14.90, 1000),
(93, '{"材质":"竹纤维","数量":"40片","可水洗"}', 19.90, 900),

-- 94. 墙面置物袋
(94, '{"颜色":"米色","尺寸":"30cm","无痕钉"}', 29.90, 500),
(94, '{"颜色":"灰色","尺寸":"40cm","挂钩式"}', 39.90, 450),
(94, '{"颜色":"蓝色","尺寸":"50cm","吸盘式"}', 49.90, 400),

-- 95. 防滑衣架 20只
(95, '{"颜色":"彩色","材质":"塑料","防滑":"硅胶"}', 19.90, 1000),
(95, '{"颜色":"白色","材质":"不锈钢","防滑":"凹槽"}', 29.90, 800),
(95, '{"颜色":"黑色","材质":"植绒","防滑":"绒毛"}', 24.90, 900),

-- 96. 极简闹钟
(96, '{"颜色":"白色","显示":"数字","供电":"电池"}', 49.90, 400),
(96, '{"颜色":"黑色","显示":"指针","供电":"电池"}', 39.90, 450),
(96, '{"颜色":"粉色","显示":"数字","供电":"USB"}', 59.90, 350),

-- 97. 高光修正带
(97, '{"宽度":"5mm","长度":"6m","颜色":"白色"}', 6.90, 900),
(97, '{"宽度":"6mm","长度":"8m","颜色":"蓝色"}', 8.90, 800),
(97, '{"宽度":"4mm","长度":"10m","颜色":"粉色"}', 9.90, 700),

-- 98. 擦窗器
(98, '{"类型":"双面磁性","适用厚度":"≤20mm","颜色":"蓝色"}', 39.90, 350),
(98, '{"类型":"伸缩杆","长度":"2m","颜色":"银色"}', 59.90, 300),
(98, '{"类型":"电动","充电式","适用玻璃"}', 129.90, 200),

-- 99. 桌面理线器
(99, '{"颜色":"黑色","数量":"5个","背胶":"3M"}', 9.90, 800),
(99, '{"颜色":"白色","数量":"10个","背胶":"普通"}', 15.90, 700),
(99, '{"颜色":"透明","数量":"8个","材质":"硅胶"}', 12.90, 750),

-- 100. 便签便利贴
(100, '{"尺寸":"76×76mm","颜色":"彩色","数量":"100张"}', 4.90, 900),
(100, '{"尺寸":"50×50mm","颜色":"荧光","数量":"200张"}', 6.90, 850),
(100, '{"尺寸":"76×127mm","颜色":"白色","数量":"100张"}', 5.90, 800),


-- 101. 温和保湿洁面乳
(101, '{"规格":"100ml","肤质":"干性","功效":"保湿"}', 79.00, 250),
(101, '{"规格":"150ml","肤质":"敏感肌","功效":"舒缓"}', 109.00, 200),
(101, '{"规格":"200ml","肤质":"油性","功效":"控油"}', 129.00, 180),

-- 102. 深层补水爽肤水
(102, '{"规格":"200ml","肤质":"干性","功效":"补水"}', 99.00, 200),
(102, '{"规格":"300ml","肤质":"混合","功效":"二次清洁"}', 129.00, 180),
(102, '{"规格":"100ml","肤质":"油性","功效":"收敛毛孔"}', 79.00, 220),

-- 103. 修护精华液
(103, '{"规格":"30ml","核心成分":"神经酰胺","功效":"修护屏障"}', 219.00, 150),
(103, '{"规格":"50ml","核心成分":"玻尿酸","功效":"深层修护"}', 299.00, 120),
(103, '{"规格":"15ml","核心成分":"维生素B5","功效":"舒缓"}', 129.00, 180),

-- 104. 水润保湿面霜
(104, '{"规格":"50g","质地":"清爽型","适合":"春夏"}', 169.00, 180),
(104, '{"规格":"80g","质地":"滋润型","适合":"秋冬"}', 229.00, 150),
(104, '{"规格":"30g","质地":"啫喱","适合":"油皮"}', 119.00, 200),

-- 105. 清爽防晒乳 SPF50+
(105, '{"规格":"50ml","肤质":"油性","质地":"清爽"}', 129.00, 200),
(105, '{"规格":"80ml","肤质":"干性","质地":"保湿"}', 179.00, 180),
(105, '{"规格":"30ml","肤质":"敏感肌","物理防晒"}', 99.00, 220),

-- 106. 丝绒雾面口红
(106, '{"色号":"#01 复古红","质地":"丝绒","持久":"8h"}', 139.00, 350),
(106, '{"色号":"#02 豆沙粉","质地":"雾面","持久":"6h"}', 139.00, 380),
(106, '{"色号":"#03 橘棕色","质地":"丝绒","持久":"8h"}', 139.00, 320),

-- 107. 水润气垫粉底
(107, '{"色号":"自然色","遮瑕":"中度","妆效":"水光"}', 189.00, 220),
(107, '{"色号":"亮白色","遮瑕":"轻度","妆效":"哑光"}', 189.00, 200),
(107, '{"色号":"小麦色","遮瑕":"高度","妆效":"奶油肌"}', 189.00, 180),

-- 108. 防水眉笔
(108, '{"颜色":"深棕色","笔芯":"细圆","持久":"防水"}', 59.00, 450),
(108, '{"颜色":"灰黑色","笔芯":"砍刀","持久":"防汗"}', 59.00, 480),
(108, '{"颜色":"浅咖色","笔芯":"极细","持久":"防水"}', 59.00, 420),

-- 109. 纤长睫毛膏
(109, '{"功效":"纤长","刷头":"细齿","防水":"是"}', 99.00, 280),
(109, '{"功效":"浓密","刷头":"大刷头","防水":"否"}', 99.00, 300),
(109, '{"功效":"卷翘","刷头":"弧形","防水":"是"}', 99.00, 260),

-- 110. 高光修容盘
(110, '{"色号":"香槟金","用途":"面部高光","粉质":"细腻"}', 159.00, 160),
(110, '{"色号":"粉金","用途":"腮红高光一体","粉质":"微闪"}', 159.00, 150),
(110, '{"色号":"自然棕","用途":"修容","粉质":"哑光"}', 159.00, 140),

-- 111. 柔顺修护洗发水
(111, '{"规格":"400ml","发质":"干枯毛躁","功效":"修护"}', 69.00, 380),
(111, '{"规格":"750ml","发质":"染烫受损","功效":"强韧"}', 99.00, 350),
(111, '{"规格":"200ml","发质":"油性","功效":"控油"}', 39.00, 400),

-- 112. 顺滑护发素
(112, '{"规格":"400ml","发质":"打结","功效":"顺滑"}', 59.00, 350),
(112, '{"规格":"750ml","发质":"干枯","功效":"滋润"}', 89.00, 320),
(112, '{"规格":"200ml","发质":"细软","功效":"蓬松"}', 29.00, 380),

-- 113. 氨基酸沐浴露
(113, '{"规格":"500ml","香型":"清新海洋","肤质":"通用"}', 49.00, 400),
(113, '{"规格":"750ml","香型":"樱花甜香","肤质":"干性"}', 69.00, 380),
(113, '{"规格":"300ml","香型":"白茶","肤质":"敏感肌"}', 39.00, 420),

-- 114. 深度滋养发膜
(114, '{"规格":"200g","发质":"受损","使用频率":"每周1-2次"}', 89.00, 240),
(114, '{"规格":"500g","发质":"干枯","沙龙级"}', 159.00, 200),
(114, '{"规格":"100g","发质":"染烫","旅行装"}', 49.00, 260),

-- 115. 旅行装洗护套装
(115, '{"包含":"洗发+护发+沐浴","规格":"50ml×3","适用":"短途"}', 39.00, 550),
(115, '{"包含":"洗发+护发+沐浴+身体乳","规格":"80ml×4","适用":"长途"}', 59.00, 500),
(115, '{"包含":"洗发+沐浴","规格":"100ml×2","适用":"健身"}', 29.00, 600),

-- 116. 花果香淡香水
(116, '{"香型":"甜橙+茉莉","规格":"30ml","持久":"4h"}', 269.00, 140),
(116, '{"香型":"玫瑰+白麝香","规格":"50ml","持久":"6h"}', 369.00, 120),
(116, '{"香型":"蓝风铃","规格":"100ml","持久":"8h"}', 499.00, 100),

-- 117. 木质麝香香水
(117, '{"香型":"木质麝香","规格":"30ml","持久":"6h"}', 329.00, 120),
(117, '{"香型":"木质麝香","规格":"50ml","持久":"8h"}', 459.00, 100),
(117, '{"香型":"木质麝香+柑橘","规格":"100ml","持久":"10h"}', 599.00, 80),

-- 118. 室内藤条香薰
(118, '{"香型":"海洋","容量":"100ml","藤条数量":"5根"}', 129.00, 200),
(118, '{"香型":"茉莉","容量":"150ml","藤条数量":"6根"}', 169.00, 180),
(118, '{"香型":"白茶","容量":"200ml","藤条数量":"8根"}', 199.00, 150),

-- 119. 车载夹式香氛
(119, '{"香型":"古龙","颜色":"黑色","夹式":"空调出风口"}', 79.00, 280),
(119, '{"香型":"海洋","颜色":"银色","夹式":"出风口"}', 79.00, 260),
(119, '{"香型":"柠檬","颜色":"金色","补充装":"含2个"}', 99.00, 240),

-- 120. 香氛蜡烛礼盒
(120, '{"香型":"玫瑰+茉莉","规格":"200g×2","燃烧时间":"40h"}', 199.00, 160),
(120, '{"香型":"檀香+琥珀","规格":"300g×3","燃烧时间":"60h"}', 269.00, 140),
(120, '{"香型":"无花果+雪松","规格":"100g×4","礼盒装"}', 229.00, 150),

-- 121. 每日坚果 750g
(121, '{"包装":"混合果仁","规格":"750g","独立小包":"30袋"}', 89.00, 350),
(121, '{"包装":"纯坚果","规格":"500g","独立小包":"20袋"}', 79.00, 300),
(121, '{"包装":"儿童款","规格":"600g","独立小包":"24袋"}', 99.00, 280),

-- 122. 海盐薯片 8连包
(122, '{"口味":"原味","规格":"8连包","单包":"40g"}', 29.90, 700),
(122, '{"口味":"海盐+黑胡椒","规格":"8连包","单包":"40g"}', 29.90, 680),
(122, '{"口味":"海盐+醋","规格":"12连包","单包":"40g"}', 39.90, 600),

-- 123. 和风鱿鱼丝
(123, '{"口味":"原味","规格":"200g","包装":"袋装"}', 19.90, 550),
(123, '{"口味":"辣味","规格":"200g","包装":"袋装"}', 19.90, 520),
(123, '{"口味":"碳烤","规格":"300g","包装":"罐装"}', 29.90, 500),

-- 124. 冻干草莓脆
(124, '{"规格":"50g","包装":"袋装","工艺":"冻干"}', 35.90, 280),
(124, '{"规格":"100g","包装":"罐装","工艺":"冻干"}', 59.90, 260),
(124, '{"规格":"200g","包装":"礼盒","工艺":"冻干+酸奶涂层"}', 99.90, 200),

-- 125. 黄油曲奇礼盒
(125, '{"规格":"400g","口味":"原味","礼盒装"}', 49.90, 240),
(125, '{"规格":"600g","口味":"巧克力味","礼盒装"}', 69.90, 220),
(125, '{"规格":"800g","口味":"混合口味","铁盒装"}', 89.90, 200),

-- 126. 挂耳咖啡 20袋
(126, '{"烘焙程度":"中度","风味":"坚果","规格":"20袋"}', 69.00, 280),
(126, '{"烘焙程度":"深度","风味":"巧克力","规格":"20袋"}', 69.00, 260),
(126, '{"烘焙程度":"浅度","风味":"果酸","规格":"30袋"}', 99.00, 240),

-- 127. 精品咖啡豆 500g
(127, '{"产地":"埃塞俄比亚","烘焙":"浅中","规格":"500g"}', 89.00, 200),
(127, '{"产地":"哥伦比亚","烘焙":"中度","规格":"500g"}', 89.00, 190),
(127, '{"产地":"印尼曼特宁","烘焙":"深度","规格":"1kg"}', 159.00, 180),

-- 128. 锡兰红茶 礼盒装
(128, '{"规格":"100g","等级":"OP","包装":"铁罐"}', 59.00, 240),
(128, '{"规格":"200g","等级":"BOP","包装":"礼盒"}', 99.00, 220),
(128, '{"规格":"300g","等级":"FBOP","包装":"木盒"}', 139.00, 200),

-- 129. 茉莉花茶 250g
(129, '{"等级":"特级","窨制次数":"5次","规格":"250g"}', 49.00, 260),
(129, '{"等级":"一级","窨制次数":"3次","规格":"500g"}', 79.00, 240),
(129, '{"等级":"香毫","窨制次数":"7次","规格":"200g"}', 69.00, 220),

-- 130. 浓缩奶茶液 6瓶装
(130, '{"口味":"原味","规格":"6瓶×200ml","可兑":"牛奶"}', 39.90, 300),
(130, '{"口味":"阿萨姆","规格":"6瓶×200ml","可兑":"水"}', 39.90, 280),
(130, '{"口味":"锡兰","规格":"12瓶×200ml","家庭装"}', 69.90, 260),

-- 131. 东北大米 10kg
(131, '{"品种":"长粒香","规格":"10kg","产地":"黑龙江"}', 89.00, 450),
(131, '{"品种":"稻花香","规格":"10kg","产地":"五常"}', 109.00, 400),
(131, '{"品种":"珍珠米","规格":"5kg","产地":"吉林"}', 49.00, 500),

-- 132. 五常稻花香 5kg
(132, '{"等级":"一级","规格":"5kg","认证":"地理标志"}', 79.00, 350),
(132, '{"等级":"特级","规格":"5kg","认证":"有机"}', 99.00, 300),
(132, '{"等级":"一级","规格":"10kg","认证":"地理标志"}', 149.00, 280),

-- 133. 非转菜籽油 5L
(133, '{"工艺":"压榨","规格":"5L","等级":"一级"}', 69.90, 240),
(133, '{"工艺":"冷榨","规格":"5L","等级":"特级"}', 89.90, 220),
(133, '{"工艺":"压榨","规格":"2.5L","等级":"一级"}', 39.90, 260),

-- 134. 橄榄调和油 2L
(134, '{"橄榄含量":"20%","规格":"2L","适用":"凉拌"}', 59.90, 260),
(134, '{"橄榄含量":"50%","规格":"2L","适用":"煎炒"}', 79.90, 240),
(134, '{"橄榄含量":"80%","规格":"1.5L","适用":"生饮"}', 99.90, 220),

-- 135. 高筋小麦粉 5kg
(135, '{"蛋白质":"≥12%","规格":"5kg","适用":"面包"}', 49.90, 300),
(135, '{"蛋白质":"≥14%","规格":"5kg","适用":"披萨"}', 59.90, 280),
(135, '{"蛋白质":"≥10%","规格":"2.5kg","适用":"馒头"}', 29.90, 320),

-- 136. 速冻手工水饺 1.5kg
(136, '{"口味":"猪肉白菜","规格":"1.5kg","数量":"约60只"}', 49.90, 240),
(136, '{"口味":"韭菜鸡蛋","规格":"1.5kg","数量":"约60只"}', 49.90, 230),
(136, '{"口味":"三鲜","规格":"1kg","数量":"约40只"}', 39.90, 250),

-- 137. 冷冻鸡翅中 1kg
(137, '{"规格":"1kg","包装":"真空","产地":"国产"}', 39.90, 260),
(137, '{"规格":"2kg","包装":"袋装","产地":"进口"}', 69.90, 240),
(137, '{"规格":"500g","包装":"气调","腌制":"奥尔良"}', 29.90, 280),

-- 138. 雪花肥牛片 500g
(138, '{"规格":"500g","部位":"胸腹","肥瘦":"3:7"}', 59.90, 200),
(138, '{"规格":"500g","部位":"上脑","肥瘦":"2:8"}', 69.90, 180),
(138, '{"规格":"1kg","部位":"眼肉","肥瘦":"1:9"}', 119.90, 160),

-- 139. 去壳虾仁 400g
(139, '{"规格":"400g","大小":"31/40","去线":"是"}', 49.90, 220),
(139, '{"规格":"400g","大小":"21/30","去线":"是"}', 59.90, 200),
(139, '{"规格":"800g","大小":"41/50","去线":"否"}', 89.90, 180),

-- 140. 冷冻披萨 半成品
(140, '{"口味":"意式腊肠","规格":"6寸","烘烤":"烤箱"}', 29.90, 240),
(140, '{"口味":"海鲜","规格":"9寸","烘烤":"空气炸锅"}', 39.90, 220),
(140, '{"口味":"榴莲","规格":"7寸","烘烤":"微波炉"}', 34.90, 230),

-- 141. 减震跑步鞋 男款
(141, '{"尺码":"39","颜色":"黑色","减震":"气垫"}', 399.00, 80),
(141, '{"尺码":"41","颜色":"灰色","减震":"EVA"}', 399.00, 100),
(141, '{"尺码":"43","颜色":"蓝色","减震":"爆米花"}', 399.00, 70),

-- 142. 轻量跑步鞋 女款
(142, '{"尺码":"36","颜色":"粉色","轻量":"单只180g"}', 369.00, 90),
(142, '{"尺码":"37","颜色":"白色","轻量":"单只175g"}', 369.00, 100),
(142, '{"尺码":"38","颜色":"紫色","轻量":"单只170g"}', 369.00, 80),

-- 143. 专业跑步短袖
(143, '{"尺码":"M","颜色":"黑色","面料":"速干"}', 129.00, 150),
(143, '{"尺码":"L","颜色":"荧光绿","面料":"冰感"}', 129.00, 140),
(143, '{"尺码":"XL","颜色":"蓝色","面料":"网眼"}', 129.00, 130),

-- 144. 运动压缩裤
(144, '{"尺码":"S","颜色":"黑色","压力":"梯度"}', 199.00, 120),
(144, '{"尺码":"M","颜色":"灰色","压力":"中度"}', 199.00, 130),
(144, '{"尺码":"L","颜色":"蓝色","压力":"轻度"}', 199.00, 110),

-- 145. 夜跑反光臂包
(145, '{"颜色":"黑色","反光":"3M","适用":"6.7英寸手机"}', 59.00, 320),
(145, '{"颜色":"荧光黄","反光":"3M","适用":"6.1英寸手机"}', 59.00, 300),
(145, '{"颜色":"粉色","反光":"高亮","适用":"钥匙+手机"}', 69.00, 280),

-- 146. 双人帐篷 防雨款
(146, '{"颜色":"军绿","尺寸":"200×150cm","防水":"PU2000mm"}', 599.00, 160),
(146, '{"颜色":"橙色","尺寸":"210×180cm","防水":"PU3000mm"}', 699.00, 140),
(146, '{"颜色":"蓝色","尺寸":"200×150cm","四季通用"}', 649.00, 150),

-- 147. 便携折叠椅
(147, '{"颜色":"军绿","材质":"牛津布","承重":"100kg"}', 129.00, 220),
(147, '{"颜色":"橙色","材质":"涤纶","承重":"120kg"}', 139.00, 200),
(147, '{"颜色":"蓝色","材质":"网格","承重":"80kg"}', 119.00, 240),

-- 148. 户外野营灯
(148, '{"颜色":"黑色","光源":"LED","供电":"3节AA"}', 99.00, 250),
(148, '{"颜色":"白色","光源":"COB","供电":"USB充电"}', 129.00, 230),
(148, '{"颜色":"迷彩","光源":"LED+COB","供电":"18650电池"}', 149.00, 200),

-- 149. 保温野餐壶 1.5L
(149, '{"颜色":"不锈钢原色","容量":"1.5L","保温":"12h"}', 89.00, 200),
(149, '{"颜色":"黑色","容量":"1.8L","保温":"24h"}', 109.00, 180),
(149, '{"颜色":"绿色","容量":"1.2L","保温":"8h"}', 79.00, 220),

-- 150. 钛合金野餐餐具套装
(150, '{"套装内容":"刀叉勺3件","颜色":"钛色","重量":"50g"}', 149.00, 180),
(150, '{"套装内容":"刀叉勺+筷子4件","颜色":"金色","重量":"80g"}', 199.00, 160),
(150, '{"套装内容":"2人全套(刀叉勺筷×2)","颜色":"彩虹色","重量":"150g"}', 299.00, 140),

-- 151. 家用哑铃套装 20kg
(151, '{"材质":"包胶","重量":"20kg(10kg×2)","调节":"可拆卸"}', 299.00, 200),
(151, '{"材质":"铸铁","重量":"30kg(15kg×2)","调节":"快调"}', 399.00, 180),
(151, '{"材质":"浸塑","重量":"10kg(5kg×2)","调节":"固定"}', 199.00, 220),

-- 152. 瑜伽垫 加厚款
(152, '{"厚度":"10mm","颜色":"紫色","材质":"TPE"}', 129.00, 280),
(152, '{"厚度":"15mm","颜色":"蓝色","材质":"NBR"}', 159.00, 260),
(152, '{"厚度":"8mm","颜色":"黑色","材质":"天然橡胶"}', 179.00, 250),

-- 153. 跳绳 轴承款
(153, '{"材质":"PVC+轴承","长度":"3m可调","颜色":"黑色"}', 59.00, 320),
(153, '{"材质":"钢丝绳+轴承","长度":"2.8m","颜色":"红色"}', 79.00, 300),
(153, '{"材质":"PU+轴承","长度":"3.2m","颜色":"蓝色","计数":"智能"}', 99.00, 280),

-- 154. 阻力带 5件套
(154, '{"套装":"5根(5-50磅)","材质":"天然乳胶","颜色":"彩色"}', 79.00, 260),
(154, '{"套装":"3根(10-30磅)","材质":"TPE","颜色":"灰色"}', 59.00, 280),
(154, '{"套装":"7根(5-70磅)","材质":"乳胶","颜色":"彩虹","门扣":"含"}', 109.00, 240),

-- 155. 家用引体向上器
(155, '{"安装方式":"免打孔","材质":"加厚钢管","承重":"150kg"}', 199.00, 160),
(155, '{"安装方式":"打孔固定","材质":"不锈钢","承重":"200kg"}', 249.00, 140),
(155, '{"安装方式":"门框式","材质":"碳钢","承重":"120kg","多功能":"含俯卧撑支架"}', 299.00, 120),

-- 156. 公路自行车 入门款
(156, '{"车架尺寸":"48cm","颜色":"黑色","变速":"14速"}', 1999.00, 60),
(156, '{"车架尺寸":"50cm","颜色":"红色","变速":"16速"}', 2199.00, 50),
(156, '{"车架尺寸":"52cm","颜色":"蓝色","变速":"18速","刹车":"油压"}', 2399.00, 40),

-- 157. 山地车 21速
(157, '{"车架":"17寸","颜色":"黑红","刹车":"机械碟刹"}', 1699.00, 70),
(157, '{"车架":"19寸","颜色":"白蓝","刹车":"油压碟刹"}', 1899.00, 60),
(157, '{"车架":"15寸","颜色":"荧光绿","前叉":"可锁死"}', 1799.00, 65),

-- 158. 骑行头盔 一体成型
(158, '{"颜色":"白色","尺码":"M(55-58cm)","重量":"260g"}', 199.00, 220),
(158, '{"颜色":"黑色","尺码":"L(59-62cm)","重量":"280g"}', 199.00, 200),
(158, '{"颜色":"红色","尺码":"M","磁吸风镜":"含"}', 249.00, 180),

-- 159. 骑行手套 透气款
(159, '{"尺码":"S","颜色":"黑色","掌心":"硅胶减震"}', 79.00, 260),
(159, '{"尺码":"M","颜色":"蓝色","掌心":"海绵减震"}', 79.00, 280),
(159, '{"尺码":"L","颜色":"红色","掌心":"碳纤维"}', 99.00, 250),

-- 160. 自行车码表
(160, '{"功能":"基础(速度/里程)","屏幕":"LCD","防水":"IPX4"}', 129.00, 200),
(160, '{"功能":"无线(速度/里程/卡路里)","屏幕":"背光","防水":"IPX6"}', 199.00, 180),
(160, '{"功能":"GPS定位/导航","屏幕":"彩屏","防水":"IPX7","蓝牙":"APP同步"}', 399.00, 150),


-- 161. iPhone 14 128G
(161, '{"颜色":"蓝色","容量":"128GB"}', 5999.00, 40),
(161, '{"颜色":"紫色","容量":"256GB"}', 6799.00, 35),
(161, '{"颜色":"红色","容量":"512GB"}', 7999.00, 25),

-- 162. Xiaomi 14 256G
(162, '{"颜色":"黑色","内存":"12GB","存储":"256GB"}', 4299.00, 100),
(162, '{"颜色":"白色","内存":"16GB","存储":"512GB"}', 4799.00, 80),
(162, '{"颜色":"绿色","内存":"12GB","存储":"512GB"}', 4599.00, 90),

-- 163. MacBook Air 13 M3 16G (新款)
(163, '{"内存":"16GB","硬盘":"512GB","颜色":"银色"}', 10999.00, 25),
(163, '{"内存":"24GB","硬盘":"1TB","颜色":"深空灰"}', 12999.00, 20),
(163, '{"内存":"8GB","硬盘":"256GB","颜色":"午夜色"}', 8999.00, 30),

-- 164. ThinkPad X1 Carbon (Gen 11)
(164, '{"内存":"16GB","硬盘":"512GB","颜色":"黑色"}', 12999.00, 15),
(164, '{"内存":"32GB","硬盘":"1TB","颜色":"灰色"}', 15999.00, 10),
(164, '{"内存":"8GB","硬盘":"256GB","颜色":"黑色"}', 10999.00, 18),

-- 165. 戴森 V12 吸尘器 (Absolute)
(165, '{"版本":"全配件版","颜色":"金色"}', 4599.00, 25),
(165, '{"版本":"宠物版","颜色":"紫色"}', 4199.00, 30),
(165, '{"版本":"标准版","颜色":"红色"}', 3999.00, 35),

-- 166. 米家扫拖机器人
(166, '{"型号":"1C","导航":"视觉","水箱":"电控"}', 1799.00, 70),
(166, '{"型号":"2 Pro","导航":"激光","水箱":"恒压"}', 2299.00, 60),
(166, '{"型号":"3","导航":"激光+视觉","集尘":"自动"}', 2999.00, 50),

-- 167. 索尼 WH-1000XM5 (银)
(167, '{"颜色":"银色","版本":"标准"}', 2599.00, 50),
(167, '{"颜色":"黑色","版本":"商务"}', 2699.00, 45),
(167, '{"颜色":"蓝色","版本":"限量"}', 2799.00, 30),

-- 168. AirPods Pro 2 (USB-C)
(168, '{"颜色":"白色","充电盒":"USB-C","刻字":"无"}', 1999.00, 80),
(168, '{"颜色":"白色","充电盒":"MagSafe","刻字":"定制"}', 2099.00, 60),
(168, '{"颜色":"白色","充电盒":"USB-C","耳塞":"S/M/L"}', 1999.00, 70),

-- 169. Dell U2723QE 27" 4K (升级版)
(169, '{"尺寸":"27英寸","接口":"Type-C 90W","颜色":"银色"}', 3999.00, 20),
(169, '{"尺寸":"27英寸","套装":"含音箱棒","颜色":"黑色"}', 4299.00, 15),
(169, '{"尺寸":"32英寸","型号":"U3223QE","接口":"Type-C 90W"}', 5999.00, 10),

-- 170. LG 34WP65C 34" 曲面 (新款)
(170, '{"尺寸":"34英寸","曲率":"1800R","分辨率":"3440×1440"}', 3299.00, 18),
(170, '{"尺寸":"34英寸","曲率":"1000R","刷新率":"160Hz"}', 3799.00, 15),
(170, '{"尺寸":"40英寸","曲率":"1800R","分辨率":"5120×2160"}', 4999.00, 10);

-- 3.7 评价数据

INSERT INTO `reviews` (`user_id`, `order_id`, `product_id`, `rating`, `content`, `images`, `create_time`, `update_time`) VALUES
-- product_id = 1 的两条评价
(1001, 20241001, 1, 5, '质量很棒，细节处理到位，物流也很快。', NULL, NOW(), NOW()),
(1002, 20241002, 1, 4, '整体不错，就是包装稍微有点挤压。', NULL, NOW(), NOW()),
-- product_id = 2 的两条评价
(1003, 20241003, 2, 5, '颜色很正，大小合适，非常满意！', NULL, NOW(), NOW()),
(1004, 20241004, 2, 3, '中规中矩吧，没有宣传图那么惊艳。', NULL, NOW(), NOW()),
-- product_id = 3 的两条评价
(1005, 20241005, 3, 4, '性价比高，这个价位能买到这样的商品很值。', NULL, NOW(), NOW()),
(1006, 20241006, 3, 2, '收到时外包装破了，里面有些划痕。', NULL, NOW(), NOW()),
-- product_id = 4 的两条评价
(1007, 20241007, 4, 5, '买给家人的，他们很喜欢，做工精细。', NULL, NOW(), NOW()),
(1008, 20241008, 4, 5, '第二次回购了，品质一直稳定。', NULL, NOW(), NOW()),
-- product_id = 5 的两条评价
(1009, 20241009, 5, 3, '还行，快递有点慢，其他都还好。', NULL, NOW(), NOW()),
(1010, 20241010, 5, 4, '商品没问题，客服态度也不错。', NULL, NOW(), NOW()),
-- product_id = 6 的两条评价
(1011, 20241011, 6, 5, '超出预期，设计很人性化。', NULL, NOW(), NOW()),
(1012, 20241012, 6, 1, '用了两天就坏了，质量太差了！', NULL, NOW(), NOW()),
-- product_id = 7 的两条评价
(1013, 20241013, 7, 4, '外观好看，功能实用。', NULL, NOW(), NOW()),
(1014, 20241014, 7, 5, '朋友推荐买的，确实不错。', NULL, NOW(), NOW()),
-- product_id = 8 的两条评价
(1015, 20241015, 8, 3, '一分钱一分货，能接受。', NULL, NOW(), NOW()),
(1016, 20241016, 8, 5, '非常棒，下次还会来买。', NULL, NOW(), NOW()),
-- product_id = 9 的两条评价
(1017, 20241017, 9, 4, '物流很快，包装严实。', NULL, NOW(), NOW()),
(1018, 20241018, 9, 5, '实物比图片好看，手感很好。', NULL, NOW(), NOW()),
-- product_id = 10 的两条评价
(1019, 20241019, 10, 2, '有点失望，功能没有描述的全。', NULL, NOW(), NOW()),
(1020, 20241020, 10, 3, '一般般，对得起这个价格。', NULL, NOW(), NOW()),
-- product_id = 11 的两条评价
(1021, 20241021, 11, 5, '完美，挑不出毛病。', NULL, NOW(), NOW()),
(1022, 20241022, 11, 4, '还不错，如果能再优惠点就更好了。', NULL, NOW(), NOW()),
-- product_id = 12 的两条评价
(1023, 20241023, 12, 5, '发货速度很快，东西也好。', NULL, NOW(), NOW()),
(1024, 20241024, 12, 3, '还行吧，能用。', NULL, NOW(), NOW()),
-- product_id = 13 的两条评价
(1025, 20241025, 13, 4, '款式新颖，喜欢。', NULL, NOW(), NOW()),
(1026, 20241026, 13, 5, '和描述一致，满意。', NULL, NOW(), NOW()),
-- product_id = 14 的两条评价
(1027, 20241027, 14, 2, '有异味，放了好几天才散掉。', NULL, NOW(), NOW()),
(1028, 20241028, 14, 3, '外观可以，细节有待提升。', NULL, NOW(), NOW()),
-- product_id = 15 的两条评价
(1029, 20241029, 15, 5, '已经用了几天，性能稳定。', NULL, NOW(), NOW()),
(1030, 20241030, 15, 4, '挺好的，给个好评。', NULL, NOW(), NOW()),
-- product_id = 16 的两条评价
(1031, 20241031, 16, 3, '包装太简陋了，还好东西没坏。', NULL, NOW(), NOW()),
(1032, 20241032, 16, 5, '东西不错，物流给力。', NULL, NOW(), NOW()),
-- product_id = 17 的两条评价
(1033, 20241033, 17, 4, '大小正好，材质也不错。', NULL, NOW(), NOW()),
(1034, 20241034, 17, 5, '非常喜欢，会回购。', NULL, NOW(), NOW()),
-- product_id = 18 的两条评价
(1035, 20241035, 18, 2, '不推荐，感觉不值这个钱。', NULL, NOW(), NOW()),
(1036, 20241036, 18, 4, '还行，凑合用。', NULL, NOW(), NOW()),
-- product_id = 19 的两条评价
(1037, 20241037, 19, 5, '质量过硬，值得信赖。', NULL, NOW(), NOW()),
(1038, 20241038, 19, 5, '很好，已经是老顾客了。', NULL, NOW(), NOW()),
-- product_id = 20 的两条评价
(1039, 20241039, 20, 3, '颜色有点色差，其他还好。', NULL, NOW(), NOW()),
(1040, 20241040, 20, 4, '性价比可以，日常使用足够。', NULL, NOW(), NOW()),
-- product_id = 21 的两条评价
(1041, 20241041, 21, 5, '精致小巧，携带方便。', NULL, NOW(), NOW()),
(1042, 20241042, 21, 4, '功能齐全，操作简单。', NULL, NOW(), NOW()),
-- product_id = 22 的两条评价
(1043, 20241043, 22, 2, '开箱就发现少了配件，差评。', NULL, NOW(), NOW()),
(1044, 20241044, 22, 3, '东西没问题，但客服响应太慢。', NULL, NOW(), NOW()),
-- product_id = 23 的两条评价
(1045, 20241045, 23, 5, '包装精美，送人很合适。', NULL, NOW(), NOW()),
(1046, 20241046, 23, 5, '物流超快，隔天就到了。', NULL, NOW(), NOW()),
-- product_id = 24 的两条评价
(1047, 20241047, 24, 4, '还不错，就是有点小贵。', NULL, NOW(), NOW()),
(1048, 20241048, 24, 5, '一分钱一分货，质量确实好。', NULL, NOW(), NOW()),
-- product_id = 25 的两条评价
(1049, 20241049, 25, 3, '普普通通，没什么亮点。', NULL, NOW(), NOW()),
(1050, 20241050, 25, 4, '日常用用还行。', NULL, NOW(), NOW()),
-- product_id = 26 的两条评价
(1051, 20241051, 26, 5, '设计感强，很喜欢。', NULL, NOW(), NOW()),
(1052, 20241052, 26, 4, '不错，符合预期。', NULL, NOW(), NOW()),
-- product_id = 27 的两条评价
(1053, 20241053, 27, 2, '质量一般，用了没多久就出问题。', NULL, NOW(), NOW()),
(1054, 20241054, 27, 3, '一般般吧，不推荐。', NULL, NOW(), NOW()),
-- product_id = 28 的两条评价
(1055, 20241055, 28, 5, '做工精细，手感好。', NULL, NOW(), NOW()),
(1056, 20241056, 28, 5, '完美，挑不出缺点。', NULL, NOW(), NOW()),
-- product_id = 29 的两条评价
(1057, 20241057, 29, 4, '大小合适，颜色也正。', NULL, NOW(), NOW()),
(1058, 20241058, 29, 3, '还行，就是发货慢了点。', NULL, NOW(), NOW()),
-- product_id = 30 的两条评价
(1059, 20241059, 30, 5, '非常满意，下次还来。', NULL, NOW(), NOW()),
(1060, 20241060, 30, 4, '不错，给个五星。', NULL, NOW(), NOW()),
-- product_id = 31 的两条评价
(1061, 20241061, 31, 3, '能用，但细节处理不到位。', NULL, NOW(), NOW()),
(1062, 20241062, 31, 4, '整体还可以，价格再低点更好。', NULL, NOW(), NOW()),
-- product_id = 32 的两条评价
(1063, 20241063, 32, 5, '质量没得说，会回购。', NULL, NOW(), NOW()),
(1064, 20241064, 32, 2, '物流太差了，包装都破了。', NULL, NOW(), NOW()),
-- product_id = 33 的两条评价
(1065, 20241065, 33, 4, '颜值高，实用性强。', NULL, NOW(), NOW()),
(1066, 20241066, 33, 5, '很满意，推荐购买。', NULL, NOW(), NOW()),
-- product_id = 34 的两条评价
(1067, 20241067, 34, 3, '一分价钱一分货。', NULL, NOW(), NOW()),
(1068, 20241068, 34, 4, '还行，对得起这个价。', NULL, NOW(), NOW()),
-- product_id = 35 的两条评价
(1069, 20241069, 35, 5, '很棒，已经用了一段时间了。', NULL, NOW(), NOW()),
(1070, 20241070, 35, 5, '完美，没什么可挑剔的。', NULL, NOW(), NOW()),
-- product_id = 36 的两条评价
(1071, 20241071, 36, 2, '有瑕疵，联系客服态度不好。', NULL, NOW(), NOW()),
(1072, 20241072, 36, 1, '非常差的一次购物体验。', NULL, NOW(), NOW()),
-- product_id = 37 的两条评价
(1073, 20241073, 37, 4, '质量不错，就是有点小瑕疵。', NULL, NOW(), NOW()),
(1074, 20241074, 37, 5, '挺好的，包装也用心。', NULL, NOW(), NOW()),
-- product_id = 38 的两条评价
(1075, 20241075, 38, 3, '能用，但感觉不值这个价。', NULL, NOW(), NOW()),
(1076, 20241076, 38, 4, '总体来说还是不错的。', NULL, NOW(), NOW()),
-- product_id = 39 的两条评价
(1077, 20241077, 39, 5, '质量很好，物流快。', NULL, NOW(), NOW()),
(1078, 20241078, 39, 5, '非常满意，以后会常来。', NULL, NOW(), NOW()),
-- product_id = 40 的两条评价
(1079, 20241079, 40, 4, '颜色好看，大小合适。', NULL, NOW(), NOW()),
(1080, 20241080, 40, 3, '一般般，没什么特别。', NULL, NOW(), NOW()),
-- product_id = 41 的两条评价
(1081, 20241081, 41, 5, '精致，送朋友很合适。', NULL, NOW(), NOW()),
(1082, 20241082, 41, 4, '包装很好，商品也没问题。', NULL, NOW(), NOW()),
-- product_id = 42 的两条评价
(1083, 20241083, 42, 2, '发货慢，东西也不新。', NULL, NOW(), NOW()),
(1084, 20241084, 42, 3, '还行，勉强接受。', NULL, NOW(), NOW()),
-- product_id = 43 的两条评价
(1085, 20241085, 43, 5, '品质很棒，值得推荐。', NULL, NOW(), NOW()),
(1086, 20241086, 43, 4, '物流很快，东西不错。', NULL, NOW(), NOW()),
-- product_id = 44 的两条评价
(1087, 20241087, 44, 3, '中规中矩，没有惊喜。', NULL, NOW(), NOW()),
(1088, 20241088, 44, 5, '很满意，超出预期。', NULL, NOW(), NOW()),
-- product_id = 45 的两条评价
(1089, 20241089, 45, 4, '东西挺好，就是价格小贵。', NULL, NOW(), NOW()),
(1090, 20241090, 45, 5, '质量过硬，下次还来。', NULL, NOW(), NOW()),
-- product_id = 46 的两条评价
(1091, 20241091, 46, 2, '有异味，影响使用心情。', NULL, NOW(), NOW()),
(1092, 20241092, 46, 3, '一般，没有图片好看。', NULL, NOW(), NOW()),
-- product_id = 47 的两条评价
(1093, 20241093, 47, 5, '非常喜欢，大小刚好。', NULL, NOW(), NOW()),
(1094, 20241094, 47, 4, '还不错，如果多送点赠品更好。', NULL, NOW(), NOW()),
-- product_id = 48 的两条评价
(1095, 20241095, 48, 3, '快递包装差，东西还行。', NULL, NOW(), NOW()),
(1096, 20241096, 48, 4, '性价比高，值得购买。', NULL, NOW(), NOW()),
-- product_id = 49 的两条评价
(1097, 20241097, 49, 5, '细节处理得很好，大爱。', NULL, NOW(), NOW()),
(1098, 20241098, 49, 5, '很好，已经推荐给同事了。', NULL, NOW(), NOW()),
-- product_id = 50 的两条评价
(1099, 20241099, 50, 4, '物流快，包装严实。', NULL, NOW(), NOW()),
(1100, 20241100, 50, 3, '功能简单，够用。', NULL, NOW(), NOW()),
-- product_id = 51 的两条评价
(1101, 20241101, 51, 5, '做工精细，物有所值。', NULL, NOW(), NOW()),
(1102, 20241102, 51, 4, '还不错，如果能便宜点更好。', NULL, NOW(), NOW()),
-- product_id = 52 的两条评价
(1103, 20241103, 52, 2, '有点失望，没有描述的那么好。', NULL, NOW(), NOW()),
(1104, 20241104, 52, 3, '能用，但做工一般。', NULL, NOW(), NOW()),
-- product_id = 53 的两条评价
(1105, 20241105, 53, 5, '非常满意，下次还会光顾。', NULL, NOW(), NOW()),
(1106, 20241106, 53, 5, '质量好，服务也好。', NULL, NOW(), NOW()),
-- product_id = 54 的两条评价
(1107, 20241107, 54, 4, '挺好的，符合预期。', NULL, NOW(), NOW()),
(1108, 20241108, 54, 3, '一般般，没什么特别的。', NULL, NOW(), NOW()),
-- product_id = 55 的两条评价
(1109, 20241109, 55, 5, '颜值高，手感好。', NULL, NOW(), NOW()),
(1110, 20241110, 55, 4, '不错，可以入手。', NULL, NOW(), NOW()),
-- product_id = 56 的两条评价
(1111, 20241111, 56, 2, '物流太慢，而且包装破损。', NULL, NOW(), NOW()),
(1112, 20241112, 56, 3, '东西还行，但服务体验差。', NULL, NOW(), NOW()),
-- product_id = 57 的两条评价
(1113, 20241113, 57, 5, '买给父母的，他们很喜欢。', NULL, NOW(), NOW()),
(1114, 20241114, 57, 5, '质量很好，会回购。', NULL, NOW(), NOW()),
-- product_id = 58 的两条评价
(1115, 20241115, 58, 4, '颜色比图片暗一点，其他都好。', NULL, NOW(), NOW()),
(1116, 20241116, 58, 3, '还行，这个价位可以了。', NULL, NOW(), NOW()),
-- product_id = 59 的两条评价
(1117, 20241117, 59, 5, '精致小巧，非常满意。', NULL, NOW(), NOW()),
(1118, 20241118, 59, 4, '物流快，东西也不错。', NULL, NOW(), NOW()),
-- product_id = 60 的两条评价
(1119, 20241119, 60, 3, '中规中矩，没有特别惊喜。', NULL, NOW(), NOW()),
(1120, 20241120, 60, 5, '物超所值，推荐购买！', NULL, NOW(), NOW()),
-- product_id = 61 的两条评价
(1121, 20241121, 61, 5, '质量一如既往的好，物流也快。', NULL, NOW(), NOW()),
(1122, 20241122, 61, 4, '不错，包装严实。', NULL, NOW(), NOW()),
-- product_id = 62 的两条评价
(1123, 20241123, 62, 3, '一般般吧，没有预期的好。', NULL, NOW(), NOW()),
(1124, 20241124, 62, 5, '性价比很高，值得购买。', NULL, NOW(), NOW()),
-- product_id = 63 的两条评价
(1125, 20241125, 63, 4, '款式好看，颜色很正。', NULL, NOW(), NOW()),
(1126, 20241126, 63, 2, '收到有小瑕疵，不太满意。', NULL, NOW(), NOW()),
-- product_id = 64 的两条评价
(1127, 20241127, 64, 5, '非常精致，推荐购买。', NULL, NOW(), NOW()),
(1128, 20241128, 64, 4, '物流超快，满意。', NULL, NOW(), NOW()),
-- product_id = 65 的两条评价
(1129, 20241129, 65, 3, '能用，但细节有待提高。', NULL, NOW(), NOW()),
(1130, 20241130, 65, 5, '第二次回购了，品质稳定。', NULL, NOW(), NOW()),
-- product_id = 66 的两条评价
(1131, 20241201, 66, 4, '挺好的，大小合适。', NULL, NOW(), NOW()),
(1132, 20241202, 66, 2, '发货太慢，体验不好。', NULL, NOW(), NOW()),
-- product_id = 67 的两条评价
(1133, 20241203, 67, 5, '完美，挑不出毛病。', NULL, NOW(), NOW()),
(1134, 20241204, 67, 5, '质量很好，会再来的。', NULL, NOW(), NOW()),
-- product_id = 68 的两条评价
(1135, 20241205, 68, 3, '一分价钱一分货，还行。', NULL, NOW(), NOW()),
(1136, 20241206, 68, 4, '对得起这个价格。', NULL, NOW(), NOW()),
-- product_id = 69 的两条评价
(1137, 20241207, 69, 5, '包装精美，送礼很合适。', NULL, NOW(), NOW()),
(1138, 20241208, 69, 4, '实物和图片一致。', NULL, NOW(), NOW()),
-- product_id = 70 的两条评价
(1139, 20241209, 70, 2, '有异味，需要通风几天。', NULL, NOW(), NOW()),
(1140, 20241210, 70, 3, '一般般，能用。', NULL, NOW(), NOW()),
-- product_id = 71 的两条评价
(1141, 20241211, 71, 5, '手感超好，颜色也高级。', NULL, NOW(), NOW()),
(1142, 20241212, 71, 4, '朋友看了也想买。', NULL, NOW(), NOW()),
-- product_id = 72 的两条评价
(1143, 20241213, 72, 3, '中规中矩，无亮点。', NULL, NOW(), NOW()),
(1144, 20241214, 72, 5, '很喜欢，用起来很方便。', NULL, NOW(), NOW()),
-- product_id = 73 的两条评价
(1145, 20241215, 73, 4, '质量可以，物流给力。', NULL, NOW(), NOW()),
(1146, 20241216, 73, 2, '有划痕，有点失望。', NULL, NOW(), NOW()),
-- product_id = 74 的两条评价
(1147, 20241217, 74, 5, '做工精细，性价比高。', NULL, NOW(), NOW()),
(1148, 20241218, 74, 4, '还不错，会再买。', NULL, NOW(), NOW()),
-- product_id = 75 的两条评价
(1149, 20241219, 75, 3, '能用，但价格略贵。', NULL, NOW(), NOW()),
(1150, 20241220, 75, 5, '品质一如既往的好。', NULL, NOW(), NOW()),
-- product_id = 76 的两条评价
(1151, 20241221, 76, 4, '大小合适，颜色好看。', NULL, NOW(), NOW()),
(1152, 20241222, 76, 2, '物流暴力，盒子都扁了。', NULL, NOW(), NOW()),
-- product_id = 77 的两条评价
(1153, 20241223, 77, 5, '非常满意，很棒的设计。', NULL, NOW(), NOW()),
(1154, 20241224, 77, 5, '已经推荐给朋友了。', NULL, NOW(), NOW()),
-- product_id = 78 的两条评价
(1155, 20241225, 78, 3, '一般，没什么特别的感觉。', NULL, NOW(), NOW()),
(1156, 20241226, 78, 4, '还行，凑合用。', NULL, NOW(), NOW()),
-- product_id = 79 的两条评价
(1157, 20241227, 79, 5, '细节处理得很好，赞。', NULL, NOW(), NOW()),
(1158, 20241228, 79, 4, '挺好的，就是等得久了点。', NULL, NOW(), NOW()),
-- product_id = 80 的两条评价
(1159, 20241229, 80, 3, '实物颜色稍微深一点。', NULL, NOW(), NOW()),
(1160, 20241230, 80, 5, '很不错，家人都很喜欢。', NULL, NOW(), NOW()),
-- product_id = 81 的两条评价
(1161, 20250101, 81, 4, '质量不错，物流快。', NULL, NOW(), NOW()),
(1162, 20250102, 81, 2, '客服态度差，体验不佳。', NULL, NOW(), NOW()),
-- product_id = 82 的两条评价
(1163, 20250103, 82, 5, '包装用心，商品精美。', NULL, NOW(), NOW()),
(1164, 20250104, 82, 4, '性价比挺高的。', NULL, NOW(), NOW()),
-- product_id = 83 的两条评价
(1165, 20250105, 83, 3, '一般水平，价格合适。', NULL, NOW(), NOW()),
(1166, 20250106, 83, 5, '非常棒，下次还来。', NULL, NOW(), NOW()),
-- product_id = 84 的两条评价
(1167, 20250107, 84, 4, '款式新颖，很喜欢。', NULL, NOW(), NOW()),
(1168, 20250108, 84, 3, '做工稍显粗糙。', NULL, NOW(), NOW()),
-- product_id = 85 的两条评价
(1169, 20250109, 85, 5, '完美，和描述一致。', NULL, NOW(), NOW()),
(1170, 20250110, 85, 5, '会回购，品质放心。', NULL, NOW(), NOW()),
-- product_id = 86 的两条评价
(1171, 20250111, 86, 2, '用了几天就出问题。', NULL, NOW(), NOW()),
(1172, 20250112, 86, 3, '勉强能用，不推荐。', NULL, NOW(), NOW()),
-- product_id = 87 的两条评价
(1173, 20250113, 87, 5, '发货快，东西也很棒。', NULL, NOW(), NOW()),
(1174, 20250114, 87, 4, '不错，价格再低点就更好了。', NULL, NOW(), NOW()),
-- product_id = 88 的两条评价
(1175, 20250115, 88, 4, '质量可以，没让我失望。', NULL, NOW(), NOW()),
(1176, 20250116, 88, 5, '非常满意，已经用起来了。', NULL, NOW(), NOW()),
-- product_id = 89 的两条评价
(1177, 20250117, 89, 3, '普通商品，无功无过。', NULL, NOW(), NOW()),
(1178, 20250118, 89, 4, '实用性还可以。', NULL, NOW(), NOW()),
-- product_id = 90 的两条评价
(1179, 20250119, 90, 5, '精巧，送人自用都好。', NULL, NOW(), NOW()),
(1180, 20250120, 90, 4, '还不错，包装漂亮。', NULL, NOW(), NOW()),
-- product_id = 91 的两条评价
(1181, 20250121, 91, 5, '质量过硬，推荐。', NULL, NOW(), NOW()),
(1182, 20250122, 91, 5, '已经是老顾客了，一如既往好。', NULL, NOW(), NOW()),
-- product_id = 92 的两条评价
(1183, 20250123, 92, 3, '有点色差，其他还好。', NULL, NOW(), NOW()),
(1184, 20250124, 92, 4, '物流很快，满意。', NULL, NOW(), NOW()),
-- product_id = 93 的两条评价
(1185, 20250125, 93, 2, '包装破损，联系客服处理中。', NULL, NOW(), NOW()),
(1186, 20250126, 93, 3, '东西能用，但服务不行。', NULL, NOW(), NOW()),
-- product_id = 94 的两条评价
(1187, 20250127, 94, 5, '颜值高，功能强大。', NULL, NOW(), NOW()),
(1188, 20250128, 94, 4, '挺好的，值得入手。', NULL, NOW(), NOW()),
-- product_id = 95 的两条评价
(1189, 20250129, 95, 4, '性价比高，日常用很好。', NULL, NOW(), NOW()),
(1190, 20250130, 95, 3, '一般吧，没有特别惊艳。', NULL, NOW(), NOW()),
-- product_id = 96 的两条评价
(1191, 20250201, 96, 5, '非常满意，物流快。', NULL, NOW(), NOW()),
(1192, 20250202, 96, 5, '会推荐给身边人。', NULL, NOW(), NOW()),
-- product_id = 97 的两条评价
(1193, 20250203, 97, 3, '能用，但质感一般。', NULL, NOW(), NOW()),
(1194, 20250204, 97, 4, '价格实惠，够用。', NULL, NOW(), NOW()),
-- product_id = 98 的两条评价
(1195, 20250205, 98, 5, '做工精细，快递给力。', NULL, NOW(), NOW()),
(1196, 20250206, 98, 2, '有瑕疵，懒得换了。', NULL, NOW(), NOW()),
-- product_id = 99 的两条评价
(1197, 20250207, 99, 4, '还不错，就是包装简陋。', NULL, NOW(), NOW()),
(1198, 20250208, 99, 5, '物超所值，会回购。', NULL, NOW(), NOW()),
-- product_id = 100 的两条评价
(1199, 20250209, 100, 3, '普普通通，能用。', NULL, NOW(), NOW()),
(1200, 20250210, 100, 5, '超出预期，很好。', NULL, NOW(), NOW()),
-- product_id = 101 的两条评价
(1201, 20250211, 101, 4, '颜色和图片一样，喜欢。', NULL, NOW(), NOW()),
(1202, 20250212, 101, 3, '一般，没什么亮点。', NULL, NOW(), NOW()),
-- product_id = 102 的两条评价
(1203, 20250213, 102, 5, '质量很好，已经是回头客了。', NULL, NOW(), NOW()),
(1204, 20250214, 102, 4, '挺不错的，物流也快。', NULL, NOW(), NOW()),
-- product_id = 103 的两条评价
(1205, 20250215, 103, 2, '有异味，影响使用。', NULL, NOW(), NOW()),
(1206, 20250216, 103, 3, '一般般，不推荐。', NULL, NOW(), NOW()),
-- product_id = 104 的两条评价
(1207, 20250217, 104, 5, '设计很人性化，用着舒服。', NULL, NOW(), NOW()),
(1208, 20250218, 104, 4, '不错，如果能多几种颜色就好了。', NULL, NOW(), NOW()),
-- product_id = 105 的两条评价
(1209, 20250219, 105, 4, '整体不错，细节再优化就更好了。', NULL, NOW(), NOW()),
(1210, 20250220, 105, 5, '满意，包装也用心。', NULL, NOW(), NOW()),
-- product_id = 106 的两条评价
(1211, 20250221, 106, 3, '还行，对得起价格。', NULL, NOW(), NOW()),
(1212, 20250222, 106, 5, '质量很好，会继续支持。', NULL, NOW(), NOW()),
-- product_id = 107 的两条评价
(1213, 20250223, 107, 4, '发货快，商品没问题。', NULL, NOW(), NOW()),
(1214, 20250224, 107, 2, '快递太慢，耽误事。', NULL, NOW(), NOW()),
-- product_id = 108 的两条评价
(1215, 20250225, 108, 5, '做工扎实，非常棒。', NULL, NOW(), NOW()),
(1216, 20250226, 108, 5, '和专卖店看的一样。', NULL, NOW(), NOW()),
-- product_id = 109 的两条评价
(1217, 20250227, 109, 3, '一般，没有惊喜。', NULL, NOW(), NOW()),
(1218, 20250228, 109, 4, '还行，可接受。', NULL, NOW(), NOW()),
-- product_id = 110 的两条评价
(1219, 20250301, 110, 5, '非常满意，推荐。', NULL, NOW(), NOW()),
(1220, 20250302, 110, 4, '东西不错，下次还来。', NULL, NOW(), NOW()),
-- product_id = 111 的两条评价
(1221, 20250303, 111, 4, '颜值在线，功能实用。', NULL, NOW(), NOW()),
(1222, 20250304, 111, 3, '中规中矩，价格合适。', NULL, NOW(), NOW()),
-- product_id = 112 的两条评价
(1223, 20250305, 112, 5, '买给孩子的，他们很喜欢。', NULL, NOW(), NOW()),
(1224, 20250306, 112, 2, '有缺陷，客服不处理。', NULL, NOW(), NOW()),
-- product_id = 113 的两条评价
(1225, 20250307, 113, 4, '还不错，物流给力。', NULL, NOW(), NOW()),
(1226, 20250308, 113, 5, '品质好，价格公道。', NULL, NOW(), NOW()),
-- product_id = 114 的两条评价
(1227, 20250309, 114, 3, '能用，但不够精细。', NULL, NOW(), NOW()),
(1228, 20250310, 114, 5, '很满意，功能齐全。', NULL, NOW(), NOW()),
-- product_id = 115 的两条评价
(1229, 20250311, 115, 5, '颜色漂亮，手感好。', NULL, NOW(), NOW()),
(1230, 20250312, 115, 4, '整体不错，略有瑕疵。', NULL, NOW(), NOW()),
-- product_id = 116 的两条评价
(1231, 20250313, 116, 2, '不太满意，退货了。', NULL, NOW(), NOW()),
(1232, 20250314, 116, 3, '一般，不推荐。', NULL, NOW(), NOW()),
-- product_id = 117 的两条评价
(1233, 20250315, 117, 5, '包装很好，送礼体面。', NULL, NOW(), NOW()),
(1234, 20250316, 117, 4, '东西不错，价格稍贵。', NULL, NOW(), NOW()),
-- product_id = 118 的两条评价
(1235, 20250317, 118, 4, '性价比可以，日常够用。', NULL, NOW(), NOW()),
(1236, 20250318, 118, 5, '非常满意的一次购物。', NULL, NOW(), NOW()),
-- product_id = 119 的两条评价
(1237, 20250319, 119, 3, '普通商品，没什么特别。', NULL, NOW(), NOW()),
(1238, 20250320, 119, 5, '很好，会回购。', NULL, NOW(), NOW()),
-- product_id = 120 的两条评价
(1239, 20250321, 120, 4, '款式好看，大小合适。', NULL, NOW(), NOW()),
(1240, 20250322, 120, 2, '有色差，不太满意。', NULL, NOW(), NOW()),
-- product_id = 121 的两条评价
(1241, 20250323, 121, 5, '质量好，发货快。', NULL, NOW(), NOW()),
(1242, 20250324, 121, 5, '会一直回购的店铺。', NULL, NOW(), NOW()),
-- product_id = 122 的两条评价
(1243, 20250325, 122, 3, '一般般，能用就行。', NULL, NOW(), NOW()),
(1244, 20250326, 122, 4, '对得起这个价位。', NULL, NOW(), NOW()),
-- product_id = 123 的两条评价
(1245, 20250327, 123, 5, '很精致，细节到位。', NULL, NOW(), NOW()),
(1246, 20250328, 123, 4, '不错，比实体店便宜。', NULL, NOW(), NOW()),
-- product_id = 124 的两条评价
(1247, 20250329, 124, 2, '有瑕疵，心情不美丽。', NULL, NOW(), NOW()),
(1248, 20250330, 124, 3, '一般，不做推荐。', NULL, NOW(), NOW()),
-- product_id = 125 的两条评价
(1249, 20250331, 125, 4, '物流很快，东西完好。', NULL, NOW(), NOW()),
(1250, 20250401, 125, 5, '非常好，已经是老顾客了。', NULL, NOW(), NOW()),
-- product_id = 126 的两条评价
(1251, 20250402, 126, 3, '使用体验一般。', NULL, NOW(), NOW()),
(1252, 20250403, 126, 5, '超喜欢，颜值高。', NULL, NOW(), NOW()),
-- product_id = 127 的两条评价
(1253, 20250404, 127, 4, '品质不错，值得购买。', NULL, NOW(), NOW()),
(1254, 20250405, 127, 5, '很满意，给五星好评。', NULL, NOW(), NOW()),
-- product_id = 128 的两条评价
(1255, 20250406, 128, 2, '发货慢，包装差。', NULL, NOW(), NOW()),
(1256, 20250407, 128, 3, '凑合能用，不推荐。', NULL, NOW(), NOW()),
-- product_id = 129 的两条评价
(1257, 20250408, 129, 5, '非常棒，超出期望。', NULL, NOW(), NOW()),
(1258, 20250409, 129, 5, '已经推荐给同事了。', NULL, NOW(), NOW()),
-- product_id = 130 的两条评价
(1259, 20250410, 130, 4, '质量可以，价格适中。', NULL, NOW(), NOW()),
(1260, 20250411, 130, 3, '一般，没有想象中的好。', NULL, NOW(), NOW()),
-- product_id = 131 的两条评价
(1261, 20250412, 131, 5, '做工很好，喜欢。', NULL, NOW(), NOW()),
(1262, 20250413, 131, 4, '不错，会再来。', NULL, NOW(), NOW()),
-- product_id = 132 的两条评价
(1263, 20250414, 132, 3, '普通，无功无过。', NULL, NOW(), NOW()),
(1264, 20250415, 132, 5, '给家人买的，都说好。', NULL, NOW(), NOW()),
-- product_id = 133 的两条评价
(1265, 20250416, 133, 4, '款式可以，质量也行。', NULL, NOW(), NOW()),
(1266, 20250417, 133, 5, '很好用，设计贴心。', NULL, NOW(), NOW()),
-- product_id = 134 的两条评价
(1267, 20250418, 134, 2, '有点失望，不值。', NULL, NOW(), NOW()),
(1268, 20250419, 134, 3, '凑合吧，便宜货。', NULL, NOW(), NOW()),
-- product_id = 135 的两条评价
(1269, 20250420, 135, 5, '很高档，朋友都问链接。', NULL, NOW(), NOW()),
(1270, 20250421, 135, 4, '满意，还会继续关注。', NULL, NOW(), NOW()),
-- product_id = 136 的两条评价
(1271, 20250422, 136, 3, '一般般，物流快。', NULL, NOW(), NOW()),
(1272, 20250423, 136, 5, '质量过硬，值得信赖。', NULL, NOW(), NOW()),
-- product_id = 137 的两条评价
(1273, 20250424, 137, 4, '性价比高，日常用。', NULL, NOW(), NOW()),
(1274, 20250425, 137, 5, '非常好，会回购。', NULL, NOW(), NOW()),
-- product_id = 138 的两条评价
(1275, 20250426, 138, 2, '收到时发现划痕。', NULL, NOW(), NOW()),
(1276, 20250427, 138, 3, '能用，但品控需加强。', NULL, NOW(), NOW()),
-- product_id = 139 的两条评价
(1277, 20250428, 139, 5, '和图片一模一样，赞。', NULL, NOW(), NOW()),
(1278, 20250429, 139, 4, '包装严实，送人好看。', NULL, NOW(), NOW()),
-- product_id = 140 的两条评价
(1279, 20250430, 140, 3, '还行，没什么特别。', NULL, NOW(), NOW()),
(1280, 20250501, 140, 5, '很满意，颜色高级。', NULL, NOW(), NOW()),
-- product_id = 141 的两条评价
(1281, 20250502, 141, 4, '不错，大小正好。', NULL, NOW(), NOW()),
(1282, 20250503, 141, 5, '会推荐给朋友。', NULL, NOW(), NOW()),
-- product_id = 142 的两条评价
(1283, 20250504, 142, 2, '有瑕疵，退换麻烦。', NULL, NOW(), NOW()),
(1284, 20250505, 142, 3, '一般，不推荐。', NULL, NOW(), NOW()),
-- product_id = 143 的两条评价
(1285, 20250506, 143, 5, '买了很多次了，质量稳定。', NULL, NOW(), NOW()),
(1286, 20250507, 143, 5, '发货快，没破损。', NULL, NOW(), NOW()),
-- product_id = 144 的两条评价
(1287, 20250508, 144, 4, '性价比高，功能简单实用。', NULL, NOW(), NOW()),
(1288, 20250509, 144, 3, '勉强能接受。', NULL, NOW(), NOW()),
-- product_id = 145 的两条评价
(1289, 20250510, 145, 5, '非常漂亮，家人都喜欢。', NULL, NOW(), NOW()),
(1290, 20250511, 145, 4, '物美价廉。', NULL, NOW(), NOW()),
-- product_id = 146 的两条评价
(1291, 20250512, 146, 2, '不好用，差评。', NULL, NOW(), NOW()),
(1292, 20250513, 146, 3, '一般，不推荐购买。', NULL, NOW(), NOW()),
-- product_id = 147 的两条评价
(1293, 20250514, 147, 5, '做工讲究，细节完美。', NULL, NOW(), NOW()),
(1294, 20250515, 147, 5, '很棒，已经回购。', NULL, NOW(), NOW()),
-- product_id = 148 的两条评价
(1295, 20250516, 148, 4, '还不错，物流很快。', NULL, NOW(), NOW()),
(1296, 20250517, 148, 3, '一般水平，没什么惊艳。', NULL, NOW(), NOW()),
-- product_id = 149 的两条评价
(1297, 20250518, 149, 5, '很满意的一次购物。', NULL, NOW(), NOW()),
(1298, 20250519, 149, 4, '东西好用，客服态度好。', NULL, NOW(), NOW()),
-- product_id = 150 的两条评价
(1299, 20250520, 150, 3, '中规中矩，价格合适。', NULL, NOW(), NOW()),
(1300, 20250521, 150, 5, '非常好，下次还来。', NULL, NOW(), NOW()),
-- product_id = 151 的两条评价
(1301, 20250522, 151, 4, '颜色好看，尺寸合适。', NULL, NOW(), NOW()),
(1302, 20250523, 151, 5, '买给父母的，都说好。', NULL, NOW(), NOW()),
-- product_id = 152 的两条评价
(1303, 20250524, 152, 2, '质量差，用了几天就坏了。', NULL, NOW(), NOW()),
(1304, 20250525, 152, 3, '能用，但质量堪忧。', NULL, NOW(), NOW()),
-- product_id = 153 的两条评价
(1305, 20250526, 153, 5, '完美，挑不出任何毛病。', NULL, NOW(), NOW()),
(1306, 20250527, 153, 5, '非常喜欢，会回购。', NULL, NOW(), NOW()),
-- product_id = 154 的两条评价
(1307, 20250528, 154, 3, '一般般，对得起价格。', NULL, NOW(), NOW()),
(1308, 20250529, 154, 4, '还算满意，物流不错。', NULL, NOW(), NOW()),
-- product_id = 155 的两条评价
(1309, 20250530, 155, 5, '手感很好，颜值爆表。', NULL, NOW(), NOW()),
(1310, 20250531, 155, 4, '包装用心，商品不错。', NULL, NOW(), NOW()),
-- product_id = 156 的两条评价
(1311, 20250601, 156, 2, '有瑕疵，差评。', NULL, NOW(), NOW()),
(1312, 20250602, 156, 3, '一般，不推荐。', NULL, NOW(), NOW()),
-- product_id = 157 的两条评价
(1313, 20250603, 157, 5, '细节精致，爱不释手。', NULL, NOW(), NOW()),
(1314, 20250604, 157, 4, '同事看了想买同款。', NULL, NOW(), NOW()),
-- product_id = 158 的两条评价
(1315, 20250605, 158, 3, '没有预期的好。', NULL, NOW(), NOW()),
(1316, 20250606, 158, 5, '性价比高，会再买。', NULL, NOW(), NOW()),
-- product_id = 159 的两条评价
(1317, 20250607, 159, 4, '挺好的，满意。', NULL, NOW(), NOW()),
(1318, 20250608, 159, 5, '质量不错，发货快。', NULL, NOW(), NOW()),
-- product_id = 160 的两条评价
(1319, 20250609, 160, 3, '普通，没有特别之处。', NULL, NOW(), NOW()),
(1320, 20250610, 160, 5, '很不错，会回购。', NULL, NOW(), NOW()),
-- product_id = 161 的两条评价
(1321, 20250611, 161, 4, '做工可以，价格实在。', NULL, NOW(), NOW()),
(1322, 20250612, 161, 5, '满意，下次还来。', NULL, NOW(), NOW()),
-- product_id = 162 的两条评价
(1323, 20250613, 162, 2, '有瑕疵，勉强接受。', NULL, NOW(), NOW()),
(1324, 20250614, 162, 3, '一般水平。', NULL, NOW(), NOW()),
-- product_id = 163 的两条评价
(1325, 20250615, 163, 5, '非常精致，推荐。', NULL, NOW(), NOW()),
(1326, 20250616, 163, 4, '物流快，包装好。', NULL, NOW(), NOW()),
-- product_id = 164 的两条评价
(1327, 20250617, 164, 3, '能用，没亮点。', NULL, NOW(), NOW()),
(1328, 20250618, 164, 5, '品质很好，回购。', NULL, NOW(), NOW()),
-- product_id = 165 的两条评价
(1329, 20250619, 165, 4, '物美价廉，不错。', NULL, NOW(), NOW()),
(1330, 20250620, 165, 5, '很棒，朋友都说好看。', NULL, NOW(), NOW()),
-- product_id = 166 的两条评价
(1331, 20250621, 166, 2, '不太满意，做工粗糙。', NULL, NOW(), NOW()),
(1332, 20250622, 166, 3, '一般般，不推荐。', NULL, NOW(), NOW()),
-- product_id = 167 的两条评价
(1333, 20250623, 167, 5, '质感很好，上档次。', NULL, NOW(), NOW()),
(1334, 20250624, 167, 5, '会再来的，好店。', NULL, NOW(), NOW()),
-- product_id = 168 的两条评价
(1335, 20250625, 168, 4, '挺不错的，物流快。', NULL, NOW(), NOW()),
(1336, 20250626, 168, 3, '价格合适，品质一般。', NULL, NOW(), NOW()),
-- product_id = 169 的两条评价
(1337, 20250627, 169, 5, '颜值和实用性并存。', NULL, NOW(), NOW()),
(1338, 20250628, 169, 4, '很满意，就是等得久了点。', NULL, NOW(), NOW()),
-- product_id = 170 的两条评价
(1339, 20250629, 170, 3, '普通，没有惊喜。', NULL, NOW(), NOW()),
(1340, 20250630, 170, 5, '买对了，家人都说好。', NULL, NOW(), NOW());
