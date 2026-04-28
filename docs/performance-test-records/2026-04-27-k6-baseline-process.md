# 2026-04-27 K6 首轮压测过程记录

## 1. 目标

验证本地环境下后端接口在基线并发下的可用性与响应时间，形成一套可复现的 K6 执行流程，并输出压测产物。

本次压测对象：

- 服务地址：`http://127.0.0.1:8080/api`
- 压测脚本：`k6/api-load.js`
- 压测类型：混合浏览读接口压测
- 并发参数：`20 VUs`
- 持续时间：`3m`

## 2. 执行前准备

执行前已确认以下条件成立：

- 后端健康检查 `GET /api/` 返回 `200`
- MySQL 进程存在
- Redis 进程存在
- `k6` 实际安装路径为 `C:\Program Files\k6\k6.exe`

执行命令：

```powershell
.\scripts\run-k6-and-record.ps1 `
  -K6Cmd 'C:\Program Files\k6\k6.exe' `
  -BaseUrl 'http://127.0.0.1:8080/api' `
  -K6Script 'k6/api-load.js' `
  -Title 'K6 API mixed browse load' `
  -Environment 'local-windows' `
  -ExtraK6Args @('--vus','20','--duration','3m') `
  -ContinueIfK6Failed
```

## 3. 执行过程

### 第一次执行

- Run ID：`PERF-20260427-202307`
- 结果：失败

发现的问题：

- `/v1/categories` 被脚本当作公开接口调用，但实际需要登录态，导致整段请求返回 `401`
- `http_req_failed` 约 `29.07%`
- `checks` 约 `70.92%`

对应产物：

- `k6/results/PERF-20260427-202307-summary.json`
- `k6/results/PERF-20260427-202307.log`

### 第二次执行

- Run ID：`PERF-20260427-202743`
- 结果：压测阈值通过，但仍存在少量详情接口失败

修正内容：

- 分类接口改为带 token 请求
- setup 阶段先拉取种子商品和地址

仍发现的问题：

- 商品详情接口存在脏数据，`productId=146` 稳定返回 `500`
- 列表页随机抽样会命中该商品，导致 `get product detail` 仍有失败
- `http_req_failed` 降到 `0.66%`
- `checks` 提升到 `99.33%`

对应产物：

- `k6/results/PERF-20260427-202743-summary.json`
- `k6/results/PERF-20260427-202743.log`
- `docs/performance-test-records/PERF-20260427-202743.md`

### 第三次执行

- Run ID：`PERF-20260427-203126`
- 结果：最终有效基线结果

修正内容：

- 商品详情不再从当前列表页随机抽样
- setup 阶段先校验可正常访问的商品详情，只从健康商品集合中取样

最终压测结果：

- `http_req_failed = 0.00%`
- `checks = 100.00%`
- `http_req_duration p95 = 2.80ms`
- `http_req_duration p99 = 4.94ms`
- `http_reqs = 12557`
- `iterations = 3580`
- `vus_max = 20`

对应产物：

- `k6/results/PERF-20260427-203126-summary.json`
- `k6/results/PERF-20260427-203126.log`
- `docs/performance-test-records/PERF-20260427-203126.md`

## 4. 本次过程中修改的脚本

为保证压测可以稳定复现，本次补充或调整了以下文件：

- `k6/api-load.js`
- `k6/checkout-smoke.js`
- `k6/lib/projectKu.js`
- `k6/README.md`
- `scripts/run-first-k6.ps1`
- `scripts/run-k6-and-record.ps1`

关键修正点：

- 兼容本地 `k6` 绝对路径执行
- 分类接口按实际后端行为使用鉴权
- setup 阶段缓存健康商品列表，避免脏数据影响基线结果

## 5. 已确认的问题

### 5.1 商品详情存在异常数据

在手工验证中，`GET /api/v1/products/146` 稳定返回 `500`。这说明当前数据库种子数据或后端详情组装逻辑存在异常项。

影响：

- 若压测脚本直接从商品列表随机挑选详情页请求，会把该后端缺陷混入压测失败率

建议：

- 单独排查 `productId=146` 的详情接口错误原因
- 在修复前，不要把该商品纳入读压测基线集合

### 5.2 记录脚本与 k6 v1.7.1 的 summary JSON 不兼容

虽然第三次压测的 K6 实际结果全部通过，但自动生成的 Markdown 报告 `PERF-20260427-203126.md` 仍显示为 `FAIL`，且核心指标为 `N/A`。

原因：

- 当前记录脚本读取的是 `metrics.<name>.values`
- 这次 `k6 v1.7.1` 导出的 summary JSON 中，指标直接位于 `metrics.<name>` 下

影响：

- 自动报告中的 `PASS/FAIL` 结论不可靠
- 本次应以 `summary.json` 和 K6 控制台结果为准

建议：

- 后续修复 `record_k6_run.py`，兼容当前 K6 summary 结构

## 6. 结论

本次首轮基线压测已经完成，最终有效结果以 `PERF-20260427-203126` 为准。

在 `20 VUs / 3m` 的本地基线条件下：

- 接口可用性达到 `100%`
- 错误率为 `0.00%`
- 延迟明显低于既定阈值

当前压测流程已经可以复跑，但在扩大并发前，建议优先处理以下两项：

1. 修复 `productId=146` 的详情接口 `500` 问题
2. 修复压测记录脚本对 `k6 v1.7.1` summary JSON 的兼容性
