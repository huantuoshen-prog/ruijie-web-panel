import { useEffect, useEffectEvent, useState } from "react";
import { ApiError, panelApi } from "./api";
import type {
  HealthDuration,
  HealthStatusResponse,
  LogLevel,
  LogLine,
  RuntimeStatusResponse,
  StatusResponse
} from "./types";

export type AuthPhase = "checking" | "authenticated" | "unauthenticated";
export type NoticeTone = "info" | "success" | "warning" | "error";
export type LogSource = "daemon" | "health";

export interface Notice {
  tone: NoticeTone;
  message: string;
}

export interface AccountForm {
  username: string;
  password: string;
  operator: string;
  accountType: string;
}

export interface SettingsForm {
  proxyUrl: string;
  proxyUrlHttps: string;
}

export function errorText(error: unknown, fallback: string): string {
  if (error instanceof Error && error.message) {
    return error.message;
  }
  return fallback;
}

// 面板的全部状态与后端交互集中在这里，页面组件只负责展示。
export function usePanel() {
  const [authPhase, setAuthPhase] = useState<AuthPhase>("checking");
  const [loginError, setLoginError] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [notice, setNotice] = useState<Notice | null>(null);
  const [status, setStatus] = useState<StatusResponse | null>(null);
  const [health, setHealth] = useState<HealthStatusResponse | null>(null);
  const [runtime, setRuntime] = useState<RuntimeStatusResponse | null>(null);
  const [account, setAccount] = useState<AccountForm>({
    username: "",
    password: "",
    operator: "DianXin",
    accountType: "student"
  });
  const [settings, setSettings] = useState<SettingsForm>({ proxyUrl: "", proxyUrlHttps: "" });
  const [accountRevision, setAccountRevision] = useState("");
  const [settingsRevision, setSettingsRevision] = useState("");
  const [accountDirty, setAccountDirty] = useState(false);
  const [settingsDirty, setSettingsDirty] = useState(false);
  const [logs, setLogs] = useState<LogLine[]>([]);
  const [logTotal, setLogTotal] = useState(0);
  const [logsLoading, setLogsLoading] = useState(false);
  const [logSource, setLogSource] = useState<LogSource>("daemon");
  const [logLevel, setLogLevel] = useState<LogLevel>("");
  const [healthLogType, setHealthLogType] = useState("");
  const [logLimit, setLogLimit] = useState(200);
  const [autoRefreshLogs, setAutoRefreshLogs] = useState(true);

  const fail = useEffectEvent((error: unknown, fallback: string, silent = false) => {
    if (error instanceof ApiError && error.status === 401) {
      setAuthPhase("unauthenticated");
      setLoginError(error.message || "登录已失效，请重新输入密码。");
      setBusy(null);
      return;
    }
    if (!silent) {
      setNotice({ tone: "error", message: errorText(error, fallback) });
    }
  });

  const refreshLogs = useEffectEvent(async (silent = false) => {
    if (!silent) setLogsLoading(true);
    try {
      if (logSource === "health") {
        const payload = await panelApi.getHealthLogs(logLevel, healthLogType, logLimit);
        setLogs(
          payload.entries.map((entry) => ({
            ts: entry.ts,
            level: entry.level,
            msg: entry.message,
            type: entry.type,
            details:
              typeof entry.details === "string"
                ? entry.details
                : entry.details
                  ? JSON.stringify(entry.details)
                  : ""
          }))
        );
        setLogTotal(payload.total);
      } else {
        const payload = await panelApi.getLogs(logLevel, logLimit);
        setLogs(payload.lines);
        setLogTotal(payload.total);
      }
    } catch (error) {
      fail(error, "无法读取日志。", silent);
    } finally {
      if (!silent) setLogsLoading(false);
    }
  });

  const refresh = useEffectEvent(async (includeLogs = true, silent = false) => {
    if (!silent) setRefreshing(true);
    try {
      const [s, a, st, h, r] = await Promise.all([
        panelApi.getStatus(),
        panelApi.getAccount(),
        panelApi.getSettings(),
        panelApi.getHealth(),
        panelApi.getRuntime()
      ]);
      setStatus(s);
      setHealth(h);
      setRuntime(r);
      setAccountRevision(a.revision ?? "");
      setSettingsRevision(st.revision ?? "");
      if (!accountDirty) {
        setAccount((current) => ({
          username: a.username || s.username || "",
          password: current.password,
          operator: a.operator || s.operator || "DianXin",
          accountType: a.account_type || s.account_type || current.accountType
        }));
      }
      if (!settingsDirty) {
        setSettings({ proxyUrl: st.proxy_url ?? "", proxyUrlHttps: st.proxy_url_https ?? "" });
      }
      setNotice((current) => (current?.tone === "error" ? null : current));
      if (includeLogs) await refreshLogs(silent);
    } catch (error) {
      fail(error, "无法加载面板状态。", silent);
    } finally {
      if (!silent) setRefreshing(false);
    }
  });

  useEffect(() => {
    void (async () => {
      try {
        const auth = await panelApi.checkAuth();
        if (auth.authenticated) {
          setAuthPhase("authenticated");
          await refresh(true, false);
        } else {
          setAuthPhase("unauthenticated");
        }
      } catch (error) {
        setAuthPhase("unauthenticated");
        setNotice({ tone: "error", message: errorText(error, "无法确认登录状态。") });
      }
    })();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (authPhase === "authenticated") void refreshLogs(false);
  }, [authPhase, logLevel, logLimit, logSource, healthLogType]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (authPhase !== "authenticated") return;
    const statusTimer = window.setInterval(() => void refresh(false, true), 15000);
    const logsTimer = autoRefreshLogs
      ? window.setInterval(() => void refreshLogs(true), 20000)
      : 0;
    return () => {
      window.clearInterval(statusTimer);
      if (logsTimer) window.clearInterval(logsTimer);
    };
  }, [authPhase, autoRefreshLogs]); // eslint-disable-line react-hooks/exhaustive-deps

  // 统一包装一次操作：占用 busy 标记、提示结果、失败时走错误处理。
  const run = async (key: string, fallback: string, task: () => Promise<string | void>) => {
    setBusy(key);
    try {
      const message = await task();
      if (message) setNotice({ tone: "success", message });
    } catch (error) {
      fail(error, fallback);
    } finally {
      setBusy(null);
    }
  };

  const login = async (password: string) => {
    setBusy("login");
    setLoginError("");
    try {
      const result = await panelApi.login(password);
      if (!result.success) {
        setLoginError(result.message ?? "密码错误。");
        return false;
      }
      setAuthPhase("authenticated");
      await refresh(true, false);
      return true;
    } catch (error) {
      setLoginError(errorText(error, "登录失败，请稍后重试。"));
      return false;
    } finally {
      setBusy(null);
    }
  };

  const logout = () =>
    run("logout", "退出失败。", async () => {
      await panelApi.logout();
      setAuthPhase("unauthenticated");
    });

  const editAccount = (patch: Partial<AccountForm>) => {
    setAccount((current) => ({ ...current, ...patch }));
    setAccountDirty(true);
  };

  const editSettings = (patch: Partial<SettingsForm>) => {
    setSettings((current) => ({ ...current, ...patch }));
    setSettingsDirty(true);
  };

  const saveAccount = () => {
    if (!account.username.trim() || (!account.password && !accountRevision)) {
      setNotice({ tone: "warning", message: "请填写学号和密码。" });
      return Promise.resolve();
    }
    return run("account", "账号保存失败。", async () => {
      const result = await panelApi.saveAccount({
        username: account.username.trim(),
        password: account.password,
        operator: account.operator,
        revision: accountRevision
      });
      setAccount((current) => ({ ...current, password: "" }));
      setAccountDirty(false);
      await refresh(false, true);
      return result.message || "账号已保存。";
    });
  };

  const saveSettings = () =>
    run("settings", "代理保存失败。", async () => {
      const result = await panelApi.saveSettings({
        proxy_url: settings.proxyUrl,
        proxy_url_https: settings.proxyUrlHttps,
        revision: settingsRevision
      });
      setSettingsDirty(false);
      await refresh(false, true);
      return result.message || "代理已保存。";
    });

  const daemon = (action: "start" | "stop" | "restart") =>
    run(`daemon-${action}`, "守护进程操作失败。", async () => {
      const result = await panelApi.runDaemon(action);
      await refresh(true, false);
      return result.message || "守护进程已更新。";
    });

  const authAction = (action: "ensure" | "reauth" | "logout") =>
    run(`auth-${action}`, "认证操作失败。", async () => {
      const result = await panelApi.runAuth(action);
      await refresh(true, false);
      return result.message || "认证操作完成。";
    });

  const healthAction = (action: "enable" | "disable", duration?: HealthDuration) =>
    run(action === "enable" ? `health-${duration}` : "health-off", "健康监听操作失败。", async () => {
      const result = await panelApi.updateHealth(action, duration);
      setHealth(result);
      await refresh(logSource === "health", true);
      return action === "enable" ? "健康监听已开启。" : "健康监听已关闭。";
    });

  return {
    authPhase, loginError, busy, refreshing, notice, setNotice,
    status, health, runtime,
    account, editAccount, accountDirty, accountRevision, saveAccount,
    settings, editSettings, settingsDirty, saveSettings,
    logs, logTotal, logsLoading, logSource, setLogSource, logLevel, setLogLevel,
    healthLogType, setHealthLogType, logLimit, setLogLimit, autoRefreshLogs, setAutoRefreshLogs,
    refresh: () => refresh(true, false),
    refreshLogs: () => refreshLogs(false),
    login, logout, daemon, authAction, healthAction
  };
}

export type Panel = ReturnType<typeof usePanel>;
