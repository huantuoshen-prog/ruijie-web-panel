# 仓库维护文档

## 仓库基本信息

| 项目 | 内容 |
|------|------|
| **仓库名称** | ruijie-web-panel |
| **GitHub URL** | https://github.com/huantuoshen-prog/ruijie-web-panel |
| **描述** | 锐捷认证脚本的可选图形管理界面，在浏览器里管理账号、守护进程和日志 |
| **当前版本** | v3.1 |
| **维护者** | huantuoshen-prog |
| **编程语言** | Shell CGI + HTML + Vanilla JavaScript |
| **许可证** | MIT |
| **依赖** | [ruijie-gdstvc-autologin](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin)（必须先安装） |

---

## 功能概述

### 核心功能
| 页面 | 功能 |
|------|------|
| **状态** | 实时在线/离线状态、守护进程 PID/运行时间、最后认证时间 |
| **账号** | 修改学号、密码、运营商（电信/联通） |
| **守护进程** | 启动 / 停止 / 重启，查看状态机当前状态 |
| **日志** | 查看认证日志，支持按级别（INFO/OK/警告/错误）过滤 |
| **设置** | 配置 HTTP / HTTPS 代理 |

### 技术特点
- **纯前端**: 纯 HTML + Vanilla JS，单文件，无任何外部依赖
- **轻量后端**: Shell CGI，每个 API 一个独立脚本，返回 JSON
- **原生集成**: 注册到 OpenWrt LuCI「服务」菜单

---

## 技术架构

### 项目结构
```
ruijie-web-panel/
├── index.html              # Web 面板主页面（单文件 SPA）
├── install.sh              # 安装脚本
├── uninstall.sh            # 卸载脚本
├── api/                    # CGI API 脚本
│   ├── common.sh           # 公共函数（JSON 转义、POST body 解析等）
│   ├── status.sh           # GET /ruijie-cgi/status → 系统状态
│   ├── account.sh          # GET/POST /ruijie-cgi/account → 账号管理
│   ├── daemon.sh           # POST /ruijie-cgi/daemon → 守护进程控制
│   ├── mode.sh             # 账号类型切换
│   ├── settings.sh         # 代理设置
│   └── log.sh              # 日志读取
├── init.d/
│   └── ruijie-panel        # OpenWrt init.d 服务脚本
└── mock/                   # 模拟数据（开发测试用）
    ├── server.py           # 模拟服务器
    ├── account.json         # 模拟账号数据
    ├── status.json         # 模拟状态数据
    └── log.json            # 模拟日志数据
```

### API 接口列表

| 端点 | 方法 | 说明 | 返回 |
|------|------|------|------|
| `/ruijie-cgi/status` | GET | 获取系统状态 | JSON: installed, online, username, daemon_running, daemon_pid, daemon_state, last_auth, version |
| `/ruijie-cgi/account` | GET | 读取账号信息（密码脱敏） | JSON: username, password(掩码), operator, account_type, proxy_url |
| `/ruijie-cgi/account` | POST | 保存账号信息 | JSON: success, message |
| `/ruijie-cgi/daemon` | POST | 守护进程控制 | JSON: success, pid, message |
| `/ruijie-cgi/log` | GET | 读取日志 | JSON: logs[], level filter |
| `/ruijie-cgi/settings` | GET/POST | 代理设置 | JSON |

### CGI 路由配置
- Web 根目录: `/overlay/usr/www/ruijie-web/`（持久化）
- CGI 路径: `/ruijie-cgi/`（由 uhttpd 路由）
- 服务脚本: `/etc/init.d/ruijie-panel`

### 状态机状态说明

| 状态 | 说明 |
|------|------|
| `ONLINE` | 在线，正常运行中，每 600s 检测一次 |
| `CHECKING` | 正在尝试验证认证 |
| `RETRYING` | 认证失败，指数退避重试中（30s→60s→120s→300s） |
| `WAIT_LONG` | 长时间离线，每 300s 重试一次 |

---

## 安装与部署

### 前置条件
1. 路由器已刷 **OpenWrt / iStoreOS / ImmortalWrt** 等衍生固件
2. 路由器 WAN 口已连接校园网
3. **已完成锐捷认证脚本安装配置**（运行过 `setup.sh`）

### 安装步骤

**第一步：下载安装脚本**
```bash
wget -O /tmp/install.sh \
  https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh
```

**第二步：运行安装**
```bash
chmod +x /tmp/install.sh && sh /tmp/install.sh
```

安装脚本会自动：
- 复制 Web 文件到持久化存储路径（`/overlay/` 或 USB）
- 注册系统服务到 LuCI「服务」菜单
- 启动面板并输出访问地址

**第三步：打开浏览器**
```
http://192.168.5.1:8080/
```
> 注意：路由器 IP 可能不是 `192.168.5.1`，常见还有 `192.168.1.1`、`192.168.31.1`

### 服务管理命令
```bash
/etc/init.d/ruijie-panel start    # 启动
/etc/init.d/ruijie-panel stop     # 停止
/etc/init.d/ruijie-panel restart  # 重启
/etc/init.d/ruijie-panel enable   # 开启开机自启
/etc/init.d/ruijie-panel disable  # 关闭开机自启
/etc/init.d/ruijie-panel enabled  # 检查是否已启用
```

### 卸载
```bash
sh /overlay/usr/www/ruijie-web/uninstall.sh
# 或
sh /mnt/sda1/ruijie-web/uninstall.sh
```

---

## 网络架构

