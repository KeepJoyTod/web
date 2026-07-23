#  Web

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

### 协作者部署前：哪些问题会因机器而异

上一台机器的部署记录只能说明那台机器当时的观察结果，不能作为其他机器的前置条件。所有协作者都应先运行 doctor，再按下表选择路径。

| 场景 | 是否会随机器变化 | 如何判断与处理 |
| --- | --- | --- |
| JDK、Node.js、npm 是否存在及版本是否满足要求 | 会 | doctor 会检查 JDK 17、Node.js 和 npm。缺失或版本不符时，脚本不会安装系统软件；由使用者安装或修复后重新诊断。 |
| Docker CLI 与 Docker daemon | 会 | `docker compose version` 或 `docker-cli PASS` 只说明 CLI 可用；只有 `docker-daemon PASS` 才能走 Docker 流程。daemon 不可达并不表示项目代码有问题。 |
| 本机 MySQL、Redis、端口和凭据 | 会 | Docker 不可用时，先复制并填写本机 `.env`，再运行 `doctor -SkipDocker` / `doctor.sh --skip-docker`。TCP 可达不等于凭据、协议或数据状态已确认。 |
| `mysql`、`redis-cli` 命令行客户端 | 会 | 缺少客户端时 doctor 只能报告协议验证未完成。首次使用本机 MySQL 初始化时必须有 `mysql` 客户端；缺少 `redis-cli` 时仍必须以最终后端健康检查确认 Redis。 |
| `3306`、`6379`、`8080`、`5173`、`5174` 等端口 | 会 | 端口被监听不等于该服务属于当前 clone，也不等于可以复用。先确认所有者，再改 `.env` 端口或由所有者停止服务。 |
| 首次数据库初始化 | 通用安全规则 | 只允许目标数据库没有表时使用 `-InitDb` / `--init-db` 或本机初始化脚本。非空库、导入中断或未知数据都不能自动清理。 |
| Git、Docker 镜像、Maven Wrapper/依赖、npm 依赖下载 | 会 | 首次下载受网络、代理、镜像源和本机缓存影响。超时或下载失败先检查网络和代理，再重试；不要把它直接归因为代码编译错误或删除数据目录。 |

选择路径：

1. doctor 显示 `docker-cli PASS` 且 `docker-daemon PASS`：使用下面的 Docker 流程。
2. Docker CLI 缺失或 daemon 不可达：仅当 `.env` 指向的本机 MySQL 和 Redis 已完成诊断时，使用“Docker 无法启动时”的本机基础设施流程。
3. 本机 MySQL、Redis 未启动、地址/凭据未确认，或首次初始化缺少 `mysql` 客户端：停止部署，先由使用者处理环境。不要把已监听端口或其他项目的健康服务当作当前项目可复用服务。

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

### macOS 注意事项

macOS 终端默认可能使用 `zsh`，但项目脚本使用 Bash 语法；始终以 `bash ./scripts/<script>.sh` 调用，不要替换为 `zsh` 或 `sh`。运行前先执行 `bash ./scripts/doctor.sh`：默认 Docker 流程要求 `macos-bash`、JDK 17、Node.js、npm、`docker-cli` 和 `docker-daemon` 均通过；Docker 不可用时按下节改走本机服务流程。

doctor 会记录 `macos-architecture`（通常为 Intel 的 `x86_64` 或 Apple Silicon 的 `arm64`），但架构识别本身不构成 Docker 兼容性承诺。只有当前 Docker Desktop 的 `docker info` 可用，并且实际 `docker compose up` 能完成所需镜像拉取和容器启动，才可确认当前机器的 Docker 路径可用。

Compose 会把项目内的 `./mysql-data`、`./redis-data` 挂载到容器；启用监控时还会读取 `./prometheus` 和 `./grafana/provisioning`。确保项目根目录可写，且 Docker Desktop 已允许访问这些目录；`docker info` 不能验证目录共享。部署脚本以 `0.0.0.0` 绑定前端端口，若需要从其他设备访问，应由使用者按本机防火墙或企业安全策略仅放行所需端口；不要为部署关闭或放宽防火墙。先以本机 `localhost` 的健康检查为准。

