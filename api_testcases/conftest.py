"""全局 pytest 配置：加载所有 fixtures 和 Allure 报告钩子"""
import sys
import json
from pathlib import Path

# 确保项目根目录在 path 中
ROOT = Path(__file__).parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

# 自动加载 fixtures
pytest_plugins = [
    "fixtures.api_fixtures",
]

# ============= Allure 报告增强钩子 =============

try:
    import allure  # type: ignore
    _ALLURE = True
except ImportError:
    _ALLURE = False


def pytest_configure(config):
    """pytest 启动时配置"""
    if _ALLURE:
        allure_dir = config.getoption("--alluredir", None)
        if allure_dir:
            # 生成环境信息附件
            env_info = {
                "Framework": "api_testcases",
                "Python": sys.version.split()[0],
                "Platform": sys.platform,
            }
            env_path = Path(allure_dir) / "environment.properties"
            env_path.parent.mkdir(parents=True, exist_ok=True)
            with open(env_path, "w") as f:
                for k, v in env_info.items():
                    f.write(f"{k}={v}\n")

            # 生成 executor 信息（CI 场景可扩展）
            executor_path = Path(allure_dir) / "executor.json"
            try:
                executor_info = {
                    "name": "pytest",
                    "type": "pytest",
                    "reportUrl": "",
                }
                with open(executor_path, "w") as f:
                    json.dump(executor_info, f, indent=2)
            except Exception:
                pass


def pytest_make_parametrize_id(config, val):
    """让 Allure 正确显示参数化用例名称"""
    if isinstance(val, dict) and "desc" in val:
        return val["desc"]
    return str(val)


def pytest_collection_modifyitems(config, items):
    """为测试用例自动添加 allure.dynamic 方法增强报告"""
    pass  # 由具体测试类中的标签实现