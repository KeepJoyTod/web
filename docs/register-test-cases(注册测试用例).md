# 注册测试用例

注册测试用于验证注册接口、注册页面表单校验、注册成功后自动登录、重复账号错误提示，以及从注册页跳转登录时的 redirect 参数保留。

## 测试数据

- 注册接口地址：`POST /api/v1/auth/register`
- 登录接口地址：`POST /api/v1/auth/login`
- 自动化脚本会生成随机邮箱账号，例如：`pw_page_success_1710000000000_abcd@example.test`
- 默认注册密码：`123456`

可通过环境变量覆盖：

- `PLAYWRIGHT_API_URL`
- `PLAYWRIGHT_BASE_URL`
- `PLAYWRIGHT_REGISTER_PASSWORD`

## 用例列表

| 用例编号 | 用例名称 | 前置条件 | 测试步骤 | 预期结果 |
| --- | --- | --- | --- | --- |
| REGISTER-001 | 注册 API 接受新账号 | 后端服务已启动，账号不存在 | 请求 `POST /api/v1/auth/register`，提交随机邮箱、密码、昵称 | 返回 `200`；响应包含用户信息；不返回密码 |
| REGISTER-002 | 注册 API 拒绝重复账号 | 后端服务已启动，已存在一个测试账号 | 使用同一账号再次请求注册接口 | 返回 `400`；错误码为 `VALIDATION_FAILED` |
| REGISTER-003 | 注册页必填项校验 | 前端可访问，用户未登录 | 打开 `/register`；切换邮箱注册；输入非法邮箱、短密码、不同确认密码；取消协议勾选 | 提交按钮保持禁用 |
| REGISTER-004 | 注册页邮箱注册成功并自动登录 | 前后端服务已启动，账号不存在 | 打开 `/register?redirect=/checkout`；切换邮箱注册；填写邮箱、验证码、密码、确认密码；提交 | 注册接口成功；登录接口成功；写入 `localStorage.auth:v1`；跳转 `/checkout` |
| REGISTER-005 | 注册页重复账号显示错误 | 前后端服务已启动，已存在一个测试账号 | 打开 `/register`；填写重复邮箱、验证码、密码、确认密码；提交 | 注册接口返回 `400`；页面停留在注册页；显示错误提示；不写入登录态 |
| REGISTER-006 | 注册页跳转登录保留 redirect | 前端可访问 | 打开 `/register?redirect=/checkout`；点击“去登录” | 跳转 `/login`，并保留 `redirect=/checkout` |

对应自动化脚本：

- `frontend/tests/register.spec.ts`
