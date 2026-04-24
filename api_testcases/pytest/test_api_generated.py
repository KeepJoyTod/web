import json
import os
import time
import uuid
from urllib import error, parse, request

import pytest


def _base_url() -> str:
    return os.environ.get("API_BASE_URL", "http://localhost:8080/api").rstrip("/")


def _api_url(path: str) -> str:
    if not path.startswith("/"):
        path = "/" + path
    return _base_url() + path


def _json_dumps(data) -> bytes:
    return json.dumps(data, ensure_ascii=False).encode("utf-8")


def _read_body(resp) -> bytes:
    return resp.read() if resp is not None else b""


def http_request(method: str, path: str, headers=None, params=None, json_body=None, timeout=15):
    url = _api_url(path)
    if params:
        q = parse.urlencode(params, doseq=True)
        url = url + ("&" if "?" in url else "?") + q

    req_headers = {"Accept": "application/json"}
    if headers:
        req_headers.update(headers)

    data = None
    if json_body is not None:
        data = _json_dumps(json_body)
        req_headers["Content-Type"] = "application/json"

    req = request.Request(url, data=data, method=method.upper(), headers=req_headers)

    try:
        with request.urlopen(req, timeout=timeout) as resp:
            body_bytes = _read_body(resp)
            ctype = resp.headers.get("Content-Type", "")
            if "application/json" in ctype:
                body = json.loads(body_bytes.decode("utf-8") or "{}")
            else:
                body = body_bytes.decode("utf-8", errors="replace")
            return resp.status, dict(resp.headers), body
    except error.HTTPError as e:
        body_bytes = e.read()
        ctype = e.headers.get("Content-Type", "")
        if "application/json" in ctype:
            try:
                body = json.loads(body_bytes.decode("utf-8") or "{}")
            except Exception:
                body = body_bytes.decode("utf-8", errors="replace")
        else:
            body = body_bytes.decode("utf-8", errors="replace")
        return e.code, dict(e.headers), body


def assert_http_200(status, body):
    assert status == 200, (status, body)


def assert_api_code_200(body):
    if isinstance(body, dict) and "code" in body:
        assert body["code"] == 200, body


def skip_if_db_schema_missing(status, body, hint: str):
    if status != 500:
        return
    if not isinstance(body, dict):
        return
    err = body.get("error") or {}
    msg = err.get("message") or ""
    if "doesn't exist" in msg or "Unknown column" in msg:
        pytest.skip(hint + "；当前数据库表结构/迁移未就绪")


def auth_header(token: str):
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture(scope="session")
def session_user():
    account = "autotest_" + uuid.uuid4().hex[:10]
    password = "Passw0rd!"

    st, _, body = http_request("POST", "/v1/auth/register", json_body={"account": account, "password": password})
    assert_http_200(st, body)
    assert isinstance(body, dict) and "data" in body

    st, _, body = http_request("POST", "/v1/auth/login", json_body={"account": account, "password": password})
    assert_http_200(st, body)
    token = body["data"]["token"]
    user_id = body["data"]["user"]["id"]
    return {"account": account, "password": password, "token": token, "userId": user_id}


@pytest.fixture(scope="session")
def product_any():
    st, _, body = http_request("GET", "/v1/products", params={"page": 1, "size": 50})
    assert_http_200(st, body)
    assert_api_code_200(body)
    items = body.get("data") or []
    assert isinstance(items, list) and items, body
    chosen = None
    for it in items:
        try:
            if int(it.get("stock", 0)) > 0:
                chosen = it
                break
        except Exception:
            continue
    if chosen is None:
        chosen = items[0]
    return chosen


@pytest.fixture()
def address_id(session_user):
    token = session_user["token"]
    payload = {
        "receiver": "张三",
        "phone": "13800000000",
        "region": "上海市浦东新区",
        "detail": "世纪大道100号",
        "isDefault": 0,
    }
    st, _, body = http_request("POST", "/v1/me/addresses", headers=auth_header(token), json_body=payload)
    assert_http_200(st, body)
    assert_api_code_200(body)
    addr_id = body["data"]["id"]
    yield addr_id
    http_request("DELETE", f"/v1/me/addresses/{addr_id}", headers=auth_header(token))


