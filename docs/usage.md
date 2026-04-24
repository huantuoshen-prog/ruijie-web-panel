# 使用文档

## 登录

安装脚本会初始化一个独立的面板密码。打开页面后，先输入这个密码完成登录。

如果需要重置密码：

```bash
rm -f /etc/ruijie-panel/auth.conf
```

然后重新运行安装脚本。

## 页面功能

### 总览

- 在线 / 离线状态
- daemon PID、运行时长、状态机状态
- 最后认证时间
- 健康监听是否开启、剩余时间、collector 是否活跃

### 账号

- 修改用户名
- 修改密码
- 切换运营商（电信 / 联通）

### 守护进程

- 启动 daemon
- 停止 daemon
- 重启 daemon
- 开启健康监听 `1天 / 3天 / 7天 / 永久`
- 手动关闭健康监听

### 日志

- 在认证日志和健康日志之间切换
- 按级别过滤
- 健康日志按类型过滤
- 自动刷新和暂停刷新

### 设置

- 配置 HTTP / HTTPS 代理
- 切换深色 / 浅色主题
- 上传 / 删除背景图
- 查看运行环境摘要

## 健康监听联动

如果主仓库版本支持健康监听，面板会额外显示：

- 健康监听是否已开启
- 剩余窗口时长
- 采样是否活跃
- 健康日志
- 运行环境（平台、shell、nohup backend、路径等）

如果主脚本版本过旧，面板会提示升级，而不是假装这些数据存在。

## 背景与主题

### 主题

- 可切换深色 / 浅色主题
- 主题选择会保存在浏览器本地

### 背景图

- 支持上传背景图
- 文件保存在浏览器本地存储
- 最大 20MB
- 可临时关闭或删除

## 常用运维命令

```bash
/etc/init.d/ruijie-panel start
/etc/init.d/ruijie-panel stop
/etc/init.d/ruijie-panel restart
/etc/init.d/ruijie-panel reload
/etc/init.d/ruijie-panel enable
/etc/init.d/ruijie-panel disable
```
