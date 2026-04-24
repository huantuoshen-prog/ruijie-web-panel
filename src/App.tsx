import {
  startTransition,
  useEffect,
  useEffectEvent,
  useRef,
  useState,
  type ChangeEvent,
  type FormEvent,
  type ReactNode
} from "react";
import { ApiError, panelApi } from "./lib/api";
import {
  clearBackgroundAsset,
  loadBackgroundAsset,
  saveBackgroundAsset
} from "./lib/background";
import {
  accountTypeLabel,
  daemonTone,
  logTone,
  metricValue,
  networkTone,
  operatorLabel
} from "./lib/presenters";
import type {
  AccountResponse,
  HealthDuration,
  HealthStatusResponse,
  LogLevel,
  LogLine,
  RuntimeStatusResponse,
  SectionId,
  SettingsResponse,
  StatusResponse,
  ThemeMode
} from "./lib/types";

type AuthPhase = "checking" | "authenticated" | "unauthenticated";
type NoticeTone = "info" | "success" | "warning" | "error";
type LogSource = "daemon" | "health";

interface Notice {
  tone: NoticeTone;
  message: string;
}

interface AccountFormState {
  username: string;
  password: string;
  operator: string;
  accountType: string;
}

interface SettingsFormState {
  proxyUrl: string;
  proxyUrlHttps: string;
}

const SECTION_ITEMS: Array<{ id: SectionId; label: string; description: string }> = [
  { id: "overview", label: "总览", description: "核心状态与快捷操作" },
  { id: "account", label: "账号", description: "认证账号与网络配置" },
  { id: "daemon", label: "守护进程", description: "服务控制与运行指标" },
  { id: "logs", label: "日志", description: "实时事件与筛选" },
  { id: "settings", label: "设置", description: "代理、主题与个性化" }
];

const LOG_LEVEL_OPTIONS: Array<{ value: LogLevel; label: string }> = [
  { value: "", label: "全部" },
  { value: "OK", label: "成功" },
  { value: "INFO", label: "信息" },
  { value: "STEP", label: "步骤" },
  { value: "WARN", label: "警告" },
  { value: "ERROR", label: "错误" }
];

const HEALTH_LOG_TYPE_OPTIONS: Array<{ value: string; label: string }> = [
  { value: "", label: "全部类型" },
  { value: "baseline", label: "基线采样" },
  { value: "auth_success", label: "认证成功" },
  { value: "auth_failed", label: "认证失败" },
  { value: "network_error", label: "网络异常" },
  { value: "daemon", label: "守护事件" },
  { value: "monitor", label: "监听开关" }
];

const LOG_LIMIT_OPTIONS = [100, 200, 500];
const THEME_STORAGE_KEY = "ruijie-panel.theme";
const BACKGROUND_ENABLED_KEY = "ruijie-panel.background.enabled";
const BACKGROUND_NAME_KEY = "ruijie-panel.background.name";
const MAX_BACKGROUND_BYTES = 20 * 1024 * 1024;

function cn(...values: Array<string | false | null | undefined>): string {
  return values.filter(Boolean).join(" ");
}

function statusMessage(error: unknown, fallback: string): string {
  if (error instanceof ApiError) {
    return error.message || fallback;
  }

  if (error instanceof Error) {
    return error.message || fallback;
  }

  return fallback;
}

function formatRemainingSeconds(value?: number | null): string {
  if (typeof value !== "number" || Number.isNaN(value)) {
    return "永久";
  }

  if (value <= 0) {
    return "已到期";
  }

  if (value >= 86400) {
    return `${Math.ceil(value / 86400)} 天`;
  }

  if (value >= 3600) {
    return `${Math.ceil(value / 3600)} 小时`;
  }

  if (value >= 60) {
    return `${Math.ceil(value / 60)} 分钟`;
  }

  return `${value} 秒`;
}

function healthModeLabel(health: HealthStatusResponse | null): string {
  if (!health) {
    return "等待加载";
  }

  if (health.supported === false) {
    return "需升级主脚本";
  }

  if (!health.enabled) {
    return "未启用";
  }

  if (health.mode === "permanent") {
    return "永久开启";
  }

  return `剩余 ${formatRemainingSeconds(health.remaining_seconds)}`;
}

function Icon(props: { section: SectionId }) {
  switch (props.section) {
    case "overview":
      return (
        <svg viewBox="0 0 20 20" aria-hidden="true">
          <path d="M3 4.5h14v3H3zM3 9.5h8v6H3zM13 9.5h4v2H13zM13 13.5h4v2H13z" />
        </svg>
      );
    case "account":
      return (
        <svg viewBox="0 0 20 20" aria-hidden="true">
          <path d="M10 10a3.5 3.5 0 1 0-3.5-3.5A3.5 3.5 0 0 0 10 10Zm0 2c-3.04 0-5.5 1.79-5.5 4v1h11v-1c0-2.21-2.46-4-5.5-4Z" />
        </svg>
      );
    case "daemon":
      return (
        <svg viewBox="0 0 20 20" aria-hidden="true">
          <path d="M7 2h6v2h2.5A1.5 1.5 0 0 1 17 5.5v9A1.5 1.5 0 0 1 15.5 16H13v2H7v-2H4.5A1.5 1.5 0 0 1 3 14.5v-9A1.5 1.5 0 0 1 4.5 4H7Zm-1 5v6h8V7Z" />
        </svg>
      );
    case "logs":
      return (
        <svg viewBox="0 0 20 20" aria-hidden="true">
          <path d="M4 3h12a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1Zm2 3v2h8V6Zm0 4v2h8v-2Zm0 4v1h5v-1Z" />
        </svg>
      );
    case "settings":
      return (
        <svg viewBox="0 0 20 20" aria-hidden="true">
          <path d="m10 2 1.1 2.2 2.4.4-.8 2.3 1.7 1.8-1.7 1.8.8 2.3-2.4.4L10 18l-1.1-2.2-2.4-.4.8-2.3-1.7-1.8 1.7-1.8-.8-2.3 2.4-.4Zm0 5a3 3 0 1 0 3 3 3 3 0 0 0-3-3Z" />
        </svg>
      );
  }
}

