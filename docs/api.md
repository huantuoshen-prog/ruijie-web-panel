# API 文档

## 总览

- Base URL：`/ruijie-cgi`
- 鉴权：除 `/ruijie-cgi/auth` 外，其他接口都要求先登录面板
- Content-Type：`application/x-www-form-urlencoded; charset=UTF-8`
- 响应格式：JSON

## CGI 路由

| 前端路径 | 实际脚本 | 说明 |
|----------|----------|------|
| `/ruijie-cgi/auth` | `/api/auth.sh` | 登录状态 / 登录 / 退出 |
| `/ruijie-cgi/status` | `/api/status.sh` | 获取系统状态 |
| `/ruijie-cgi/account` | `/api/account.sh` | 读取 / 保存账号 |
| `/ruijie-cgi/daemon` | `/api/daemon.sh` | 守护进程控制 |
| `/ruijie-cgi/mode` | `/api/mode.sh` | 运营商切换 |
| `/ruijie-cgi/settings` | `/api/settings.sh` | 代理设置 |
| `/ruijie-cgi/log` | `/api/log.sh` | 认证日志 |
| `/ruijie-cgi/health` | `/api/health.sh` | 健康监听状态与控制 |
| `/ruijie-cgi/health-log` | `/api/health-log.sh` | 健康日志 |
| `/ruijie-cgi/runtime` | `/api/runtime.sh` | 运行环境摘要 |

## 网络架构

```text
Browser -> uhttpd(:8080) -> dist/index.html + /ruijie-cgi/* -> 主仓库 lib/*
```

## 端点说明

### `GET /ruijie-cgi/auth`

返回当前登录状态：

```json
{"success": true, "authenticated": false}
```

### `POST /ruijie-cgi/auth`

登录：

| 参数 | 说明 |
|------|------|
| `password` | 面板密码 |

退出：

| 参数 | 说明 |
|------|------|
| `action=logout` | 退出登录 |

### `GET /ruijie-cgi/status`

返回系统状态：

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

### `GET /ruijie-cgi/account`

读取当前账号信息。

### `POST /ruijie-cgi/account`

| 参数 | 说明 |
|------|------|
| `username` | 用户名 |
| `password` | 密码 |
| `operator` | `DianXin` / `LianTong` |

### `POST /ruijie-cgi/daemon`

| 参数 | 说明 |
|------|------|
| `action` | `start` / `stop` / `restart` |

### `POST /ruijie-cgi/mode`

| 参数 | 说明 |
|------|------|
| `operator` | `DianXin` / `LianTong` |

### `GET /ruijie-cgi/settings`

读取代理设置。

### `POST /ruijie-cgi/settings`

| 参数 | 说明 |
|------|------|
| `proxy_url` | HTTP 代理 |
| `proxy_url_https` | HTTPS 代理 |

### `GET /ruijie-cgi/log`

读取认证日志。

查询参数：

| 参数 | 说明 |
|------|------|
| `lines` | 最近 N 条 |
| `level` | 级别过滤 |

### `GET /ruijie-cgi/health`

返回健康监听状态、剩余时间和快照。

### `POST /ruijie-cgi/health`

| 参数 | 说明 |
|------|------|
| `action` | `enable` / `disable` |
| `duration` | `1d` / `3d` / `7d` / `permanent` |

### `GET /ruijie-cgi/health-log`

读取健康日志。

查询参数：

| 参数 | 说明 |
|------|------|
| `lines` | 最近 N 条 |
| `level` | 级别过滤 |
| `type` | 类型过滤，如 `baseline`、`auth_failed` |

### `GET /ruijie-cgi/runtime`

读取运行环境摘要。
