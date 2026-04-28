# ProjectKu Web

## 后台管理平台

本项目已配备独立后台管理端：

- 后端管理接口：`/api/v1/admin/**`
- 管理端前端目录：`frontend-admin/`
- 管理端地址：`http://localhost:5174`
- 默认管理员：`admin@example.com`
- 默认密码：`admin123`

如果是已有数据库，先执行管理端迁移脚本：

```powershell
cd d:\Java\class\projectKu\web
Get-Content back\sql\schema_admin.sql -Raw | mysql -uroot -p123456 web
```

如果是全新数据库，直接执行 `back/sql/init_db.sql` 即可，脚本已经包含默认管理员和后台所需字段。

启动后台管理前端：

```powershell
cd d:\Java\class\projectKu\web\frontend-admin
npm install
npm run dev
```

后台依赖后端服务，请先启动 `back/` 下的 Spring Boot 服务。

本项目为一个前后端分离的电商示例工程：

- 后端：Spring Boot 3 + MyBatis + MySQL（端口 `8080`，上下文 `/api`）
- 前端：Vue 3 + Vite（开发端口 `5173`）

## 快速开始（推荐：Windows PowerShell 直接复制执行）

前置：

- 已安装并启动 MySQL
- 已安装 JDK 17、Maven、Node.js
- 已安装 MySQL 客户端（命令行 `mysql` 可用）

在项目根目录依次执行：

```powershell
# 1) 初始化数据库（默认连接信息：root / 123456，数据库：web）
mysql -uroot -p123456 -e "CREATE DATABASE IF NOT EXISTS web DEFAULT CHARSET utf8mb4;"

$sqls = @(
  "back/sql/schema_v1.sql",
  "back/sql/schema_v2_address.sql",
  "back/sql/schema_v3_payment.sql",
  "back/sql/schema_v4_marketing_aftersales.sql",
  "back/sql/schema_v5_products_tags.sql",
  "back/sql/seed_demo.sql",
  "back/sql/seed_products_categories_1_8.sql"
)

foreach ($f in $sqls) {
  Write-Host "Importing $f ..."
  Get-Content $f -Raw | mysql -uroot -p123456 web
}

# 2) 启动后端（新开一个终端执行）
cd back
mvn spring-boot:run
```

后端启动成功后，再新开一个终端在项目根目录执行：

```powershell
cd frontend
npm install
npm run dev
```

访问：

- 前端：`http://localhost:5173`
- 后端：`http://localhost:8080/api`

## 目录结构

- `back/`：后端服务（Spring Boot）
- `frontend/`：前端项目（Vue）
- `back/sql/`：数据库建表与种子数据脚本

## 环境要求

- JDK 17
- Maven 3.8+
- Node.js 18+（建议）
- MySQL 8+（建议）

## 数据库初始化

1. 创建数据库 `web`
2. 依次执行以下脚本（推荐顺序）：

- `back/sql/schema_v1.sql`
- `back/sql/schema_v2_address.sql`
- `back/sql/schema_v3_payment.sql`
- `back/sql/schema_v4_marketing_aftersales.sql`
- `back/sql/schema_v5_products_tags.sql`
- `back/sql/seed_demo.sql`
- `back/sql/seed_products_categories_1_8.sql`

说明：

- `schema_v5_products_tags.sql` 用于为 `products` 表增加 `tags` 字段；如果未执行该脚本，执行 `seed_products_categories_1_8.sql` 会出现 `1054 Unknown column 'tags'` 错误。
- `seed_products_categories_1_8.sql` 为类目 1–8 每类填充 20 条商品数据，并在 `tags` 中写入可用于前端类目筛选的标签（例如手机：旗舰/性价比/折叠屏/配件）。

## 启动后端

在 `back/` 目录执行：

```bash
mvn spring-boot:run
```

后端默认地址：

- `http://localhost:8080/api` (服务状态)
- `http://localhost:8080/api/swagger-ui.html` (Swagger UI)
- `http://localhost:8080/api/v1/products` (示例接口)

### Swagger / OpenAPI 文档

后端已集成 springdoc-openapi（Swagger UI）。

配置位置：

- `back/src/main/resources/application.yml`（`springdoc.*`）

默认可访问：

- Swagger UI：`http://localhost:8080/api/swagger-ui-custom.html`
- OpenAPI JSON：`http://localhost:8080/api/api-docs`

## 启动前端

在 `frontend/` 目录执行：

```bash
npm install
npm run dev
```

前端默认地址：

- `http://localhost:5173`

