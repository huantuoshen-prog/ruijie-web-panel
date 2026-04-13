# 锐捷认证 Web 管理面板

> 锐捷认证脚本的可选图形管理界面。在浏览器里管理账号、守护进程和日志，无需敲命令。

**本面板是 [ruijie-gdstvc-autologin](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin)（主仓库）的扩展，需要先完成主仓库的安装配置后才能使用。**

---

## 效果预览

```
┌─────────────────────────────────────────────────────────┐
│  锐捷认证 Web 管理面板                              v3.1  │
│  广东科学技术职业学院 · 校园网认证                             │
├─────────────────────────────────────────────────────────┤
│  [状态]  [账号]  [守护进程]  [日志]  [设置]                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  网络状态                守护进程                          │
│  ┌──────────────┐        ┌──────────────┐                │
│  │  ● 已连接   │        │  ● 运行中    │  PID 1234    │
│  │  在线 4h 23m │        │  ONLINE      │                │
│  └──────────────┘        └──────────────┘                │
│                                                          │
│  账号: 1720240564  运营商: 电信  最后认证: 2 分钟前        │
│                                                          │
│  [▶ 启动]  [■ 停止]  [↻ 重启]  [⟳ 刷新]                   │
└─────────────────────────────────────────────────────────┘
        访问地址: http://路由器IP:8080/
```

---

## 网络架构

```
                    你的电脑 / 手机
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

## 功能一览

| 页面 | 功能 |
|------|------|
| **状态** | 实时在线/离线、守护进程状态、最后认证时间 |
| **账号** | 修改学号、密码、运营商（电信/联通） |
| **守护进程** | 启动 / 停止 / 重启，查看 PID、运行时间、状态机 |
| **日志** | 查看认证日志，支持按级别（INFO / OK / 警告 / 错误）过滤 |
| **设置** | 配置 HTTP / HTTPS 代理 |

---

## 安装前提

> ⚠️ 请按顺序完成，缺少任一步骤面板将无法正常使用

- [x] 路由器已刷 **OpenWrt / iStoreOS / ImmortalWrt** 等衍生固件
- [x] 路由器 WAN 口已连接校园网（墙壁网线）
- [x] **已完成锐捷认证脚本安装配置**（运行过 `setup.sh`）

> **不知道如何进路由器终端？** 请先阅读 [主仓库 README - 进入路由器终端](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin#方式-a通过-web-后台适合大多数用户)

---

## 安装步骤

> 以下命令在**路由器终端**里运行，不是你自己的电脑！

### 第一步：下载安装脚本

```bash
wget -O /tmp/install.sh \
  https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh
```

### 第二步：运行安装

```bash
chmod +x /tmp/install.sh && sh /tmp/install.sh
```

安装脚本会自动：
- 复制 Web 文件到持久化存储路径（`/overlay/` 或 USB）
- 注册系统服务到 LuCI「服务」菜单
- 启动面板并输出访问地址

### 第三步：打开浏览器

```
http://192.168.5.1:8080/
```

> 路由器 IP 不一定是 `192.168.5.1`，常见还有：
> - `192.168.1.1` — OpenWrt 默认
> - `192.168.31.1` — 小米路由器
>
> 看路由器背面或管理页面地址栏确认。**注意**：面板使用端口 **8080**，需要带上 `:8080`。

### 第四步（可选）：通过 LuCI 后台访问

安装后，面板会出现在路由器后台的「服务」菜单中：

```
LuCI → 服务 → 锐捷 Web 管理面板 → 打开
```

---

## 服务管理

面板作为 OpenWrt 系统服务运行，支持完整控制：

```bash
# 启动
/etc/init.d/ruijie-panel start

# 停止
/etc/init.d/ruijie-panel stop

# 重启
/etc/init.d/ruijie-panel restart

# 开启开机自启（安装后默认已开启）
/etc/init.d/ruijie-panel enable

# 关闭开机自启
/etc/init.d/ruijie-panel disable

# 检查是否已启用
/etc/init.d/ruijie-panel enabled
```

---

## 常见问题

**提示"锐捷脚本未安装"**

面板需要锐捷认证脚本已完成配置。请先在路由器终端运行：

```bash
cd /etc/ruijie && sh setup.sh
```

**提示"wget: command not found"**

某些精简固件没有 wget，改用 curl：

```bash
curl -LO https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh
chmod +x install.sh && sh install.sh
```

**Web 页面打不开**

```bash
# 检查端口是否监听
netstat -tlnp | grep 8080

# 重启 Web 服务
/etc/init.d/uhttpd restart

# 确认文件存在
ls /overlay/usr/www/ruijie-web/
```

**页面显示空白或排版错乱**

本面板需要 JavaScript 支持。请确认浏览器没有禁用 JS，或尝试换用 Chrome / Edge。

**重启路由器后页面打不开**

原因：安装到了临时目录（`/www/`），重启后被清空。

```bash
# 重新运行安装脚本（会使用持久化路径）
sh /tmp/install.sh
```

---

## 卸载

```bash
# 路径根据安装位置选择其一
sh /overlay/usr/www/ruijie-web/uninstall.sh
# 或
sh /mnt/sda1/ruijie-web/uninstall.sh
```

卸载脚本会自动停止服务、删除文件、清理配置。

---

## 技术说明

| 项目 | 说明 |
|------|------|
| 后端 | Shell CGI，每个 API 一个独立脚本，返回 JSON |
| 前端 | 纯 HTML + Vanilla JS，单文件，无任何外部依赖 |
| 部署路径 | `/overlay/usr/www/ruijie-web/`（持久化，重启不丢失） |
| CGI 路径 | `/ruijie-cgi/`（由 uhttpd 路由） |
| 服务脚本 | `/etc/init.d/ruijie-panel`（注册到 LuCI「服务」菜单） |
| 必要依赖 | uhttpd（大多数固件自带）+ [ruijie-gdstvc-autologin](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin) |

---

## 相关项目

| 项目 | 说明 |
|------|------|
| [ruijie-gdstvc-autologin](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin) | **主仓库** — 核心认证脚本，支持命令行管理 |
| ruijie-web-panel（本仓库） | **从仓库** — Web 图形管理界面，依赖主仓库 |