```
                    用户电脑 / 手机
                      浏览器打开
                    http://路由器IP:8080/
                              │
                              │ WiFi / 有线
                              ▼
                    ┌──────────────────┐
                    │ OpenWrt / iStoreOS│
                    │                  │
                    │  ┌────────────┐   │
                    │  │ Web 面板   │   │
                    │  │ (:8080)   │   │
                    │  └─────┬──────┘   │
                    │        │ CGI     │
                    │  ┌─────▼──────┐   │
                    │  │ ruijie.sh  │   │
                    │  └─────┬──────┘   │
                    └────────┼───────────┘
                             │ 校园网认证
                             ▼
                    ┌──────────────────┐
                    │  锐捷认证服务器   │
                    └──────────────────┘
```

---

## 前端页面结构

### 状态页
- 网络连接状态卡片（在线/离线指示）
- 守护进程状态卡片（PID、运行时间、状态机状态）
- 账号信息摘要
- 操作按钮：启动、停止、重启、刷新

### 账号页
- 用户名输入框
- 密码输入框
- 运营商选择（电信/联通）
- 保存按钮

### 守护进程页
- 当前状态显示
- PID 和运行时间
- 状态机当前状态
- 启动/停止/重启按钮

### 日志页
- 日志内容显示区
- 级别过滤器（全部/INFO/OK/警告/错误）
- 刷新按钮

### 设置页
- HTTP 代理输入框
- HTTPS 代理输入框
- 不走代理的地址列表
- 保存按钮

---

## 与主仓库的关系

| 项目 | GitHub URL | 说明 |
|------|------------|------|
| **ruijie-gdstvc-autologin** | https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin | **主仓库** — 核心认证脚本 |
| ruijie-web-panel（本仓库） | https://github.com/huantuoshen-prog/ruijie-web-panel | **从仓库** — Web 管理界面 |

### 数据流
1. Web 面板通过 CGI 调用 `api/*.sh` 脚本
2. API 脚本加载 `ruijie.sh` 的 lib 模块
3. lib 模块读写配置文件 `~/.config/ruijie/ruijie.conf`
4. 通过守护进程状态文件 `/var/run/ruijie-daemon.*` 获取运行时状态

---

## 常见问题排查

### 提示"锐捷脚本未安装"
```
面板需要锐捷认证脚本已完成配置。请先在路由器终端运行：
cd /etc/ruijie && sh setup.sh
```

### 提示"wget: command not found"
```bash
curl -LO https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh
chmod +x install.sh && sh install.sh
```

### Web 页面打不开
```bash
# 检查端口是否监听
netstat -tlnp | grep 8080

# 重启 Web 服务
/etc/init.d/uhttpd restart

# 确认文件存在
ls /overlay/usr/www/ruijie-web/
```

### 页面显示空白或排版错乱
本面板需要 JavaScript 支持。请确认浏览器没有禁用 JS，或尝试换用 Chrome / Edge。

### 重启路由器后页面打不开
原因：安装到了临时目录（`/www/`），重启后被清空。
```bash
# 重新运行安装脚本（会使用持久化路径）
sh /tmp/install.sh
```

---

## 安装脚本详解

### install.sh 主要功能
1. **检测 OpenWrt 环境**: 检查 `/etc/openwrt_release` 或 `ubus` 命令
2. **确定安装路径**: 优先使用 `/overlay/usr/www/ruijie-web/`（持久化）
3. **复制文件**: index.html, api/, init.d/
4. **注册服务**: `/etc/init.d/ruijie-panel enable`
5. **配置 uhttpd**: 添加 CGI 路由 `/ruijie-cgi/`

### 路径持久化策略
- **优先**: `/overlay/usr/www/` — 重启不丢失
- **备选**: USB 存储 `/mnt/sda1/`
- **临时**: `/www/` — 不推荐，重启清空

---

## API 响应格式

### status 接口响应
```json
{
  "installed": true,
  "online": true,
  "username": "1720240564",
  "operator": "DianXin",
  "account_type": "student",
  "daemon_running": true,
  "daemon_pid": "1234",
  "daemon_uptime": "4小时23分钟",
  "daemon_state": "ONLINE",
  "last_auth": "2026-04-13 10:30:00",
  "version": "3.1",
  "message": ""
}
```

### account 接口响应 (GET)
```json
{
  "username": "1720240564",
  "password": "********",
  "operator": "DianXin",
  "account_type": "student",
  "proxy_url": ""
}
```

### daemon 接口响应
```json
{
  "success": true,
  "pid": "1234",
  "message": "守护进程已启动"
}
```

---

## 开发指南

### 添加新的 API 端点
1. 在 `api/` 目录创建新的 `.sh` 脚本
2. 参考现有 API 的结构（common.sh 引入、Content-Type 设置）
3. 使用 `find_ruijie_dir()` 函数定位 ruijie 脚本目录
4. 加载必要的 lib 模块
5. 返回 JSON 格式响应

### 修改 Web 界面
- 编辑 `index.html`
- 使用原生 `fetch()` 调用 CGI API
- 无需任何构建步骤

### 测试
- 使用 `mock/` 目录下的模拟数据进行开发测试
- `mock/server.py` 可启动本地模拟服务器

---

## CI/CD

### GitHub Actions 工作流
- **触发条件**:
  - push 到 `main` 或 `develop` 分支
  - PR 合并到 `main` 分支
- **检查项目**:
  1. ShellCheck lint（所有 Shell 脚本，错误级别）
  2. HTML 验证（检查 index.html 是否存在）

### CI 环境要求
- **Runner**: Ubuntu Latest
- **依赖**: ShellCheck

---

## 版本历史

### v3.1 (2026-04)
- 初始版本
- 状态监控、账号管理、守护进程控制
- 日志查看、代理设置
- OpenWrt LuCI 集成

---

## 联系方式

- **GitHub Issues**: https://github.com/huantuoshen-prog/ruijie-web-panel/issues
- **主仓库 Issues**: https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin/issues
