#!/bin/sh
# ========================================
# 卸载锐捷 Web 管理面板
# ========================================

echo "正在卸载锐捷认证 Web 管理面板..."

# 停止并禁用服务
/etc/init.d/ruijie-panel stop   2>/dev/null
/etc/init.d/ruijie-panel disable 2>/dev/null

# 删除服务脚本（覆盖所有可能的安装位置）
rm -f /overlay/etc/init.d/ruijie-panel 2>/dev/null
rm -f /etc/init.d/ruijie-panel 2>/dev/null

# 删除 Web 文件（覆盖所有可能的安装路径）
rm -rf /overlay/usr/www/ruijie-web 2>/dev/null
rm -rf /mnt/sda1/ruijie-web 2>/dev/null
rm -rf /www/ruijie-web 2>/dev/null

# 清理 uhttpd 独立实例配置（不碰 LuCI 主实例）
if uci get uhttpd.ruijie >/dev/null 2>&1; then
    uci del uhttpd.ruijie
    uci commit uhttpd
fi

# 重启 Web 服务
/etc/init.d/uhttpd restart 2>/dev/null

echo "卸载完成。如需重新安装，请运行 install.sh"
