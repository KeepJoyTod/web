# ProjectKu Web 项目对话记录

**日期：** 2026年5月2日  
**项目：** ProjectKu Web 电商系统

---

## 1. 项目总结与优化建议

### 项目概述
这是一个完整的前后端分离电商示例工程，包含：

**技术栈：**
- 后端：Spring Boot 3.2.3 + MyBatis + MySQL + Redis
- 前端：Vue 3 + Vite + TypeScript + Pinia
- 监控：Prometheus + Grafana + Actuator
- 测试：Playwright + Allure

**架构特点：**
- 独立后台管理系统（frontend-admin）
- 完整的用户认证授权体系
- 商品管理、购物车、订单流程
- 性能监控和自动化测试覆盖

### 主要优化建议

#### 1. 安全性优化
- **敏感信息硬编码**：数据库密码、Redis配置等应使用环境变量
- **API安全**：添加接口限流、参数校验、SQL注入防护
- **认证增强**：JWT token刷新机制、密码强度策略

#### 2. 性能优化
- **数据库**：添加索引优化查询性能，考虑读写分离
- **缓存策略**：Redis缓存热点数据，实现多级缓存
- **前端**：代码分割、懒加载、图片压缩优化

#### 3. 代码质量
- **配置管理**：使用Spring Profiles区分环境配置
- **异常处理**：统一异常处理机制和错误码规范
- **日志规范**：结构化日志输出，便于监控和排查

#### 4. 运维优化
- **容器化**：完善Dockerfile，支持多阶段构建
- **CI/CD**：添加自动化构建、测试、部署流水线
- **监控告警**：Grafana告警规则配置，关键指标监控

#### 5. 开发体验
- **文档完善**：API文档自动生成，开发环境一键启动
- **代码规范**：统一代码风格，添加pre-commit hooks
- **依赖管理**：定期更新依赖版本，修复安全漏洞

#### 6. 功能扩展
- **搜索优化**：集成Elasticsearch实现全文搜索
- **消息队列**：引入RabbitMQ/Kafka处理异步任务
- **分布式**：支持水平扩展和负载均衡

---

## 2. Grafana K6 仪表板配置分析

### 文件位置
`grafana/provisioning/dashboard-json/k6-prometheus-dashboard.json`

### 主要面板

#### 1. K6 Request Rate（左上）
- 显示每秒请求数 (requests/sec)
- 指标：`sum(rate(k6_http_reqs_total[1m])) by (testid)`
- 单位：reqps

#### 2. K6 Latency（右上）
- 显示响应延迟指标
- 包含 p95、p99、avg 三条曲线
- 指标：`k6_http_req_duration_p95/p99/avg`
- 单位：毫秒

#### 3. K6 Checks And Failures（左下）
- 显示检查通过率和失败率
- 指标：`k6_http_req_failed_rate` 和 `k6_checks_rate`
- 单位：百分比

#### 4. K6 Virtual Users（右下）
- 显示虚拟用户数
- 包含当前活跃 VUs 和最大 VUs
- 指标：`k6_vus` 和 `k6_vus_max`

### 配置特点
- **数据源**：Prometheus (UID: PBFA97CFB590B2093)
- **刷新间隔**：5秒
- **时间范围**：最近1小时
- **标签**：projectku, k6, prometheus
- **自动刷新**：启用

---

## 3. 性能压测操作指南

### 前置准备

#### 1. 启动依赖服务
```powershell
cd d:\Java\class\projectKu\web
docker compose up -d
```

#### 2. 启动后端服务
```powershell
cd d:\Java\class\projectKu\web\back
mvn spring-boot:run
```

#### 3. 确保K6已安装
如果没有安装K6，访问 https://k6.io/docs/getting-started/installation/ 下载安装

### 快速开始（推荐）

**首次运行使用自动化脚本：**
```powershell
cd d:\Java\class\projectKu\web
.\scripts\run-first-k6.ps1
```

### 手动运行压测

#### 1. 混合浏览负载测试
测试商品列表、分类、详情等读接口性能

```powershell
.\scripts\run-k6-and-record.ps1 `
  -BaseUrl "http://127.0.0.1:8080/api" `
  -K6Script "k6/api-load.js" `
  -Title "K6 API mixed browse load" `
  -Environment "local-windows" `
  -ExtraK6Args @("--vus", "20", "--duration", "3m")
