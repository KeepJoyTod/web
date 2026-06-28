#!/usr/bin/env bash
# ============================================================
# E-Commerce 项目启动脚本
# 功能：检测端口占用/进程运行状态 -> 清理冲突 -> 启动前后端
# 用法：
#   ./start_ecommerce.sh              # 启动全部（后端+前端+管理后台）
#   ./start_ecommerce.sh backend       # 仅启动后端
#   ./start_ecommerce.sh frontend      # 仅启动用户前端
#   ./start_ecommerce.sh admin         # 仅启动管理后台
#   ./start_ecommerce.sh status        # 查看项目运行状态
#   ./start_ecommerce.sh stop          # 停止全部服务
#   ./start_ecommerce.sh restart       # 重启全部服务
# ============================================================
set -euo pipefail

# ---------- 配置 ----------
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT/back"
FRONTEND_DIR="$ROOT/frontend"
ADMIN_DIR="$ROOT/frontend-admin"
LOG_DIR="$ROOT/logs"
PID_DIR="$ROOT/.pids"

# 后端配置
BACKEND_PORT="${BACKEND_PORT:-8080}"
BACKEND_PID_FILE="$PID_DIR/backend.pid"
BACKEND_LOG="$LOG_DIR/backend.log"

# 用户前端配置
FRONTEND_PORT="${FRONTEND_PORT:-5173}"
FRONTEND_PID_FILE="$PID_DIR/frontend.pid"
FRONTEND_LOG="$LOG_DIR/frontend.log"

# 管理后台配置
ADMIN_PORT="${ADMIN_PORT:-5174}"
ADMIN_PID_FILE="$PID_DIR/admin.pid"
ADMIN_LOG="$LOG_DIR/admin.log"

# 健康检查超时（秒）
HEALTH_CHECK_TIMEOUT="${HEALTH_CHECK_TIMEOUT:-120}"

# ---------- 颜色输出 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { printf "${GREEN}[INFO]${NC}  %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$*"; }
log_section() { printf "\n${BLUE}==== %s ====${NC}\n" "$*"; }

# ---------- 工具函数 ----------

# 获取监听指定端口的进程 PID 列表
get_port_pids() {
    local port="$1"
    # macOS 使用 lsof，返回所有 LISTEN 在该端口的 PID
    lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null || true
}

# 检查端口是否被占用
is_port_in_use() {
    local port="$1"
    local pids
    pids=$(get_port_pids "$port")
    [[ -n "$pids" ]]
}

# 通过 PID 文件检查进程是否存活
is_pid_alive() {
    local pid_file="$1"
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null || true)
        if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# 安全杀掉 PID 文件记录的进程
kill_by_pid_file() {
    local pid_file="$1"
    local name="$2"
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null || true)
        if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
            log_warn "正在终止旧${name}进程 (PID: $pid)..."
            kill "$pid" >/dev/null 2>&1 || true
            # 等待进程退出
            for _ in $(seq 1 10); do
                if ! kill -0 "$pid" >/dev/null 2>&1; then
                    log_info "旧${name}进程已终止"
                    break
                fi
                sleep 0.5
            done
            # 如果还没退出，强制杀掉
            if kill -0 "$pid" >/dev/null 2>&1; then
                log_warn "强制终止${name}进程 (PID: $pid)..."
                kill -9 "$pid" >/dev/null 2>&1 || true
                sleep 1
            fi
        fi
        rm -f "$pid_file"
    fi
}

# 清理指定端口的占用进程
kill_port_processes() {
    local port="$1"
    local service_name="$2"
    local pids
    pids=$(get_port_pids "$port")

    if [[ -n "$pids" ]]; then
        log_warn "端口 $port 被以下进程占用: $pids"
        log_warn "正在终止占用端口 $port 的进程..."
        for pid in $pids; do
            log_info "  终止 PID: $pid"
            kill "$pid" >/dev/null 2>&1 || true
        done

        # 等待所有进程退出
        for _ in $(seq 1 10); do
            local remaining
            remaining=$(get_port_pids "$port")
            if [[ -z "$remaining" ]]; then
                log_info "端口 $port 已释放"
                break
            fi
            sleep 0.5
        done

        # 强制杀掉残留进程
        local remaining
        remaining=$(get_port_pids "$port")
        if [[ -n "$remaining" ]]; then
            log_warn "端口 $port 仍有残留进程，强制终止..."
            for pid in $remaining; do
                kill -9 "$pid" >/dev/null 2>&1 || true
            done
            sleep 1
        fi

        log_info "${service_name} 端口 $port 清理完成"
    else
        log_info "端口 $port 未被占用"
    fi
}

