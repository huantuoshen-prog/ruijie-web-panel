# 故障排除

## 提示“锐捷脚本未安装”

原因：主仓库未安装或安装目录不正确。

解决：

```bash
cd /etc/ruijie && sh setup.sh
```

## `wget: command not found`

使用 `curl`：

```bash
curl -LO https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh
chmod +x install.sh && sh install.sh
```

## 页面打不开

先看端口：

```bash
netstat -tlnp | grep 8080
```

如果没监听：

```bash
/etc/init.d/ruijie-panel start
```

如果装在临时目录，重启后可能会失效，重新安装到持久化路径即可。

## 页面空白或排版错乱

优先检查：

1. 浏览器是否禁用了 JavaScript
2. 是否使用了过旧浏览器
3. 浏览器控制台是否有错误

## 认证失败

如果面板显示离线：

```bash
cd /etc/ruijie
./ruijie.sh --status
tail -f /var/log/ruijie-daemon.log
```

## 健康监听不可用

如果面板提示主脚本版本过低，说明主仓库还没升级到支持健康监听的版本。先升级主仓库，再刷新面板。

## 安全注意事项

- 面板监听在 `8080` 端口
- 所有管理接口都要求先登录面板
- 面板密码与主脚本账号密码是两套独立信息
- 不用时可以关闭服务：

```bash
/etc/init.d/ruijie-panel disable
```