@pytest.fixture()
def pending_order(session_user, product_any, address_id):
    token = session_user["token"]
    product_id = product_any["id"]

    st, _, body = http_request(
        "POST",
        "/v1/cart/items",
        headers=auth_header(token),
        json_body={"productId": product_id, "quantity": 1},
    )
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("POST", "/v1/orders/checkout", headers=auth_header(token), json_body={"addressId": address_id})
    assert_http_200(st, body)
    assert_api_code_200(body)
    order = body["data"]
    assert order.get("id"), body
    return {"order": order, "productId": product_id}


@pytest.fixture()
def paid_order(session_user, pending_order):
    token = session_user["token"]
    order_id = pending_order["order"]["id"]

    st, _, body = http_request("POST", f"/v1/payments/{order_id}/pay", headers=auth_header(token), json_body={"channel": "alipay"})
    assert_http_200(st, body)
    assert_api_code_200(body)
    trade_id = body["data"]["tradeId"]

    st, _, body = http_request("POST", "/v1/payments/webhook", json_body={"tradeId": trade_id, "status": "SUCCESS"})
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("GET", f"/v1/orders/{order_id}", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)
    assert body["data"]["status"] == 1, body

    return {"orderId": order_id, "tradeId": trade_id, "productId": pending_order["productId"]}


def test_openapi_docs_accessible():
    candidates = ["/v3/api-docs", "/api-docs"]
    last = None
    for path in candidates:
        st, _, body = http_request("GET", path)
        last = (st, body, path)
        if st == 200 and isinstance(body, dict) and body.get("openapi"):
            return
    assert False, last


def test_protected_endpoint_requires_token():
    st, _, body = http_request("GET", "/v1/me")
    assert st == 400, (st, body)
    assert body["error"]["code"] == "UNAUTHORIZED"


def test_products_list():
    st, _, body = http_request("GET", "/v1/products", params={"page": 1, "size": 10})
    assert_http_200(st, body)
    assert_api_code_200(body)
    assert isinstance(body.get("data"), list)


def test_products_detail(product_any):
    st, _, body = http_request("GET", f"/v1/products/{product_any['id']}")
    assert_http_200(st, body)
    assert_api_code_200(body)
    assert body["data"]["id"] == product_any["id"]


def test_products_create():
    now = int(time.time())
    payload = {
        "categoryId": 1,
        "name": f"自动化测试商品_{now}",
        "description": "autotest",
        "tags": "autotest",
        "price": 9.99,
        "stock": 10,
        "status": 1,
    }
    st, _, body = http_request("POST", "/v1/products", json_body=payload)
    assert_http_200(st, body)
    assert_api_code_200(body)


def test_me_get_current_user(session_user):
    st, _, body = http_request("GET", "/v1/me", headers=auth_header(session_user["token"]))
    assert_http_200(st, body)
    assert_api_code_200(body)
    assert body["data"]["id"] == session_user["userId"]


def test_addresses_crud(session_user):
    token = session_user["token"]

    st, _, body = http_request("GET", "/v1/me/addresses", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)

    payload = {
        "receiver": "李四",
        "phone": "13900000000",
        "region": "北京市海淀区",
        "detail": "中关村1号",
        "isDefault": 0,
    }
    st, _, body = http_request("POST", "/v1/me/addresses", headers=auth_header(token), json_body=payload)
    assert_http_200(st, body)
    assert_api_code_200(body)
    addr_id = body["data"]["id"]

    payload_update = dict(payload)
    payload_update["detail"] = "中关村2号"
    st, _, body = http_request("PUT", f"/v1/me/addresses/{addr_id}", headers=auth_header(token), json_body=payload_update)
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("DELETE", f"/v1/me/addresses/{addr_id}", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)


def test_cart_and_items(session_user, product_any):
    token = session_user["token"]

    st, _, body = http_request(
        "POST",
        "/v1/cart/items",
        headers=auth_header(token),
        json_body={"productId": product_any["id"], "quantity": 1},
    )
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("GET", "/v1/cart", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)
    items = body.get("data") or []
    assert isinstance(items, list)
    assert items
    cart_item_id = items[0]["id"]

    st, _, body = http_request("PUT", f"/v1/cart/items/{cart_item_id}", headers=auth_header(token), json_body={"quantity": 2})
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("DELETE", f"/v1/cart/items/{cart_item_id}", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)


