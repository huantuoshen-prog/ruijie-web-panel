# 锐捷认证 Web 管理面板

> 锐捷认证脚本的可选图形管理界面。在浏览器里管理账号、守护进程和日志，无需敲命令。

[![CI](https://github.com/huantuoshen-prog/ruijie-web-panel/actions/workflows/ci.yml/badge.svg)](https://github.com/huantuoshen-prog/ruijie-web-panel/actions)
[![版本](https://img.shields.io/badge/version-v3.1-blue)](https://github.com/huantuoshen-prog/ruijie-web-panel)

**本面板是 [ruijie-gdstvc-autologin](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin)（主仓库）的扩展，需要先完成主仓库的安装配置后才能使用。**

---

## 目录

- [项目简介](#项目简介)
- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [安装指南](#安装指南)
- [使用指南](#使用指南)
- [服务管理](#服务管理)
- [网络架构](#网络架构)
- [API 参考文档](#api-参考文档)
- [故障排除](#故障排除)
- [开发者指南](#开发者指南)
- [版本历史](#版本历史)
- [相关项目](#相关项目)
- [许可证](#许可证)

---

## 项目简介

### 什么是 Web 管理面板？

Web 管理面板是锐捷认证脚本的可选图形界面，提供以下功能：

| 页面 | 功能 |
|------|------|
| **状态** | 实时在线/离线状态、守护进程 PID/运行时间、最后认证时间 |
| **账号** | 修改学号、密码、运营商（电信/联通） |
| **守护进程** | 启动 / 停止 / 重启，查看状态机当前状态 |
| **日志** | 查看认证日志，支持按级别过滤 |
| **设置** | 配置 HTTP / HTTPS 代理 |

### 技术特点

- **纯前端**：纯 HTML + Vanilla JavaScript，无任何外部依赖
- **轻量后端**：Shell CGI，每个 API 一个独立脚本
- **原生集成**：自动注册到 OpenWrt LuCI「服务」菜单
- **响应式设计**：支持深色模式，自定义背景
- **数据安全**：密码本地脱敏显示，不暴露

### 与主仓库的关系

```
┌─────────────────────────────────────────────────────────────────┐
│                      ruijie-gdstvc-autologin                     │
│                    （主仓库，必须先安装）                          │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ 锐捷认证脚本 · 命令行管理 · 配置文件 · 守护进程              │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                    │
│                     lib/ 模块被调用                              │
│                              ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                   ruijie-web-panel                          │ │
│  │                   （本仓库，可选安装）                        │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐   │ │
│  │  │ Web 界面    │──│ CGI API    │──│ OpenWrt 服务        │   │ │
│  │  │ index.html │  │ api/*.sh   │  │ /etc/init.d/       │   │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘   │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 效果预览

```
┌─────────────────────────────────────────────────────────────────────────┐
│  锐捷认证 Web 管理面板                                            v3.1 │
│  广东科学技术职业学院 · 校园网认证                                      │
├─────────────────────────────────────────────────────────────────────────┤
│  [状态]  [账号]  [守护进程]  [日志]  [设置]                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  网络状态                        守护进程                                │
│  ┌────────────────────┐        ┌────────────────────┐                   │
│  │  ● 已连接          │        │  ● 运行中           │  PID 12345        │
│  │  在线 4 小时 23 分钟│        │  ONLINE            │                   │
│  └────────────────────┘        └────────────────────┘                   │
│                                                                          │
│  账号: 1720240564  运营商: 电信   最后认证: 2 分钟前                      │
│                                                                          │
│  [▶ 启动]  [■ 停止]  [↻ 重启]  [⟳ 刷新]                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                           访问地址: http://路由器IP:8080/
```

---

## 系统要求

### 硬件要求

| 项目 | 最低要求 | 推荐 |
|------|----------|------|
| 路由器 | 64MB RAM | 128MB RAM |
| 存储 | 2MB 可用 | 10MB 可用 |
| CPU | 任意 | ARM/x86 均可 |

### 软件要求

- **路由器固件**：OpenWrt / iStoreOS / ImmortalWrt 或其他衍生固件
- **Web 服务器**：uhttpd（大多数固件自带）
- **必要依赖**：
  - `/bin/sh`（POSIX shell）
  - `wget` 或 `curl`（下载安装）

### 前置条件

> ⚠️ 请按顺序完成，缺少任一步骤面板将无法正常使用

- [x] 路由器已刷 **OpenWrt / iStoreOS / ImmortalWrt** 等衍生固件
- [x] 路由器 WAN 口已连接校园网（墙壁网线）
- [x] **已完成锐捷认证脚本安装配置**（运行过 `setup.sh`）

> **不知道如何进路由器终端？** 请先阅读 [主仓库 README - 进入路由器终端](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin#方式一通过路由器后台图形界面适合大多数用户)

---

## 快速开始

### 3 步安装

**第一步：下载安装脚本**

```bash
wget -O /tmp/install.sh \
  https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh
```

> 如果路由器没有 wget，使用 curl：
> ```bash
> curl -LO https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh
> ```

**第二步：运行安装**

```bash
chmod +x /tmp/install.sh && sh /tmp/install.sh
```

**第三步：打开浏览器访问**

```
http://192.168.5.1:8080/
```

> 路由器 IP 可能不是 `192.168.5.1`，常见还有：
> - `192.168.1.1` — OpenWrt 默认
> - `192.168.31.1` — 小米路由器

### 安装验证

```bash
# 1. 检查端口是否监听
netstat -tlnp | grep 8080

# 2. 检查文件是否存在
ls -la /overlay/usr/www/ruijie-web/

# 3. 检查服务是否启用
/etc/init.d/ruijie-panel enabled
```

---

## 安装指南

### 安装方式

#### 方式一：自动安装（推荐）

一键安装，自动选择最佳路径：

```bash
wget -O /tmp/install.sh \
  https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh
chmod +x /tmp/install.sh && sh /tmp/install.sh
```

#### 方式二：手动安装

手动下载并安装：

```bash
# 创建目录
mkdir -p /overlay/usr/www/ruijie-web/api

# 下载文件
cd /overlay/usr/www/ruijie-web
wget https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/index.html
wget https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/uninstall.sh

# 下载 API 脚本
for f in account.sh common.sh daemon.sh log.sh mode.sh settings.sh status.sh; do
  wget "https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/api/$f" -O "api/$f"
done

# 创建 CGI 软链接
ln -sf api /overlay/usr/www/ruijie-web/ruijie-cgi

# 设置权限
chmod +x api/*.sh uninstall.sh
```

#### 方式三：USB 存储

如果路由器的 overlay 分区空间不足，可以安装到 USB 存储：

```bash
# 挂载 USB 设备
mount /dev/sda1 /mnt/sda1

# 安装到 USB
cd /mnt/sda1
mkdir -p ruijie-web/api
# 手动下载文件到 /mnt/sda1/ruijie-web/
```

### 路径说明

安装脚本会根据路由器环境自动选择最佳路径：

| 路径 | 优先级 | 说明 |
|------|--------|------|
| `/overlay/usr/www/ruijie-web/` | ⭐⭐⭐ 优先 | 持久化存储，重启不丢失 |
| `/mnt/sda1/ruijie-web/` | ⭐⭐ 备选 | USB 存储，需要手动挂载 |
| `/www/ruijie-web/` | ⭐ 临时 | 内存存储，重启清空 |

### CGI 配置说明

面板使用 CGI 路由，前端通过 `/ruijie-cgi/` 路径访问 API：

```
前端请求: /ruijie-cgi/status
       ↓ 软链接
实际路径: /overlay/usr/www/ruijie-web/api/status.sh
```

安装脚本会自动创建软链接，无需手动配置。

### 服务注册

安装完成后，服务会自动注册到 OpenWrt：

- 服务名称：`ruijie-panel`
- 启动顺序：`95`（较晚启动，确保网络就绪）
- 停止顺序：`15`

### 卸载

```bash
# 使用安装目录下的卸载脚本
sh /overlay/usr/www/ruijie-web/uninstall.sh

# 或（如果使用 USB 安装）
sh /mnt/sda1/ruijie-web/uninstall.sh
```

卸载脚本会自动：
1. 停止并禁用服务
2. 删除服务脚本
3. 删除 Web 文件
4. 清理 uhttpd 配置
5. 重启 Web 服务

---

## 使用指南

### 页面功能

#### 状态页面

显示系统当前状态：

| 显示项 | 说明 |
|--------|------|
| 网络连接状态 | 在线（绿色）/ 离线（红色）|
| 账号信息 | 当前用户名、运营商 |
| 守护进程 | PID、运行时间、状态机状态 |
| 最后认证时间 | 上次认证成功的时间 |

自动刷新间隔：**30 秒**

#### 账号管理页面

修改锐捷认证账号：

| 字段 | 说明 |
|------|------|
| 用户名 | 学号或工号 |
| 密码 | 校园网密码 |
| 运营商 | 电信（默认）或联通 |

保存后会自动更新配置文件。

#### 守护进程控制

管理后台认证进程：

| 按钮 | 功能 |
|------|------|
| 启动 | 启动守护进程 |
| 停止 | 停止守护进程 |
| 重启 | 重启守护进程 |

> 注意：停止守护进程后，网络可能会在下次断线时无法自动重连。

#### 日志查看

实时查看认证日志：

| 功能 | 说明 |
|------|------|
| 自动刷新 | 每 **10 秒** 自动加载新日志 |
| 级别过滤 | 全部 / INFO / 成功 / 警告 / 错误 |
| 暂停刷新 | 点击暂停按钮可停止自动刷新 |

**日志级别说明：**

| 级别 | 标识 | 含义 |
|------|------|------|
| INFO | `[INFO]` | 一般信息 |
| OK | `[OK]` | 认证成功 |
| STEP | `[STEP]` | 处理步骤 |
| WARN | `[WARN]` | 警告，可能有问题 |
| ERROR | `[ERROR]` | 错误，认证失败 |

#### 代理设置

配置 HTTP 代理上网：

| 字段 | 说明 |
|------|------|
| HTTP 代理 | 例如 `http://127.0.0.1:7890` |
| HTTPS 代理 | 留空则同 HTTP 代理 |

> 提示：国内校园网通常不需要代理，直接留空即可。

### 界面个性化

#### 深色模式

页面支持自动检测系统深色模式偏好，也可以手动切换：

1. 点击页面右上角的主题按钮
2. 选择「深色」或「浅色」
3. 选择会被保存到浏览器

#### 背景自定义

可以自定义页面背景图片：

1. **拖拽上传**：直接将图片拖入页面任意位置
2. **点击上传**：点击背景区域选择图片文件
3. 图片会自动保存到浏览器（IndexedDB）
4. 支持的最大文件大小：**20MB**

清除自定义背景：打开设置弹窗，点击「恢复默认背景」。

---

## 服务管理

### 命令行管理

```bash
# 启动服务
/etc/init.d/ruijie-panel start

# 停止服务
/etc/init.d/ruijie-panel stop

# 重启服务
/etc/init.d/ruijie-panel restart

# 重新加载配置
/etc/init.d/ruijie-panel reload

# 开启开机自启
/etc/init.d/ruijie-panel enable

# 关闭开机自启
/etc/init.d/ruijie-panel disable

# 检查是否已启用
/etc/init.d/ruijie-panel enabled
```

### LuCI 后台管理

安装后，面板会出现在路由器后台的「服务」菜单中：

```
LuCI → 服务 → 锐捷 Web 管理面板 → 打开
```

### 端口说明

面板使用 **8080** 端口，独立于 LuCI 的 80/443 端口，不会影响路由器后台的正常访问。

---

## 网络架构

### 数据流向

```
                         用户浏览器
                              │
                              │ HTTP 请求
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         OpenWrt 路由器                               │
│                                                                      │
│    ┌─────────────┐         ┌─────────────┐         ┌─────────────┐ │
│    │   uhttpd   │─────────▶│  index.html │         │   API CGI   │ │
│    │  (:8080)   │         │  (静态页面)  │         │  api/*.sh   │ │
│    └─────────────┘         └─────────────┘         └──────┬──────┘ │
│                                                           │         │
│                                                           ▼         │
│                                                  ┌─────────────────┐│
│                                                  │ ruijie-gdstvc   ││
│                                                  │    -autologin    ││
│                                                  │  lib/ 模块调用   ││
│                                                  └────────┬────────┘│
│                                                           │         │
│                                                           ▼         │
│                                                  ┌─────────────────┐│
│                                                  │ 配置文件         ││
│                                                  │ ~/.config/ruijie ││
│                                                  └─────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ 锐捷认证
                              ▼
                    ┌─────────────────────┐
                    │   锐捷认证服务器     │
                    │  (校园网 portal)     │
                    └─────────────────────┘
```

### CGI 路由说明

| 前端路径 | 实际路径 | 说明 |
|----------|----------|------|
| `/ruijie-cgi/status` | `/api/status.sh` | 获取系统状态 |
| `/ruijie-cgi/account` | `/api/account.sh` | 账号管理 |
| `/ruijie-cgi/daemon` | `/api/daemon.sh` | 守护进程控制 |
| `/ruijie-cgi/mode` | `/api/mode.sh` | 运营商切换 |
| `/ruijie-cgi/settings` | `/api/settings.sh` | 代理设置 |
| `/ruijie-cgi/log` | `/api/log.sh` | 日志读取 |

---

## API 参考文档

### 通用说明

- **Base URL**: `/ruijie-cgi`
- **Content-Type**: `application/x-www-form-urlencoded; charset=UTF-8`
- **响应格式**: JSON

### 端点列表

#### GET /ruijie-cgi/status — 系统状态

获取系统当前状态。

**响应示例：**
```json
{
  "installed": true,
  "online": true,
  "username": "1720240564",
  "operator": "DianXin",
  "account_type": "student",
  "daemon_running": true,
  "daemon_pid": "12345",
  "daemon_uptime": "4小时23分钟",
  "daemon_state": "ONLINE",
  "last_auth": "2026-04-13 10:30:00",
  "version": "3.1",
  "message": ""
}
```

#### GET /ruijie-cgi/account — 读取账号

获取当前账号信息（密码脱敏）。

**响应示例：**
```json
{
  "username": "1720240564",
  "password": "******",
  "operator": "DianXin",
  "account_type": "student",
  "proxy_url": ""
}
```

#### POST /ruijie-cgi/account — 保存账号

保存新的账号信息。

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | string | 是 | 用户名 |
| password | string | 是 | 密码 |
| operator | string | 否 | 运营商（DianXin/LianTong）|

**响应示例：**
```json
{"success": true, "message": "账号已保存"}
```

#### POST /ruijie-cgi/daemon — 守护进程控制

控制守护进程状态。

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| action | string | 是 | 操作：start / stop / restart |

**响应示例：**
```json
// 成功
{"success": true, "pid": "12345", "message": "守护进程已启动"}

// 失败
{"success": false, "message": "启动失败，守护进程可能已在运行"}
```

#### POST /ruijie-cgi/mode — 运营商切换

切换网络运营商。

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| operator | string | 是 | 运营商：DianXin 或 LianTong |

**响应示例：**
```json
{"success": true, "message": "已切换到DianXin，网络已连接", "operator": "DianXin"}
```

#### GET /ruijie-cgi/settings — 读取代理设置

获取当前代理配置。

**响应示例：**
```json
{
  "proxy_url": "http://127.0.0.1:7890",
  "proxy_url_https": "http://127.0.0.1:7890"
}
```

#### POST /ruijie-cgi/settings — 保存代理设置

保存代理配置。

**请求参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| proxy_url | string | 否 | HTTP 代理地址 |
| proxy_url_https | string | 否 | HTTPS 代理地址 |

**响应示例：**
```json
{"success": true, "message": "设置已保存"}
```

#### GET /ruijie-cgi/log — 读取日志

获取认证日志。

**响应示例：**
```json
{
  "lines": [
    {"ts": "2026-04-13 10:30:01", "level": "INFO", "msg": "守护进程已启动 (PID 12345)"},
    {"ts": "2026-04-13 10:30:02", "level": "OK", "msg": "认证成功! 服务器消息: 网络连接已建立"},
    {"ts": "2026-04-13 11:00:01", "level": "WARN", "msg": "在线检测失败"},
    {"ts": "2026-04-13 11:00:01", "level": "ERROR", "msg": "认证失败! 错误信息: 账号密码错误"}
  ],
  "total": 4
}
```

---

## 故障排除

### 提示「锐捷脚本未安装」

**原因**：主仓库（ruijie-gdstvc-autologin）未安装或安装目录不对。

**解决方法**：
```bash
# 先安装主仓库
cd /etc/ruijie && sh setup.sh
```

### wget: command not found

**原因**：某些精简固件没有 wget。

**解决方法**：使用 curl 代替：
```bash
curl -LO https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh
chmod +x install.sh && sh install.sh
```

### Web 页面打不开

<details>
<summary><b>检查端口是否监听</b></summary>

```bash
netstat -tlnp | grep 8080
```

如果没有输出，说明服务未启动：
```bash
/etc/init.d/ruijie-panel start
```
</details>

<details>
<summary><b>端口被占用</b></summary>

如果 8080 端口已被占用，修改 `init.d/ruijie-panel` 中的监听端口。
</details>

<details>
<summary><b>重启后失效</b></summary>

原因：安装到了临时目录（`/www/`），重启后被清空。

**解决方法**：重新运行安装脚本，会自动选择持久化路径：
```bash
sh /tmp/install.sh
```
</details>

### 页面显示空白或排版错乱

**原因**：浏览器禁用了 JavaScript。

**解决方法**：
1. 确保浏览器未禁用 JS
2. 尝试换用 Chrome / Edge / Firefox
3. 检查浏览器控制台是否有错误

### 认证失败

如果面板显示网络离线，请检查：

1. 账号密码是否正确（可在命令行测试）
```bash
cd /etc/ruijie && ./ruijie.sh --status
```

2. 查看日志排查问题
```bash
tail -f /var/log/ruijie-daemon.log
```

### 安全注意事项

- 面板端口 **8080** 会暴露在局域网内
- 在公共 WiFi 环境下，敏感信息可能被局域网内其他设备访问
- 建议在安全的网络环境下使用，或在不使用时关闭服务：
```bash
/etc/init.d/ruijie-panel disable
```

---

## 开发者指南

### 项目结构

```
ruijie-web-panel/
├── index.html              # Web 面板主页面（单文件 SPA）
├── install.sh              # 安装脚本
├── uninstall.sh            # 卸载脚本
├── api/                    # CGI API 脚本
│   ├── common.sh           # 公共函数（JSON 转义、POST body 解析等）
│   ├── status.sh           # GET /ruijie-cgi/status
│   ├── account.sh          # GET/POST /ruijie-cgi/account
│   ├── daemon.sh           # POST /ruijie-cgi/daemon
│   ├── mode.sh             # POST /ruijie-cgi/mode
│   ├── settings.sh         # GET/POST /ruijie-cgi/settings
│   └── log.sh              # GET /ruijie-cgi/log
├── init.d/                 # OpenWrt init.d 脚本
│   └── ruijie-panel       # 服务管理脚本
├── mock/                   # 测试用 mock 数据
│   ├── server.py           # 模拟服务器
│   ├── account.json
│   ├── status.json
│   └── log.json
└── README.md
```

### 添加新 API 端点

1. 在 `api/` 目录创建新的 `.sh` 脚本：
```bash
# api/example.sh
#!/bin/sh
. "$(dirname "$0")/common.sh"

echo "Content-Type: application/json; charset=utf-8"
echo ""

# 业务逻辑
printf '{"success":true,"message":"示例"}'
```

2. 在 `index.html` 中添加前端调用：
```javascript
async function callExample() {
  return api('/example');
}
```

3. 创建 CGI 软链接（安装时自动处理）：
```bash
ln -sf api/example.sh /path/to/ruijie-web/ruijie-cgi/example
```

### 修改前端

前端代码在 `index.html` 中，使用原生 JavaScript：

- API 调用使用 `fetch()`
- 无需任何构建步骤
- 修改后直接刷新浏览器即可生效

### 测试方法

使用 mock 数据本地测试：

```bash
# 启动模拟服务器
cd mock && python3 server.py
```

---

## 版本历史

### v3.1 (2026-04)

- 初始版本
- 状态监控、账号管理、守护进程控制
- 日志查看、代理设置
- 深色模式支持
- 背景自定义功能
- OpenWrt LuCI 集成

---

## 相关项目

| 项目 | GitHub | 说明 |
|------|--------|------|
| **ruijie-gdstvc-autologin** | [链接](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin) | **主仓库** — 核心认证脚本，必须先安装 |
| Qclaw | [链接](https://github.com/qiuzhi2046/Qclaw) | OpenClaw 桌面管家（非本项目）|

---

## 许可证

MIT License

Copyright (c) 2026 huantuoshen-prog

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
