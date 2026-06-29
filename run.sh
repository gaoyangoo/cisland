#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODEPROJ="$PROJECT_DIR/cisland.xcodeproj"
SCHEME="cisland"
CONFIG="Debug"
APP_NAME="cisland"

# ── Colors ──────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

divider() {
    echo -e "${CYAN}──────────────────────────────────────────────────${NC}"
}

step() {
    echo -e "\n${BOLD}${YELLOW}▶  $1${NC}"
    divider
}

ok() {
    echo -e "  ${GREEN}✓${NC} $1"
}

fail() {
    echo -e "  ${RED}✗${NC} $1"
    exit 1
}

# ── Step 1: Kill old process ────────────────────────
step "关闭旧进程"
OLD_PID=$(pgrep -f "$APP_NAME.app" 2>/dev/null || true)
if [ -n "$OLD_PID" ]; then
    kill $OLD_PID 2>/dev/null && ok "已终止 cisland (PID $OLD_PID)" || ok "进程已退出"
    sleep 1
else
    ok "没有正在运行的 cisland 进程"
fi

# ── Step 2: Build ───────────────────────────────────
step "编译项目"
echo -e "  ${CYAN}项目:${NC} $XCODEPROJ"
echo -e "  ${CYAN}配置:${NC} $CONFIG"

BUILD_OUTPUT=$(xcodebuild \
    -project "$XCODEPROJ" \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    build 2>&1) || {
    echo "$BUILD_OUTPUT" | tail -20
    fail "编译失败"
}

# Count warnings
WARNINGS=$(echo "$BUILD_OUTPUT" | grep -c "warning:" || true)
ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "error:" || true)

ok "编译成功"

# Find the built app
BUILD_DIR=$(echo "$BUILD_OUTPUT" | grep -o '/Users[^ ]*cisland.app' | head -1)
if [ -z "$BUILD_DIR" ]; then
    BUILD_DIR="$HOME/Library/Developer/Xcode/DerivedData"
    BUILD_DIR=$(find "$BUILD_DIR" -path "*/Build/Products/$CONFIG/$APP_NAME.app" -type d 2>/dev/null | head -1)
fi

if [ -z "$BUILD_DIR" ]; then
    fail "找不到编译产物"
fi

echo -e "  ${CYAN}产物:${NC} $BUILD_DIR"

if [ "$ERRORS" -gt 0 ]; then
    echo -e "  ${RED}错误: $ERRORS${NC}"
fi
if [ "$WARNINGS" -gt 0 ]; then
    echo -e "  ${YELLOW}警告: $WARNINGS${NC}"
else
    ok "无警告"
fi

# ── Step 3: Launch ──────────────────────────────────
step "启动应用"
"$BUILD_DIR/Contents/MacOS/$APP_NAME" &
sleep 1

NEW_PID=$(pgrep -f "$APP_NAME.app" 2>/dev/null || true)
if [ -n "$NEW_PID" ]; then
    ok "cisland 已启动 (PID $NEW_PID)"
else
    fail "启动失败"
fi

# ── Done ────────────────────────────────────────────
divider
echo -e "${BOLD}${GREEN}  全部完成！${NC}"
echo -e "  按 ${BOLD}⇧⌘O${NC} 切换面板"
echo -e "  菜单栏图标 ${BOLD}⎈${NC} 右键退出"
divider
