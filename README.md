# ProjectKu Web

前后端分离的电商示例项目，包含用户端、管理端、Spring Boot API、MySQL、Redis，以及可选的 Prometheus/Grafana 监控。

## 项目组成

| 模块 | 目录 | 技术 | 默认地址 |
| --- | --- | --- | --- |
| 用户端 | `frontend/` | Vue 3 + Vite | `http://localhost:5173` |
| 管理端 | `frontend-admin/` | Vue 3 + Vite | `http://localhost:5174` |
| 后端 | `back/` | Spring Boot 3 + MyBatis | `http://localhost:8080/api` |
| 数据库 | `back/sql/` | MySQL 8 | `127.0.0.1:3306` |
| 缓存 | Compose / 本地服务 | Redis | `127.0.0.1:6379` |

## 快速开始

环境要求：

- JDK 17
- Node.js `^20.19.0` 或 `>=22.12.0`
- Docker Desktop / Docker Engine（推荐，用于 MySQL 和 Redis）
- Git

项目已包含 Maven Wrapper，不要求全局安装 Maven。Docker Compose 默认只启动 MySQL 和 Redis，不会容器化启动三个应用服务。

把仓库交给 AI 时可直接发送：

> 请在仓库根目录完成本地部署。先读取 `AGENTS.md` 和 `DEPLOYMENT.md`，查看 `git status`，运行对应平台的 doctor，再根据结果选择 Docker 或本机 MySQL/Redis 流程。不得自动安装系统软件、清库、删除 volume 或终止非本项目进程。启动后验证后端健康状态以及两个前端 HTTP 状态，并报告实际命令、日志和未验证项。

### Windows PowerShell

```powershell
# 1. 只读检查环境
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1

# 2. 首次部署：启动基础设施、初始化空数据库、构建并启动三个应用
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -InitDb
```

数据库已经初始化时，后续启动不要再传 `-InitDb`：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1
```

### Linux / macOS

```bash
bash ./scripts/doctor.sh
bash ./scripts/deploy.sh --init-db
```

后续启动：

```bash
bash ./scripts/deploy.sh
```

### Docker 无法启动时

`docker compose version` 成功只表示 Docker CLI 已安装，不代表 Docker daemon 可用。若 doctor 报告 `docker-daemon FAIL`，AI 不得把它判断为项目代码错误，也不得删除 volume、禁用 Redis、修改业务代码或直接终止未知进程。

先创建本地配置，并按机器上的实际地址、端口和凭据修改 `.env`：

```powershell
Copy-Item .env.example .env
```

然后让 doctor 跳过 Docker，直接检查 `.env` 指向的 MySQL 和 Redis：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1 -SkipDocker
```

```bash
bash ./scripts/doctor.sh --skip-docker
```

根据结果选择：

| 检查结果 | 处理方式 |
| --- | --- |
| MySQL、Redis 都可连接 | 使用下面的本机基础设施流程 |
| 缺少其中任意一个 | 停止部署，请使用者先启动/安装缺失服务或修复 Docker |
| 端口被其他程序占用 | 先识别占用进程，不得直接结束未知进程 |

本机 MySQL/Redis 都可连接时，首次部署使用安全初始化脚本。脚本会创建不存在的数据库、拒绝非空数据库，并以字节流导入 SQL：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\init-local-db.ps1
```

```bash
bash ./scripts/init-local-db.sh
```

初始化完成后跳过 Compose 启动应用：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -SkipInfrastructure
```

```bash
bash ./scripts/deploy.sh --skip-infrastructure
```

本机服务流程不要传 `-InitDb` / `--init-db`。如果本机没有 MySQL、Redis 或 `mysql` 命令行客户端，部署处于环境阻塞状态；AI 只能报告缺失项并请求使用者处理或授权。完整故障处理见 [DEPLOYMENT.md](DEPLOYMENT.md)。

### 启动验证

```powershell
Invoke-RestMethod http://127.0.0.1:8080/api/actuator/health
Invoke-WebRequest http://127.0.0.1:5173/ -UseBasicParsing
Invoke-WebRequest http://127.0.0.1:5174/ -UseBasicParsing
```

浏览器入口：

- 用户端：`http://localhost:5173`
- 管理端：`http://localhost:5174`
- 后端健康检查：`http://localhost:8080/api/actuator/health`
- Swagger UI：`http://localhost:8080/api/swagger-ui.html`
- OpenAPI JSON：`http://localhost:8080/api/v3/api-docs`

种子账号：

| 用途 | 账号 | 密码 |
| --- | --- | --- |
| 用户端 | `user@example.com` | `123456` |
| 管理端 | `admin@example.com` | `admin123` |

这些账号仅用于本地演示，不应复用于真实环境。

## 配置

默认值已经写在 Compose 和 Spring Boot 配置中；只有需要改端口或凭据时才复制模板：

```powershell
Copy-Item .env.example .env
```

`.env` 同时由 Docker Compose 和部署脚本读取，且已被 Git 忽略。主要变量：

