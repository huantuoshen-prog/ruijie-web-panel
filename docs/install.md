# OpenWrt 安装、升级与回滚

面板仅支持 OpenWrt、iStoreOS、ImmortalWrt 及使用 `procd`、`uhttpd` 的衍生固件。安装阶段不会发起校园网认证，也不会执行认证下线。

## 系统要求

- 已有可用的 LAN 地址，且面板只绑定该地址的 `8080` 端口
- 固件提供 `procd`、`uhttpd`、`uci`
- 已安装 `bash`、`curl`、`jq`、`flock`、`sha256sum`、`tar`
- 至少约 10 MB 可用空间，建议 128 MB 内存

安装器不会修改固件软件源。缺少依赖时会明确停止，请根据自己的固件来源安装依赖后重试。

## 使用固定发布包

不要逐个下载 `main` 分支中的文件。完整组合包固定了核心与面板的准确提交，并带有逐文件校验值。

以下命令以 `v4.0.0` 为例。在路由器 SSH 或 TTYD 终端执行：

```sh
cd /tmp
VERSION=v4.0.0
BASE="https://github.com/huantuoshen-prog/ruijie-web-panel/releases/download/$VERSION"
curl -fLO "$BASE/ruijie-openwrt-bundle.tar.gz"
curl -fLO "$BASE/SHA256SUMS"
grep ' ruijie-openwrt-bundle.tar.gz$' SHA256SUMS | sha256sum -c -

mkdir -p /tmp/ruijie-release
tar -xzf ruijie-openwrt-bundle.tar.gz -C /tmp/ruijie-release
cd /tmp/ruijie-release/ruijie-openwrt-bundle
sha256sum -c manifest.sha256
```

先安装核心，再安装面板：

```sh
mkdir -p /tmp/ruijie-core /tmp/ruijie-panel
tar -xzf core.tar.gz -C /tmp/ruijie-core
tar -xzf panel.tar.gz -C /tmp/ruijie-panel

cd /tmp/ruijie-core/ruijie-core
sha256sum -c manifest.sha256
sh install.sh

cd /tmp/ruijie-panel/ruijie-panel
sha256sum -c manifest.sha256
sh install.sh
```

首次安装面板会要求输入两次独立的面板密码。这个密码只用于访问管理页面，不是校园网密码。

安装完成后，浏览器访问：

```text
http://路由器LAN地址:8080/
```

## 升级行为

- 核心与面板都会先校验完整发布包，再切换文件。
- 账号配置和面板密码不会被代码升级覆盖。
- 升级前处于停用或停止状态的服务，升级后仍保持原状态。
- 最近一个完整版本会保留在同一存储位置，供回滚使用。
- 若切换后的服务健康检查失败，安装器会自动恢复上一版。

核心安装器若发现无法识别的旧守护进程或旧 `rc.local`、cron 启动项，会在修改任何文件前停止。这种迁移应留到计划维护时段处理。

## 手动回滚

核心回滚：

```sh
/etc/ruijie/rollback.sh
```

面板回滚：

```sh
/overlay/usr/www/ruijie-web/rollback.sh
```

少数没有 overlay 的固件使用：

```sh
/www/ruijie-web/rollback.sh
```

回滚会恢复上一版代码以及当时的启用、运行状态。被替换的文件会保留为带时间戳的 `failed` 目录，方便进一步排查。

## 验证

```sh
/etc/ruijie/ruijiectl runtime
uci get network.lan.ipaddr
curl --noproxy '*' -s "http://$(uci get network.lan.ipaddr):8080/ruijie-cgi/auth"
```

最后一条应返回合法 JSON。验证只读取运行环境和面板登录状态，不会触发校园网重新认证或下线。

## 卸载面板

```sh
/overlay/usr/www/ruijie-web/uninstall.sh
```

卸载会删除面板、面板密码和会话，不会删除认证核心及校园网账号配置。