端口、已有本机 MySQL/Redis 与数据库安全规则仍适用：先确认端口和服务归属，再统一通过 `.env` 调整端口；只有 `bash ./scripts/doctor.sh --skip-docker` 完成可用诊断后，才可使用 `--skip-infrastructure`。本机初始化仅针对空数据库，不能通过清库、删表或删除 Docker volume 重试。

### Docker CLI 缺失或 daemon 无法启动时

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
| `mysql-tcp`、`redis-tcp` 都通过，且可用的协议检查也通过 | 使用下面的本机基础设施流程 |
| `mysql-client WARN` | 首次本机初始化被阻塞：`init-local-db` 需要 `mysql` 客户端。安装或暴露客户端后重新诊断；不要改用手写 SQL 导入。 |
| `redis-client WARN` | TCP 仅证明端口可达，不能证明 Redis 协议已确认。可在使用者确认服务后继续，但最终必须通过后端健康检查中的 Redis 状态。 |
| MySQL、Redis 有任一 TCP 或协议检查失败 | 停止部署，请使用者先启动/修复本机服务、地址或凭据，或修复 Docker。 |
| 端口被其他程序占用 | 先识别占用进程并确认服务归属；不得直接结束未知进程，也不得因 HTTP 200 而默认复用。 |

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

`init-local-db` 导入失败后，目标数据库可能已有部分表。保留它用于排查，在 `.env` 中设置一个新的未使用 `DB_NAME` 后再重试；不要自动删表、清库或删除 Compose volume。

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

部署脚本只会复用带有当前仓库身份元数据、且健康检查通过的后端或前端进程。即使某个端口已经返回 HTTP 200，也可能属于另一个 clone 或其他项目；这种情况应先确认归属，不能直接当成当前项目已启动。

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

GitHub 上的 `Deployment Check` 工作流会检查 Linux、Windows 和 macOS 的脚本语法与 dry-run；Linux/macOS Job 还会编译后端并构建两个前端，Linux Job 会校验 Compose 配置。只有相应 Job 实际成功后，才把对应提交作为该平台的部署基线。

### macOS CI 与目标机验收

工作流定义了托管 macOS Runner Job `macos-dry-run`。该 Job 配置 JDK 17 和 `.nvmrc` 指定的 Node.js，检查 Bash 脚本语法、`macos-architecture` / `macos-bash` / `macos-ps-identity` doctor 输出、数据库初始化与跳过基础设施的部署 dry-run，并编译后端、构建两个前端。工作流文件存在不代表 Job 已运行；只有 GitHub Actions 中该 Job 实际完成且成功，才产生这部分验证证据。

`macos-dry-run` 当前不启动 Docker Compose 或应用进程，因此不能取代 Docker Desktop 图形界面状态、bind mount 目录共享、真实镜像拉取、容器完整启动和三个 HTTP 入口的目标机器验收。每台首次使用的 macOS 应至少完成一次人工验收：确认 Docker Desktop 正在运行且项目目录可共享，执行 `bash ./scripts/doctor.sh`；目标数据库为空时执行 `bash ./scripts/deploy.sh --init-db`，已有表时省略 `--init-db`；仅在后端健康检查为 `UP` 且两个前端均返回 HTTP `200` 后接受结果。数据库非空、端口归属或目录共享不明确时停止并由使用者确认。

需要持续验证特定 Mac 硬件、网络或 Docker Desktop 行为时，可由项目所有者决定维护自托管 macOS Runner。它不应被自动创建、注册或配置真实凭据；除非工作流另行显式增加 Docker 与完整启动测试，否则它同样不能填补上述验收缺口。

## 部署说明

- 本仓库脚本面向本地开发和本地构建验证。
- `-Mode prod` / `--mode=prod` 只是运行构建后的本地 preview，不是生产级 Web Server 或生产发布方案。
- 不要把 `.env`、真实凭据、`mysql-data/`、`redis-data/`、`logs/`、`.pids/`、`dist/` 或 `target/` 提交到仓库。
