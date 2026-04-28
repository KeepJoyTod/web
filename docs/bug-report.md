# Bug 整理报告

本文档按 `bug-report-writer` skill 的标准 Markdown 结构整理当前自动化测试过程中发现的缺陷。

## 当前结论

已覆盖并通过的自动化测试：

| 测试类型 | 脚本 | 最近验证结果 |
| --- | --- | --- |
| 冒烟测试 | `frontend/tests/smoke.spec.ts` | 已纳入全量测试 |
| 登录测试 | `frontend/tests/login.spec.ts` | 已纳入全量测试 |
| 注册测试 | `frontend/tests/register.spec.ts` | `6 passed` |
| 核心页面跳转测试 | `frontend/tests/navigation.spec.ts` | 已纳入全量测试 |
| 商品详情测试 | `frontend/tests/product-detail.spec.ts` | 已纳入全量测试 |
| 购物车测试 | `frontend/tests/cart.spec.ts` | 已纳入全量测试 |
| 下单 / 结算测试 | `frontend/tests/checkout.spec.ts` | `7 passed` |
| 全量 Playwright 测试 | `npm.cmd run test:e2e` | `41 passed` |
| 前端构建 | `npm.cmd run build` | build success |

当前确认 Bug：

| Bug 编号 | 标题 | 状态 | 严重度 | 优先级 |
| --- | --- | --- | --- | --- |
| BUG-001 | [商品详情] 未登录访问商品详情页会被评价接口带到登录页 | 已修复 | S2-严重 | P1-高 |
| BUG-002 | [商品评价] 公开评价列表接口被后端鉴权拦截 | 待修复 | S3-一般 | P2-中 |
| BUG-003 | [购物车] 游客态修改购物车数量会被服务端同步接口带到登录页 | 已修复 | S2-严重 | P1-高 |
| BUG-004 | [结算] 下单成功后本地购物车未清空 | 已修复 | S2-严重 | P1-高 |

## BUG-001 [商品详情] 未登录访问商品详情页会被评价接口带到登录页

### 基本信息

| 字段 | 内容 |
| --- | --- |
| Bug 标题 | [商品详情] 未登录访问商品详情页会被评价接口带到登录页 |
| 状态 | 已修复 |
| 严重度 | S2-严重 |
| 优先级 | P1-高 |
| Bug 类型 | 功能缺陷 |
| 所属模块 | 商品详情、评价加载、前端 API 全局响应拦截 |
| 发现方式 | Playwright 商品详情测试 |
| 影响版本 | 当前开发版本 |

### 环境信息

| 字段 | 内容 |
| --- | --- |
| 操作系统 | Windows |
| 运行环境 | PC Web，Vue 3 + Vite |
| 后端服务 | Spring Boot，`http://127.0.0.1:8080/api` |
| 前端服务 | Vite，`http://127.0.0.1:5173` |

### 复现步骤

1. 用户保持未登录状态。
2. 打开任意商品详情页，例如 `/products/{id}`。
3. 页面加载商品详情数据。
4. 页面同时请求 `/api/v1/reviews?productId={id}`。
5. 观察页面跳转结果。

### 预期结果

未登录用户可以正常浏览商品详情页。商品评价加载失败时，不应导致整页跳转登录；只有结算、收藏、消息、售后等受保护操作才应触发登录拦截。

### 实际结果

`/v1/reviews` 返回未授权后，前端全局响应拦截器触发 `app:unauthorized`，页面被重定向到 `/login`，商品详情主体无法稳定停留展示。

### 错误信息

```text
GET /api/v1/reviews?productId={id}
未登录状态下返回未授权，前端触发 app:unauthorized
```

### 影响范围

- 影响未登录用户浏览商品详情页。
- 阻断商品详情页的公开浏览链路。
- 影响商品详情页自动化测试稳定性。

### 根因分析

商品详情页会加载公开商品评价，但该请求未登录时返回未授权。前端全局响应拦截器没有区分“公开评价列表加载失败”和“真正需要登录的业务操作”，导致整页被带到登录页。

### 修复方案

已在 `frontend/src/lib/api.ts` 中增加 `isPublicProductReviewsRequest` 判断。对 `GET /v1/reviews` 且带 `productId`、不带 `orderId` 的公开评价列表请求，不触发全局未登录跳转。

### 验证结果

