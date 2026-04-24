# 锐捷认证 Web 管理面板

> 锐捷认证脚本的可选图形界面，在浏览器里管理账号、守护进程、日志和健康监听。

[![CI](https://github.com/huantuoshen-prog/ruijie-web-panel/actions/workflows/ci.yml/badge.svg)](https://github.com/huantuoshen-prog/ruijie-web-panel/actions)
[![版本](https://img.shields.io/badge/version-v3.1-blue)](https://github.com/huantuoshen-prog/ruijie-web-panel)

**本仓库依赖主仓库 [ruijie-gdstvc-autologin](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin)。请先安装并配置主脚本，再安装这个面板。**

## 快速入口

- [3 步安装](#快速开始)
- [功能概览](#功能概览)
- [安装文档](./docs/install.md)
- [Agent 安装 Prompt](./docs/AGENT_INSTALL_PROMPT.md)
- [使用文档](./docs/usage.md)
- [API 文档](./docs/api.md)
- [故障排除](./docs/troubleshooting.md)
- [开发者文档](./docs/development.md)
- [更新记录](./CHANGELOG.md)
- [主仓库 Agent 调试 Prompt](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin/blob/main/docs/AGENT_DEBUG_PROMPT.md)

## 项目简介

这个面板适合：

- 不想频繁敲命令、希望在浏览器里查看状态的人
- 想在路由器后台直接管理锐捷账号和守护进程的人
- 想查看健康监听、健康日志和运行环境摘要的人

核心特点：

- React + Vite + TypeScript 构建式前端
- Shell CGI 后端，直接跑在 OpenWrt 上
- 独立面板密码和会话保护
- 适配桌面端与移动端
- 支持健康监听、健康日志和运行环境可视化

## 给 Agent 安装 / 排障

- 让 Agent 帮你在路由器上安装面板： [docs/AGENT_INSTALL_PROMPT.md](./docs/AGENT_INSTALL_PROMPT.md)
- 主脚本还没装好： [主仓库安装 Prompt](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin/blob/main/docs/AGENT_INSTALL_PROMPT.md)
- 已安装后让 Agent 排障： [主仓库调试 Prompt](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin/blob/main/docs/AGENT_DEBUG_PROMPT.md)

## 快速开始

### 3 步安装

```bash
wget -O /tmp/install.sh \
  https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh
chmod +x /tmp/install.sh && sh /tmp/install.sh
```

安装完成后：

1. 记住安装脚本初始化的面板密码
2. 浏览器访问 `http://路由器IP:8080/`
3. 登录后进入总览页面

常见路由器地址：

- `http://192.168.5.1:8080/`
- `http://192.168.1.1:8080/`

如果你想看手动安装、路径说明、服务注册和卸载：
[docs/install.md](./docs/install.md)

## 功能概览

| 页面 | 能力 |
|------|------|
| 总览 | 在线状态、daemon 状态、最后认证时间、健康监听摘要 |
| 账号 | 修改用户名、密码、运营商 |
| 守护进程 | 启动 / 停止 / 重启 daemon，控制健康监听窗口 |
| 日志 | 查看认证日志与健康日志，按级别和类型过滤 |
| 设置 | 代理、主题、背景图、运行环境摘要 |

额外说明：

- 健康监听需要主仓库升级到支持版本后才能使用
- 主脚本首次安装后默认开启 3 天健康监听；后续升级不会自动重开
- 如果你想把当前状态直接交给 Agent 分析，可以使用主仓库的现成 Prompt：
  [AGENT_DEBUG_PROMPT.md](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin/blob/main/docs/AGENT_DEBUG_PROMPT.md)

## 深入阅读

| 文档 | 说明 |
|------|------|
| [docs/install.md](./docs/install.md) | 系统要求、自动 / 手动 / USB 安装、服务注册、卸载 |
| [docs/AGENT_INSTALL_PROMPT.md](./docs/AGENT_INSTALL_PROMPT.md) | 给通用 Agent 的现成安装 Prompt |
| [docs/usage.md](./docs/usage.md) | 页面功能、健康监听控制、日志、主题与背景 |
| [docs/api.md](./docs/api.md) | `/ruijie-cgi/*` 路由、鉴权与请求/响应示例 |
| [docs/troubleshooting.md](./docs/troubleshooting.md) | 安装失败、页面打不开、认证问题、安全注意事项 |
| [docs/development.md](./docs/development.md) | 项目结构、本地 mock、API 扩展与前端测试 |
| [CHANGELOG.md](./CHANGELOG.md) | 面板版本历史 |

## 相关项目

| 项目 | GitHub | 说明 |
|------|--------|------|
| **ruijie-gdstvc-autologin** | [链接](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin) | 主仓库，核心认证脚本 |
| Qclaw | [链接](https://github.com/qiuzhi2046/Qclaw) | OpenClaw 桌面管家（非本项目） |

## 许可证

本项目使用 MIT 许可证。
完整文本见 [LICENSE](./LICENSE)。
