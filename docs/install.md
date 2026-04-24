# 安装文档

## 系统要求

## 让 Agent 帮你安装

如果你想把主脚本前置检查、自动安装和安装后验证一次性交给通用 Agent，直接复制：
[AGENT_INSTALL_PROMPT.md](./AGENT_INSTALL_PROMPT.md)

如果主仓库还没装好，请先使用主仓库的安装 Prompt：
[ruijie-gdstvc-autologin / AGENT_INSTALL_PROMPT.md](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin/blob/main/docs/AGENT_INSTALL_PROMPT.md)

这个 Prompt 默认假设面板部署在路由器上；如果 Agent 当前不在路由器终端，它应该先引导你切到 SSH / TTYD 终端，或要求一个可用 SSH 目标，而不是读取本地电脑的 `/etc/ruijie`。

### 硬件

| 项目 | 最低要求 | 推荐 |
|------|----------|------|
| 路由器 | 64MB RAM | 128MB RAM |
| 存储 | 2MB 可用 | 10MB 可用 |
| CPU | 任意 | ARM / x86 均可 |

### 软件

- OpenWrt / iStoreOS / ImmortalWrt 或其他衍生固件
- `uhttpd`
- `/bin/sh`
- `wget` 或 `curl`

### 前置条件

- 已安装主仓库 `ruijie-gdstvc-autologin`
- 已完成主脚本的 `setup.sh`

## 自动安装（推荐）

```bash
wget -O /tmp/install.sh \
  https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh
chmod +x /tmp/install.sh && sh /tmp/install.sh
```

安装脚本会自动：

- 选择安装路径
- 下载 `dist/` 静态产物
- 部署 CGI 脚本和 `ruijie-cgi` 路由
- 初始化独立面板密码
- 注册并启动 `ruijie-panel` 服务

## 手动安装

```bash
mkdir -p /overlay/usr/www/ruijie-web/api
cd /overlay/usr/www/ruijie-web

wget https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/dist/index.html -O index.html
wget https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/dist/app.js -O app.js
wget https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/dist/app.css -O app.css
wget https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/dist/favicon.ico -O favicon.ico
wget https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/uninstall.sh

for f in auth.sh account.sh common.sh daemon.sh health-log.sh health.sh log.sh mode.sh runtime.sh settings.sh status.sh; do
  wget "https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/api/$f" -O "api/$f"
done

mkdir -p ruijie-cgi
for name in auth account daemon health health-log log mode runtime settings status; do
  ln -sf "../api/${name}.sh" "ruijie-cgi/${name}"
done

chmod +x api/*.sh uninstall.sh
```

面板密码初始化示例：

```bash
mkdir -p /etc/ruijie-panel
printf 'PASSWORD_SHA256=%s\n' "$(printf 'panel-secret' | sha256sum | awk '{print $1}')" > /etc/ruijie-panel/auth.conf
chmod 600 /etc/ruijie-panel/auth.conf
```

## USB 安装

如果 overlay 空间不足，可以装到 USB：

```bash
mount /dev/sda1 /mnt/sda1
cd /mnt/sda1
mkdir -p ruijie-web/api
```

然后按手动安装方式下载对应文件。

## 路径选择

| 路径 | 优先级 | 说明 |
|------|--------|------|
| `/overlay/usr/www/ruijie-web/` | 高 | 持久化、重启不丢 |
| `/mnt/sda1/ruijie-web/` | 中 | USB 存储 |
| `/www/ruijie-web/` | 低 | 临时目录，重启清空 |

## 服务注册

安装完成后会注册：

- 服务名：`ruijie-panel`
- 监听端口：`8080`
- LuCI 入口：`服务 -> 锐捷 Web 管理面板`

## 卸载

```bash
sh /overlay/usr/www/ruijie-web/uninstall.sh
```

如果是 USB 安装，就执行对应 USB 路径下的 `uninstall.sh`。
