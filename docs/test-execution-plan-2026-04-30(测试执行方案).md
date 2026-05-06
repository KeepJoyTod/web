# 测试执行方案（仅方案，不执行）

更新时间：2026-04-30  
适用项目：`D:\Java\class\projectKu\web`

## 1. 目标

- 在不修改业务代码的前提下，完成一次可复现的全链路测试执行。
- 覆盖后端接口、用户端前端、管理端前端、API 自动化、性能基线。
- 沉淀可追溯产物（报告、日志、缺陷、性能记录）。

## 2. 测试范围

- 后端：`back/`（Spring Boot + MyBatis）
- 用户端：`frontend/`（Vue + Playwright）
- 管理端：`frontend-admin/`（Vue + Playwright）
- API 自动化：`api_testcases/pytest/`
- 性能测试：`k6/` + `scripts/run-k6-and-record.ps1`

## 3. 执行前检查（Gate 0）

1. 环境依赖
- JDK 17、Maven、Node.js、Python3、Docker Desktop 可用。
- MySQL/Redis 可连接。

2. 服务与端口
- 后端：`http://127.0.0.1:8080/api`
- 用户端：`http://127.0.0.1:5173`
- 管理端：`http://127.0.0.1:5174`
- Prometheus：`http://127.0.0.1:9090`
- Grafana：`http://127.0.0.1:3000`

3. 数据准备
- 初始化或确认数据库脚本已执行（`back/sql/*.sql`）。
- 测试账号可用：`user@example.com / 123456`、`admin@example.com / admin123`。

## 4. 分阶段执行方案

## 阶段A：基础可用性冒烟（必须先过）

1. 启动基础依赖（如使用 Docker）
```powershell
cd D:\Java\class\projectKu\web
docker compose up -d
```

2. 启动后端
```powershell
cd D:\Java\class\projectKu\web\back
mvn spring-boot:run
```

3. 冒烟检查点
- `GET /api/` 可访问
- `GET /api/actuator/health` 返回 `UP`
- `GET /api/v1/products` 返回 200 且有数据

准入标准：
- 关键接口 100% 可访问，若失败则停止后续阶段。

## 阶段B：API 自动化测试（Pytest）

1. 执行目录：`api_testcases/pytest`
2. 建议命令
```powershell
cd D:\Java\class\projectKu\web\api_testcases\pytest
python -m pip install -r requirements.txt
python -m pytest -q --junitxml=pytest-report.xml --html=pytest-report.html --self-contained-html
```

检查点：
- 主接口状态码与返回结构符合预期。
- 无阻塞级失败（P0/P1）。

产物：
- `api_testcases/pytest/pytest-report.xml`
- `api_testcases/pytest/pytest-report.html`

## 阶段C：用户端 E2E 自动化（Playwright）

1. 执行目录：`frontend`
2. 建议顺序（先冒烟后专项）
```powershell
cd D:\Java\class\projectKu\web\frontend
npm.cmd run test:e2e
npm.cmd run test:login
npm.cmd run test:register
npm.cmd run test:navigation
npm.cmd run test:product-detail
npm.cmd run test:cart
npm.cmd run test:checkout
```

3. 报告生成
```powershell
cd D:\Java\class\projectKu\web\frontend
npm.cmd run allure:generate
```

产物：
- `frontend/playwright-report/`
- `frontend/test-results/`
- `frontend/allure-results/`
- `frontend/allure-report/`

## 阶段D：管理端 E2E 冒烟

1. 执行目录：`frontend-admin`
2. 建议命令
```powershell
cd D:\Java\class\projectKu\web\frontend-admin
npx.cmd playwright test tests/admin-smoke.spec.ts
```

检查点：
- 管理端登录、核心列表页、基础操作链路可达。

产物：
- `frontend-admin/test-results/`

## 阶段E：回归测试

触发条件：
- 阶段B/C/D 出现缺陷并修复后。

执行策略：
- 仅重跑受影响模块 + 主流程（登录、商品详情、购物车、结算、管理端冒烟）。

准入标准：
- 已修复缺陷回归通过；
- 主流程连续两轮执行稳定。

## 阶段F：性能基线（K6）

1. 浏览类混合负载
```powershell
cd D:\Java\class\projectKu\web
.\scripts\run-k6-and-record.ps1 `
  -BaseUrl "http://127.0.0.1:8080/api" `
  -K6Script "k6/api-load.js" `
  -Title "K6 API mixed browse load" `
  -Environment "local-windows" `
  -ExtraK6Args @("--vus", "20", "--duration", "3m")
```

2. 结算链路低并发冒烟
```powershell
cd D:\Java\class\projectKu\web
.\scripts\run-k6-and-record.ps1 `
  -BaseUrl "http://127.0.0.1:8080/api" `
  -K6Script "k6/checkout-smoke.js" `
  -Title "K6 checkout smoke" `
  -Environment "local-windows" `
  -ExtraK6Args @("--vus", "1", "--duration", "1m")
```

重点指标：
- `http_req_failed`
- `checks`
- `http_req_duration p(95), p(99)`
- `http_reqs`、`iterations`、`vus_max`

产物：
- `docs/performance-test-records/`（Markdown 记录）

## 5. 缺陷分级与阻断策略

- P0：系统不可用/核心交易中断，立即阻断发布。
- P1：核心流程失败（登录、下单、支付前链路），阻断发布。
- P2：非核心功能异常，可评估后带风险上线。
- P3：体验类问题，进入后续迭代。

规则：
- 存在未关闭 P0/P1 时，不进入性能结论和上线建议。

## 6. 准出标准（Exit Criteria）

- 冒烟通过率 100%。
- API 自动化无 P0/P1 失败。
- 用户端与管理端主流程 E2E 通过。
- 回归结果稳定（至少 2 轮）。
- 性能指标达标或已明确优化计划与复测时间。
- 缺陷与风险已沉淀到 `docs/bug-report.md`。

## 7. 建议执行节奏（1 天版本）

- 上午：Gate 0 + 阶段A + 阶段B
- 下午：阶段C + 阶段D + 回归
- 晚些时候：阶段F（性能基线）+ 汇总结论

## 8. 说明

- 本文档为执行方案，不包含实际执行动作。
- 本次仅完成方案落盘，未运行任何测试命令。
