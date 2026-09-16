# Changelog - Ruijie Web Panel

## v4.0.0 (2026-09-16)

### Added
- 重构为 React + Vite + TypeScript 控制台前端
- 新增健康监听控制、健康日志查看和运行环境摘要
- 新增 `docs/install.md`、`docs/usage.md`、`docs/api.md`、`docs/troubleshooting.md`、`docs/development.md`
- 新增固定版本组合包、逐文件校验、升级失败自动恢复与手动回滚
- 新增独立面板密码、会话保护、登录限速和请求大小限制

### Changed
- README 调整为首页导航，不再承载完整安装和 API 手册
- API 路径文档统一迁到 `docs/api.md`
- 安装流程默认部署 `dist/` 产物和新的 CGI 路由
- 仅支持 OpenWrt 系固件，并保留升级前的服务启用与运行状态

## v3.1 (2026-04)

- 初始版本
- 状态监控、账号管理、守护进程控制
- 日志查看、代理设置
- 深色模式支持
- 背景自定义功能
- OpenWrt LuCI 集成
