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

## 2.1 协作者机器差异与选择流程

已有部署记录仅代表记录机器当时的状态。其他协作者不应假设会复现 Docker、端口、客户端或网络下载问题，也不应假设已有监听服务可以复用。

| 检查项 | 机器差异 / 通用规则 | 可执行决策 |
| --- | --- | --- |
| JDK 17、Node.js、npm | 机器差异 | doctor 未通过时停止部署。脚本不会安装系统软件，由使用者修复环境后重新运行 doctor。 |
| Docker CLI | 机器差异 | 缺少 CLI 时不能使用 Compose；可改走已确认的本机 MySQL/Redis 流程。 |
| Docker daemon | 机器差异 | `docker compose version` 成功不等于 daemon 可用。仅 `docker info` 成功后才可使用默认 Docker 流程。 |
| 本机 MySQL/Redis | 机器差异 | 使用 `-SkipDocker` / `--skip-docker` 后，TCP 通过只说明端口可达；协议与凭据是否通过以 `mysql-protocol`、`redis-protocol` 为准。 |
| `mysql` / `redis-cli` 客户端 | 机器差异 | 缺少客户端时 doctor 会标记验证边界。`init-local-db` 必须使用 `mysql` 客户端；缺少 `redis-cli` 时，Redis 必须由最终后端健康检查确认。 |
| 数据库初始化 | 通用安全规则 | 只对没有表的目标库初始化。非空库或导入失败后的部分库必须保留，改用新的 `DB_NAME` 重试。 |
| 端口与已运行进程 | 机器差异，且有通用安全规则 | 监听、HTTP 200 或健康状态均不能证明进程属于当前 clone。仅脚本身份元数据与健康检查都匹配时才可复用。 |
| Git、镜像、Maven、npm 下载 | 机器差异 | 首次下载受网络、代理、镜像源和本机缓存影响。先检查网络/代理后重试；不要把下载失败当作代码故障，也不要删除数据目录作为重试手段。 |

按以下顺序选择：

1. 正常运行 doctor。仅当 Docker CLI 与 daemon 都通过时，使用第 3 节 Docker 流程。
2. Docker CLI 缺失或 daemon 不可达时，复制 `.env.example` 为 `.env` 并填写本机服务配置，运行带 `-SkipDocker` / `--skip-docker` 的 doctor。
3. 本机流程要求 MySQL、Redis 的目标端口可达。可用客户端时还必须通过协议检查；没有 `mysql` 客户端时不能执行首次本机初始化。任何凭据、服务归属或数据状态不明确时停止并由使用者确认。
4. 只有目标库为空时才初始化。数据库已含表或上次导入中断时，保持原库不变并设置新的未使用 `DB_NAME` 后重试。
5. 启动后以第 6 节的三项 HTTP 检查为准，不能只依据端口监听、进程存在或前端 HTTP 200 判断成功。

## 2.2 macOS 额外前置检查

macOS 终端默认可能运行 `zsh`，但项目的 `.sh` 脚本依赖 Bash 语法。必须使用 `bash ./scripts/doctor.sh`、`bash ./scripts/deploy.sh`、`bash ./scripts/init-local-db.sh` 和 `bash ./scripts/stop.sh` 调用；不要用 `zsh` 或 `sh` 替代。

1. 先运行 `bash ./scripts/doctor.sh`。默认 Docker 流程要求 JDK 17、Node.js、npm、`macos-bash`、`docker-cli` 与 `docker-daemon` 均通过。Docker 未通过时，按第 4 节使用 `bash ./scripts/doctor.sh --skip-docker` 诊断本机 MySQL/Redis；脚本不会安装或配置系统软件。
2. doctor 的 `macos-architecture` 仅记录当前机器报告的 `arm64` 或 `x86_64` 等架构。Intel 与 Apple Silicon 均不作预先兼容性承诺；只有当前 Docker Desktop 的 `docker info` 成功，且实际 `docker compose up` 完成镜像拉取和容器启动，才能确认该机器的 Docker 流程可用。
3. Docker Desktop 使用 Compose bind mount 时，默认会访问 `./mysql-data`、`./redis-data`；启用监控时还会访问 `./prometheus` 和 `./grafana/provisioning`。确认项目根目录对当前用户可写，并在 Docker Desktop 中确认这些目录可被共享访问。`docker info` 只能确认 daemon，不能确认 bind mount 的目录共享。
4. 部署脚本会让两个前端以 `0.0.0.0` 监听配置端口。只验证本机时使用第 6 节的 `127.0.0.1` 检查；若需要其他设备访问，由使用者根据 macOS 防火墙或企业安全策略仅放行所需端口。不得为部署关闭防火墙或扩大安全策略。
5. 端口、本机服务与数据规则不因 macOS 而变化：先确认占用进程和 MySQL/Redis 的归属，再通过 `.env` 统一配置端口。仅在 `--skip-docker` 诊断完成后使用 `--skip-infrastructure`；`init-local-db.sh` 只可初始化空数据库，禁止用清库、删表或删除 Docker volume 作为重试手段。

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

适用于 Docker CLI 缺失或 Docker Desktop/Engine 无法启动，但机器上已有 MySQL 和 Redis 的情况。`docker compose version` 成功本身不能满足这一前提，必须以 `docker info` 判断 daemon 是否可达。

1. 复制 `.env.example` 为 `.env`（若尚未创建），并确认 MySQL 和 Redis 的目标地址、端口和凭据均属于使用者可操作的本机服务。端口监听不等于可复用服务。
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

本机服务流程下不要传 `-InitDb` / `--init-db`；部署脚本不会代替用户操作本机数据库。`mysql-client WARN` 表示 `mysql` 客户端缺失，首次本机初始化必须停止；`redis-client WARN` 表示 Redis 协议未由 doctor 确认，不能把 TCP 可达视为最终成功，需由第 6 节后端健康检查确认。

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

处理：先启动 Docker Desktop/Engine 并重新运行 doctor。无法启动时，先运行带 `-SkipDocker` / `--skip-docker` 的 doctor；仅当 `.env` 指向的本机 MySQL/Redis 通过所能完成的诊断时，使用 `-SkipInfrastructure` / `--skip-infrastructure`。不要把 Docker 环境故障判断为项目代码故障。

### 本机客户端缺失

症状：本机流程中 doctor 显示 `mysql-client WARN` 或 `redis-client WARN`。

处理：`mysql-client WARN` 时无法运行 `init-local-db`，必须由使用者安装或将 MySQL 客户端加入 `PATH` 后重试，禁止改用手写导入命令。`redis-client WARN` 时 TCP 探测不能证明 Redis 协议正常；可在使用者确认服务后继续，但只有第 6 节后端健康检查中的 `redis=UP` 才能完成验证。

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

### Git、Docker 镜像或 npm 下载失败

仓库拉取、`docker compose up` 的镜像拉取和 `npm ci` 的依赖下载都依赖当前机器的网络、代理、镜像源和缓存。先检查这些环境因素并重试；不要通过删除 `mysql-data/`、`redis-data/`、Docker volume 或现有数据库来解决下载问题。

## 9. 监控与生产边界

本地监控：

```powershell
docker compose --profile monitoring up -d
```

- Prometheus：`http://localhost:9090`
- Grafana：`http://localhost:3000`，本地默认账号 `admin` / `admin`

本仓库部署脚本只覆盖本地开发和构建预览。`prod` 模式使用 Vite preview，不提供 HTTPS、反向代理、持久化备份、secret 管理、滚动发布或生产回滚，不能作为生产部署方案。
