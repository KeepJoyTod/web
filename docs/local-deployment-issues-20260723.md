# 本地部署问题记录

日期：2026-07-23

## 部署目标

- 仓库：`https://github.com/KeepJoyTod/web`
- 本地目录：`D:\Java\web222`
- 目标：启动后端、用户端和管理端，并分别验证健康检查与 HTTP 可访问性。

## 已观察的问题

### 1. 初始 Git 克隆超时

- 时间：2026-07-23 00:14 +08:00
- 现象：`git clone https://github.com/KeepJoyTod/web.git .` 在 124 秒后超时，只留下不完整的 Git 元数据。
- 处理：未删除目录，已通过 `git fetch --depth=1 origin main` 和 `git checkout -B main FETCH_HEAD` 恢复工作区。
- 结果：已检出远端 `main` 的 `cbd6ee5`；该问题不再阻塞本地部署。

### 2. Docker daemon 不可达

- 现象：`scripts/doctor.ps1` 检测到 Docker CLI，但 `docker-daemon` 为 `FAIL`。
- 影响：不能使用 Compose 管理 MySQL 和 Redis，也不能使用 `-InitDb`。
- 处理：依据仓库部署协议转用 `-SkipDocker` 诊断；没有停止或修改占用端口的未知进程，也没有删除数据库、卷或数据目录。
- 当前状态：阻塞 Docker 流程，但不一定阻塞本机 MySQL/Redis 流程。

### 3. 本机数据库和缓存只能确认 TCP 可连接

- 现象：`127.0.0.1:3306` 和 `127.0.0.1:6379` 的 TCP 检查通过，但系统没有 `mysql` 和 `redis-cli`。
- 影响：部署前无法通过项目诊断验证 MySQL 凭据、数据库结构或 Redis 协议响应。
- 处理：将使用 `scripts/deploy.ps1 -SkipInfrastructure` 启动应用，由 Spring Boot 健康检查确认实际连接结果；不会对本机数据库执行初始化或写入。
- 当前状态：`unverified`，等待应用启动后的健康检查。

### 4. Java 环境变量告警

- 现象：`JAVA_HOME` 未设置或无效，但 PATH 中可用 Java 17。
- 影响：当前部署脚本会使用检测到的 JDK；未观察到阻塞。
- 当前状态：`unverified`，等待 Maven Wrapper 编译结果。

## 保护措施

- 工作区已有 7 个未提交业务文件改动；本次不修改这些文件。
- 未终止 PID `6580`（MySQL）或 PID `31616`（Redis）。
- 未执行数据库初始化、清库、删除 Docker volume 或数据目录。

## 后续验证

- `http://127.0.0.1:8080/api/actuator/health` 返回 `UP`。
- `http://127.0.0.1:5173/` 和 `http://127.0.0.1:5174/` 返回 HTTP `200`。
- 部署日志位于 `logs/`，启动进程元数据位于 `.pids/`。

## 启动执行与结果

- 执行时间：2026-07-23 00:20 至 00:21 +08:00
- 执行命令：`powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -SkipInfrastructure`
- 脚本结果：退出码 `0`，耗时 67.3 秒。
- 后端验证：`/api/actuator/health` 返回 `status=UP`、`db=UP`、`redis=UP`。
- 用户端验证：`http://127.0.0.1:5173/` 返回 HTTP `200`，并包含 `projectku-user` 页面标识。
- 管理端验证：`http://127.0.0.1:5174/` 返回 HTTP `200`，并包含 `projectku-admin` 页面标识。
- 数据接口验证：`/api/v1/products?page=1&size=6` 返回 HTTP `200`。
- 受管进程元数据：`.pids/backend.pid.json`、`.pids/frontend.pid.json`、`.pids/admin.pid.json` 已生成。

### 5. 用户端在后端启动窗口内出现一次代理连接失败

