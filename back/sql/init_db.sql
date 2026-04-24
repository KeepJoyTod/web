-- --------------------------------------------------
-- ProjectKu 数据库完整初始化脚本（修复版）
-- 包含所有表结构、基础数据、商品、订单等
-- --------------------------------------------------

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- 0. 创建并选择数据库
-- ----------------------------
CREATE DATABASE IF NOT EXISTS `web`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE `web`;

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
  PRIMARY KEY (`id`)
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
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`)
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
INSERT INTO `users`(`account`, `password`, `nickname`) VALUES 
('user@example.com','e10adc3949ba59abbe56e057f20f883e','测试用户'),
('alice@example.com','e10adc3949ba59abbe56e057f20f883e','Alice');

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

-- 可选：添加几条商品媒体和SKU示例（供测试）
INSERT INTO `product_media`(`product_id`, `url`, `sort_order`) VALUES
(1, 'https://example.com/iphone15_1.jpg', 1),
(1, 'https://example.com/iphone15_2.jpg', 2);
INSERT INTO `product_skus`(`product_id`, `attrs`, `price`, `stock`) VALUES
(1, '{"颜色":"黑色","容量":"128G"}', 7999.00, 50),
(1, '{"颜色":"白色","容量":"128G"}', 7999.00, 50);

-- 3.7 评价数据
INSERT INTO `reviews`(`user_id`, `product_id`, `rating`, `content`, `create_time`) VALUES
(2, 1, 5, '性能非常强劲，拍照效果无敌！', NOW() - INTERVAL 2 DAY),
(1, 1, 4, '手感很好，就是有点贵，希望能多用几年。', NOW() - INTERVAL 5 DAY);

SET FOREIGN_KEY_CHECKS = 1;