| 变量 | 默认值 | 用途 |
| --- | --- | --- |
| `DB_HOST` | `127.0.0.1` | 后端连接 MySQL 的地址 |
| `DB_PORT` | `3306` | MySQL 宿主机端口及后端连接端口 |
| `DB_NAME` | `web` | 数据库名 |
| `DB_USER` | `root` | 数据库用户 |
| `DB_PASSWORD` | `123456` | 仅限本地开发的默认密码 |
| `REDIS_HOST` | `127.0.0.1` | 后端连接 Redis 的地址 |
| `REDIS_PORT` | `6379` | Redis 宿主机端口及后端连接端口 |
| `BACKEND_PORT` | `8080` | 后端端口 |
| `FRONTEND_PORT` | `5173` | 用户端端口 |
| `ADMIN_PORT` | `5174` | 管理端端口 |

修改 MySQL 或 Redis 端口时只改 `.env`，不要分别修改 Compose 和 `application.yml`。

同一台机器存在多个目录名相同的 clone 时，在每个 clone 的 `.env` 中设置不同的 `COMPOSE_PROJECT_NAME`，避免 Compose 项目互相接管；应用和基础设施端口也必须分别设置为未占用值。

Compose 初始化流程固定使用 `DB_USER=root`；需要非 root 数据库账号时，请准备已有的本机/远程 MySQL，并使用 `-SkipInfrastructure` / `--skip-infrastructure`。

## 常用命令

```powershell
# 仅预览部署动作，不启动服务
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -DryRun -SkipInfrastructure

# 仅预览本机数据库初始化，不执行 SQL
powershell -ExecutionPolicy Bypass -File .\scripts\init-local-db.ps1 -DryRun

# 停止由部署脚本记录的应用进程
powershell -ExecutionPolicy Bypass -File .\scripts\stop.ps1

# 同时停止 MySQL 和 Redis 容器
powershell -ExecutionPolicy Bypass -File .\scripts\stop.ps1 -StopInfrastructure

# 启动基础设施和监控
docker compose --profile monitoring up -d
```

Linux/macOS 对应命令：`bash ./scripts/deploy.sh --dry-run --skip-infrastructure`、`bash ./scripts/init-local-db.sh --dry-run`、`bash ./scripts/stop.sh` 和 `bash ./scripts/stop.sh --stop-infrastructure`。

## 手动启动

希望逐项启动时，在三个终端执行：

```powershell
cd back
.\mvnw.cmd spring-boot:run
```

```powershell
cd frontend
npm.cmd ci
npm.cmd run dev
```

```powershell
cd frontend-admin
npm.cmd ci
npm.cmd run dev
```

使用本机 MySQL/Redis、端口冲突、Docker daemon 不可用、`JAVA_HOME` 错误和数据库初始化规则见 [DEPLOYMENT.md](DEPLOYMENT.md)。把项目交给 AI 部署时，也应让它先读取该文件。

## 构建与测试

```powershell
cd back
.\mvnw.cmd -DskipTests compile

cd ..\frontend
npm.cmd run build
npm.cmd run test:e2e

cd ..\frontend-admin
npm.cmd run build
```

用户端还提供 `test:login`、`test:register`、`test:navigation`、`test:product-detail`、`test:cart` 和 `test:checkout`。Playwright 测试要求后端、MySQL 和 Redis 已启动。

## 目录结构

```text
back/                 Spring Boot API、Maven Wrapper、SQL 初始化脚本
frontend/             用户端 Vue 应用与 Playwright 测试
frontend-admin/       管理端 Vue 应用
scripts/              环境诊断、部署和停止脚本
prometheus/           Prometheus 配置
grafana/              Grafana provisioning
docs/                 API、测试、监控和项目文档
DEPLOYMENT.md          人工/AI 本地部署唯一事实源
```

## 提交前部署资产检查

部署文件必须和 README 一起提交。推送前至少执行：

```powershell
git status --short
git diff --check
git ls-files --error-unmatch DEPLOYMENT.md scripts/doctor.ps1 scripts/doctor.sh scripts/deploy.ps1 scripts/deploy.sh scripts/init-local-db.ps1 scripts/init-local-db.sh scripts/stop.ps1 scripts/stop.sh back/mvnw back/mvnw.cmd back/.mvn/wrapper/maven-wrapper.properties
```

GitHub 上的 `Deployment Check` 工作流会检查两种平台的脚本语法与 dry-run、Compose 配置、后端编译和两个前端构建。只有工作流成功后，才把对应提交作为小伙伴的部署基线。

## 部署说明

- 本仓库脚本面向本地开发和本地构建验证。
- `-Mode prod` / `--mode=prod` 只是运行构建后的本地 preview，不是生产级 Web Server 或生产发布方案。
- 不要把 `.env`、真实凭据、`mysql-data/`、`redis-data/`、`logs/`、`.pids/`、`dist/` 或 `target/` 提交到仓库。
