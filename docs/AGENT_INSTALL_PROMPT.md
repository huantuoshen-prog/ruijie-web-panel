# Ruijie Web Panel Agent Install Prompt

这份文档提供一套可直接复制给通用 Agent 使用的安装 Prompt，用来协助安装 `ruijie-web-panel`。

## 适用场景

- 你已经想用 Web 面板管理锐捷脚本
- 你希望 Agent 先检查主仓库是否安装完成，再决定是否继续安装面板
- 你希望 Agent 自动走最短安装路径，并在安装后做页面与服务验证

这个 Prompt 默认假设面板部署在路由器上，而不是本地电脑。Agent 不应该拿本地电脑的 `/etc/ruijie`、`/etc/ruijie-panel`、`/overlay/usr/www` 来判断路由器上的真实状态。

## 前置条件检查

这个面板不是独立产品，安装前必须满足：

- 主仓库 `ruijie-gdstvc-autologin` 已安装
- 主脚本已完成基本配置
- 当前环境是 OpenWrt / iStoreOS / ImmortalWrt 这类路由器终端

如果这些条件还没满足，请先使用主仓库安装 Prompt：
[ruijie-gdstvc-autologin / AGENT_INSTALL_PROMPT.md](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin/blob/main/docs/AGENT_INSTALL_PROMPT.md)

如果 Agent 当前不在路由器终端，就不要直接读取这些路径；应先让我切到路由器 SSH / TTYD 终端，或明确要求一个可用 SSH 目标。

## 精简安装 Prompt

适合大多数场景：

```text
你正在帮助我安装锐捷认证 Web 管理面板。

仓库：
https://github.com/huantuoshen-prog/ruijie-web-panel

安装文档：
https://github.com/huantuoshen-prog/ruijie-web-panel/blob/main/docs/install.md

主仓库安装 Prompt：
https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin/blob/main/docs/AGENT_INSTALL_PROMPT.md

请先检查：
- 当前会话是不是直接运行在 OpenWrt / iStoreOS / ImmortalWrt 路由器终端
- 如果不是，是否已经拿到可用 SSH 目标
- 只有在路由器上，才检查 `/etc/ruijie/ruijie.sh` 是否存在、主脚本是否已经基本可用

执行要求：
- 不要用本地电脑上的 `/etc/ruijie`、`/etc/ruijie-panel`、`/overlay/usr/www` 来推断路由器状态
- 如果你当前不是路由器终端，也没有远程执行能力，就先让我进入路由器 SSH / TTYD 终端，再继续
- 如果主仓库没装好，停止面板安装，并明确提示我先走主仓库安装 Prompt
- 如果主仓库已具备条件，优先使用自动安装脚本
- 只有自动安装不可用时，才切换到手动安装或 USB 安装
- 安装完成后必须验证访问地址、服务状态和面板密码初始化结果

请按下面格式告诉我：
- 前置条件检查结果
- 实际执行的命令
- 面板访问地址
- 面板密码初始化结果
- 安装后验证结果
```

## 完整安装 Prompt

适合希望 Agent 更完整接手时使用：

```text
你是一个负责 OpenWrt 路由器安装任务的工程 Agent。目标是帮我安装锐捷认证 Web 管理面板，而不是只给出一个下载命令。

先读取并遵循以下仓库信息：

- 面板仓库：https://github.com/huantuoshen-prog/ruijie-web-panel
- 面板安装文档：https://github.com/huantuoshen-prog/ruijie-web-panel/blob/main/docs/install.md
- 主仓库安装 Prompt：https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin/blob/main/docs/AGENT_INSTALL_PROMPT.md

工作要求：

1. 先确认当前会话是不是路由器终端，而不是普通电脑终端。
   - 如果当前会话不是路由器终端，不要直接运行本地 `/etc/ruijie/ruijie.sh`、`test -f /etc/ruijie/ruijie.sh` 之类的命令
   - 先让我切到路由器 SSH / TTYD 终端，或要求我提供一个可用 SSH 目标
   - 如果你具备远程执行能力，再通过 SSH 在路由器上执行后续命令

2. 前置检查必须在路由器上执行：
   - `test -f /etc/ruijie/ruijie.sh`
   - `/etc/ruijie/ruijie.sh --status`
   - 如果主脚本不存在或未完成基本配置，停止继续安装，并明确要求我先完成主仓库安装

3. 如果前置条件满足，优先使用自动安装脚本：
   - `wget -O /tmp/install.sh https://raw.githubusercontent.com/huantuoshen-prog/ruijie-web-panel/main/install.sh`
   - `chmod +x /tmp/install.sh && sh /tmp/install.sh`
   - 如果当前环境没有 `wget`，再改用 `curl`

