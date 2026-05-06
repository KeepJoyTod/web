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

