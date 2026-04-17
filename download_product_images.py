#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Iterable, List, Optional, Sequence, Tuple


@dataclass(frozen=True)
class Product:
    id: str
    name: str


def _ua() -> str:
    return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"


def _fetch_bytes(url: str, timeout_s: int) -> Tuple[bytes, str]:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": _ua(),
            "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
        },
    )
    with urllib.request.urlopen(req, timeout=timeout_s) as resp:
        content_type = resp.headers.get("Content-Type", "") or ""
        return resp.read(), content_type


def _fetch_json(url: str, timeout_s: int) -> object:
    req = urllib.request.Request(url, headers={"User-Agent": _ua(), "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout_s) as resp:
        raw = resp.read()
    try:
        return json.loads(raw.decode("utf-8"))
    except Exception:
        return {}


def _unwrap_data(obj: object) -> object:
    if isinstance(obj, dict) and "data" in obj:
        return obj.get("data")
    return obj


def iter_products_from_api(base_url: str, page_size: int, timeout_s: int) -> Iterable[Product]:
    base = base_url.rstrip("/")
    page = 1
    while True:
        items: Optional[Sequence[object]] = None
        for size_key in ("size", "pageSize"):
            url = f"{base}/v1/products?page={page}&{size_key}={page_size}"
            obj = _fetch_json(url, timeout_s)
            data = _unwrap_data(obj)
            if isinstance(data, list):
                items = data
                break
            if isinstance(data, dict) and isinstance(data.get("data"), list):
                items = data.get("data")
                break
        if not items:
            break
        for x in items:
            if not isinstance(x, dict):
                continue
            pid = str(x.get("id") or "").strip()
            name = str(x.get("name") or x.get("title") or "").strip()
            if pid and name:
                yield Product(id=pid, name=name)
        if len(items) < page_size:
            break
        page += 1


def parse_products_from_seed_sql(sql_path: str, start_id: int) -> List[Product]:
    with open(sql_path, "r", encoding="utf-8") as f:
        content = f.read()
    rx = re.compile(r"\(\s*\d+\s*,\s*'((?:''|[^'])*)'\s*,", re.MULTILINE)
    names = [m.group(1).replace("''", "'").strip() for m in rx.finditer(content)]
    products: List[Product] = []
    pid = start_id
    for name in names:
        if not name:
            continue
        products.append(Product(id=str(pid), name=name))
        pid += 1
    return products


def _norm_query(name: str) -> str:
    s = str(name or "").strip()
    if not s:
        return s
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"\b\d{1,2}\+?\d{2,4}g\b", "", s, flags=re.IGNORECASE)
    s = re.sub(r"\b\d{2,4}gb\b", "", s, flags=re.IGNORECASE)
    s = re.sub(r"\b\d+(?:\.\d+)?\s*(?:kg|g|l|ml|w|wh|mah|hz|p)\b", "", s, flags=re.IGNORECASE)
    s = re.sub(r"\b\d+(?:\.\d+)?\s*\"|\b\d+(?:\.\d+)?\s*inch\b", "", s, flags=re.IGNORECASE)
    s = re.sub(r"[()（）【】\[\]{}<>《》]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def _commons_api(url: str, timeout_s: int) -> object:
    return _fetch_json(url, timeout_s)


def _commons_search_file_titles(query: str, timeout_s: int, limit: int) -> List[str]:
    q = urllib.parse.quote(query, safe="")
    url = f"https://commons.wikimedia.org/w/api.php?action=query&list=search&srnamespace=6&srsearch={q}&srlimit={int(limit)}&format=json"
    obj = _commons_api(url, timeout_s)
    out: List[str] = []
    if isinstance(obj, dict):
        qv = obj.get("query")
        if isinstance(qv, dict):
            sv = qv.get("search")
            if isinstance(sv, list):
                for it in sv:
                    if isinstance(it, dict):
                        t = str(it.get("title") or "").strip()
                        if t:
                            out.append(t)
    return out


def _commons_image_url(title: str, timeout_s: int, width: int) -> Optional[str]:
    t = urllib.parse.quote(title, safe="")
    url = (
        "https://commons.wikimedia.org/w/api.php?action=query"
        f"&titles={t}&prop=imageinfo&iiprop=url&iiurlwidth={int(width)}&format=json"
    )
    obj = _commons_api(url, timeout_s)
    if not isinstance(obj, dict):
        return None
    q = obj.get("query")
    if not isinstance(q, dict):
        return None
    pages = q.get("pages")
    if not isinstance(pages, dict):
        return None
    for _, p in pages.items():
        if not isinstance(p, dict):
            continue
        ii = p.get("imageinfo")
        if not (isinstance(ii, list) and ii):
            continue
        first = ii[0]
        if not isinstance(first, dict):
            continue
        thumb = str(first.get("thumburl") or "").strip()
        if thumb:
            return thumb
        raw = str(first.get("url") or "").strip()
        if raw:
            return raw
    return None


def _wikimedia_candidate_urls(name: str, timeout_s: int, width: int, per_query: int) -> List[str]:
    q1 = _norm_query(name)
    queries = [q1] if q1 else []
    if q1 and q1 != name:
        queries.append(str(name))
    urls: List[str] = []
    for q in queries:
        titles = _commons_search_file_titles(q, timeout_s=timeout_s, limit=per_query)
        for t in titles:
            low = t.lower()
            if not (low.endswith(".jpg") or low.endswith(".jpeg")):
                continue
            u = _commons_image_url(t, timeout_s=timeout_s, width=width)
            if u and (u.lower().endswith(".jpg") or u.lower().endswith(".jpeg")):
                urls.append(u)
    return urls


def _dummyimage_url(name: str, size: int) -> str:
    text = urllib.parse.quote_plus(str(name or "").strip())
    return f"https://dummyimage.com/{int(size)}x{int(size)}/eeeeee/111111.jpg&text={text}"


def build_candidate_urls(name: str, timeout_s: int, prefer_wikimedia: bool, size: int) -> List[str]:
    urls: List[str] = []
    if prefer_wikimedia:
        try:
            urls.extend(_wikimedia_candidate_urls(name, timeout_s=timeout_s, width=size, per_query=6))
        except Exception:
            urls = urls
    urls.append(_dummyimage_url(name, size=size))
    return urls


def download_one(p: Product, out_dir: str, timeout_s: int, overwrite: bool, prefer_wikimedia: bool, size: int) -> bool:
    out_path = os.path.join(out_dir, f"product_{p.id}.jpg")
    if (not overwrite) and os.path.exists(out_path):
        return True
    for url in build_candidate_urls(p.name, timeout_s=timeout_s, prefer_wikimedia=prefer_wikimedia, size=size):
        try:
            blob, ctype = _fetch_bytes(url, timeout_s)
            if not ctype.lower().startswith("image/"):
                continue
            tmp = out_path + ".tmp"
            with open(tmp, "wb") as f:
                f.write(blob)
            os.replace(tmp, out_path)
            return True
        except Exception:
            continue
    return False


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="frontend/public")
    parser.add_argument("--sql", default="back/sql/seed_products_categories_1_8.sql")
    parser.add_argument("--start-id", type=int, default=1)
    parser.add_argument("--api", default="http://localhost:8080")
    parser.add_argument("--no-api", action="store_true")
    parser.add_argument("--prefer-wikimedia", action="store_true")
    parser.add_argument("--size", type=int, default=800)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--sleep", type=float, default=0.3)
    parser.add_argument("--timeout", type=int, default=15)
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--log-every", type=int, default=20)
    args = parser.parse_args(argv)

    os.makedirs(args.out, exist_ok=True)

    products: List[Product] = []
    if not args.no_api:
        try:
            products = list(iter_products_from_api(args.api, page_size=200, timeout_s=args.timeout))
        except Exception:
            products = []

    if not products:
        if not os.path.exists(args.sql):
            print(f"seed sql not found: {args.sql}", file=sys.stderr)
            return 2
        products = parse_products_from_seed_sql(args.sql, start_id=args.start_id)

    if args.limit and args.limit > 0:
        products = products[: args.limit]

    ok = 0
    fail = 0
    for i, p in enumerate(products, start=1):
        success = download_one(
            p,
            args.out,
            timeout_s=args.timeout,
            overwrite=args.overwrite,
            prefer_wikimedia=bool(args.prefer_wikimedia),
            size=int(args.size),
        )
        if success:
            ok += 1
            if int(args.log_every) > 0 and (i == 1 or i == len(products) or i % int(args.log_every) == 0):
                print(f"[{i}/{len(products)}] ok={ok} fail={fail}")
        else:
            fail += 1
            print(f"[{i}/{len(products)}] FAIL {p.id} {p.name}", file=sys.stderr)
        if args.sleep:
            time.sleep(max(0.0, float(args.sleep)))

    print(f"done. ok={ok} fail={fail} out={os.path.abspath(args.out)}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())

