# 下单 / 结算测试用例

下单 / 结算测试用于验证结算页访问控制、空购物车状态、订单信息渲染、发票校验、下单接口创建订单、跳转收银台以及下单成功后购物车清理。

## 测试数据

- 自动化脚本会通过 `POST /api/v1/auth/register` 创建随机邮箱测试账号。
- 自动化脚本会从 `GET /api/v1/products?page=1&size=50` 获取有库存商品。
- 本地购物车使用 `localStorage.cart:v1` 准备测试商品。
- 下单时前端会先同步本地购物车到服务端，再调用 `POST /api/v1/orders/checkout`。

可通过环境变量覆盖：

- `PLAYWRIGHT_API_URL`
- `PLAYWRIGHT_BASE_URL`
- `PLAYWRIGHT_CHECKOUT_PASSWORD`

## 用例列表

| 用例编号 | 用例名称 | 前置条件 | 测试步骤 | 预期结果 |
| --- | --- | --- | --- | --- |
| CHECKOUT-001 | 未登录访问结算页跳转登录 | 用户未登录 | 打开 `/checkout` | 跳转到 `/login`，并带有 `redirect=/checkout` |
| CHECKOUT-002 | 登录态空购物车显示空状态 | 已登录，`localStorage.cart:v1` 为空 | 打开 `/checkout` | 显示空购物车提示，不显示结算表单 |
| CHECKOUT-003 | 结算页展示本地购物车和金额明细 | 已登录，购物车存在 1 件商品 | 打开 `/checkout` | 显示收货地址、配送、发票、优惠券、商品清单和应付金额 |
| CHECKOUT-004 | 发票抬头必填校验 | 已登录，购物车存在商品 | 选择个人发票但不填写抬头 | 提交按钮禁用；填写抬头后提交按钮可用 |
| CHECKOUT-005 | 下单成功创建订单并跳转收银台 | 已登录，购物车存在有库存商品 | 打开 `/checkout`；点击提交订单 | 请求 `/api/v1/orders/checkout` 成功；跳转 `/cashier?orderId=...`；本地订单草稿写入订单金额；本地购物车清空 |
| CHECKOUT-006 | 空服务端购物车调用下单接口失败 | 已登录，服务端购物车为空 | 直接请求 `POST /api/v1/orders/checkout` | 返回业务失败，不创建订单 |

对应自动化脚本：

- `frontend/tests/checkout.spec.ts`
