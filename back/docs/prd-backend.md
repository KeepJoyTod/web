# 企业级电商平台 PRD（后端篇）

## 1. 文档目的
- 明确后端业务域、接口契约、数据模型、业务流程、非功能SLO、安全与合规、运维与可观测，支撑稳定可扩展的电商交易闭环。

## 2. 业务范围与域边界
- 范围：商品目录与SKU、库存与价格、促销与优惠券、购物车、订单、支付、发货与物流、评价、售后、会员与成长、消息通知、结算与对账、报表。
- 边界：不自建支付清结算（对接支付宝/微信/Stripe），不自建物流（对接三方），跨境税务由三方服务对接。

## 3. 服务/模块划分（模块化单体→可演进为服务）
- 商品域（catalog）：SPU/SKU、属性模板、媒体、上/下架
- 价规与库存（pricing/inventory）：价格、活动价、渠道价、库存预占与回滚
- 购物车（cart）：跨端合并、活动与券可用性计算
- 促销与券（promo）：规则引擎、优惠叠加与优先级
- 订单（order）：下单校验、拆单/合单可选、状态机
- 支付（payment）：统一收银台、回调处理、幂等与补偿
- 履约（fulfillment）：仓配选择、出库、物流、签收
- 售后（aftersales）：仅退款/退货退款、逆向物流、质检、退款入账
- 会员（member）：积分、等级、权益
- 结算与对账（settlement/recon）：商家结算、对账差异处理
- 报表与分析（reporting）：GMV、转化、活动效果
- 风控（risk）：黑名单、设备指纹、行为评分、频控
- 权限与审计（auth/rbac）：组织、角色、菜单/数据范围、审计日志
- 配置与开关（config/feature-flags）：站点配置、开关、灰度与A/B

## 4. 数据模型（核心表，节选）
- 用户与权限：users、roles、role_permissions、user_addresses、user_points、invoices、audit_logs
- 商品与类目：categories、attributes、attribute_values、products（SPU）、product_skus（SKU）、sku_prices、sku_inventory、media_assets
- 交易：carts、cart_items、orders、order_items、order_coupons、payments、refunds、shipments、invoices_issued
- 营销：coupons、coupon_templates、promotions、promotion_rules、membership_levels
- 商家与结算：merchants、stores、settlements、settlement_items、reconciliation_records
- 内容与互动：reviews、review_media、favorites、footprints
- 系统：notifications、config_entries、feature_flags、risk_events

## 5. 核心流程
- 注册登录：手机号/邮箱/OAuth，短信/邮件验证码，风控拦截
- 下单（二次校验）：收货地址与发票 → 库存预占 → 价规重算 → 优惠券核销预占 → 生成订单（状态：Created）→ 支付期内待支付
- 支付：创建交易单 → 跳转/唤起支付 → 回调验签 → 幂等落单（Paid/Failed）→ 失败则可重试/关单
- 履约：仓配选择 → 出库生成物流单 → 轨迹同步 → 签收 → 订单完成
- 售后：用户申请 → 审核 → 逆向物流 → 质检 → 退款单入账 → 订单状态与结算联动
- 结算与对账：按周期生成商家结算单（佣金/手续费/退款冲减）→ 拉取网关对账单 → 差异处理（短/长/错账）

## 6. 接口与契约
- API 风格：REST，版本化 /v1；服务间调用可用 gRPC/事件流（可选）
- 规范：幂等性（Idempotency-Key）、签名（服务间）、一致的错误码与错误语义
- 身份鉴权：OAuth2.1/JWT；敏感接口二次校验（短信/邮箱）；RBAC + 数据范围（按商家/店铺）
- 示例（节选）
  - GET /v1/products?keyword=&category=&sort=&page=
  - GET /v1/products/{id}
  - POST /v1/cart/items
  - POST /v1/orders/checkout
  - POST /v1/payments/{orderId}/pay
  - POST /v1/aftersales/apply
  - GET /v1/shipments/{orderId}/tracking

## 7. 非功能与SLO
- 可用性：99.9%/月；核心链路（下单/支付）降级≤5分钟
- 性能：缓存命中 p95 接口 <200ms；峰值容量按大促×5 冗余
- 一致性：订单/支付/库存使用最终一致性 + 补偿；关键路径清晰事务边界
- 可扩展：多商家、多仓、多币种、多语言（配置驱动）

