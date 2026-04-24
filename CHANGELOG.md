# Changelog - Ruijie Web Panel

## Unreleased

### Added
- 重构为 React + Vite + TypeScript 控制台前端
- 新增健康监听控制、健康日志查看和运行环境摘要
- 新增 `docs/install.md`、`docs/usage.md`、`docs/api.md`、`docs/troubleshooting.md`、`docs/development.md`

### Changed
- README 调整为首页导航，不再承载完整安装和 API 手册
- API 路径文档统一迁到 `docs/api.md`
- 安装流程默认部署 `dist/` 产物和新的 CGI 路由

## v3.1 (2026-04)

- 初始版本
- 状态监控、账号管理、守护进程控制
- 日志查看、代理设置
- 深色模式支持
- 背景自定义功能
- OpenWrt LuCI 集成