# 根据名称查找并杀掉相关 Java/Node 进程
kill_by_name() {
    local pattern="$1"
    local label="$2"
    local pids
    pids=$(pgrep -f "$pattern" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        log_warn "发现匹配 \"$pattern\" 的${label}进程: $pids"
        for pid in $pids; do
            kill "$pid" >/dev/null 2>&1 || true
        done
        sleep 1
        pids=$(pgrep -f "$pattern" 2>/dev/null || true)
        if [[ -n "$pids" ]]; then
            log_warn "强制终止残留${label}进程..."
            for pid in $pids; do
                kill -9 "$pid" >/dev/null 2>&1 || true
            done
            sleep 1
        fi
    fi
}

# ---------- 状态检查 ----------
show_status() {
    log_section "项目运行状态"

    echo ""
    echo "  —— 后端 (Spring Boot) ——"
    echo "  端口: $BACKEND_PORT"
    if is_port_in_use "$BACKEND_PORT"; then
        local pids
        pids=$(get_port_pids "$BACKEND_PORT")
        printf "  状态: ${GREEN}运行中${NC} (PID: %s)\n" "$pids"
        if curl -sSf "http://localhost:$BACKEND_PORT/api/actuator/health" >/dev/null 2>&1; then
            echo "  健康: ✓"
        else
            echo "  健康: ✗ (无法访问 health 端点)"
        fi
    else
        printf "  状态: ${RED}未运行${NC}\n"
    fi

    echo ""
    echo "  —— 用户前端 (Vite) ——"
    echo "  端口: $FRONTEND_PORT"
    if is_port_in_use "$FRONTEND_PORT"; then
        local pids
        pids=$(get_port_pids "$FRONTEND_PORT")
        printf "  状态: ${GREEN}运行中${NC} (PID: %s)\n" "$pids"
        if curl -sSf "http://localhost:$FRONTEND_PORT/" >/dev/null 2>&1; then
            echo "  健康: ✓"
        else
            echo "  健康: ✗ (无法访问首页)"
        fi
    else
        printf "  状态: ${RED}未运行${NC}\n"
    fi

    echo ""
    echo "  —— 管理后台 (Vite) ——"
    echo "  端口: $ADMIN_PORT"
    if is_port_in_use "$ADMIN_PORT"; then
        local pids
        pids=$(get_port_pids "$ADMIN_PORT")
        printf "  状态: ${GREEN}运行中${NC} (PID: %s)\n" "$pids"
    else
        printf "  状态: ${RED}未运行${NC}\n"
    fi

    echo ""
    echo "访问地址："
    echo "  用户前端:  http://localhost:$FRONTEND_PORT/"
    echo "  管理后台:  http://localhost:$ADMIN_PORT/"
    echo "  后端 API:  http://localhost:$BACKEND_PORT/api"
    echo "  Swagger:   http://localhost:$BACKEND_PORT/api/swagger-ui/index.html"
    echo ""
}

# ---------- 停止服务 ----------
stop_backend() {
    log_section "停止后端服务"
    kill_by_pid_file "$BACKEND_PID_FILE" "后端"
    kill_port_processes "$BACKEND_PORT" "后端"
}

stop_frontend() {
    log_section "停止用户前端服务"
    kill_by_pid_file "$FRONTEND_PID_FILE" "用户前端"
    kill_port_processes "$FRONTEND_PORT" "用户前端"
}

stop_admin() {
    log_section "停止管理后台服务"
    kill_by_pid_file "$ADMIN_PID_FILE" "管理后台"
    kill_port_processes "$ADMIN_PORT" "管理后台"
}

stop_all() {
    log_section "停止所有服务"
    stop_backend
    stop_frontend
    stop_admin
    log_info "所有服务已停止"
}

# ---------- 依赖检查 ----------
check_dependencies() {
    local target="$1"

    case "$target" in
        backend)
            if ! command -v java >/dev/null 2>&1; then
                log_error "未找到 Java，请安装 JDK 17+"
                exit 1
            fi
            if ! command -v mvn >/dev/null 2>&1; then
                log_error "未找到 Maven，请安装 Maven"
                exit 1
            fi
            ;;
        frontend|admin)
            if ! command -v node >/dev/null 2>&1; then
                log_error "未找到 Node.js，请安装 Node.js 18+"
                exit 1
            fi
            if ! command -v npm >/dev/null 2>&1; then
                log_error "未找到 npm，请安装 npm"
                exit 1
            fi
            ;;
        all)
            check_dependencies backend
            check_dependencies frontend
            ;;
    esac
}