```

#### 2. 结账流程冒烟测试
测试购物车和下单等写接口（低并发）

```powershell
.\scripts\run-k6-and-record.ps1 `
  -BaseUrl "http://127.0.0.1:8080/api" `
  -K6Script "k6/checkout-smoke.js" `
  -Title "K6 checkout smoke" `
  -Environment "local-windows" `
  -ExtraK6Args @("--vus", "1", "--duration", "1m")
```

### 环境变量配置

可通过环境变量自定义测试参数：
- `BASE_URL`: API基础地址（默认：http://127.0.0.1:8080/api）
- `ACCOUNT`: 登录账号（默认：user@example.com）
- `PASSWORD`: 登录密码（默认：123456）
- `ENABLE_AUTH`: 是否启用认证（默认：true）
- `VUS`: 虚拟用户数
- `DURATION`: 测试持续时间
- `THINK_TIME`: 思考时间间隔（默认：1秒）

### 测试脚本说明

- **api-load.js**: 混合浏览负载，包含分类、商品列表、详情、用户信息等接口
- **checkout-smoke.js**: 结账流程测试，包含加购、购物车查询、下单等接口

---

## 4. 环境检查与性能测试执行

### 环境状态检查结果

**检查结果：**
- ✅ K6 已安装（v1.7.1）
- ✅ MySQL 正在运行（端口 3306）
- ✅ Redis 正在运行（端口 6379）
- ✅ 后端服务已启动且健康
- ✅ Grafana 和 Prometheus 正在运行

### 性能测试执行结果

**测试配置：**
- 虚拟用户数：20
- 持续时间：3分钟
- 测试脚本：混合浏览负载（分类、商品列表、详情、用户信息等）

**测试结果：**

#### 整体性能指标
- 总请求数：12,516
- 请求速率：69.14 req/s
- 失败率：0.00%
- 总迭代次数：3,582

#### 响应时间
- 平均响应时间：1.53ms
- 中位数：1.08ms
- P90：2.68ms
- P95：3.79ms
- P99：7.7ms
- 最大响应时间：32.82ms

#### 检查通过率
- 总检查数：24,992
- 成功率：100.00%
- 失败数：0

#### 阈值检查
- ✅ 检查通过率 > 99%：100.00%
- ✅ P95 < 800ms：3.79ms
- ✅ P99 < 1500ms：7.7ms
- ✅ 失败率 < 1%：0.00%

#### 网络流量
- 接收数据：23 MB
- 发送数据：2.9 MB

**结论：**
系统在20个并发用户下表现优秀，所有响应时间指标远低于阈值，无任何失败请求，系统性能稳定。

---

## 5. Grafana 监控数据查看指南

### 访问 Grafana

**登录地址：**
- URL：http://localhost:3000
- 账号：admin
- 密码：admin

**找到 K6 仪表板：**
1. 登录后点击左侧菜单 "Dashboards"
2. 选择 "Browse"
3. 找到 "ProjectKu K6 Performance Test" 仪表板
4. 点击打开

### 仪表板指标说明

#### 1. K6 Request Rate（请求速率）
- **指标含义**：每秒请求数（requests per second）
- **单位**：reqps
- **数据解读**：
  - 数值越高表示系统吞吐量越大
  - 波动较大可能表示系统负载不稳定
  - 正常情况下应该保持相对稳定

#### 2. K6 Latency（响应延迟）
- **指标含义**：请求响应时间分布
- **单位**：毫秒（ms）
- **三条曲线**：
  - **p95**：95%的请求响应时间低于此值
  - **p99**：99%的请求响应时间低于此值
  - **avg**：平均响应时间
- **数据解读**：
  - p95 和 p99 越低表示性能越好
  - 如果 p99 突然升高，说明有慢请求
  - 正常电商系统 p95 应 < 500ms

#### 3. K6 Checks And Failures（检查和失败率）
- **指标含义**：业务检查通过率和请求失败率
- **单位**：百分比（%）
- **两条曲线**：
  - **failed rate**：请求失败率
  - **checks rate**：业务检查通过率
- **数据解读**：
  - failed rate 应该接近 0%
  - checks rate 应该接近 100%
  - 失败率突然升高表示系统异常

#### 4. K6 Virtual Users（虚拟用户）
- **指标含义**：当前活跃的虚拟用户数
- **单位**：用户数
- **两条曲线**：
  - **active VUs**：当前活跃虚拟用户数
  - **max VUs**：最大虚拟用户数
- **数据解读**：
  - 显示测试负载大小
  - 可以用来分析负载与性能的关系

