param(
  [string]$CodexHome = "$env:USERPROFILE\.codex",
  [string]$ProjectCwd = "\\?\D:\Java\class\projectKu\web",
  [string]$PythonPath = "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe",
  [switch]$WaitForExit,
  [int]$TimeoutSeconds = 900
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

function Get-CodexProcesses {
  Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -eq "Codex" -or $_.ProcessName -eq "codex"
  }
}

if ($WaitForExit) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-CodexProcesses) -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 2
  }
}

$running = @(Get-CodexProcesses)
if ($running.Count -gt 0) {
  throw "Codex is still running. Fully exit Codex, then run this script again."
}

if (-not (Test-Path -LiteralPath $PythonPath)) {
  throw "Bundled Python not found: $PythonPath"
}

$backupDir = Join-Path $CodexHome ("backup-chatlist-repair-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

$python = @'
import json
import os
import shutil
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

codex = Path(sys.argv[1])
project_cwd = sys.argv[2]
backup_dir = Path(sys.argv[3])

project_plain = project_cwd
if project_plain.startswith("\\\\?\\"):
    project_plain = project_plain[4:]

state_db = codex / "state_5.sqlite"
session_index = codex / "session_index.jsonl"
global_state = codex / ".codex-global-state.json"
sessions_root = codex / "sessions"

def backup_file(path: Path):
    if not path.exists():
        return
    rel = path.relative_to(codex) if path.is_relative_to(codex) else Path(path.name)
    dest = backup_dir / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, dest)

for p in [
    state_db,
    codex / "state_5.sqlite-wal",
    codex / "state_5.sqlite-shm",
    session_index,
    global_state,
    codex / ".codex-global-state.json.bak",
]:
    backup_file(p)

session_files_seen = 0
session_files_changed = 0
session_meta_changed = 0

for path in sessions_root.rglob("*.jsonl"):
    try:
        lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    except UnicodeDecodeError:
        continue

    belongs_to_project = False
    parsed_meta_index = None
    parsed_meta = None

    for i, line in enumerate(lines[:80]):
        if not line.strip():
            continue
        try:
            obj = json.loads(line)
        except Exception:
            continue
        if obj.get("type") == "session_meta":
            payload = obj.get("payload") or {}
            cwd = payload.get("cwd")
            if cwd in {project_plain, project_cwd}:
                belongs_to_project = True
                parsed_meta_index = i
                parsed_meta = obj
            break

    if not belongs_to_project:
        continue

    session_files_seen += 1
    backup_file(path)

    payload = parsed_meta.setdefault("payload", {})
    changed = False
    if payload.get("model_provider") == "OpenAI":
        payload["model_provider"] = "gpt"
        changed = True
        session_meta_changed += 1

    if changed:
        lines[parsed_meta_index] = json.dumps(parsed_meta, ensure_ascii=False, separators=(",", ":")) + "\n"
        path.write_text("".join(lines), encoding="utf-8")
        session_files_changed += 1

con = sqlite3.connect(str(state_db), timeout=30)
con.row_factory = sqlite3.Row
cur = con.cursor()
cur.execute("PRAGMA busy_timeout=30000")

cur.execute(
    "update threads set model_provider='gpt' where cwd in (?, ?) and model_provider='OpenAI'",
    (project_cwd, project_plain),
)
db_provider_rows_changed = cur.rowcount

existing_ids = set()
if session_index.exists():
    with session_index.open("r", encoding="utf-8") as f:
        for line in f:
            if not line.strip():
                continue
            try:
                existing_ids.add(json.loads(line)["id"])
            except Exception:
                pass

append_records = []
rows = cur.execute(
    "select id, title, updated_at_ms from threads where cwd in (?, ?) order by created_at_ms",
    (project_cwd, project_plain),
).fetchall()
for row in rows:
    if row["id"] in existing_ids:
        continue
    updated_at = datetime.fromtimestamp(row["updated_at_ms"] / 1000, tz=timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    append_records.append({
        "id": row["id"],
        "thread_name": row["title"],
        "updated_at": updated_at,
    })

if append_records:
    with session_index.open("a", encoding="utf-8", newline="") as f:
        for record in append_records:
            f.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n")

con.commit()
try:
    cur.execute("PRAGMA wal_checkpoint(TRUNCATE)")
except Exception:
    pass
con.close()

if global_state.exists():
    backup_file(global_state)
    data = json.loads(global_state.read_text(encoding="utf-8"))
    atom = data.setdefault("electron-persisted-atom-state", {})
    sections = atom.setdefault("sidebar-collapsed-sections-v1", {})
    sections["chats"] = False
    sections["threads"] = False
    atom["sidebar-workspace-filter-v2"] = "all"
    global_state.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")

result = {
    "project_cwd": project_cwd,
    "project_plain": project_plain,
    "backup_dir": str(backup_dir),
    "session_files_seen": session_files_seen,
    "session_files_changed": session_files_changed,
    "session_meta_changed": session_meta_changed,
    "db_provider_rows_changed": db_provider_rows_changed,
    "session_index_records_appended": len(append_records),
}

(backup_dir / "repair-result.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(result, ensure_ascii=False, indent=2))
'@

$result = $python | & $PythonPath - $CodexHome $ProjectCwd $backupDir
$latestLog = Join-Path $CodexHome "restore-chatlist-latest.log"
$result | Set-Content -Path $latestLog -Encoding UTF8
Write-Output $result
