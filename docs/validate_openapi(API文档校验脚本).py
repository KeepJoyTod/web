import json
import re
from pathlib import Path


root = Path("/Users/bill/Downloads/e-commerce/web")
spec_path = root / "docs" / "openapi-v3-api-docs.json"
controllers_dir = root / "back" / "src" / "main" / "java" / "com" / "web" / "controller"
report_path = root / "docs" / "openapi-v3-api-docs.validation.txt"

with spec_path.open("r", encoding="utf-8") as f:
    spec = json.load(f)

paths = spec.get("paths", {})
components = spec.get("components", {}).get("schemas", {})

class_base_re = re.compile(r'@RequestMapping\("([^"]+)"\)')
method_res = [
    (re.compile(r'@GetMapping(?:\("([^"]*)"\))?'), "get"),
    (re.compile(r'@PostMapping(?:\("([^"]*)"\))?'), "post"),
    (re.compile(r'@PutMapping(?:\("([^"]*)"\))?'), "put"),
    (re.compile(r'@DeleteMapping(?:\("([^"]*)"\))?'), "delete"),
    (re.compile(r'@PatchMapping(?:\("([^"]*)"\))?'), "patch"),
]

controller_endpoints = []
for file in sorted(controllers_dir.glob("*.java")):
    text = file.read_text(encoding="utf-8")
    if "@RestController" not in text:
        continue
    m = class_base_re.search(text)
    base = m.group(1) if m else ""
    for rx, method in method_res:
        for mm in rx.finditer(text):
            sub = mm.group(1) if mm.group(1) is not None else ""
            full = (base.rstrip("/") + "/" + sub.lstrip("/")).replace("//", "/")
            if not full.startswith("/"):
                full = "/" + full
            if full.endswith("/") and full != "/":
                full = full[:-1]
            controller_endpoints.append((method, full, file.name))

controller_api = {(m, p) for m, p, _ in controller_endpoints}
spec_api = {(m.lower(), p) for p, methods in paths.items() for m in methods.keys()}

missing_in_spec = sorted(controller_api - spec_api)
extra_in_spec = sorted(spec_api - controller_api)

request_issues = []
server_only = {"id", "userId", "createTime", "updateTime"}
for p, methods in paths.items():
    for m, op in methods.items():
        rb = op.get("requestBody")
        if not rb:
            continue
        content = (rb.get("content") or {}).get("application/json") or {}
        schema = content.get("schema") or {}
        if "$ref" not in schema and schema.get("additionalProperties") is not None:
            request_issues.append(f"{m.upper()} {p}: requestBody is map/additionalProperties")
            continue
        ref = schema.get("$ref")
        if ref:
            name = ref.split("/")[-1]
            if not name.lower().endswith("request"):
                request_issues.append(f"{m.upper()} {p}: requestBody schema not *Request ({name})")
            sch = components.get(name, {})
            props = set((sch.get("properties") or {}).keys())
            bad = sorted(props & server_only)
            if bad:
                request_issues.append(f"{m.upper()} {p}: request schema {name} contains server-only fields {bad}")

response_warnings = []
for p, methods in paths.items():
    for m, op in methods.items():
        for code, resp in (op.get("responses") or {}).items():
            content = (resp.get("content") or {}).get("*/*") or (resp.get("content") or {}).get("application/json") or {}
            schema = content.get("schema") or {}
            if (
                schema.get("type") == "object"
                and schema.get("additionalProperties") is not None
                and schema.get("properties") is None
                and "$ref" not in schema
            ):
                response_warnings.append(f"{m.upper()} {p} -> {code}")

summary = [
    "VALID_JSON: True",
    f"OPENAPI_VERSION: {spec.get('openapi')}",
    f"PATH_COUNT: {len(paths)}",
    f"SCHEMA_COUNT: {len(components)}",
    f"CONTROLLER_ENDPOINT_COUNT: {len(controller_api)}",
    f"MISSING_IN_SPEC: {len(missing_in_spec)}",
]
summary.extend([f"  - {m.upper()} {p}" for m, p in missing_in_spec])
summary.append(f"EXTRA_IN_SPEC: {len(extra_in_spec)}")
summary.extend([f"  - {m.upper()} {p}" for m, p in extra_in_spec])
summary.append(f"REQUEST_SCHEMA_ISSUES: {len(request_issues)}")
summary.extend([f"  - {x}" for x in request_issues])
summary.append(f"RESPONSE_WRAPPER_WARNINGS: {len(response_warnings)}")
summary.extend([f"  - {x}" for x in response_warnings[:20]])

report_path.write_text("\n".join(summary) + "\n", encoding="utf-8")
print(report_path)
print("\n".join(summary))