- 时间：2026-07-23 00:21:03 +08:00
- 证据：`logs/frontend.err.log` 记录了对 `/api/v1/products?page=1&size=6` 的 Vite 代理请求失败，错误为 `ECONNREFUSED 127.0.0.1:8080`。
- 对照：`logs/backend.out.log` 显示后端于 00:21:07 完成启动；后续健康检查、前端 HTTP 检查和商品接口检查均已通过。
- 影响：这是服务并行启动期间的短暂时序问题，不阻塞当前已完成的部署。`verified`：后端和接口现已可访问；`unverified`：未使用浏览器执行页面首屏交互回归。

### 6. 工作区既有改动使全量 `git diff --check` 失败

- 现象：全量 `git diff --check` 报告 7 个预先存在的未提交业务文件包含行尾空白，并以非零退出。
- 处理：未改动这些文件；本次新增的问题记录文件单独执行 `git diff --check -- docs/local-deployment-issues-20260723.md` 未报告问题。
- 影响：不影响已完成的本地运行验证，但提交前仍需要由这些业务改动的所有者处理格式问题。

### 7. 受管应用进程在启动后退出，终止来源未知

- 现象：后续复检时 `8080`、`5173` 和 `5174` 均无监听进程；`.pids/` 中的记录仍存在，但对应 PID 已不在运行。
- 证据：`logs/backend.out.log` 仅记录 Maven Wrapper 的 Spring Boot 子进程以退出码 `1073807364`（`0x40010004`）终止；`logs/backend.err.log` 没有 Java 异常堆栈。
- 影响：此前已通过的 HTTP 验证不能代表服务仍持续运行；需要在优化完成后使用标准部署脚本重新启动并立即复验。
- 当前状态：`unknown`。现有日志不足以确定是项目代码、终端/进程托管环境或外部操作导致的终止，因此本次不修改业务代码或强行改变进程模型。

## 后续部署优化

- 启动时序：`scripts/deploy.ps1` 与 `scripts/deploy.sh` 现在会在启动或复用后端后，先等待 `/api/actuator/health` 返回 `UP`、`db=UP`、`redis=UP`，再启动用户端和管理端，避免本记录中第 5 项的前端代理竞态。
- 降级指引：`scripts/doctor.ps1` 与 `scripts/doctor.sh` 在 Docker CLI 缺失或 daemon 不可达时会输出本机 MySQL/Redis 的安全诊断与启动命令；缺少 `mysql` 或 `redis-cli` 时会明确 TCP 检查的限制和最终健康检查标准。
- 协作者说明：`README.md` 与 `DEPLOYMENT.md` 已增加“机器差异与选择流程”，覆盖 Docker、端口归属、客户端、数据库初始化和网络下载失败。
- 当前环境限制：后续复检中 Docker daemon 仍不可达，`127.0.0.1:6379` 的 Redis TCP 检查失败。因此本次优化后未重启应用；待使用者恢复 Redis 或 Docker 后，应重新运行 doctor、部署脚本和三项 HTTP 验证。

## macOS 协作者评估

- `inference`：当前 Bash 脚本使用的数组、正则、`sed`、`shasum` 回退和 `ps` 身份校验路径已通过静态兼容审计，未发现需要针对 macOS 修改的已证实 Shell 缺陷。
- 已增加的预检：macOS 上的 `doctor.sh` 会报告架构、Bash 版本、`ps` 身份字段、项目目录可写性，并提示 Docker Desktop 的 bind mount 目录共享不能由 `docker info` 自动证明。
- 可能因机器不同而出现：JDK/Node、Docker Desktop daemon、Intel/Apple Silicon 的实际镜像拉取、项目目录共享、端口、防火墙、本机 MySQL/Redis 和命令行客户端。
- 当前状态：`unverified`。本轮没有 macOS 实机，未宣称 Docker 镜像、容器启动或完整应用链路已在 Intel 或 Apple Silicon 上通过。
