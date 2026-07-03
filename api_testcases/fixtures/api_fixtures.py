"""全局 API Fixtures"""
import pytest
from core.api_client import ApiClient
from helpers.auth_helper import AuthHelper
from helpers.data_factory import DataFactory
from config.settings import settings


@pytest.fixture(scope="session")
def base_client():
    """无 Token 的基础客户端（session 级复用）"""
    client = ApiClient()
    yield client
    client.close()


@pytest.fixture(scope="module")
def client():
    """模块级客户端"""
    c = ApiClient()
    yield c
    c.close()


@pytest.fixture(scope="module")
def auth_helper(client):
    """认证辅助"""
    return AuthHelper(client)


@pytest.fixture(scope="module")
def auth_token(client, auth_helper):
    """模块级：自动注册+登录，返回 AuthManager"""
    account = DataFactory.random_email()
    password = "Test@123456"
    am = auth_helper.register_and_login(account, password)
    client.set_token(am.token)
    yield am
    # 恢复 token（防止测试中修改 client token 影响后续）
    client.set_token(am.token)


@pytest.fixture(scope="module")
def product_id(client, auth_token):
    """获取一个有效商品 ID"""
    resp = client.get("/v1/products", params={"size": 1})
    assert resp.status_code == 200
    data = resp.json()
    if data.get("data"):
        return data["data"][0]["id"]
    pytest.skip("数据库无商品，跳过测试")


@pytest.fixture(scope="module")
def address_id(client, auth_token):
    """创建测试地址并返回 ID"""
    resp = client.post("/v1/me/addresses", json={
        "receiver": "测试用户",
        "phone": "13800138000",
        "region": "北京市 朝阳区",
        "detail": f"测试地址_{DataFactory.random_string(4)}",
        "isDefault": 1,
    })
    assert resp.status_code == 200
    data = resp.json()
    if data.get("code") == 200:
        addr_list = client.get("/v1/me/addresses").json().get("data", [])
        if addr_list:
            return addr_list[-1].get("id")
    pytest.skip("无法创建地址，跳过测试")


@pytest.fixture(scope="module")
def user_a(client, auth_helper):
    """用户 A（用于用户隔离测试）"""
    account = DataFactory.random_email("userA")
    am = auth_helper.register_and_login(account, "Test@123456")
    client_copy = ApiClient(token=am.token)
    yield {"auth": am, "client": client_copy}
    client_copy.close()


@pytest.fixture(scope="module")
def user_b(client, auth_helper):
    """用户 B"""
    account = DataFactory.random_email("userB")
    am = auth_helper.register_and_login(account, "Test@123456")
    client_copy = ApiClient(token=am.token)
    yield {"auth": am, "client": client_copy}
    client_copy.close()