#!/bin/sh
# ========================================
# Ruijie Web 管理面板 安装脚本
# 自动部署到 OpenWrt / iStoreOS 路由器
# 支持一键安装：仅需一条 wget/curl 命令
# ========================================

set -e

# ----------------------------------------
# 颜色
# ----------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo_info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
echo_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
echo_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ----------------------------------------
# 配置
# ----------------------------------------
GITHUB_REPO="huantuoshen-prog/ruijie-web-panel"
GITHUB_BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}"
API_BASE="https://api.github.com/repos/${GITHUB_REPO}/contents"
INSTALL_TEMP="/tmp/ruijie-panel-install"
INSTALL_MARKER="${INSTALL_TEMP}/.installed"

# 需要下载的文件列表（路径相对于仓库根）
DOWNLOAD_FILES="
index.html
uninstall.sh
api/account.sh
api/common.sh
api/daemon.sh
api/log.sh
api/mode.sh
api/settings.sh
api/status.sh
init.d/ruijie-panel
"

# ----------------------------------------
# 1. 检测运行环境
# ----------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  锐捷认证 Web 管理面板 安装程序"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo_info "检测路由器环境..."

if [ ! -f /etc/config/uhttpd ]; then
    echo_error "未检测到 uhttpd（Web 服务器），当前固件可能不支持"
    echo ""
    echo "  请确认你的路由器运行的是 OpenWrt、iStoreOS、ImmortalWrt 等衍生固件"
    echo "  或者手动安装：opkg update && opkg install uhttpd"
    exit 1
fi
echo_ok "uhttpd 已就绪"

# 检测是否有 wget（优先）或 curl
if command -v wget >/dev/null 2>&1; then
    # wget 优先，避免默认的 HTML/CSS/JS 文件名转换
    DOWNLOADER="wget -q --no-config -O"
elif command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl -s -o"
else
    echo_error "未找到 wget 或 curl，无法下载文件"
    exit 1
fi
echo_ok "下载工具: ${DOWNLOADER%% *}"

# ----------------------------------------
# 2. 确定安装目标路径
# ----------------------------------------
if [ -d /overlay ]; then
    WEB_TARGET="/overlay/usr/www/ruijie-web"
    INIT_TARGET="/overlay/etc/init.d/ruijie-panel"
    echo_ok "检测到 overlay 持久化存储"
elif [ -d /mnt/sda1 ]; then
    WEB_TARGET="/mnt/sda1/ruijie-web"
    INIT_TARGET="/etc/init.d/ruijie-panel"
    echo_warn "未检测到 overlay，使用 USB 存储: $WEB_TARGET"
else
    WEB_TARGET="/www/ruijie-web"
    INIT_TARGET="/etc/init.d/ruijie-panel"
    echo_warn "未检测到 overlay 和 USB，使用临时路径（重启后需重新安装）"
fi

# ----------------------------------------
# 3. 下载文件到临时目录
# ----------------------------------------
echo_info "正在下载安装文件（从 GitHub）..."

rm -rf "$INSTALL_TEMP"
mkdir -p "$INSTALL_TEMP"

_fetch_ok=true
for _file in $DOWNLOAD_FILES; do
    _url="${RAW_BASE}/${_file}"
    _dest="${INSTALL_TEMP}/${_file}"
    _dir="$(dirname "$_dest")"
    mkdir -p "$_dir"

    if eval "$DOWNLOADER \"$_dest\" \"$_url\"" 2>/dev/null; then
        echo "    $_file"
    else
        echo_error "下载失败: $_file"
        _fetch_ok=false
    fi
    fi
done

if [ "$_fetch_ok" != "true" ]; then
    echo_error "部分文件下载失败，请检查网络连接"
    exit 1
fi
echo_ok "文件下载完成"

# ----------------------------------------
# 4. 复制 Web 文件到目标目录
# ----------------------------------------
echo_info "安装 Web 文件到 $WEB_TARGET ..."

mkdir -p "$WEB_TARGET"
mkdir -p "${WEB_TARGET}/api"

cp "${INSTALL_TEMP}/index.html" "${WEB_TARGET}/"
cp "${INSTALL_TEMP}/uninstall.sh" "${WEB_TARGET}/"
for _f in "${INSTALL_TEMP}/api/"*.sh; do
    [ -f "$_f" ] && cp "$_f" "${WEB_TARGET}/api/"
done

# 标记已安装路径（供卸载脚本使用）
echo "$WEB_TARGET" > "${WEB_TARGET}/.install_path"

chmod +x "${WEB_TARGET}/api/"*.sh 2>/dev/null || true
chmod +x "${WEB_TARGET}/uninstall.sh" 2>/dev/null || true

# 创建 CGI 软链接（前端调用 /ruijie-cgi/*，实际脚本在 /api/*.sh）
ln -sf api "${WEB_TARGET}/ruijie-cgi"
echo_ok "Web 文件已复制"

# ----------------------------------------
# 5. 安装服务脚本
# ----------------------------------------
echo_info "注册系统服务..."

mkdir -p "$(dirname "$INIT_TARGET")"
cp "${INSTALL_TEMP}/init.d/ruijie-panel" "$INIT_TARGET"
chmod +x "$INIT_TARGET"

/etc/init.d/ruijie-panel enable 2>/dev/null
echo_ok "服务已注册并启用"

# ----------------------------------------
# 6. 启动服务
# ----------------------------------------
echo_info "启动 Web 服务..."
/etc/init.d/ruijie-panel start 2>&1

# 清理临时目录
rm -rf "$INSTALL_TEMP"

# 获取路由器 LAN IP
_ROUTER_IP=$(uci get network.lan.ipaddr 2>/dev/null || echo "192.168.5.1")

echo ""
echo_ok "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo_ok "  安装完成！"
echo_ok "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  访问地址：http://${_ROUTER_IP}:8080/"
echo ""
echo "  LuCI 管理方法："
echo "    路由器后台 → 服务 → 锐捷 Web 管理面板"
echo ""
echo "  命令行管理："
echo "    /etc/init.d/ruijie-panel start   # 启动"
echo "    /etc/init.d/ruijie-panel stop    # 停止"
echo "    /etc/init.d/ruijie-panel restart # 重启"
echo "    /etc/init.d/ruijie-panel enable  # 开机自启"
echo ""
echo "  卸载命令：sh $WEB_TARGET/uninstall.sh"
echo ""