前端开发环境代理：

- `frontend/vite.config.ts` 已将 `/api` 代理到 `http://localhost:8080`
- 因此前端请求 `/api/v1/...` 会自动转发到后端

## 图片说明（前端商品封面）

前端会基于商品名做图片映射，以便展示更贴近商品类型的封面图：

- 映射规则：`frontend/src/lib/productCovers.ts`
- 详情页图片展示为“居中完整（contain）”，避免裁切

若外链图片加载失败，会自动回退到 SVG 占位图，避免页面出现空白封面。

## 常用页面文件（前端）

- 首页：`frontend/src/views/HomeView.vue`
- 类目页：`frontend/src/views/CategoryView.vue`
- 商品详情：`frontend/src/views/ProductDetailView.vue`

## Playwright 冒烟测试

项目已在 `frontend/tests/smoke.spec.ts` 中固化基础冒烟测试，用于快速确认后端接口、首页商品加载、登录页和未登录拦截是否正常。

### 1) 启动依赖服务

确保 MySQL、Redis 已启动。如果使用 Docker：

```powershell
cd d:\Java\class\projectKu\web
docker compose up -d
```

### 2) 启动后端

新开一个 PowerShell：

```powershell
cd d:\Java\class\projectKu\web\back
mvn spring-boot:run
```

确认后端地址可访问：

```text
http://127.0.0.1:8080/api/
```

### 3) 运行冒烟测试

再新开一个 PowerShell：

```powershell
cd d:\Java\class\projectKu\web\frontend
npm.cmd run test:e2e
```

Playwright 会根据 `frontend/playwright.config.ts` 自动启动前端 `http://127.0.0.1:5173`，不需要手动执行 `npm run dev`。

看到类似结果表示通过：

```text
4 passed
```

如需查看 HTML 报告：

```powershell
npx.cmd playwright show-report
```

说明：在 Windows PowerShell 中建议使用 `npm.cmd` / `npx.cmd`，避免直接运行 `npm` / `npx` 时被执行策略拦截。

## Playwright 登录测试

登录测试用例文档已保存到：

- `docs/login-test-cases.md`

Playwright 自动化脚本已保存到：

- `frontend/tests/login.spec.ts`

默认登录账号来自数据库种子数据：

- 账号：`user@example.com`
- 密码：`123456`

测试覆盖：

- 登录 API 正确账号密码成功
- 登录 API 错误密码失败
- 登录页密码登录成功
- 登录页错误密码显示错误提示
- 未登录访问 `/checkout` 后登录，成功回跳 `/checkout`

运行前需确保 MySQL、Redis 和后端服务已启动。后端启动方式：

```powershell
cd d:\Java\class\projectKu\web\back
mvn spring-boot:run
```

运行登录测试：

```powershell
cd d:\Java\class\projectKu\web\frontend
npm.cmd run test:login
```

如需使用其他账号密码：

```powershell
cd d:\Java\class\projectKu\web\frontend
$env:PLAYWRIGHT_LOGIN_ACCOUNT="user@example.com"
$env:PLAYWRIGHT_LOGIN_PASSWORD="123456"
npm.cmd run test:login
```

如需查看 HTML 报告：

```powershell
npx.cmd playwright show-report
```

## Playwright 注册测试

注册测试用例文档已保存到：

- `docs/register-test-cases.md`

Playwright 自动化脚本已保存到：

- `frontend/tests/register.spec.ts`

测试覆盖：

- 注册 API 新账号成功
- 注册 API 重复账号失败
- 注册页必填项与协议勾选校验
- 注册页邮箱注册成功并自动登录
- 注册成功后按 `redirect` 回跳受保护页面
- 重复账号注册时页面显示错误提示
- 从注册页跳转登录时保留 `redirect` 参数

运行注册测试：

```powershell
cd d:\Java\class\projectKu\web\frontend
npm.cmd run test:register
```

如需覆盖默认注册密码：

```powershell
cd d:\Java\class\projectKu\web\frontend
$env:PLAYWRIGHT_REGISTER_PASSWORD="123456"
npm.cmd run test:register
```

## Playwright 核心页面跳转测试

核心页面跳转测试用例文档已保存到：

- `docs/navigation-test-cases.md`

Playwright 自动化脚本已保存到：

- `frontend/tests/navigation.spec.ts`

测试覆盖：

- 后端服务可访问
- 公开核心路由可渲染
- 底部导航可切换主页面
- 首页分类快捷入口可跳转
- 首页搜索可跳转搜索页
- 商品卡片可跳转详情页
- 未登录访问受保护页面会跳转登录页

