# 本地部署与 AI 执行协议

本文件是 ProjectKu Web 本地部署的唯一事实源。目标是让开发者或 AI 助手在不猜测配置、不自动改系统环境、不破坏已有数据的前提下完成部署。

## 1. AI 必须遵守的执行顺序

1. 读取根目录 `AGENTS.md`、本文件、`.env.example`、`docker-compose.yml` 和 `back/src/main/resources/application.yml`。
2. 查看 `git status --short --branch`，保留已有改动。
3. 运行只读诊断：Windows 使用 `scripts/doctor.ps1`，Linux/macOS 使用 `scripts/doctor.sh`；Docker 不可用且准备使用本机服务时，分别传 `-SkipDocker` / `--skip-docker`。
4. 根据诊断选择默认 Docker 流程或本机 MySQL/Redis 流程。
5. 首次空库才使用 `-InitDb` / `--init-db`。已有表时禁止自动清库、删 volume 或重导 SQL。
6. 启动后必须验证后端健康检查和两个前端 HTTP 状态，不能只根据进程存在判断成功。
7. 总结实际命令、观察结果、日志路径和未验证项。

AI 不得自行执行以下操作：安装或卸载系统软件、修改系统级环境变量、终止不属于本项目的进程、删除 `mysql-data/` 或 `redis-data/`、清空数据库、写入生产环境。需要这些操作时先向项目所有者说明原因并取得确认。

## 2. 环境契约

| 依赖 | 要求 | 项目内依据 |
| --- | --- | --- |
| Java | JDK 17 | `back/pom.xml` 的 `java.version` |
| Maven | 无需全局安装 | `back/mvnw` / `back/mvnw.cmd` 固定 Maven 3.9.9 |
| Node.js | `^20.19.0` 或 `>=22.12.0` | 两个前端 `package.json` 的 `engines` |
| npm | 使用各前端的 `package-lock.json` 和 `npm ci` | `frontend/`、`frontend-admin/` |
| MySQL | 8.0，默认 `127.0.0.1:3306` | `docker-compose.yml`、`application.yml` |
| Redis | 默认 `127.0.0.1:6379` | `docker-compose.yml`、`application.yml` |

Windows 上优先使用 `npm.cmd` 和 `npx.cmd`，避免 PowerShell 执行策略拦截同名 `.ps1` shim。

## 3. 默认流程：Docker 提供 MySQL/Redis

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -InitDb
```

### Linux / macOS

```bash
bash ./scripts/doctor.sh
bash ./scripts/deploy.sh --init-db
```

脚本会执行：

1. 使用 Compose 启动 `mysql` 和 `redis`。
2. 等待 MySQL 可连接。
3. 仅在 `-InitDb` / `--init-db` 且数据库没有表时导入 `back/sql/init_db.sql`。
4. 使用 Maven Wrapper 编译后端。
5. 服务未运行时使用 `npm ci` 按锁文件同步并构建两个前端；已确认同一项目的 dev server 正在运行时跳过 `npm ci`，避免 Windows 锁定原生模块导致安装失败。
6. 启动后端、用户端和管理端，日志写入 `logs/`，PID 写入 `.pids/`。
7. 等待三个 HTTP 入口可访问。

后续启动省略初始化参数：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1
```

## 4. 备选流程：使用本机 MySQL/Redis

适用于 Docker Desktop 无法启动，但机器上已有 MySQL 和 Redis 的情况。

1. 确认 MySQL 和 Redis 已监听 `.env` 中的端口。
2. 首次部署使用安全初始化脚本。脚本读取 `.env`，创建不存在的数据库，确认数据库没有表后才以字节流导入 SQL：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1 -SkipDocker
powershell -ExecutionPolicy Bypass -File .\scripts\init-local-db.ps1
```

3. 启动应用但跳过 Compose：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -SkipInfrastructure
```

Linux/macOS 使用：

```bash
bash ./scripts/doctor.sh --skip-docker
bash ./scripts/init-local-db.sh
bash ./scripts/deploy.sh --skip-infrastructure
```

本机服务流程下不要传 `-InitDb` / `--init-db`；部署脚本不会代替用户操作本机数据库。

## 5. 自定义配置

只有默认端口或凭据不适用时才创建 `.env`：

```powershell
Copy-Item .env.example .env
```

Compose 自动读取根目录 `.env`，部署脚本会把同一组变量传给 Spring Boot。`DB_PORT` 同时控制 MySQL 的宿主机映射和后端连接端口，因此不要只改某一侧配置。

Compose 不使用固定容器名。多个目录名相同的 clone 共用一个 Docker daemon 时，应为每个 clone 设置唯一的 `COMPOSE_PROJECT_NAME`，并配置不冲突的应用、MySQL 和 Redis 端口。

