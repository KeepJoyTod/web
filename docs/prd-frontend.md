# 企业级电商平台 PRD（前端篇）

## 1. 文档目的
- 将整体PRD按前后端解耦，明确前端范围、页面与交互、性能与可用性、埋点与接口契约，支撑快速上线与持续演进。

## 2. 目标与指标
- 业务目标：提升首页与商品页转化、缩短加购到支付路径、支撑大促稳定增长。
- 关键指标：注册转化≥35%；首页首屏TTFB≤300ms；商品详情页p95渲染≤1.2s；下单页到提交转化≥35%；支付成功后状态同步≤2s。

## 3. 版本范围
- MVP：目录/搜索/详情、购物车、下单与支付跳转、订单列表/详情、基础优惠券、售后（仅退款入口）、基础会员与消息中心。
- 1.0：满减/折扣/限时购、退货退款全流程、评价与追评、积分/会员等级、埋点看板。
- 1.1+：拼团/预售、个性化推荐、A/B与灰度、国际化与多币种切换。

## 4. 信息架构与页面地图
- 全局导航：首页、类目、搜索、购物车、我的
- 页面列表
  - 商品列表：类目/关键词搜索、排序（综合/销量/价格）、筛选（品牌/价格区间/规格）
  - 商品详情：SKU选择、价格与库存、活动信息、评价、推荐
  - 活动页：限时购/预售/拼团等
  - 购物车：批量编辑、跨店满减门槛提示、券可用性展示
  - 结算页：收货地址、配送/发票、价格明细（活动/券/积分）、提交订单
  - 支付结果：成功/失败/处理中态与重试入口
  - 订单：列表、详情、取消、售后入口、评价入口、发票申请
  - 售后：申请页（仅退款/退货退款）、进度页
  - 评价：发布评价（文字/图片/视频）、追评
  - 个人中心：资料/安全、地址簿、发票抬头、消息中心、会员与积分
  - 消息中心：站内信/系统通知、物流签收等
  - 登录注册：手机号/邮箱/第三方OAuth；短信/邮件验证码

## 5. 关键交互与状态管理
- 购物车
  - 跨端同步：登录态下与服务器合并；未登录存本地，登录后合并并提示差异
  - 实时优惠：展示满减/折扣/券可用性与门槛提醒；冲突规则按后端返回优先级
- 详情页SKU选择：实时校验库存与价规；不可售SKU置灰并提示
- 提交订单：提交前对地址、发票、配送、价格明细进行前置校验；提交中显示加载阻断二次点击
- 支付：统一收银台参数由后端返回；回跳后展示最终状态；失败支持重试与更换支付方式
- 错误态与空态：网络错误、无结果、库存不足、活动结束、券不可用等均有明确提示与引导
- 状态管理：Pinia 管理用户、购物车、订单草稿、营销上下文；关键数据持久化（localStorage + 版本号）

## 6. 性能、SEO 与体验
- 性能
  - p95首屏≤1.2s：关键路径资源压缩与拆分、路由级按需加载、组件懒加载
  - 缓存：静态资源CDN；列表页与详情页数据短期缓存；骨架屏与占位图
  - 预取：首页→列表→详情常用链路预取关键数据；下单前预取地址与默认发票
- SEO/可索引
  - 商品详情页SSR/预渲染（Prerender），规范化URL与面包屑、结构化数据（schema.org Product）
  - 元信息与Open Graph完善，404/301正确处理
- 可访问性（a11y）
  - 表单/按钮语义化、键盘可达、对比度合规、图片alt、直播区域减少动画干扰
- 体验细节
  - 骨架屏、乐观更新（加购）、优雅降级（活动/券无法实时计算时以最稳妥展示）

## 7. 埋点与监控
- 行为事件
  - 曝光/点击：banner、商品卡
  - 加购：商品ID、SKU、来源位、活动上下文
  - 结算：下单页曝光、提交点击、失败原因
  - 支付：收银台曝光、拉起、结果
  - 评价与售后：入口点击、提交
