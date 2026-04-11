-- Seed demo data for  (idempotent-ish)

-- Users
INSERT INTO users(account, password, nickname)
VALUES 
('user@example.com','e10adc3949ba59abbe56e057f20f883e','测试用户'),
('alice@example.com','e10adc3949ba59abbe56e057f20f883e','Alice')
ON DUPLICATE KEY UPDATE nickname=VALUES(nickname), update_time=NOW();

-- Products
-- 先清理 5-8 类商品数据
DELETE FROM products WHERE category_id IN (5,6,7,8);
-- 避免重复：删除将要插入的同名商品（幂等化）
DELETE FROM products WHERE name IN (
  'iPhone 15 128G','iPhone 15 Pro 256G','Xiaomi 14 256G','Huawei Mate 60 256G','OPPO Find X7 Pro 12+256','vivo X100 12+256',
  'MacBook Air 13 M3 16G','MacBook Pro 14 M3 Pro 16G','ThinkPad X1 Carbon','Dell XPS 13 9320','Lenovo Legion R9000P 2024','HP Spectre x360 14',
  '戴森 V12 Detect Slim','米家扫拖机器人 S8','美的 KFR-35GW 大1.5匹空调','海尔 456L 对开门冰箱',
  '索尼 WH-1000XM5','AirPods Pro 2','Anker 65W GaN 充电器','SanDisk Extreme Pro 1TB 移动固态'
);
-- 插入 20 条真实商品数据（覆盖 1-4 类）
INSERT INTO products(category_id, name, description, price, stock, status) VALUES
-- 1: 手机
(1,'iPhone 15 128G','苹果 A16，6.1 英寸 OLED，双摄',5999.00,200,1),
(1,'iPhone 15 Pro 256G','A17 Pro，钛合金机身，ProMotion 120Hz',8999.00,120,1),
(1,'Xiaomi 14 256G','徕卡光学影像，骁龙 8 Gen3',4299.00,300,1),
(1,'Huawei Mate 60 256G','昆仑玻璃，卫星通信',5699.00,150,1),
(1,'OPPO Find X7 Pro 12+256','潜望长焦，超帧画质',5499.00,180,1),
(1,'vivo X100 12+256','蔡司影像，自研影像芯片',4999.00,160,1),
-- 2: 电脑
(2,'MacBook Air 13 M3 16G','轻薄本，日常学习办公优选',9999.00,80,1),
(2,'MacBook Pro 14 M3 Pro 16G','专业创作，Liquid Retina XDR',14999.00,40,1),
(2,'ThinkPad X1 Carbon','商务轻薄，高可靠性',12999.00,50,1),
(2,'Dell XPS 13 9320','InfinityEdge 13.4 英寸屏',10999.00,60,1),
(2,'Lenovo Legion R9000P 2024','RTX 4070，2.5K 240Hz',8999.00,55,1),
(2,'HP Spectre x360 14','2 合 1 触控本',8999.00,30,1),
-- 3: 家电
(3,'戴森 V12 Detect Slim','激光显尘，强劲吸力',3999.00,100,1),
(3,'米家扫拖机器人 S8','激光导航，自动回充',1799.00,200,1),
(3,'美的 KFR-35GW 大1.5匹空调','变频节能，自清洁',2699.00,80,1),
(3,'海尔 456L 对开门冰箱','风冷无霜，纤薄机身',4299.00,45,1),
-- 4: 数码配件
(4,'索尼 WH-1000XM5','旗舰降噪耳机，舒适佩戴',2599.00,150,1),
(4,'AirPods Pro 2','主动降噪，通透模式',1999.00,180,1),
(4,'Anker 65W GaN 充电器','三口快充，折叠插脚',199.00,500,1),
(4,'SanDisk Extreme Pro 1TB 移动固态','USB 3.2 Gen2，高速传输',999.00,220,1);

-- Default address for user 1
INSERT INTO user_addresses(user_id, receiver, phone, region, detail, is_default)
VALUES (1,'张三','13800000000','北京','朝阳区建国路 88 号',1);

-- Coupon for user 1
INSERT INTO coupons(user_id, code, name, type, min_amount, discount_amount, status, start_time, end_time)
VALUES (1,'NEW300','新客满5000-300','FULL_REDUCTION',5000.00,300.00,'VALID', NOW() - INTERVAL 1 DAY, NOW() + INTERVAL 30 DAY)
ON DUPLICATE KEY UPDATE name=VALUES(name), update_time=NOW();

-- Example orders for user 1
-- Paid order
INSERT INTO orders(user_id, order_no, total_amount, pay_amount, status, address_id)
VALUES (1,'A20260405001',9999.00,9999.00,1, (SELECT id FROM user_addresses WHERE user_id=1 ORDER BY id DESC LIMIT 1));
INSERT INTO order_items(order_id, product_id, product_name, price, quantity, total_amount)
SELECT o.id, p.id, p.name, 9999.00, 1, 9999.00
FROM orders o JOIN products p ON p.name='MacBook Air 13 M3 16G'
WHERE o.order_no='A20260405001';
INSERT INTO payments(order_id, trade_id, channel, amount, status, paid_at)
SELECT o.id, 'T20260405001', 'alipay', 9999.00, 'SUCCESS', NOW() FROM orders o WHERE o.order_no='A20260405001';

-- Created (unpaid) order
INSERT INTO orders(user_id, order_no, total_amount, pay_amount, status, address_id)
VALUES (1,'A20260405002',4299.00,4299.00,0, (SELECT id FROM user_addresses WHERE user_id=1 ORDER BY id DESC LIMIT 1));
INSERT INTO order_items(order_id, product_id, product_name, price, quantity, total_amount)
SELECT o.id, p.id, p.name, 4299.00, 1, 4299.00
FROM orders o JOIN products p ON p.name='Xiaomi 14 256G'
WHERE o.order_no='A20260405002';
INSERT INTO payments(order_id, trade_id, channel, amount, status, paid_at)
SELECT o.id, 'T20260405002', 'alipay', 4299.00, 'PENDING', NULL FROM orders o WHERE o.order_no='A20260405002';