function MetricCard(props: {
  eyebrow: string;
  value: string;
  detail: string;
  tone: "positive" | "warning" | "neutral" | "info";
}) {
  return (
    <article className="metric-card surface">
      <p className="surface__eyebrow">{props.eyebrow}</p>
      <strong className="metric-card__value">{props.value}</strong>
      <div className="metric-card__footer">
        <span className={cn("status-pill", `status-pill--${props.tone}`)}>{props.detail}</span>
      </div>
    </article>
  );
}

function Surface(props: {
  eyebrow: string;
  title: string;
  description: string;
  actions?: JSX.Element;
  children: JSX.Element | JSX.Element[] | string;
}) {
  return (
    <section className="surface">
      <div className="surface__header">
        <div>
          <p className="surface__eyebrow">{props.eyebrow}</p>
          <h3>{props.title}</h3>
          <p className="surface__body">{props.description}</p>
        </div>
        {props.actions ? <div className="surface__actions">{props.actions}</div> : null}
      </div>
      {props.children}
    </section>
  );
}

function DefinitionList(props: { items: Array<[string, ReactNode]> }) {
  return (
    <dl className="definition-list">
      {props.items.map(([label, value]) => (
        <div key={label} className="definition-list__item">
          <dt>{label}</dt>
          <dd>{value}</dd>
        </div>
      ))}
    </dl>
  );
}

function EmptyState(props: { title: string; description: string; compact?: boolean }) {
  return (
    <div className={cn("empty-state", props.compact && "empty-state--compact")}>
      <div className="empty-state__mark" aria-hidden="true" />
      <div>
        <h3>{props.title}</h3>
        <p>{props.description}</p>
      </div>
    </div>
  );
}