### 其他重要信息

**仪表板设置：**
- **刷新间隔**：5秒自动刷新
- **时间范围**：默认显示最近1小时数据
- **图例**：显示 lastNotNull（最新值）和 max（最大值）

**性能评估标准：**
- 响应时间：p95 < 500ms 为优秀
- 失败率：< 0.1% 为可接受
- 吞吐量：根据业务需求确定

---

## 6. Prometheus 监控指标查看指南

### 访问 Prometheus 界面

**地址：** http://localhost:9090

### 常用 Spring Boot 指标查询

#### 1. JVM 内存指标

**堆内存使用：**
```
jvm_memory_used_bytes{area="heap"}
```

**非堆内存使用：**
```
jvm_memory_used_bytes{area="nonheap"}
```

**内存使用率：**
```
jvm_memory_used_bytes / jvm_memory_max_bytes
```

#### 2. HTTP 请求指标

**请求总数：**
```
http_server_requests_seconds_count
```

**请求响应时间：**
```
http_server_requests_seconds
```

**P95 响应时间：**
```
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))
```

#### 3. 数据库连接池指标

**活跃连接数：**
```
hikaricp_connections_active
```

**空闲连接数：**
```
hikaricp_connections_idle
```

**连接池使用率：**
```
hikaricp_connections_active / hikaricp_connections_max
```

#### 4. 系统资源指标

**CPU 使用率：**
```
system_cpu_usage
```

**线程数：**
```
jvm_threads_live_threads
```

**GC 时间：**
```
jvm_gc_pause_seconds
```

### Prometheus 界面操作步骤

#### 1. 查询指标
- 在首页搜索框输入查询语句
- 点击 "Execute" 执行查询
- 选择 "Graph" 或 "Table" 视图

#### 2. 查看所有可用指标
- 点击顶部 "Status" → "Targets"
- 查看所有采集目标
- 点击 "Metrics" 查看完整指标列表

#### 3. 设置时间范围
- 右上角选择时间范围
- 支持自定义时间范围

#### 4. 构建复杂查询
- 使用 Graph 面板
- 支持多个查询组合
- 可添加告警规则

### 实用查询示例

**查看最近5分钟的请求速率：**
```
rate(http_server_requests_seconds_count[5m])
```

**查看错误率：**
```
rate(http_server_requests_seconds_count{status=~"5.."}[5m]) / rate(http_server_requests_seconds_count[5m])
```

**查看内存趋势：**
```
jvm_memory_used_bytes{area="heap"}
```

### 当前 Prometheus 数据状态

**K6 测试数据：**
- ❌ **无数据** - K6 测试指标未推送到 Prometheus
- 原因：K6 测试脚本没有配置 Prometheus 输出

**Spring Boot 应用数据：**
- ✅ **有数据** - 正在采集 Spring Boot 应用指标

**当前可用的 Prometheus 指标：**

**JVM 内存使用情况：**
- G1 Old Gen：455 MB
- G1 Eden Space：44 MB  
- G1 Survivor Space：0.5 MB
- Metaspace：66.7 MB
- Code Cache：23 MB
- Compressed Class Space：9 MB

**系统健康状态：**
- Spring Boot 应用：UP (正常运行)
- Prometheus 自身：UP (正常运行)

---

## 7. K6 数据集成说明

### K6 数据未集成的原因

Grafana 中的 K6 仪表板配置了 K6 指标，但需要 K6 测试时配置 Prometheus 输出。当前测试使用的是 K6 默认输出，没有将数据推送到 Prometheus。

### 如需集成 K6 数据到 Prometheus

需要：
1. 配置 K6 使用 Prometheus 输出格式
2. 或使用 K6 + Prometheus Remote Write 集成

目前 Prometheus 主要监控 Spring Boot 应用的运行时指标，这对应用性能监控同样有价值。

---

## 总结

本次对话涵盖了 ProjectKu Web 项目的全面分析，包括：

1. **项目架构分析**：技术栈、架构特点、优化建议
2. **监控系统**：Grafana 仪表板配置、Prometheus 指标采集
3. **性能测试**：K6 压测脚本、环境检查、测试执行
4. **监控使用**：Grafana 和 Prometheus 的使用指南
5. **实际测试**：成功执行了20并发用户的性能测试，系统表现优秀

项目整体架构合理，功能完整，具备良好的扩展性。监控体系完善，为性能优化和问题排查提供了有力支持。
