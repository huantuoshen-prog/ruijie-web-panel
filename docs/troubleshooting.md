# 故障排除

## 提示“锐捷脚本未安装”

原因：主仓库未安装或安装目录不正确。

解决：

```bash
/etc/ruijie/ruijiectl runtime
```

## 下载或安装失败

只使用 GitHub Release 中的完整组合包。不要下载单独的 `install.sh`，因为安装器会拒绝缺少清单和配套文件的目录。

```bash
curl -fLO https://github.com/huantuoshen-prog/ruijie-web-panel/releases/download/v4.0.0/ruijie-openwrt-bundle.tar.gz
curl -fLO https://github.com/huantuoshen-prog/ruijie-web-panel/releases/download/v4.0.0/SHA256SUMS
grep ' ruijie-openwrt-bundle.tar.gz$' SHA256SUMS | sha256sum -c -
```

完整解压和安装步骤见 [安装文档](./install.md)。安装器不会自动修改 `opkg` 软件源；缺少依赖时请按固件自己的软件源配置处理。

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
/etc/ruijie/ruijiectl status
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