function App() {
  const [theme, setTheme] = useState<ThemeMode>(() => {
    const stored = localStorage.getItem(THEME_STORAGE_KEY);
    return stored === "light" ? "light" : "dark";
  });
  const [activeSection, setActiveSection] = useState<SectionId>("overview");
  const [authPhase, setAuthPhase] = useState<AuthPhase>("checking");
  const [loginPassword, setLoginPassword] = useState("");
  const [loginError, setLoginError] = useState("");
  const [busyAction, setBusyAction] = useState<string | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isLogsLoading, setIsLogsLoading] = useState(false);
  const [notice, setNotice] = useState<Notice | null>(null);
  const [status, setStatus] = useState<StatusResponse | null>(null);
  const [health, setHealth] = useState<HealthStatusResponse | null>(null);
  const [runtime, setRuntime] = useState<RuntimeStatusResponse | null>(null);
  const [accountForm, setAccountForm] = useState<AccountFormState>({
    username: "",
    password: "",
    operator: "DianXin",
    accountType: "student"
  });
  const [settingsForm, setSettingsForm] = useState<SettingsFormState>({
    proxyUrl: "",
    proxyUrlHttps: ""
  });
  const [logs, setLogs] = useState<LogLine[]>([]);
  const [logSource, setLogSource] = useState<LogSource>("daemon");
  const [logLevel, setLogLevel] = useState<LogLevel>("");
  const [healthLogType, setHealthLogType] = useState("");
  const [logLimit, setLogLimit] = useState(200);
  const [logTotal, setLogTotal] = useState(0);
  const [autoRefreshLogs, setAutoRefreshLogs] = useState(true);
  const [backgroundEnabled, setBackgroundEnabled] = useState(
    localStorage.getItem(BACKGROUND_ENABLED_KEY) !== "false"
  );
  const [backgroundName, setBackgroundName] = useState<string | null>(
    localStorage.getItem(BACKGROUND_NAME_KEY)
  );
  const [backgroundUrl, setBackgroundUrl] = useState<string | null>(null);
  const [personalizationOpen, setPersonalizationOpen] = useState(false);
  const backgroundObjectUrlRef = useRef<string | null>(null);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem(THEME_STORAGE_KEY, theme);
  }, [theme]);

  const setBackgroundFromBlob = useEffectEvent((blob: Blob | null) => {
    if (backgroundObjectUrlRef.current) {
      URL.revokeObjectURL(backgroundObjectUrlRef.current);
      backgroundObjectUrlRef.current = null;
    }

    if (!blob) {
      setBackgroundUrl(null);
      return;
    }

    const nextUrl = URL.createObjectURL(blob);
    backgroundObjectUrlRef.current = nextUrl;
    setBackgroundUrl(nextUrl);
  });

  // useEffectEvent callbacks stay out of deps so initialization does not resubscribe on every render.
  useEffect(() => {
    void (async () => {
      const blob = await loadBackgroundAsset();
      setBackgroundFromBlob(blob);
    })();

    return () => {
      if (backgroundObjectUrlRef.current) {
        URL.revokeObjectURL(backgroundObjectUrlRef.current);
      }
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const requireLogin = useEffectEvent((message: string) => {
    setAuthPhase("unauthenticated");
    setLoginError(message);
    setBusyAction(null);
  });

  const handleRequestFailure = useEffectEvent(
    (error: unknown, fallback: string, silent = false): boolean => {
      if (error instanceof ApiError && error.status === 401) {
        requireLogin(error.message || "登录状态已失效，请重新输入面板密码。");
        return true;
      }

      if (!silent) {
        setNotice({
          tone: "error",
          message: statusMessage(error, fallback)
        });
      }

      return false;
    }
  );

  const hydrateForms = useEffectEvent(
    (
      nextStatus: StatusResponse,
      nextAccount: AccountResponse,
      nextSettings: SettingsResponse,
      nextHealth: HealthStatusResponse,
      nextRuntime: RuntimeStatusResponse
    ) => {
      setStatus(nextStatus);
      setHealth(nextHealth);
      setRuntime(nextRuntime);
      setAccountForm((current) => ({
        username: nextAccount.username || nextStatus.username || "",
        password: current.password,
        operator: nextAccount.operator || nextStatus.operator || "DianXin",
        accountType: nextAccount.account_type || nextStatus.account_type || current.accountType
      }));
      setSettingsForm({
        proxyUrl: nextSettings.proxy_url ?? "",
        proxyUrlHttps: nextSettings.proxy_url_https ?? ""
      });
    }
  );

  const refreshLogs = useEffectEvent(async (silent = false) => {
    if (!silent) {
      setIsLogsLoading(true);
    }

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
      handleRequestFailure(error, "无法读取日志。", silent);
    } finally {
      if (!silent) {
        setIsLogsLoading(false);
      }
    }
  });

  const refreshPanel = useEffectEvent(async (includeLogs = true, silent = false) => {
    if (!silent) {
      setIsRefreshing(true);
    }

    try {
      const [nextStatus, nextAccount, nextSettings, nextHealth, nextRuntime] = await Promise.all([
        panelApi.getStatus(),
        panelApi.getAccount(),
        panelApi.getSettings(),
        panelApi.getHealth(),
        panelApi.getRuntime()
      ]);

      hydrateForms(nextStatus, nextAccount, nextSettings, nextHealth, nextRuntime);

      if (includeLogs) {
        await refreshLogs(silent);
      }
    } catch (error) {
      handleRequestFailure(error, "无法加载面板状态。", silent);
    } finally {
      if (!silent) {
        setIsRefreshing(false);
      }
    }
  });

  useEffect(() => {
    void (async () => {
      try {
        const auth = await panelApi.checkAuth();

        if (auth.authenticated) {
          setAuthPhase("authenticated");
          await refreshPanel(true, false);
        } else {
          setAuthPhase("unauthenticated");
        }
      } catch (error) {
        setAuthPhase("unauthenticated");
        setNotice({
          tone: "error",
          message: statusMessage(error, "无法确认当前登录状态。")
        });
      }
    })();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (authPhase !== "authenticated") {
      return;
    }

    void refreshLogs(false);
  }, [authPhase, logLevel, logLimit, logSource, healthLogType]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (authPhase !== "authenticated") {
      return;
    }

    const statusTimer = window.setInterval(() => {
      void refreshPanel(false, true);
    }, 15000);

    let logsTimer = 0;
    if (autoRefreshLogs) {
      logsTimer = window.setInterval(() => {
        void refreshLogs(true);
      }, 20000);
    }

    return () => {
      window.clearInterval(statusTimer);
      if (logsTimer) {
        window.clearInterval(logsTimer);
      }
    };
  }, [authPhase, autoRefreshLogs]); // eslint-disable-line react-hooks/exhaustive-deps

  const goToSection = (section: SectionId) => {
    startTransition(() => {
      setActiveSection(section);
    });
  };

  const handleLogin = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setBusyAction("login");
    setLoginError("");

    try {
      const result = await panelApi.login(loginPassword);

      if (!result.success) {
        setLoginError(result.message ?? "面板密码错误。");
        return;
      }

      setAuthPhase("authenticated");
      setLoginPassword("");
      setNotice({
        tone: "success",
        message: "已登录面板，正在同步当前状态。"
      });
      await refreshPanel(true, false);
    } catch (error) {
      setLoginError(statusMessage(error, "登录失败，请稍后重试。"));
    } finally {
      setBusyAction(null);
    }
  };

  const handleLogout = async () => {
    setBusyAction("logout");

    try {
      await panelApi.logout();
      setAuthPhase("unauthenticated");
      setNotice({
        tone: "info",
        message: "当前会话已退出。"
      });
    } catch (error) {
      handleRequestFailure(error, "退出登录失败。");
    } finally {
      setBusyAction(null);
    }
  };

  const handleAccountInput = (event: ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = event.target;

    setAccountForm((current) => ({
      ...current,
      [name]: value
    }));
  };

  const handleSettingsInput = (
    event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = event.target;

    setSettingsForm((current) => ({
      ...current,
      [name]: value
    }));
  };

  const handleSaveAccount = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (!accountForm.username.trim() || !accountForm.password.trim()) {
      setNotice({
        tone: "warning",
        message: "保存账号前需要同时填写用户名和密码。"
      });
      return;
    }

    setBusyAction("account");

    try {
      const result = await panelApi.saveAccount({
        username: accountForm.username.trim(),
        password: accountForm.password.trim(),
        operator: accountForm.operator
      });

      setAccountForm((current) => ({
        ...current,
        password: ""
      }));

      setNotice({
        tone: "success",
        message: result.message || "账号配置已保存。"
      });

      await refreshPanel(false, true);
    } catch (error) {
      handleRequestFailure(error, "账号配置保存失败。");
    } finally {
      setBusyAction(null);
    }
  };

  const handleSaveSettings = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setBusyAction("settings");

    try {
      const result = await panelApi.saveSettings({
        proxy_url: settingsForm.proxyUrl,
        proxy_url_https: settingsForm.proxyUrlHttps
      });

      setNotice({
        tone: "success",
        message: result.message || "代理设置已保存。"
      });

      await refreshPanel(false, true);
    } catch (error) {
      handleRequestFailure(error, "代理设置保存失败。");
    } finally {
      setBusyAction(null);
    }
  };

  const handleDaemonAction = async (action: "start" | "stop" | "restart") => {
    setBusyAction(`daemon-${action}`);

    try {
      const result = await panelApi.runDaemon(action);
      setNotice({
        tone: "success",
        message: result.message || "守护进程状态已更新。"
      });
      await refreshPanel(true, false);
    } catch (error) {
      handleRequestFailure(error, "守护进程操作失败。");
    } finally {
      setBusyAction(null);
    }
  };

  const handleModeSwitch = async (operator: "DianXin" | "LianTong") => {
    setBusyAction(`mode-${operator}`);

    try {
      const result = await panelApi.switchOperator(operator);
      setNotice({
        tone: "success",
        message: result.message || `已切换到 ${operatorLabel(operator)}。`
      });
      await refreshPanel(true, false);
    } catch (error) {
      handleRequestFailure(error, "切换网络模式失败。");
    } finally {
      setBusyAction(null);
    }
  };

  const handleHealthAction = async (action: "enable" | "disable", duration?: HealthDuration) => {
    setBusyAction(
      action === "enable" ? `health-enable-${duration ?? "unknown"}` : "health-disable"
    );

    try {
      const result = await panelApi.updateHealth(action, duration);
      setHealth(result);
      setNotice({
        tone: "success",
        message:
          action === "enable"
            ? `健康监听已开启${duration ? `（${duration}）` : ""}。`
            : "健康监听已关闭。"
      });
      await refreshPanel(logSource === "health", false);
    } catch (error) {
      handleRequestFailure(error, "健康监听操作失败。");
    } finally {
      setBusyAction(null);
    }
  };

  const handleBackgroundUpload = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];

    if (!file) {
      return;
    }

    if (file.size > MAX_BACKGROUND_BYTES) {
      setNotice({
        tone: "warning",
        message: "背景图不能超过 20MB，请压缩后再上传。"
      });
      event.target.value = "";
      return;
    }

    setBusyAction("background");

    try {
      await saveBackgroundAsset(file);
      localStorage.setItem(BACKGROUND_NAME_KEY, file.name);
      localStorage.setItem(BACKGROUND_ENABLED_KEY, "true");
      setBackgroundEnabled(true);
      setBackgroundName(file.name);
      setBackgroundFromBlob(file);
      setNotice({
        tone: "success",
        message: "背景图已更新。当前界面会自动增加遮罩，保证可读性。"
      });
    } catch (error) {
      setNotice({
        tone: "error",
        message: statusMessage(error, "背景图保存失败。")
      });
    } finally {
      setBusyAction(null);
      event.target.value = "";
    }
  };

  const handleBackgroundToggle = (enabled: boolean) => {
    setBackgroundEnabled(enabled);
    localStorage.setItem(BACKGROUND_ENABLED_KEY, String(enabled));
  };

  const handleBackgroundClear = async () => {
    setBusyAction("background-clear");

    try {
      await clearBackgroundAsset();
      localStorage.removeItem(BACKGROUND_NAME_KEY);
      localStorage.setItem(BACKGROUND_ENABLED_KEY, "false");
      setBackgroundEnabled(false);
      setBackgroundName(null);
      setBackgroundFromBlob(null);
      setNotice({
        tone: "info",
        message: "背景个性化已清除。"
      });
    } catch (error) {
      setNotice({
        tone: "error",
        message: statusMessage(error, "清除背景图失败。")
      });
    } finally {
      setBusyAction(null);
    }
  };

  const statusTone = status ? networkTone(status.online) : "warning";
  const daemonStatusTone = status
    ? daemonTone(status.daemon_state, status.daemon_running)
    : "neutral";
  const healthTone = !health?.supported
    ? "warning"
    : health.enabled
      ? health.collector_active
        ? "positive"
        : "info"
      : "neutral";
  const activeSectionMeta =
    SECTION_ITEMS.find((section) => section.id === activeSection) ?? SECTION_ITEMS[0];
  const recentLogs = [...logs].slice(-4).reverse();
  const healthUnavailableMessage =
    health && health.supported === false
      ? health.message || "主脚本版本过低，需升级后使用"
      : runtime && runtime.supported === false
        ? runtime.message || "主脚本版本过低，需升级后使用"
        : "";
  const shellStyle =
    backgroundEnabled && backgroundUrl
      ? {
          backgroundImage: `linear-gradient(var(--bg-image-overlay-start), var(--bg-image-overlay-end)), url("${backgroundUrl}")`
        }
      : undefined;

  const renderOverview = () => (
    <div className="page-grid">
      <div className="metric-grid">
        <MetricCard
          eyebrow="网络状态"
          value={status?.online ? "已连接" : authPhase === "checking" ? "检测中" : "未连接"}
          detail={status ? operatorLabel(status.operator) : "等待后端状态"}
          tone={statusTone}
        />
        <MetricCard
          eyebrow="守护进程"
          value={status?.daemon_running ? "运行中" : "未运行"}
          detail={status?.daemon_uptime || "—"}
          tone={daemonStatusTone}
        />
        <MetricCard
          eyebrow="账号摘要"
          value={status?.username || "未配置"}
          detail={status ? accountTypeLabel(status.account_type) : "等待加载"}
          tone="neutral"
        />
        <MetricCard
          eyebrow="健康监听"
          value={health?.supported === false ? "需升级" : health?.enabled ? "已开启" : "未开启"}
          detail={healthModeLabel(health)}
          tone={healthTone}
        />
        <MetricCard
          eyebrow="最近认证"
          value={status?.last_auth || "—"}
          detail={`核心版本 ${status?.version || "—"}`}
          tone="info"
        />
      </div>

      {!status?.installed && authPhase === "authenticated" ? (
        <EmptyState
          title="未检测到锐捷主脚本"
          description="面板已启动，但后端主脚本不存在或没有完成安装。先在路由器里安装 ruijie-gdstvc-autologin，再回来刷新面板。"
        />
      ) : null}

      <div className="content-grid">
        <Surface
          eyebrow="快捷控制"
          title="即时操作"
          description="把常用的守护进程控制和运营商切换放在首屏。"
          actions={
            <button
              type="button"
              className="button button--ghost"
              disabled={authPhase !== "authenticated"}
              onClick={() => goToSection("daemon")}
            >
              打开守护进程页
            </button>
          }
        >
          <div className="quick-actions">
            <button
              type="button"
              className="button button--primary"
              disabled={busyAction === "daemon-start" || authPhase !== "authenticated"}
              onClick={() => void handleDaemonAction("start")}
            >
              启动守护进程
            </button>
            <button
              type="button"
              className="button button--secondary"
              disabled={busyAction === "daemon-restart" || authPhase !== "authenticated"}
              onClick={() => void handleDaemonAction("restart")}
            >
              重启守护进程
            </button>
            <button
              type="button"
              className="button button--danger"
              disabled={busyAction === "daemon-stop" || authPhase !== "authenticated"}
              onClick={() => void handleDaemonAction("stop")}
            >
              停止守护进程
            </button>
          </div>

          <div className="segmented-group">
            <button
              type="button"
              className={cn(
                "segmented-group__button",
                status?.operator === "DianXin" && "is-active"
              )}
              disabled={busyAction === "mode-DianXin" || authPhase !== "authenticated"}
              onClick={() => void handleModeSwitch("DianXin")}
            >
              切到电信
            </button>
            <button
              type="button"
              className={cn(
                "segmented-group__button",
                status?.operator === "LianTong" && "is-active"
              )}
              disabled={busyAction === "mode-LianTong" || authPhase !== "authenticated"}
              onClick={() => void handleModeSwitch("LianTong")}
            >
              切到联通
            </button>
          </div>
        </Surface>

        <Surface
          eyebrow="健康监听"
          title="调试窗口"
          description="首次安装后会默认开启 3 天；后续可在守护页重新打开，用来保留认证、网络和运行环境上下文。"
          actions={
            <button
              type="button"
              className="button button--ghost"
              disabled={authPhase !== "authenticated"}
              onClick={() => goToSection("daemon")}
            >
              打开健康控制
            </button>
          }
        >
          {health?.supported === false ? (
            <EmptyState
              title="主脚本版本过低"
              description={healthUnavailableMessage || "升级主脚本后才能使用健康监听。"}
              compact
            />
          ) : (
            <DefinitionList
              items={[
                ["当前状态", health?.enabled ? "已开启" : "未开启"],
                ["剩余窗口", healthModeLabel(health)],
                ["采样状态", health?.collector_active ? "守护进程正在采样" : "已开启但未采样"],
                ["最近事件", health?.last_event_at || "—"]
              ]}
            />
          )}
        </Surface>

        <Surface
          eyebrow="健康摘要"
          title="当前运行面"
          description="为移动端巡检保留关键信息，不把细节埋得太深。"
        >
          <DefinitionList
            items={[
              ["运行 PID", status?.daemon_pid || "—"],
              ["守护状态", status?.daemon_state || "—"],
              ["账号类型", accountTypeLabel(status?.account_type || accountForm.accountType)],
              ["当前运营商", operatorLabel(status?.operator || accountForm.operator)]
            ]}
          />
        </Surface>
      </div>

      <Surface
        eyebrow="最近事件"
        title="最新日志预览"
        description="保留最近几条关键事件，完整筛选和阅读放到日志工作区。"
        actions={
          <button type="button" className="button button--ghost" onClick={() => goToSection("logs")}>
            打开日志中心
          </button>
        }
      >
        {recentLogs.length > 0 ? (
          <div className="log-feed">
            {recentLogs.map((line, index) => (
              <article key={`${line.ts}-${line.level}-${index}`} className="log-row">
                <div className={cn("log-badge", `log-badge--${logTone(line.level)}`)}>
                  {line.level}
                </div>
                <div className="log-row__body">
                  <p>{line.msg}</p>
                  <span>{line.ts}</span>
                </div>
              </article>
            ))}
          </div>
        ) : (
          <EmptyState
            title="还没有日志"
            description="如果你刚安装面板或守护进程还没启动，日志区会暂时保持空白。"
            compact
          />
        )}
      </Surface>
    </div>
  );

  const renderAccount = () => (
    <div className="page-grid">
      <Surface
        eyebrow="账号与认证"
        title="编辑校园网账号"
        description="保存时会保留已有账号类型，只更新用户名、密码和运营商。"
      >
        <form className="form-grid" onSubmit={handleSaveAccount}>
          <label className="field">
            <span className="field__label">用户名</span>
            <input
              className="input"
              name="username"
              value={accountForm.username}
              onChange={handleAccountInput}
              placeholder="例如 1720240564"
              autoComplete="username"
            />
          </label>

          <label className="field">
            <span className="field__label">密码</span>
            <input
              className="input"
              type="password"
              name="password"
              value={accountForm.password}
              onChange={handleAccountInput}
              placeholder="保存时需要重新输入密码"
              autoComplete="current-password"
            />
          </label>

          <label className="field">
            <span className="field__label">运营商</span>
            <select
              className="input"
              name="operator"
              value={accountForm.operator}
              onChange={handleAccountInput}
            >
              <option value="DianXin">校园电信</option>
              <option value="LianTong">校园联通</option>
            </select>
          </label>

          <div className="field">
            <span className="field__label">账号类型</span>
            <div className="readonly-card">
              <strong>{accountTypeLabel(accountForm.accountType)}</strong>
              <span>由主脚本配置决定，Web 面板只展示不覆盖。</span>
            </div>
          </div>

          <div className="form-actions">
            <button
              type="submit"
              className="button button--primary"
              disabled={busyAction === "account" || authPhase !== "authenticated"}
            >
              {busyAction === "account" ? "保存中..." : "保存账号配置"}
            </button>
            <button
              type="button"
              className="button button--ghost"
              disabled={authPhase !== "authenticated"}
              onClick={() => void refreshPanel(false, false)}
            >
              从后端重新加载
            </button>
          </div>
        </form>
      </Surface>

      <div className="content-grid">
        <Surface
          eyebrow="当前摘要"
          title="已生效配置"
          description="展示当前后端实际读到的账号信息。"
        >
          <DefinitionList
            items={[
              ["当前用户名", status?.username || accountForm.username || "—"],
              ["当前运营商", operatorLabel(status?.operator || accountForm.operator)],
              ["账号类型", accountTypeLabel(status?.account_type || accountForm.accountType)],
              ["最近认证", status?.last_auth || "—"]
            ]}
          />
        </Surface>

        <Surface
          eyebrow="快速切换"
          title="运营商热切换"
          description="不改账号资料，直接调用 `/ruijie-cgi/mode` 执行在线切换。"
        >
          <div className="segmented-group">
            <button
              type="button"
              className={cn(
                "segmented-group__button",
                status?.operator === "DianXin" && "is-active"
              )}
              disabled={busyAction === "mode-DianXin" || authPhase !== "authenticated"}
              onClick={() => void handleModeSwitch("DianXin")}
            >
              电信
            </button>
            <button
              type="button"
              className={cn(
                "segmented-group__button",
                status?.operator === "LianTong" && "is-active"
              )}
              disabled={busyAction === "mode-LianTong" || authPhase !== "authenticated"}
              onClick={() => void handleModeSwitch("LianTong")}
            >
              联通
            </button>
          </div>
        </Surface>
      </div>
    </div>
  );

  const renderDaemon = () => (
    <div className="page-grid">
      <div className="metric-grid metric-grid--three">
        <MetricCard
          eyebrow="运行状态"
          value={status?.daemon_running ? "在线" : "离线"}
          detail={status?.daemon_state || "—"}
          tone={daemonStatusTone}
        />
        <MetricCard
          eyebrow="进程 PID"
          value={metricValue(status?.daemon_pid)}
          detail={status?.daemon_running ? "当前活跃进程" : "未运行"}
          tone="neutral"
        />
        <MetricCard
          eyebrow="累计运行"
          value={metricValue(status?.daemon_uptime)}
          detail={status?.last_auth ? `最近认证 ${status.last_auth}` : "等待首次认证"}
          tone="info"
        />
      </div>

      <Surface
        eyebrow="服务控制"
        title="守护进程动作"
        description="把启动、停止和重启放在统一控制栏里，减少误操作。"
      >
        <div className="quick-actions">
          <button
            type="button"
            className="button button--primary"
            disabled={busyAction === "daemon-start" || authPhase !== "authenticated"}
            onClick={() => void handleDaemonAction("start")}
          >
            启动
          </button>
          <button
            type="button"
            className="button button--secondary"
            disabled={busyAction === "daemon-restart" || authPhase !== "authenticated"}
            onClick={() => void handleDaemonAction("restart")}
          >
            重启
          </button>
          <button
            type="button"
            className="button button--danger"
            disabled={busyAction === "daemon-stop" || authPhase !== "authenticated"}
            onClick={() => void handleDaemonAction("stop")}
          >
            停止
          </button>
        </div>
      </Surface>

      <Surface
        eyebrow="健康监听"
        title="健康监听控制"
        description="需要排障或给 agent 更多上下文时，可以临时开启更完整的健康采样。"
      >
        {health?.supported === false ? (
          <EmptyState
            title="主脚本版本过低"
            description={healthUnavailableMessage || "升级主脚本后才能启用健康监听。"}
          />
        ) : (
          <>
            <DefinitionList
              items={[
                ["监听状态", health?.enabled ? "已开启" : "未开启"],
                ["剩余窗口", healthModeLabel(health)],
                ["采样是否活跃", health?.collector_active ? "活跃" : "等待守护进程运行"],
                ["脱敏策略", health?.redaction || "mask_password_and_session_only"]
              ]}
            />
            <div className="quick-actions">
              <button
                type="button"
                className="button button--secondary"
                disabled={busyAction === "health-enable-1d" || authPhase !== "authenticated"}
                onClick={() => void handleHealthAction("enable", "1d")}
              >
                开启 1 天
              </button>
              <button
                type="button"
                className="button button--primary"
                disabled={busyAction === "health-enable-3d" || authPhase !== "authenticated"}
                onClick={() => void handleHealthAction("enable", "3d")}
              >
                开启 3 天
              </button>
              <button
                type="button"
                className="button button--secondary"
                disabled={busyAction === "health-enable-7d" || authPhase !== "authenticated"}
                onClick={() => void handleHealthAction("enable", "7d")}
              >
                开启 7 天
              </button>
              <button
                type="button"
                className="button button--ghost"
                disabled={
                  busyAction === "health-enable-permanent" || authPhase !== "authenticated"
                }
                onClick={() => void handleHealthAction("enable", "permanent")}
              >
                永久开启
              </button>
              <button
                type="button"
                className="button button--danger"
                disabled={busyAction === "health-disable" || authPhase !== "authenticated"}
                onClick={() => void handleHealthAction("disable")}
              >
                关闭监听
              </button>
            </div>
          </>
        )}
      </Surface>

      <Surface
        eyebrow="运行细节"
        title="状态细节"
        description="保留实际故障排查需要的 PID、线路与版本信息。"
      >
        <DefinitionList
          items={[
            ["当前线路", operatorLabel(status?.operator || accountForm.operator)],
            ["核心版本", status?.version || "—"],
            ["最近认证", status?.last_auth || "—"],
            ["账号用户", status?.username || accountForm.username || "—"]
          ]}
        />
      </Surface>
    </div>
  );

  const renderLogs = () => (
    <div className="page-grid">
      <Surface
        eyebrow="日志中心"
        title="筛选与回看"
        description="认证日志和健康日志共用一套阅读面，切换来源后保留同样的筛选节奏。"
        actions={
          <label className="toggle">
            <input
              type="checkbox"
              checked={autoRefreshLogs}
              onChange={(event) => setAutoRefreshLogs(event.target.checked)}
            />
            <span>自动刷新</span>
          </label>
        }
      >
        <div className="toolbar">
          <div className="toolbar__group toolbar__group--wrap">
            <button
              type="button"
              className={cn("filter-chip", logSource === "daemon" && "filter-chip--active")}
              onClick={() => setLogSource("daemon")}
            >
              认证日志
            </button>
            <button
              type="button"
              className={cn("filter-chip", logSource === "health" && "filter-chip--active")}
              onClick={() => setLogSource("health")}
            >
              健康日志
            </button>
          </div>

          <div className="toolbar__group toolbar__group--wrap">
            {LOG_LEVEL_OPTIONS.map((option) => (
              <button
                key={option.value || "all"}
                type="button"
                className={cn("filter-chip", logLevel === option.value && "filter-chip--active")}
                onClick={() => setLogLevel(option.value)}
              >
                {option.label}
              </button>
            ))}
          </div>

          {logSource === "health" ? (
            <div className="toolbar__group toolbar__group--wrap">
              {HEALTH_LOG_TYPE_OPTIONS.map((option) => (
                <button
                  key={option.value || "all-health-types"}
                  type="button"
                  className={cn(
                    "filter-chip",
                    healthLogType === option.value && "filter-chip--active"
                  )}
                  onClick={() => setHealthLogType(option.value)}
                >
                  {option.label}
                </button>
              ))}
            </div>
          ) : null}

          <div className="toolbar__group">
            <label className="field field--inline">
              <span className="field__label">行数</span>
              <select
                className="input input--compact"
                value={logLimit}
                onChange={(event) => setLogLimit(Number(event.target.value))}
              >
                {LOG_LIMIT_OPTIONS.map((option) => (
                  <option key={option} value={option}>
                    {option}
                  </option>
                ))}
              </select>
            </label>
            <button
              type="button"
              className="button button--secondary"
              disabled={isLogsLoading || authPhase !== "authenticated"}
              onClick={() => void refreshLogs(false)}
            >
              {isLogsLoading ? "读取中..." : "刷新日志"}
            </button>
          </div>
        </div>

        <div className="logs-headline">
          <span>
            {logSource === "health" ? "健康日志" : "认证日志"}，返回 {logTotal} 条记录
          </span>
          <span>{autoRefreshLogs ? "已开启自动刷新" : "手动刷新模式"}</span>
        </div>

        {logs.length > 0 ? (
          <div className="log-table" role="list" aria-label="日志列表">
            {logs.map((line, index) => (
              <article
                key={`${line.ts}-${line.level}-${index}`}
                className="log-table__row"
                role="listitem"
              >
                <div className="log-table__meta">
                  <span className={cn("log-badge", `log-badge--${logTone(line.level)}`)}>
                    {line.type ? `${line.level} · ${line.type}` : line.level}
                  </span>
                  <time>{line.ts}</time>
                </div>
                <p className="log-table__message">{line.msg}</p>
                {line.details ? <p className="surface__body">{line.details}</p> : null}
              </article>
            ))}
          </div>
        ) : (
          <EmptyState
            title="没有匹配日志"
            description={
              logSource === "health"
                ? "尝试切换类型筛选，或先开启健康监听生成新的调试上下文。"
                : "尝试切换筛选级别，或先启动守护进程生成新的日志。"
            }
          />
        )}
      </Surface>
    </div>
  );

  const renderSettings = () => (
    <div className="page-grid">
      <div className="content-grid">
        <Surface
          eyebrow="主题"
          title="界面观感"
          description="深色是默认首选，亮色作为完整等价方案保留。"
        >
          <div className="theme-cards">
            <button
              type="button"
              className={cn("theme-card", theme === "dark" && "theme-card--active")}
              onClick={() => setTheme("dark")}
            >
              <span className="theme-card__preview theme-card__preview--dark" />
              <strong>深色控制台</strong>
              <span>默认石墨主题，适合夜间和移动端巡检。</span>
            </button>
            <button
              type="button"
              className={cn("theme-card", theme === "light" && "theme-card--active")}
              onClick={() => setTheme("light")}
            >
              <span className="theme-card__preview theme-card__preview--light" />
              <strong>亮色工作台</strong>
              <span>在强光环境下保持更高可读性。</span>
            </button>
          </div>
        </Surface>

        <Surface
          eyebrow="关于"
          title="版本与链接"
          description="保留当前核心版本感知，把上游更新入口收敛为手动查看。"
        >
          <DefinitionList
            items={[
              ["面板工作区", "React + Vite + TypeScript"],
              ["当前核心版本", status?.version || "—"],
              [
                "上游发布页",
                <a
                  key="core-releases"
                  className="inline-link"
                  href="https://github.com/huantuoshen-prog/ruijie-gdstvc-autologin/releases"
                  target="_blank"
                  rel="noreferrer"
                >
                  查看主仓库 Releases
                </a>
              ],
              ["接口入口", "/ruijie-cgi/<name>"]
            ]}
          />
        </Surface>

        <Surface
          eyebrow="运行环境"
          title="运行环境"
          description="直接暴露给排障和 agent 的环境摘要，方便判断当前路由器是否具备采样与守护能力。"
        >
          {runtime?.supported === false ? (
            <EmptyState
              title="主脚本版本过低"
              description={healthUnavailableMessage || "升级主脚本后才能读取运行环境摘要。"}
              compact
            />
          ) : (
            <DefinitionList
              items={[
                ["平台", runtime?.platform || "—"],
                ["内核", runtime?.kernel || "—"],
                ["架构", runtime?.arch || "—"],
                ["Shell", runtime?.shell || "—"],
                ["后台能力", runtime?.nohup_backend || "—"],
                ["脚本目录", runtime?.script_dir || "—"],
                ["配置路径", runtime?.config_file || "—"],
                ["健康日志", runtime?.health_logfile || "—"]
              ]}
            />
          )}
        </Surface>
      </div>

      <Surface
        eyebrow="代理设置"
        title="网络出口"
        description="与后端 `/settings` 接口保持兼容，不改变原有字段语义。"
      >
        <form className="form-grid" onSubmit={handleSaveSettings}>
          <label className="field">
            <span className="field__label">HTTP 代理</span>
            <input
              className="input"
              name="proxyUrl"
              value={settingsForm.proxyUrl}
              onChange={handleSettingsInput}
              placeholder="http://127.0.0.1:7890"
            />
          </label>

          <label className="field">
            <span className="field__label">HTTPS 代理</span>
            <input
              className="input"
              name="proxyUrlHttps"
              value={settingsForm.proxyUrlHttps}
              onChange={handleSettingsInput}
              placeholder="http://127.0.0.1:7890"
            />
          </label>

          <div className="form-actions">
            <button
              type="submit"
              className="button button--primary"
              disabled={busyAction === "settings" || authPhase !== "authenticated"}
            >
              {busyAction === "settings" ? "保存中..." : "保存代理配置"}
            </button>
          </div>
        </form>
      </Surface>

      <Surface
        eyebrow="个性化"
        title="背景定制"
        description="背景图被降为次级能力，默认不会主导界面；启用后会自动增加遮罩。"
        actions={
          <button
            type="button"
            className="button button--ghost"
            onClick={() => setPersonalizationOpen((current) => !current)}
          >
            {personalizationOpen ? "收起" : "展开"}
          </button>
        }
      >
        {personalizationOpen ? (
          <div className="personalization-panel">
            <label className="toggle">
              <input
                type="checkbox"
                checked={backgroundEnabled}
                onChange={(event) => handleBackgroundToggle(event.target.checked)}
              />
              <span>启用背景图</span>
            </label>

            <div className="readonly-card">
              <strong>{backgroundName || "未设置背景图"}</strong>
              <span>个性化只影响表面氛围，不改变内容层级和可读性。</span>
            </div>

            <div className="quick-actions">
              <label className="button button--secondary button--file">
                <input type="file" accept="image/*" onChange={handleBackgroundUpload} hidden />
                {busyAction === "background" ? "上传中..." : "上传背景图"}
              </label>
              <button
                type="button"
                className="button button--ghost"
                disabled={!backgroundUrl}
                onClick={() => handleBackgroundToggle(!backgroundEnabled)}
              >
                {backgroundEnabled ? "临时关闭背景" : "重新启用背景"}
              </button>
              <button
                type="button"
                className="button button--danger"
                disabled={!backgroundUrl || busyAction === "background-clear"}
                onClick={() => void handleBackgroundClear()}
              >
                {busyAction === "background-clear" ? "清除中..." : "删除背景图"}
              </button>
            </div>
          </div>
        ) : (
          <p className="surface__body">默认保持关闭，只在你确实需要更强的个性化时再展开。</p>
        )}
      </Surface>
    </div>
  );

  const sectionContent =
    activeSection === "overview"
      ? renderOverview()
      : activeSection === "account"
        ? renderAccount()
        : activeSection === "daemon"
          ? renderDaemon()
          : activeSection === "logs"
            ? renderLogs()
            : renderSettings();

  return (
    <div className="app-shell">
      <div className="app-shell__backdrop" style={shellStyle} aria-hidden="true" />
      <div className="app-frame">
        <aside className="sidebar">
          <div className="sidebar__brand">
            <div className="brand-mark" aria-hidden="true">
              <span />
            </div>
            <div>
              <p className="brand-kicker">Ruijie Panel</p>
              <h1>锐捷 Web 管理面板</h1>
            </div>
          </div>

          <div className="sidebar__stack">
            <div className="surface surface--muted">
              <p className="surface__eyebrow">部署形态</p>
              <p className="surface__body">
                面向 OpenWrt / iStoreOS 的单页运维控制台，默认深色主题，支持移动端巡检。
              </p>
            </div>

            <nav className="nav-list" aria-label="主导航">
              {SECTION_ITEMS.map((section) => (
                <button
                  key={section.id}
                  type="button"
                  className={cn("nav-item", activeSection === section.id && "nav-item--active")}
                  aria-current={activeSection === section.id ? "page" : undefined}
                  onClick={() => goToSection(section.id)}
                >
                  <span className="nav-item__icon">
                    <Icon section={section.id} />
                  </span>
                  <span className="nav-item__content">
                    <span className="nav-item__label">{section.label}</span>
                    <span className="nav-item__meta">{section.description}</span>
                  </span>
                </button>
              ))}
            </nav>
          </div>

          <div className="sidebar__footer">
            <div className="surface surface--muted">
              <p className="surface__eyebrow">当前主题</p>
              <div className="theme-toggle">
                <button
                  type="button"
                  className={cn("theme-toggle__button", theme === "dark" && "is-active")}
                  onClick={() => setTheme("dark")}
                >
                  深色
                </button>
                <button
                  type="button"
                  className={cn("theme-toggle__button", theme === "light" && "is-active")}
                  onClick={() => setTheme("light")}
                >
                  亮色
                </button>
              </div>
            </div>
          </div>
        </aside>

        <main className="workspace">
          <header className="workspace__header">
            <div>
              <p className="workspace__eyebrow">Professional Network Console</p>
              <h2>{activeSectionMeta.label}</h2>
              <p className="workspace__subtitle">{activeSectionMeta.description}</p>
            </div>

            <div className="workspace__actions">
              <button
                type="button"
                className="button button--secondary"
                disabled={isRefreshing || authPhase !== "authenticated"}
                onClick={() => void refreshPanel(true, false)}
              >
                {isRefreshing ? "同步中..." : "刷新面板"}
              </button>
              <button
                type="button"
                className="button button--ghost"
                disabled={busyAction === "logout" || authPhase !== "authenticated"}
                onClick={() => void handleLogout()}
              >
                {busyAction === "logout" ? "退出中..." : "退出登录"}
              </button>
            </div>
          </header>

          {notice ? (
            <div className={cn("notice", `notice--${notice.tone}`)}>
              <span>{notice.message}</span>
              <button type="button" className="notice__dismiss" onClick={() => setNotice(null)}>
                关闭
              </button>
            </div>
          ) : null}

          {status?.message ? (
            <div className="notice notice--warning">
              <span>{status.message}</span>
            </div>
          ) : null}

          {healthUnavailableMessage ? (
            <div className="notice notice--warning">
              <span>{healthUnavailableMessage}</span>
            </div>
          ) : null}

          <section className="workspace__section">{sectionContent}</section>
        </main>
      </div>

      <nav className="mobile-nav" aria-label="移动端导航">
        {SECTION_ITEMS.map((section) => (
          <button
            key={section.id}
            type="button"
            className={cn("mobile-nav__item", activeSection === section.id && "is-active")}
            onClick={() => goToSection(section.id)}
          >
            <span className="mobile-nav__icon">
              <Icon section={section.id} />
            </span>
            <span>{section.label}</span>
          </button>
        ))}
      </nav>

      {authPhase !== "authenticated" ? (
        <div className="auth-layer" role="dialog" aria-modal="true" aria-labelledby="login-title">
          <div className="auth-card">
            <div className="auth-card__header">
              <p className="surface__eyebrow">Web 面板访问保护</p>
              <h2 id="login-title">
                {authPhase === "checking" ? "正在检查登录状态" : "输入面板密码"}
              </h2>
              <p className="surface__body">
                面板已默认加上独立访问保护；同一局域网里的其他设备不能再直接裸用管理接口。
              </p>
            </div>

            {authPhase === "checking" ? (
              <div className="auth-card__pending">正在与 CGI 接口同步当前会话...</div>
            ) : (
              <form className="auth-form" onSubmit={handleLogin}>
                <label className="field">
                  <span className="field__label">面板密码</span>
                  <input
                    className="input"
                    type="password"
                    value={loginPassword}
                    onChange={(event) => setLoginPassword(event.target.value)}
                    placeholder="请输入安装脚本初始化的 Web 面板密码"
                    autoFocus
                    autoComplete="current-password"
                  />
                </label>

                {loginError ? <p className="field__error">{loginError}</p> : null}

                <button
                  type="submit"
                  className="button button--primary button--full"
                  disabled={busyAction === "login"}
                >
                  {busyAction === "login" ? "登录中..." : "进入控制台"}
                </button>
              </form>
            )}
          </div>
        </div>
      ) : null}
    </div>
  );
}

export default App;
