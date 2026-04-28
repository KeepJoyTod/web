# 登录测试用例

默认测试账号来自数据库种子数据：

- 账号：`user@example.com`
- 密码：`123456`

如需覆盖默认账号，可在运行 Playwright 前设置环境变量：

- `PLAYWRIGHT_LOGIN_ACCOUNT`
- `PLAYWRIGHT_LOGIN_PASSWORD`
- `PLAYWRIGHT_API_URL`
- `PLAYWRIGHT_BASE_URL`

| 用例编号 | 用例名称 | 前置条件 | 测试步骤 | 预期结果 |
| --- | --- | --- | --- | --- |
| LOGIN-001 | 登录 API 接受有效账号密码 | 后端服务已启动，数据库存在种子账号 | 请求 `POST /api/v1/auth/login`，提交 `user@example.com / 123456` | 返回 `200`；响应包含 `data.token`、`data.expiresIn=7200`、`data.user.account=user@example.com`；不返回用户密码 |
| LOGIN-002 | 登录 API 拒绝错误密码 | 后端服务已启动，数据库存在种子账号 | 请求 `POST /api/v1/auth/login`，提交 `user@example.com / wrong123` | 返回 `400`；响应错误码为 `UNAUTHORIZED`；返回错误信息 |
| LOGIN-003 | 登录页密码登录成功 | 后端服务已启动，前端可访问 | 打开 `/login`；填写账号 `user@example.com`；填写密码 `123456`；点击提交 | 请求 `/api/v1/auth/login` 成功；页面跳转首页；`localStorage.auth:v1` 写入 token 和用户信息 |
| LOGIN-004 | 登录页错误密码提示失败 | 后端服务已启动，前端可访问 | 打开 `/login`；填写账号 `user@example.com`；填写密码 `wrong123`；点击提交 | 请求 `/api/v1/auth/login` 返回 `400`；页面仍停留在登录页；页面显示错误提示；未写入登录态 |
| LOGIN-005 | 登录后按 redirect 回跳受保护页面 | 后端服务已启动，前端可访问，用户未登录 | 打开 `/checkout`；确认跳转到 `/login?redirect=/checkout`；填写正确账号密码并提交 | 登录成功后回跳 `/checkout` |

对应自动化脚本：

- `frontend/tests/login.spec.ts`