# ---------- 启动后端 ----------
start_backend() {
    log_section "启动后端服务"

    # 检查依赖
    check_dependencies backend

    # 1. 停止旧的进程和释放端口
    log_info "检查并清理旧进程和端口..."
    kill_by_pid_file "$BACKEND_PID_FILE" "后端"
    kill_port_processes "$BACKEND_PORT" "后端"
    kill_by_name "spring-boot.*back" "后端"
    kill_by_name "mvn.*spring-boot:run" "后端 maven"

    # 2. 确保目录存在
    mkdir -p "$LOG_DIR" "$PID_DIR"

    # 3. 检查是否有构建产物，如果需要可先构建
    local jar_file
    jar_file=$(find "$BACKEND_DIR/target" -maxdepth 1 -name '*.jar' ! -name '*sources.jar' 2>/dev/null | head -n 1 || true)

    if [[ -z "$jar_file" ]]; then
        log_info "未找到后端 jar 包，开始构建..."
        (cd "$BACKEND_DIR" && mvn -q -DskipTests package)
        jar_file=$(find "$BACKEND_DIR/target" -maxdepth 1 -name '*.jar' ! -name '*sources.jar' | head -n 1)
        if [[ -z "$jar_file" ]]; then
            log_error "后端构建失败，请检查 Maven 日志"
            exit 1
        fi
        log_info "构建完成: $jar_file"
    fi

    # 4. 启动后端
    log_info "正在启动后端服务..."
    nohup java -jar "$jar_file" \
        --server.port="$BACKEND_PORT" \
        --spring.datasource.url="jdbc:mysql://localhost:3309/web?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true" \
        >"$BACKEND_LOG" 2>&1 &
    local backend_pid=$!
    echo "$backend_pid" > "$BACKEND_PID_FILE"
    log_info "后端进程已启动 (PID: $backend_pid), 日志: $BACKEND_LOG"

    # 5. 健康检查
    log_info "等待后端服务就绪..."
    local waited=0
    while [[ $waited -lt $HEALTH_CHECK_TIMEOUT ]]; do
        if curl -fsS "http://localhost:$BACKEND_PORT/api/actuator/health" >/dev/null 2>&1; then
            log_info "后端服务已就绪！http://localhost:$BACKEND_PORT/api"
            return 0
        fi
        # 检查进程是否还活着
        if ! kill -0 "$backend_pid" >/dev/null 2>&1; then
            log_error "后端进程已退出，请查看日志:"
            tail -50 "$BACKEND_LOG"
            exit 1
        fi
        sleep 2
        waited=$((waited + 2))
        if [[ $((waited % 10)) -eq 0 ]]; then
            log_info "  等待中... ($waited 秒)"
        fi
    done

    log_error "后端服务在 ${HEALTH_CHECK_TIMEOUT} 秒内未就绪，请查看日志:"
    tail -50 "$BACKEND_LOG"
    exit 1
}

# ---------- 启动用户前端 ----------
start_frontend() {
    log_section "启动用户前端服务"

    # 检查依赖
    check_dependencies frontend

    # 1. 停止旧的进程和释放端口
    log_info "检查并清理旧进程和端口..."
    kill_by_pid_file "$FRONTEND_PID_FILE" "用户前端"
    kill_port_processes "$FRONTEND_PORT" "用户前端"

    # 2. 确保目录存在
    mkdir -p "$LOG_DIR" "$PID_DIR"

    # 3. 安装依赖（如果需要）
    if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
        log_info "安装用户前端依赖..."
        (cd "$FRONTEND_DIR" && npm install)
    fi

    # 4. 启动前端
    log_info "正在启动用户前端服务..."
    nohup bash -lc "cd '$FRONTEND_DIR' && npm run dev -- --host 0.0.0.0 --port '$FRONTEND_PORT'" \
        >"$FRONTEND_LOG" 2>&1 &
    local frontend_pid=$!
    echo "$frontend_pid" > "$FRONTEND_PID_FILE"
    log_info "用户前端进程已启动 (PID: $frontend_pid), 日志: $FRONTEND_LOG"

    # 5. 健康检查
    log_info "等待用户前端服务就绪..."
    local waited=0
    while [[ $waited -lt 60 ]]; do
        if curl -fsS "http://localhost:$FRONTEND_PORT/" >/dev/null 2>&1; then
            log_info "用户前端服务已就绪！http://localhost:$FRONTEND_PORT/"
            return 0
        fi
        if ! kill -0 "$frontend_pid" >/dev/null 2>&1; then
            log_error "用户前端进程已退出，请查看日志:"
            tail -30 "$FRONTEND_LOG"
            exit 1
        fi
        sleep 1
        waited=$((waited + 1))
    done

    log_error "用户前端服务在 60 秒内未就绪，请查看日志:"
    tail -30 "$FRONTEND_LOG"
    exit 1
}