Compose 初始化流程要求 `DB_USER=root`。非 root 账号只用于已经由使用者预先授权和建库的 MySQL，此时必须选择 `-SkipInfrastructure` / `--skip-infrastructure`，脚本不会代替使用者创建或授权数据库账号。

默认凭据只用于本地开发。真实环境必须通过外部 secret 管理提供凭据，不能提交 `.env`。

## 6. 验证标准

Windows：

```powershell
$health = Invoke-RestMethod http://127.0.0.1:8080/api/actuator/health
$user = Invoke-WebRequest http://127.0.0.1:5173/ -UseBasicParsing
$admin = Invoke-WebRequest http://127.0.0.1:5174/ -UseBasicParsing
"health=$($health.status) user=$($user.StatusCode) admin=$($admin.StatusCode)"
```

期望：`health=UP user=200 admin=200`。还应执行：

```powershell
docker compose ps
git diff --check
```

Docker 被跳过时，不要求 `docker compose ps`，但健康检查中的 `db` 和 `redis` 必须为 `UP`。

## 7. 日志与停止

日志：

- `logs/backend.out.log`、`logs/backend.err.log`
- `logs/frontend.out.log`、`logs/frontend.err.log`
- `logs/admin.out.log`、`logs/admin.err.log`

部署脚本还会在 `.pids/` 写入进程身份元数据。停止脚本会同时核对 PID、启动时间和项目根目录；旧格式或身份不一致时会拒绝终止进程，避免 PID 复用造成误杀。

停止应用：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\stop.ps1
```

同时停止 MySQL/Redis：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\stop.ps1 -StopInfrastructure
```

Linux/macOS 分别使用 `bash ./scripts/stop.sh` 和 `bash ./scripts/stop.sh --stop-infrastructure`。

## 8. 已知问题与处理

### Docker CLI 存在但 daemon 不可用

症状：`docker compose version` 正常，但 `docker info` 或 `docker compose up` 报连接 daemon/service 失败。

处理：先启动 Docker Desktop/Engine。无法启动时，若本机 MySQL/Redis 可用，则使用 `-SkipInfrastructure` / `--skip-infrastructure`；不要把 Docker 环境故障判断为项目代码故障。

### `JAVA_HOME` 错误

症状：`java -version` 可用，但 Maven 报 `JAVA_HOME environment variable is not defined correctly`。

处理：让 `JAVA_HOME` 指向 JDK 17 根目录，而不是 `bin/java`。临时 PowerShell 示例：

```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
```

路径必须以当前机器实际安装位置为准。

### MySQL 端口被占用

先确认占用者是否为预期的本机 MySQL。使用本机服务时选择 `-SkipInfrastructure`；需要 Compose 改端口时，在 `.env` 中统一修改 `DB_PORT`，例如 `DB_PORT=3309`。

### 数据库已存在表

部署脚本会拒绝对非空数据库执行初始化。正常后续启动应移除 `-InitDb` / `--init-db`。任何清库、删 volume 或重置数据都属于破坏性操作，必须由项目所有者明确批准。

### SQL 导入中途失败

MySQL DDL 不能依赖单个事务自动回滚。导入失败后，原数据库可能只包含部分表，不要直接省略初始化参数继续启动，也不要让 AI 自动删除这些表。

保守恢复方式是在 `.env` 中改用一个新的 `DB_NAME`，重新运行对应初始化流程。Compose 部署脚本和本机初始化脚本都会创建不存在的新数据库，旧数据库会原样保留，待项目所有者确认备份和清理方案后再处理。

### 应用端口已被其他项目占用

健康接口返回 `UP` 不能证明服务属于当前 clone。部署脚本只复用身份元数据与当前仓库匹配的受管理进程；遇到其他健康服务时会停止并报告端口冲突，不会自动结束该进程。请先确认占用者，再修改 `.env` 端口或由其所有者停止服务。

### Maven 下载失败

项目 Wrapper 首次运行需要下载 Maven 3.9.9 和项目依赖。检查网络、代理及 Maven `settings.xml`；不要把本地仓库的 `.lastUpdated` 文件或镜像不可达误判为代码编译错误。

## 9. 监控与生产边界

本地监控：

```powershell
docker compose --profile monitoring up -d
```

- Prometheus：`http://localhost:9090`
- Grafana：`http://localhost:3000`，本地默认账号 `admin` / `admin`

本仓库部署脚本只覆盖本地开发和构建预览。`prod` 模式使用 Vite preview，不提供 HTTPS、反向代理、持久化备份、secret 管理、滚动发布或生产回滚，不能作为生产部署方案。
