# ProjectKu Web

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

