## api_testcases

基于后端 Swagger/OpenAPI 生成的接口冒烟用例（Pytest）。

### 前置条件

- 后端已启动：`http://localhost:8080/api`
- OpenAPI 文档可访问：`http://localhost:8080/api/v3/api-docs`（兼容旧路径：`/api/api-docs`）

### 运行（建议）

进入目录 `web/api_testcases/pytest` 后安装依赖并执行：

```bash
python3 -m pip install -r requirements.txt
python3 -m pytest -q
```

### 生成报告

- JUnit XML（便于 CI 解析）：

```bash
python3 -m pytest -q --junitxml=pytest-report.xml
```

- HTML（便于人工查看）：

```bash
python3 -m pytest -q --html=pytest-report.html --self-contained-html
```

### 环境变量（可选）

- `API_BASE_URL`：默认 `http://localhost:8080/api`