```text
npm.cmd run test:product-detail
7 passed

npm.cmd run test:e2e
41 passed

npm.cmd run build
build success
```

## BUG-002 [商品评价] 公开评价列表接口被后端鉴权拦截

### 基本信息

| 字段 | 内容 |
| --- | --- |
| Bug 标题 | [商品评价] 公开评价列表接口被后端鉴权拦截 |
| 状态 | 待修复 |
| 严重度 | S3-一般 |
| 优先级 | P2-中 |
| Bug 类型 | 功能缺陷 / 接口权限设计不一致 |
| 所属模块 | 后端鉴权拦截器、商品评价接口 |
| 发现方式 | 商品详情测试与代码排查 |
| 影响版本 | 当前开发版本 |

### 环境信息

| 字段 | 内容 |
| --- | --- |
| 操作系统 | Windows |
| 运行环境 | PC Web |
| 后端服务 | Spring Boot，`http://127.0.0.1:8080/api` |
| 涉及代码 | `back/src/main/java/com/web/config/WebConfig.java`、`back/src/main/java/com/web/controller/ReviewController.java` |

### 复现步骤

1. 用户保持未登录状态。
2. 请求公开商品评价列表：

```text
GET /api/v1/reviews?productId={id}
```

3. 观察接口返回结果。

### 预期结果

未登录用户可以查看商品公开评价。只有“我的评价”“按订单查询评价”“发布评价”等个人相关操作需要登录。

### 实际结果

请求被后端鉴权拦截器拦截，未登录用户无法获取公开商品评价数据。

### 错误信息

```text
AuthInterceptor 拦截 GET /v1/reviews?productId={id}
返回未登录或令牌失效
```

### 影响范围

- 商品详情页评价区域无法真正加载公开评价数据。
- 前端目前只能避免整页跳登录，但无法解决后端评价数据不可访问的问题。
- 对商品详情页信息完整性有影响，但不阻断商品详情主体浏览。

### 根因分析

`ReviewController.list` 的逻辑显示：当传入 `productId` 且没有传入 `orderId` 时，应返回该商品的评价列表。这类请求语义上属于公开数据。

但当前后端鉴权放行路径仅包含：

```java
.excludePathPatterns("/", "/v1/auth/**", "/v1/products/**", "/v1/payments/webhook")
```

没有针对 `GET /v1/reviews?productId=...` 做公开放行，所以请求会先被 `AuthInterceptor` 拦截。

### 建议修复方案

方案一：在后端鉴权拦截器中细化放行规则。

- 放行 `GET /v1/reviews` 且带 `productId`、不带 `orderId` 的请求。
- 继续保护 `POST /v1/reviews`、按订单查询评价、用户私有评价等接口。

方案二：拆分公开接口。

- 新增或改用 `/v1/products/{id}/reviews` 作为公开商品评价列表接口。
- 用户私有评价继续使用 `/v1/reviews` 并要求登录。

### 当前处理状态

前端已规避该接口未授权时触发整页跳登录，但后端接口本身仍未真正开放，建议后续修复。

## BUG-003 [购物车] 游客态修改购物车数量会被服务端同步接口带到登录页

### 基本信息

| 字段 | 内容 |
| --- | --- |
| Bug 标题 | [购物车] 游客态修改购物车数量会被服务端同步接口带到登录页 |
| 状态 | 已修复 |
| 严重度 | S2-严重 |
| 优先级 | P1-高 |
| Bug 类型 | 功能缺陷 |
| 所属模块 | 购物车页、购物车 store、前端 API 全局响应拦截 |
| 发现方式 | Playwright 购物车测试 |
| 影响版本 | 当前开发版本 |

### 环境信息

| 字段 | 内容 |
| --- | --- |
| 操作系统 | Windows |
| 运行环境 | PC Web，Vue 3 + Vite |
| 后端服务 | Spring Boot，`http://127.0.0.1:8080/api` |
| 前端服务 | Vite，`http://127.0.0.1:5173` |

### 复现步骤

1. 用户保持未登录状态。
2. `localStorage.cart:v1` 中存在购物车商品。
3. 打开 `/cart`。
4. 点击商品数量增加或减少按钮。
5. 观察页面跳转结果和购物车状态。

### 预期结果

未登录用户可以正常使用本地购物车。数量增加、减少、移除等本地操作不应触发登录跳转；登录后再进行服务端购物车同步。