4. 只有自动安装失败或当前路径不适合时，才切换到手动安装或 USB 安装路径；不要一开始就走长路径。

5. 安装完成后必须做验证：
   - 检查 `/etc/ruijie-panel/auth.conf` 是否存在
   - 检查面板文件目录是否存在：`/overlay/usr/www/ruijie-web`、`/mnt/sda1/ruijie-web` 或 `/www/ruijie-web`
   - 启动或重载面板服务：`/etc/init.d/ruijie-panel start`
   - 读取路由器 LAN IP：`uci get network.lan.ipaddr`
   - 优先使用 `curl -s http://127.0.0.1:8080/ruijie-cgi/auth` 检查接口是否可访问；如果没有 `curl`，再改用 `wget -qO-`

6. 输出要求：
   - 先给出前置条件检查结果
   - 再给出实际执行的命令
   - 再给出面板访问地址
   - 再说明面板密码是“新初始化”还是“保留了已有配置”
   - 最后给出安装后验证结论

限制：
- 不要把主仓库未安装的问题伪装成面板安装问题
- 不要要求我重复提供文档里已有的安装步骤
- 不要把本地电脑上的文件系统结果当成路由器状态
- 不要把排障内容塞进安装流程；如果已经安装但运行异常，请单独指出那是排障问题
```

## 安装后验证 Prompt

如果 Agent 已经安装完面板，你只想让它做验证，可以单独复制这一段：

```text
你已经完成锐捷 Web 面板安装。现在只做安装后验证，不要继续泛泛解释。

如果你当前不在路由器终端：
- 不要直接读取本地电脑上的 `/etc/ruijie`、`/etc/ruijie-panel`、`/overlay/usr/www`
- 先让我切到路由器 SSH / TTYD 终端，或要求我提供可用 SSH 目标

请执行并检查：
1. `test -f /etc/ruijie/ruijie.sh`
2. `test -f /etc/ruijie-panel/auth.conf`
3. 检查 Web 根目录是否存在：`/overlay/usr/www/ruijie-web`、`/mnt/sda1/ruijie-web` 或 `/www/ruijie-web`
4. `/etc/init.d/ruijie-panel start`
5. `uci get network.lan.ipaddr`
6. 优先运行 `curl -s http://127.0.0.1:8080/ruijie-cgi/auth`；如果没有 curl，就改用 `wget -qO-`

请只输出：
1. 主脚本前置条件是否满足
2. 面板文件是否已经部署
3. 面板密码文件是否存在
4. 面板访问地址
5. `/ruijie-cgi/auth` 是否返回可用 JSON
6. 如果不是安装问题，而是后续使用或排障问题，请明确指出
```

## 与主仓库的依赖关系

- `ruijie-web-panel` 依赖 `ruijie-gdstvc-autologin`
- 主脚本没装好时，不应继续尝试面板安装
- 主脚本安装与基础配置，应该优先交给主仓库的安装 Prompt

主仓库安装 Prompt：
[ruijie-gdstvc-autologin / AGENT_INSTALL_PROMPT.md](https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin/blob/main/docs/AGENT_INSTALL_PROMPT.md)
