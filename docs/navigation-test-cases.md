# 核心页面跳转测试用例

核心页面跳转测试用于验证前端主要入口和路由跳转是否可用，避免页面无法打开、导航失效、跳转目标错误等问题。

对应自动化脚本：

- `frontend/tests/navigation.spec.ts`

运行命令：

```powershell
cd d:\Java\class\projectKu\web\frontend
npm.cmd run test:navigation
```

| 用例编号 | 用例名称 | 前置条件 | 测试步骤 | 预期结果 |
| --- | --- | --- | --- | --- |
| NAV-001 | 后端服务可访问 | MySQL、Redis、后端已启动 | 请求 `GET /api/` | 返回 `200`，后端可用 |
| NAV-002 | 公开核心路由可渲染 | 前端可访问，后端已启动 | 依次打开 `/`、`/category`、`/search`、`/cart`、`/me`、`/phone`、`/computer`、`/appliance` | 页面地址正确，页面内容非空 |
| NAV-003 | 底部导航可切换主页面 | 位于首页 | 依次点击底部导航中的类目、搜索、购物车、我的、首页 | 分别跳转到 `/category`、`/search`、`/cart`、`/me`、`/` |
| NAV-004 | 首页分类快捷入口可跳转 | 位于首页 | 点击首页快捷入口中的手机、电脑、家电、更多 | 分别跳转到 `/phone`、`/computer`、`/appliance`、`/category` |
| NAV-005 | 首页搜索可跳转搜索页 | 位于首页 | 在搜索框输入 `phone` 并提交 | 跳转到 `/search?q=phone` |
| NAV-006 | 商品卡片可跳转详情页 | 首页商品列表已加载 | 点击第一个商品卡片 | 跳转到 `/products/{id}` |
| NAV-007 | 受保护页面未登录拦截 | 用户未登录 | 依次打开 `/checkout`、`/favorites`、`/messages`、`/aftersales` | 均跳转到登录页，并带有 `redirect` 参数 |