## 8. 安全与合规
- 安全：OWASP Top 10、防刷/防爬、CSRF/XSS/SQLi防护、密码加盐、敏感数据脱敏；支付回调隔离与最小权限
- 风控：高危名单、设备指纹、异常地理位置、下单行为评分、支付重试限制、IP/UA/频控
- 合规：PIPL/GDPR、数据可导出/删除、日志留存与审计、Cookie 同意

## 9. 集成与依赖
- 支付：支付宝/微信/Stripe（统一收银台，交易单与业务单解耦；回调幂等、重试与补单）
- 短信：阿里云/腾讯云；邮件：企业邮/第三方服务
- 物流：快递鸟/菜鸟/Shippo 等
- 对象存储：OSS/S3/MinIO
- 搜索：Elasticsearch（可选）
- 消息：Kafka/RabbitMQ；缓存：Redis；数据库：MySQL 8

## 10. 技术架构建议
- Java 17 + Spring Boot 3；MyBatis/JPA 二选一；分层架构或模块化单体
- 网关：Nginx/API Gateway；限流/熔断/降级；分布式锁与任务调度
- 事件驱动：订单/支付/库存/营销关键事件上报（用于异步任务与分析）
- 可观测性：Prometheus + Grafana + Loki；分布式追踪；审计日志
- CI/CD：流水线构建、单元/集成测试、灰度发布、回滚

## 11. 结算、对账与分账
- 结算：周期生成商家结算单（含佣金/手续费/退款冲减）→ 复核 → 打款 → 回填流水
- 对账：拉取网关对账单 → 差异识别（短/长/错账）→ 差异单处理与补偿
- 分账（可选）：多商户资金分配策略、合规风控

## 12. 报表与BI
- 实时与离线结合：交易关键指标实时聚合；活动与用户画像离线数仓（后续）
- 指标：UV、转化漏斗、客单价、复购、券核销、活动GMV、履约时效、售后率

## 13. 版本规划与准入
- MVP：商品/购物车/下单/支付闭环；履约与物流查询；售后（仅退款）；基础券；商家发货；基础报表
- 1.0：满减/折扣/限时购；退货退款；会员与积分；结算对账；风控；埋点与看板
- 准入：单测≥70%；核心链路E2E通过；压测达峰值×1.5；回滚演练；运行手册与应急预案

## 14. 验收标准（后端侧）
- 下单/支付/退款/履约/售后全链路状态一致、幂等与补偿完善
- 优惠计算准确、冲突优先级符合规则；对账差异可被识别与处理
- 核心接口性能达标、错误率与慢查询受控；安全与合规检查通过

## 15. 风险与对策
- 大促峰值：容量规划、缓存与降级、消息队列削峰、读写分离
- 支付回调可靠性：幂等键、重试队列、对账补偿、超时关单
- 营销复杂度：规则引擎化、优先级矩阵、回归用例库
- 数据一致性：明确事务边界、最终一致性模型与定期巡检任务