### 实际结果

本地数量先发生变化，随后 `cart.updateQty` 请求 `/api/v1/cart` 做服务端同步。后端返回未授权后，前端全局响应拦截器触发 `app:unauthorized`，页面被重定向到 `/login`。

### 错误信息

```text
未登录状态下请求 /api/v1/cart 或 /api/v1/cart/items
后端返回未授权
前端触发 app:unauthorized
```

### 影响范围

- 影响所有未登录用户的本地购物车编辑流程。
- 用户修改数量、移除商品时会被意外打断。
- 影响购物车页核心体验。

### 根因分析

购物车 store 没有区分游客态和登录态。游客态本应只读写 `localStorage.cart:v1`，但修改数量后仍尝试同步到后端购物车接口，导致未授权响应触发全局登录跳转。

### 修复方案

已在 `frontend/src/stores/cart.ts` 中增加 `hasAuthToken` 判断：

- 未登录时跳过 `/v1/cart`、`/v1/cart/items` 等服务端同步请求。
- 本地购物车继续正常读写 `localStorage.cart:v1`。
- 登录态下保留服务端购物车同步能力。

### 验证结果

```text
npm.cmd run test:cart
5 passed

npm.cmd run test:e2e
41 passed

npm.cmd run build
build success
```

## BUG-004 [结算] 下单成功后本地购物车未清空

### 基本信息

| 字段 | 内容 |
| --- | --- |
| Bug 标题 | [结算] 下单成功后本地购物车未清空 |
| 状态 | 已修复 |
| 严重度 | S2-严重 |
| 优先级 | P1-高 |
| Bug 类型 | 功能缺陷 / 数据状态不一致 |
| 所属模块 | 结算页、购物车 store、订单创建流程 |
| 发现方式 | Playwright 下单 / 结算测试 |
| 影响版本 | 当前开发版本 |

### 环境信息

| 字段 | 内容 |
| --- | --- |
| 操作系统 | Windows |
| 运行环境 | PC Web，Vue 3 + Vite |
| 后端服务 | Spring Boot，`http://127.0.0.1:8080/api` |
| 前端服务 | Vite，`http://127.0.0.1:5173` |

### 复现步骤

1. 用户登录。
2. `localStorage.cart:v1` 中存在购物车商品。
3. 打开 `/checkout`。
4. 点击提交订单。
5. 订单创建成功并跳转到 `/cashier?orderId=...`。
6. 检查 `localStorage.cart:v1`。

### 预期结果

订单创建成功后，已下单商品应从本地购物车中移除，前端本地购物车状态应与后端购物车清空结果一致。

### 实际结果

订单已成功创建并跳转收银台，但 `localStorage.cart:v1` 中仍保留已下单商品。用户回到购物车时仍可能看到已经提交过的商品。

### 错误信息

```text
POST /api/v1/orders/checkout 返回 code=200
后端已执行 cartItemMapper.clearCheckedByUserId(userId)
前端 localStorage.cart:v1 仍保留原商品
```

### 影响范围

- 影响登录用户下单后的购物车状态。
- 用户可能误以为商品仍未下单，存在重复提交订单的风险。
- 前后端购物车状态不一致，影响后续购物车同步。

### 根因分析

结算页在订单创建成功后只写入 `orderDraft` 并跳转收银台，没有调用购物车 store 清空本地购物车。后端已经清空服务端购物车，但前端 `localStorage.cart:v1` 没有同步更新。

### 修复方案

已在 `frontend/src/views/CheckoutView.vue` 的下单成功路径中调用 `cart.clear()`。执行顺序为：写入订单草稿、清空本地购物车、跳转收银台。

### 验证结果

```text
npm.cmd run test:checkout
7 passed

npm.cmd run test:e2e
41 passed
```

## 环境注意事项

以下不是业务 Bug，但会影响测试执行：

- Windows PowerShell 中建议使用 `npm.cmd` / `npx.cmd`，避免直接运行 `npm` / `npx` 时被执行策略拦截。
- Playwright 启动本地 Vite 服务或浏览器时，在当前沙箱环境可能出现 `spawn EPERM`，需要授权后在沙箱外执行。
- Allure 报告脚本已设置 `ALLURE_NO_ANALYTICS=1`，避免生成报告时出现联网统计请求噪声。