# ---------- 启动管理后台 ----------
start_admin() {
    log_section "启动管理后台服务"

    # 检查依赖
    check_dependencies admin

    # 1. 停止旧的进程和释放端口
    log_info "检查并清理旧进程和端口..."
    kill_by_pid_file "$ADMIN_PID_FILE" "管理后台"
    kill_port_processes "$ADMIN_PORT" "管理后台"

    # 2. 确保目录存在
    mkdir -p "$LOG_DIR" "$PID_DIR"

    # 3. 安装依赖（如果需要）
    if [[ ! -d "$ADMIN_DIR/node_modules" ]]; then
        log_info "安装管理后台依赖..."
        (cd "$ADMIN_DIR" && npm install)
    fi

    # 4. 启动管理后台
    log_info "正在启动管理后台服务..."
    nohup bash -lc "cd '$ADMIN_DIR' && npm run dev" \
        >"$ADMIN_LOG" 2>&1 &
    local admin_pid=$!
    echo "$admin_pid" > "$ADMIN_PID_FILE"
    log_info "管理后台进程已启动 (PID: $admin_pid), 日志: $ADMIN_LOG"

    # 5. 健康检查
    log_info "等待管理后台服务就绪..."
    local waited=0
    while [[ $waited -lt 40 ]]; do
        if curl -fsS "http://localhost:$ADMIN_PORT/" >/dev/null 2>&1; then
            log_info "管理后台服务已就绪！http://localhost:$ADMIN_PORT/"
            return 0
        fi
        if ! kill -0 "$admin_pid" >/dev/null 2>&1; then
            log_error "管理后台进程已退出，请查看日志:"
            tail -30 "$ADMIN_LOG"
            exit 1
        fi
        sleep 1
        waited=$((waited + 1))
    done

    log_error "管理后台服务在 40 秒内未就绪，请查看日志:"
    tail -30 "$ADMIN_LOG"
    exit 1
}

# ---------- 启动全部 ----------
start_all() {
    log_section "启动 E-Commerce 全部服务"
    echo ""
    start_backend
    start_frontend
    start_admin

    echo ""
    log_section "全部服务已就绪"
    echo "  ┌─────────────────────────────────────────────┐"
    echo "  │  用户前端:  http://localhost:$FRONTEND_PORT/          │"
    echo "  │  管理后台:  http://localhost:$ADMIN_PORT/          │"
    echo "  │  后端 API:  http://localhost:$BACKEND_PORT/api       │"
    echo "  │  Swagger:   http://localhost:$BACKEND_PORT/api/swagger-ui/index.html │"
    echo "  └─────────────────────────────────────────────┘"
    echo ""
    echo "  PID 文件目录: $PID_DIR"
    echo "  日志文件目录: $LOG_DIR"
    echo ""
}

# ---------- 重启 ----------
restart_all() {
    log_section "重启全部服务"
    stop_all
    sleep 2  # 等待端口完全释放
    start_all
}

# ---------- 帮助信息 ----------
show_help() {
    cat << EOF

E-Commerce 项目启动管理脚本

用法: $0 [命令]

命令:
  (无参数)          启动全部服务（后端 + 用户前端 + 管理后台）
  backend           仅启动后端服务 (Spring Boot, 端口 $BACKEND_PORT)
  frontend          仅启动用户前端 (Vite, 端口 $FRONTEND_PORT)
  admin             仅启动管理后台 (Vite, 端口 $ADMIN_PORT)
  status            查看各服务运行状态
  stop              停止全部服务
  restart           重启全部服务
  help              显示此帮助信息

环境变量:
  BACKEND_PORT       后端端口 (默认: 8080)
  FRONTEND_PORT      用户前端端口 (默认: 5173)
  ADMIN_PORT         管理后台端口 (默认: 5174)
  HEALTH_CHECK_TIMEOUT  健康检查超时秒数 (默认: 120)

示例:
  $0                  # 启动全部
  $0 backend          # 仅启动后端
  $0 status           # 查看状态
  $0 stop             # 停止所有服务
  $0 restart          # 重启所有服务
  BACKEND_PORT=8081 $0 backend   # 指定端口启动

EOF
}

# ---------- 主入口 ----------
main() {
    local cmd="${1:-all}"

    case "$cmd" in
        all|"")
            start_all
            ;;
        backend)
            start_backend
            ;;
        frontend)
            start_frontend
            ;;
        admin)
            start_admin
            ;;
        status)
            show_status
            ;;
        stop)
            stop_all
            ;;
        restart)
            restart_all
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            log_error "未知命令: $cmd"
            show_help
            exit 1
            ;;
    esac
}

mkdir -p "$LOG_DIR" "$PID_DIR"
main "$@"