## 16. 接口契约（完整引用）
- 完整接口契约文档位置：[api-contract.md](file:///d:/Java/class/projectKu/web/docs/api-contract.md)
- 公共约定
  - Base URL：/v1；统一 Headers：Authorization、Idempotency-Key、X-Client-Version、X-Request-Id
  - 统一错误码与响应结构；写接口要求幂等（Idempotency-Key），敏感动作二次校验，限流标准化
- 服务端端点（节选，与域模块对应）
  - 类目与商品：GET /v1/categories、GET /v1/products、GET /v1/products/{id}、GET /v1/products/{id}/reviews
  - 购物车：GET /v1/cart、POST/PUT/DELETE /v1/cart/items、POST /v1/cart/apply-coupon
  - 订单：POST /v1/orders/checkout、GET /v1/orders、GET /v1/orders/{id}、POST /v1/orders/{id}/cancel
  - 支付：POST /v1/payments/{orderId}/pay、GET /v1/payments/{orderId}/status、POST /v1/payments/webhook
  - 履约与物流：GET /v1/shipments/{orderId}/tracking
  - 售后与评价：POST /v1/aftersales/apply、GET /v1/aftersales、POST /v1/aftersales/{id}/cancel、POST /v1/reviews
  - 营销与会员：GET /v1/coupons/available、POST /v1/coupons/{code}/check、GET /v1/memberships/me、GET /v1/points/ledger
  - 消息与商家后台：GET /v1/notifications、POST /v1/notifications/{id}/read、GET /v1/merchant/products、POST /v1/merchant/products、GET /v1/merchant/settlements
  - # 电商平台 前后端接口契约（v1）
  
    ## 0. 总览与约定
  
    - Base URL：/v1
    - Headers
      - Content-Type: application/json
      - Accept: application/json
      - Authorization: Bearer <jwt>（登录后端返回）
      - X-Client-Version: <semver>（前端版本号）
      - Idempotency-Key: <uuid>（用于创建/支付等需要幂等的接口）
      - X-Request-Id: <uuid>（链路追踪）
    - 分页与排序
      - 请求：page（默认1）、pageSize（默认20）、sort（字段名）、order（asc|desc）
      - 响应：meta.page、meta.pageSize、meta.total
    - 成功响应
  
    ```json
    { "data": {}, "meta": { "requestId": "xxxx" } }
    ```
  
    - 错误响应
  
    ```json
    { "error": { "code": "PRODUCT_NOT_FOUND", "message": "商品不存在" }, "meta": { "requestId": "xxxx" } }
    ```
  
    ## 1. 认证与用户
  
    - 登录
      - POST /v1/auth/login
      - 请求
  
    ```json
    { "account": "user@example.com", "password": "hashed-or-plain-by-agreement" }
    ```
  
      - 响应
  
    ```json
    { "data": { "token": "jwt-token", "expiresIn": 7200, "user": { "id": "u_1", "nickname": "张三" } } }
    ```
  
    - 刷新令牌
      - POST /v1/auth/refresh
  
    ```json
    { "data": { "token": "new-jwt-token", "expiresIn": 7200 } }
    ```
  
    - 当前用户
      - GET /v1/me
  
    ```json
    { "data": { "id": "u_1", "nickname": "张三", "phone": "138****0000", "email": "user@example.com" } }
    ```
  
    - 地址簿
      - GET /v1/me/addresses
  
    ```json
    { "data": [ { "id": "addr_1", "receiver": "张三", "phone": "13800000000", "region": "北京", "detail": "朝阳区xx路", "isDefault": true } ], "meta": { "total": 1 } }
    ```
  
      - POST /v1/me/addresses
  
    ```json
    { "receiver": "张三", "phone": "13800000000", "region": "北京", "detail": "朝阳区xx路", "isDefault": false }
    ```
  
    ## 2. 类目与商品
  
    - 获取类目树
      - GET /v1/categories
  
    ```json
    { "data": [ { "id": "c_1", "name": "手机", "children": [ { "id": "c_1_1", "name": "智能手机" } ] } ] }
    ```
  
    - 搜索商品列表
      - GET /v1/products?keyword=&category=&brand=&minPrice=&maxPrice=&sort=&order=&page=&pageSize=
  
    ```json
    { "data": [ { "id": "p_1", "title": "iPhone 14", "price": 5999.00, "cover": "https://...", "tags": ["热卖"], "rating": 4.8 } ], "meta": { "page": 1, "pageSize": 20, "total": 1000 } }
    ```
  
    - 商品详情
      - GET /v1/products/{id}
  
    ```json
    { "data": { "id": "p_1", "title": "iPhone 14", "desc": "产品详情...", "skus": [ { "id": "sku_1", "attrs": { "颜色": "黑色", "容量": "128G" }, "price": 5999.00, "stock": 20 } ], "media": [ "https://img1", "https://img2" ], "activity": { "type": "limited_time", "label": "限时直降300" } } }
    ```
  
    - 商品评价列表
      - GET /v1/products/{id}/reviews?page=&pageSize=
  
    ```json
    { "data": [ { "id": "rv_1", "userId": "u_1", "rating": 5, "content": "很好用", "images": [] } ], "meta": { "page": 1, "pageSize": 10, "total": 120 } }
    ```
  
    ## 3. 购物车
  
    - 查询购物车
      - GET /v1/cart
  
    ```json
    { "data": { "items": [ { "itemId": "ci_1", "productId": "p_1", "skuId": "sku_1", "title": "iPhone 14", "price": 5999.00, "qty": 1, "cover": "https://..." } ], "summary": { "original": 5999.00, "discount": 300.00, "payable": 5699.00, "promotions": [ { "type": "full_reduction", "desc": "满5000-300" } ] } } }
    ```
  
    - 加入/更新/删除
      - POST /v1/cart/items
  
    ```json
    { "productId": "p_1", "skuId": "sku_1", "qty": 2, "source": "product_detail" }
    ```
  
      - PUT /v1/cart/items/{itemId}
  
    ```json
    { "qty": 3 }
    ```
  
      - DELETE /v1/cart/items/{itemId}
  
    ```json
    { "data": true }
    ```
  
    - 应用优惠券（校验与提示）
      - POST /v1/cart/apply-coupon
  
    ```json
    { "code": "NEW300" }
    ```
  
    ```json
    { "data": { "valid": true, "discount": 300.00, "reason": null } }
    ```
  
    ## 4. 下单与订单
  
    - 结算与下单（二次校验）
      - POST /v1/orders/checkout
  
    ```json
    { "addressId": "addr_1", "invoice": { "type": "normal", "title": "个人" }, "delivery": { "method": "express", "schedule": null }, "couponCode": "NEW300", "usePoints": 0 }
    ```
  
    ```json
    { "data": { "orderId": "o_1", "amounts": { "items": 5999.00, "discount": 300.00, "shipping": 0.00, "payable": 5699.00 }, "expiresAt": "2026-03-31T12:00:00Z" } }
    ```
  
    - 订单列表与详情
      - GET /v1/orders?page=&pageSize=&status=
  
    ```json
    { "data": [ { "id": "o_1", "status": "Created", "payable": 5699.00, "createdAt": "2026-03-31T10:00:00Z" } ], "meta": { "page": 1, "pageSize": 20, "total": 10 } }
    ```
  
      - GET /v1/orders/{id}
  
    ```json
    { "data": { "id": "o_1", "status": "Paid", "items": [ { "productId": "p_1", "skuId": "sku_1", "title": "iPhone 14", "price": 5699.00, "qty": 1 } ], "amounts": { "items": 5999.00, "discount": 300.00, "shipping": 0, "paid": 5699.00 }, "address": { "receiver": "张三", "phone": "138...", "detail": "北京..." } } }
    ```
  
    - 取消订单
      - POST /v1/orders/{id}/cancel
  
    ```json
    { "reason": "下错单" }
    ```
  
    ```json
    { "data": true }
    ```
  
    ## 5. 支付
  
    - 发起支付
      - POST /v1/payments/{orderId}/pay
  
    ```json
    { "channel": "alipay", "returnUrl": "https://shop.example.com/pay-return" }
    ```
  
    ```json
    { "data": { "tradeId": "t_1", "channel": "alipay", "params": { "qr": "https://...", "sdk": null }, "expiresAt": "2026-03-31T12:00:00Z" } }
    ```
  
    - 查询支付状态
      - GET /v1/payments/{orderId}/status
  
    ```json
    { "data": { "status": "SUCCESS", "paidAt": "2026-03-31T10:05:00Z" } }
    ```
  
    - 支付回调（后端接收）
      - POST /v1/payments/webhook
  
    ```json
    { "gateway": "alipay", "tradeId": "t_1", "status": "SUCCESS", "sign": "..." }
    ```
  
    ## 6. 履约与物流
  
    - 物流轨迹
      - GET /v1/shipments/{orderId}/tracking
  
    ```json
    { "data": { "orderId": "o_1", "carrier": "SF", "waybillNo": "SF123", "events": [ { "time": "2026-03-31T11:00:00Z", "desc": "已揽收" } ] } }
    ```
  
    ## 7. 售后与评价
  
    - 售后申请
      - POST /v1/aftersales/apply
  
    ```json
    { "orderId": "o_1", "type": "refund_only", "items": [ { "orderItemId": "oi_1", "qty": 1 } ], "reason": "质量问题", "evidence": [ "https://img1" ] }
    ```
  
    ```json
    { "data": { "aftersaleId": "as_1", "status": "Submitted" } }
    ```
  
    - 查询与取消
      - GET /v1/aftersales?page=&pageSize=
  
    ```json
    { "data": [ { "id": "as_1", "orderId": "o_1", "status": "Processing" } ], "meta": { "page": 1, "pageSize": 20, "total": 1 } }
    ```
  
      - POST /v1/aftersales/{id}/cancel
  
    ```json
    { "data": true }
    ```
  
    - 发布评价
      - POST /v1/reviews
  
    ```json
    { "orderId": "o_1", "productId": "p_1", "rating": 5, "content": "很好用", "images": [] }
    ```
  
    ```json
    { "data": { "reviewId": "rv_2" } }
    ```
  
    ## 8. 营销与会员
  
    - 可用优惠券
      - GET /v1/coupons/available?scene=cart
  
    ```json
    { "data": [ { "code": "NEW300", "desc": "新客满5000-300", "valid": true } ] }
    ```
  
    - 校验券
      - POST /v1/coupons/{code}/check
  
    ```json
    { "scene": "checkout", "cartSummary": { "amount": 5999.00 } }
    ```
  
    ```json
    { "data": { "valid": true, "discount": 300.00, "reason": null } }
    ```
  
    - 会员与积分
      - GET /v1/memberships/me
  
    ```json
    { "data": { "level": "Gold", "benefits": [ "95折" ] } }
    ```
  
      - GET /v1/points/ledger?page=&pageSize=
  
    ```json
    { "data": [ { "id": "pt_1", "delta": 100, "reason": "下单赠送", "ts": "2026-03-31T10:00:00Z" } ], "meta": { "page": 1, "pageSize": 20, "total": 10 } }
    ```
  
    ## 9. 消息与通知
  
    - 通知列表
      - GET /v1/notifications?page=&pageSize=&status=
  
    ```json
    { "data": [ { "id": "n_1", "type": "order_paid", "title": "订单已支付", "read": false, "ts": "2026-03-31T10:05:00Z" } ], "meta": { "page": 1, "pageSize": 20, "total": 5 } }
    ```
  
    - 标记已读
      - POST /v1/notifications/{id}/read
  
    ```json
    { "data": true }
    ```
  
    ## 10. 商家与结算（后台）
  
    - 商家商品列表
      - GET /v1/merchant/products?page=&pageSize=&status=
  
    ```json
    { "data": [ { "id": "p_1", "title": "iPhone 14", "status": "online", "stock": 20 } ], "meta": { "page": 1, "pageSize": 20, "total": 10 } }
    ```
  
    - 新建商品
      - POST /v1/merchant/products
  
    ```json
    { "title": "新商品", "spu": "SPU123", "skus": [ { "attrs": { "颜色": "黑色" }, "price": 199.00, "stock": 100 } ] }
    ```
  
    ```json
    { "data": { "id": "p_new" } }
    ```
  
    - 商家结算单
      - GET /v1/merchant/settlements?page=&pageSize=
  
    ```json
    { "data": [ { "id": "st_1", "period": "2026-03", "amount": 100000.00, "status": "Pending" } ], "meta": { "page": 1, "pageSize": 20, "total": 2 } }
    ```
  
    ## 11. 安全、幂等与限流
  
    - 幂等：对 POST /orders/checkout、POST /payments/.../pay、POST /aftersales/apply 等必须传 Idempotency-Key；后端以键+业务唯一约束去重。
    - 限流：公共读接口按 IP 与 UA 限流；写接口按用户与资源维度限流；返回标准错误码 "RATE_LIMITED"。
    - 二次校验：敏感动作（绑定支付、发起高额售后）需短信/邮件验证码校验。
  
    ## 12. 错误码示例
  
    ```json
    [
      { "code": "UNAUTHORIZED", "http": 401, "message": "未登录或令牌失效" },
      { "code": "FORBIDDEN", "http": 403, "message": "无权限访问" },
      { "code": "VALIDATION_FAILED", "http": 400, "message": "参数校验失败" },
      { "code": "PRODUCT_NOT_FOUND", "http": 404, "message": "商品不存在" },
      { "code": "INSUFFICIENT_STOCK", "http": 409, "message": "库存不足" },
      { "code": "COUPON_INVALID", "http": 409, "message": "优惠券不可用" },
      { "code": "ORDER_STATE_INVALID", "http": 409, "message": "订单状态不允许该操作" },
      { "code": "PAYMENT_FAILED", "http": 400, "message": "支付失败" },
      { "code": "RATE_LIMITED", "http": 429, "message": "请求过于频繁" },
      { "code": "INTERNAL_ERROR", "http": 500, "message": "服务器内部错误" }
    ]
    ```
  
    ## 13. 前后端映射说明
  
    - 前端页面调用点与接口
      - 列表页 → GET /v1/products
      - 详情页 → GET /v1/products/{id}、GET /v1/products/{id}/reviews
      - 购物车页 → GET /v1/cart、POST/PUT/DELETE /v1/cart/items、POST /v1/cart/apply-coupon
      - 结算页 → POST /v1/orders/checkout
      - 支付页/回跳 → POST /v1/payments/{orderId}/pay、GET /v1/payments/{orderId}/status
      - 订单页 → GET /v1/orders、GET /v1/orders/{id}、POST /v1/orders/{id}/cancel
      - 售后/评价 → POST /v1/aftersales/apply、GET /v1/aftersales、POST /v1/reviews
      - 个人中心 → GET /v1/me、GET/POST /v1/me/addresses、GET /v1/notifications、POST /v1/notifications/{id}/read
  
    