运行前需确保 MySQL、Redis 和后端服务已启动。后端启动方式：

```powershell
cd d:\Java\class\projectKu\web\back
mvn spring-boot:run
```

运行核心页面跳转测试：

```powershell
cd d:\Java\class\projectKu\web\frontend
npm.cmd run test:navigation
```

## Playwright 商品详情测试

商品详情测试用例文档已保存到：

- `docs/product-detail-test-cases.md`

Playwright 自动化脚本已保存到：

- `frontend/tests/product-detail.spec.ts`

测试覆盖：

- 商品详情 API 返回详情数据
- 商品详情页可渲染核心信息
- 无效商品 ID 显示空状态
- 选择规格后可购买，数量可增加
- 加入购物车写入本地购物车
- 立即购买未登录跳转登录并保留购物车
- 未登录点击收藏跳转登录

运行前需确保 MySQL、Redis 和后端服务已启动。后端启动方式：

```powershell
cd d:\Java\class\projectKu\web\back
mvn spring-boot:run
```

运行商品详情测试：

```powershell
cd d:\Java\class\projectKu\web\frontend
npm.cmd run test:product-detail
```

## Playwright 购物车测试

购物车测试用例文档已保存到：

- `docs/cart-test-cases.md`

Playwright 自动化脚本已保存到：

- `frontend/tests/cart.spec.ts`

测试覆盖：

- 空购物车显示空状态
- 本地购物车商品可展示
- 数量按钮可更新商品数量
- 移除商品后显示空状态
- 未登录结算跳转登录并保留购物车数据

运行购物车测试：

```powershell
cd d:\Java\class\projectKu\web\frontend
npm.cmd run test:cart
```

## Playwright 下单 / 结算测试

下单 / 结算测试用例文档已保存到：

- `docs/checkout-test-cases.md`

Playwright 自动化脚本已保存到：

- `frontend/tests/checkout.spec.ts`

测试覆盖：

- 未登录访问 `/checkout` 跳转登录
- 登录态空购物车显示空状态
- 结算页展示购物车商品、地址、发票、优惠券和金额明细
- 选择发票后抬头必填校验
- 提交订单成功后创建后端订单并跳转收银台
- 下单成功后清空本地购物车
- 服务端空购物车调用下单接口失败
- 服务端购物车调用下单接口成功并清空服务端购物车

运行下单 / 结算测试：

```powershell
cd d:\Java\class\projectKu\web\frontend
npm.cmd run test:checkout
```

## Allure 测试报告

项目已接入 Allure，用于把 Playwright 测试结果生成可视化报告。

相关配置：

- Playwright reporter：`frontend/playwright.config.ts`
- Allure 结果目录：`frontend/allure-results/`
- Allure 报告目录：`frontend/allure-report/`

运行测试后会自动生成 `allure-results`。例如运行登录测试：

```powershell
cd d:\Java\class\projectKu\web\frontend
npm.cmd run test:login
```

生成 Allure HTML 报告：

```powershell
npm.cmd run allure:generate
```

打开已生成的 Allure 报告：

```powershell
npm.cmd run allure:open
```

也可以直接临时生成并打开报告：

```powershell
npm.cmd run allure:serve
```

说明：

- `allure-results/` 和 `allure-report/` 是测试产物，已在 `frontend/.gitignore` 中忽略。
- `frontend/tests/login.spec.ts` 已使用 `test.step` 标注关键步骤，Allure 报告中可以看到更清晰的执行过程。

## 常见问题

### 1) 执行种子数据时报错：`1054 Unknown column 'tags' in 'field list'`

原因：`products` 表尚未增加 `tags` 字段。

解决：先执行：

```sql
SOURCE d:/Java/class/projectKu/web/back/sql/schema_v5_products_tags.sql;
```

再执行 `seed_products_categories_1_8.sql`。

### 2) Maven 构建报错：`FileNotFoundException ... maven-surefire-common-3.1.2.jar.lastUpdated`

通常是本机 Maven 本地仓库目录配置异常导致（例如 `localRepository` 指向了不可写/不完整路径）。

解决方式（任选其一）：

- 临时指定本地仓库到默认目录：

```powershell
cd back
mvn -Dmaven.repo.local="$env:USERPROFILE\.m2\repository" -DskipTests spring-boot:run
```

- 或检查你本机 `~/.m2/settings.xml` 中的 `localRepository` 配置，修改为可写目录后重试。