def test_orders_checkout_and_get(session_user, pending_order):
    token = session_user["token"]
    order_id = pending_order["order"]["id"]

    st, _, body = http_request("GET", "/v1/orders", headers=auth_header(token), params={"page": 1, "size": 10})
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("GET", f"/v1/orders/{order_id}", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)
    assert body["data"]["id"] == order_id


def test_orders_cancel(session_user, product_any, address_id):
    token = session_user["token"]

    st, _, body = http_request(
        "POST",
        "/v1/cart/items",
        headers=auth_header(token),
        json_body={"productId": product_any["id"], "quantity": 1},
    )
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("POST", "/v1/orders/checkout", headers=auth_header(token), json_body={"addressId": address_id})
    assert_http_200(st, body)
    assert_api_code_200(body)
    order_id = body["data"]["id"]

    st, _, body = http_request("POST", f"/v1/orders/{order_id}/cancel", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)


def test_payments_flow(session_user, pending_order):
    token = session_user["token"]
    order_id = pending_order["order"]["id"]

    st, _, body = http_request("POST", f"/v1/payments/{order_id}/pay", headers=auth_header(token), json_body={"channel": "alipay"})
    assert_http_200(st, body)
    assert_api_code_200(body)
    trade_id = body["data"]["tradeId"]

    st, _, body = http_request("GET", f"/v1/payments/{order_id}/status", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("POST", "/v1/payments/webhook", json_body={"tradeId": trade_id, "status": "SUCCESS"})
    assert_http_200(st, body)
    assert_api_code_200(body)


def test_reviews_create_and_list(session_user, paid_order):
    token = session_user["token"]
    payload = {
        "orderId": paid_order["orderId"],
        "productId": paid_order["productId"],
        "rating": 5,
        "content": "自动化测试评价",
        "images": "[]",
    }
    st, _, body = http_request("POST", "/v1/reviews", headers=auth_header(token), json_body=payload)
    skip_if_db_schema_missing(st, body, "reviews 相关表缺失")
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request(
        "GET",
        "/v1/reviews",
        headers=auth_header(token),
        params={"page": 1, "size": 10, "orderId": paid_order["orderId"]},
    )
    assert_http_200(st, body)
    assert_api_code_200(body)


def test_notifications_flow(session_user):
    token = session_user["token"]

    st, _, body = http_request(
        "POST",
        "/v1/notifications",
        headers=auth_header(token),
        json_body={"type": "system", "title": "自动化通知", "content": "hello", "relatedId": ""},
    )
    skip_if_db_schema_missing(st, body, "notifications 相关表缺失")
    assert_http_200(st, body)
    assert_api_code_200(body)
    nid = body["data"]["id"]

    st, _, body = http_request("GET", "/v1/notifications", headers=auth_header(token), params={"page": 1, "size": 20})
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("POST", f"/v1/notifications/{nid}/read", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("POST", "/v1/notifications/markAllRead", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("DELETE", "/v1/notifications", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)


def test_coupons_flow(session_user):
    token = session_user["token"]

    st, _, body = http_request("GET", "/v1/coupons/available", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)
    coupons = body.get("data") or []
    if not coupons:
        pytest.skip("当前用户没有可用优惠券")

    code = coupons[0].get("code")
    if not code:
        pytest.skip("优惠券数据缺少 code 字段")

    st, _, body = http_request("POST", f"/v1/coupons/{code}/check", headers=auth_header(token), json_body={"amount": "100.00"})
    assert_http_200(st, body)
    assert_api_code_200(body)


def test_aftersales_flow(session_user, paid_order):
    token = session_user["token"]
    order_id = paid_order["orderId"]

    st, _, body = http_request(
        "POST",
        "/v1/aftersales/apply",
        headers=auth_header(token),
        json_body={"orderId": order_id, "type": "refund_only", "reason": "自动化测试"},
    )
    skip_if_db_schema_missing(st, body, "aftersales 相关表/字段缺失")
    assert_http_200(st, body)
    assert_api_code_200(body)
    aftersale_id = body["data"]["id"]

    st, _, body = http_request("GET", "/v1/aftersales", headers=auth_header(token), params={"page": 1, "size": 10})
    assert_http_200(st, body)
    assert_api_code_200(body)

    st, _, body = http_request("POST", f"/v1/aftersales/{aftersale_id}/cancel", headers=auth_header(token))
    assert_http_200(st, body)
    assert_api_code_200(body)