- 技术监控：JS错误率、接口错误率、白屏/TTFB/FCP/LCP、路由时长、慢接口
- 埋点规范：事件命名、参数字典、版本字段、匿名ID与用户ID绑定策略、隐私合规开关

## 8. 接口契约（前端视角，节选）
- 版本与幂等：所有请求加 X-Client-Version；提交类接口支持 Idempotency-Key
- 身份与安全：Authorization: Bearer <jwt>；敏感操作加一次短信/邮箱验证态
- 示例
  - GET /v1/products?keyword=&category=&sort=&page=
  - GET /v1/products/{id}
  - POST /v1/cart/items
  - POST /v1/orders/checkout
  - POST /v1/payments/{orderId}/pay
  - POST /v1/aftersales/apply
  - GET /v1/shipments/{orderId}/tracking

## 9. 技术选型与工程规范
- 技术栈：Vue 3 + TypeScript + Pinia + Vite；组件库（Ant Design Vue 或 Element Plus 二选一）
- 路由与布局：Vue Router + 动态路由守卫；多布局支持（主站、后台登录等）
- HTTP：Axios 封装（重试、取消、超时、错误码统一处理、签名/时间偏差校正可选）
- 样式：CSS变量与主题切换；移动端/PC自适应（断点体系）
- 代码质量：ESLint + Prettier + Stylelint；单测 Vitest；E2E（Cypress/Playwright 可选）
- i18n：vue-i18n，按需加载词条，默认中文，预留多语言扩展
- 安全：CSRF防护（仅需时）、XSS转义、敏感数据不入日志、本地存储加密（可选）

## 10. 与运营/商家后台
- 后台为独立前端应用，共享UI与基础库；RBAC基于后端权限下发，按菜单/数据范围控制
- 模块：商品与类目、订单与售后、营销、报表、权限、配置
- 表格大数据加载：分页/服务端筛选、导出异步任务

## 11. 交付物与验收
- 交付物
  - 页面与组件资产、路由与状态管理、网络层封装、埋点与监控集成、SSR/预渲染配置
  - 文档：接口对接清单、参数字典、埋点字典、错误码与文案清单
- 验收标准
  - 从浏览→加购→下单→支付→评价完整链路可用
  - p95首屏/接口性能达标；关键错误无明显回归
  - 埋点完整上报；隐私与合规提示到位

## 12. 风险与对策（前端侧）
- 大促峰值：静态化/预渲染、缓存策略、降级方案（关闭非关键动画与实时计算）
- 营销复杂度：规则由后端裁决，前端仅展示与有限校验；建立灰度与A/B
- 支付回跳一致性：以后端最终态为准，UI仅作提示与重试引导

## 13. 接口契约（完整引用）

# 电商平台 前后端接口契约（v1）

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



- 完整接口契约文档位置：[api-contract.md](file:///d:/Java/class/projectKu/web/docs/api-contract.md)
- 公共约定
  - Base URL：/v1；统一 Headers：Authorization、Idempotency-Key、X-Client-Version、X-Request-Id
  - 分页与排序：page、pageSize、sort、order；统一成功/错误响应结构与错误码
- 前端页面调用点与接口（与产品页面映射）
  - 列表页 → GET /v1/products
  - 详情页 → GET /v1/products/{id}、GET /v1/products/{id}/reviews
  - 购物车页 → GET /v1/cart、POST/PUT/DELETE /v1/cart/items、POST /v1/cart/apply-coupon
  - 结算页 → POST /v1/orders/checkout
  - 支付页/回跳 → POST /v1/payments/{orderId}/pay、GET /v1/payments/{orderId}/status
  - 订单页 → GET /v1/orders、GET /v1/orders/{id}、POST /v1/orders/{id}/cancel
  - 售后/评价 → POST /v1/aftersales/apply、GET /v1/aftersales、POST /v1/reviews
  - 个人中心 → GET /v1/me、GET/POST /v1/me/addresses、GET /v1/notifications、POST /v1/notifications/{id}/read
