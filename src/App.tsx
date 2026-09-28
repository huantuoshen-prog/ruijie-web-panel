import { startTransition, useEffect, useState, type FormEvent, type ReactNode } from "react";
import { accountTypeLabel, logTone, operatorLabel } from "./lib/presenters";
import type { HealthDuration, HealthStatusResponse, LogLevel, ThemeMode } from "./lib/types";
import { usePanel, type Panel } from "./lib/usePanel";

type Tab = "status" | "account" | "logs" | "system";

const TABS: Array<{ id: Tab; label: string }> = [
  { id: "status", label: "状态" },
  { id: "account", label: "账号" },
  { id: "logs", label: "日志" },
  { id: "system", label: "系统" }
];

const LEVELS: Array<{ value: LogLevel; label: string }> = [
  { value: "", label: "全部" },
  { value: "OK", label: "成功" },
  { value: "INFO", label: "信息" },
  { value: "STEP", label: "步骤" },
  { value: "WARN", label: "警告" },
  { value: "ERROR", label: "错误" }
];

const HEALTH_TYPES: Array<{ value: string; label: string }> = [
  { value: "", label: "全部类型" },
  { value: "baseline", label: "基线采样" },
  { value: "auth_success", label: "认证成功" },
  { value: "auth_failed", label: "认证失败" },
  { value: "network_error", label: "网络异常" },
  { value: "daemon", label: "守护事件" },
  { value: "monitor", label: "监听开关" }
];

const DURATIONS: Array<{ value: HealthDuration; label: string }> = [
  { value: "1d", label: "1 天" },
  { value: "3d", label: "3 天" },
  { value: "7d", label: "7 天" },
  { value: "permanent", label: "永久" }
];

const THEME_KEY = "ruijie-panel.theme";

function cn(...values: Array<string | false | null | undefined>): string {
  return values.filter(Boolean).join(" ");
}

function remaining(value?: number | null): string {
  if (typeof value !== "number" || Number.isNaN(value)) return "永久";
  if (value <= 0) return "已到期";
  if (value >= 86400) return `${Math.ceil(value / 86400)} 天`;
  if (value >= 3600) return `${Math.ceil(value / 3600)} 小时`;
  if (value >= 60) return `${Math.ceil(value / 60)} 分钟`;
  return `${value} 秒`;
}

function healthLabel(health: HealthStatusResponse | null): string {
  if (!health) return "—";
  if (health.supported === false) return "主脚本不支持";
  if (!health.enabled) return "未开启";
  if (health.mode === "permanent") return "永久开启";
  return `剩余 ${remaining(health.remaining_seconds)}`;
}

function formatTime(value?: string | number): string {
  const epoch = Number(value);
  if (Number.isFinite(epoch) && epoch > 1e9) {
    return new Date(epoch * 1000).toLocaleString("zh-CN", { hour12: false });
  }
  return value ? String(value) : "—";
}

function Rows(props: { items: Array<[string, ReactNode]> }) {
  return (
    <dl className="rows">
      {props.items.map(([k, v]) => (
        <div key={k}>
          <dt>{k}</dt>
          <dd>{v === "" || v === null || v === undefined ? "—" : v}</dd>
        </div>
      ))}
    </dl>
  );
}

function Section(props: { index?: string; title: string; aside?: ReactNode; children: ReactNode }) {
  return (
    <section className="section">
      <header>
        <h3>
          {props.index ? <span className="section__no">{props.index}</span> : null}
          {props.title}
        </h3>
        {props.aside}
      </header>
      {props.children}
    </section>
  );
}

function Btn(props: {
  children: ReactNode;
  onClick?: () => void;
  busy?: boolean;
  kind?: "primary" | "danger" | "plain";
  type?: "button" | "submit";
  disabled?: boolean;
}) {
  return (
    <button
      type={props.type ?? "button"}
      className={cn("btn", props.kind && `btn--${props.kind}`)}
      onClick={props.onClick}
      disabled={props.busy || props.disabled}
      aria-busy={props.busy || undefined}
    >
      {props.children}
    </button>
  );
}

type Tone = "ok" | "warn" | "bad" | "off";

function Node(props: { label: string; value: string; tone: Tone }) {
  return (
    <div className={cn("chain__node", `is-${props.tone}`)}>
      <span className="chain__label">{props.label}</span>
      <span className="chain__value">{props.value}</span>
    </div>
  );
}

function StatusPage({ p }: { p: Panel }) {
  const s = p.status;
  const online = s?.online;
  const netTone: Tone = online === true ? "ok" : online === false ? "bad" : "off";
  const daemonTone: Tone = !s?.daemon_running ? "off" : s.daemon_state === "ONLINE" ? "ok" : "warn";
  const authTone: Tone = online === true ? "ok" : s?.daemon_running ? "warn" : "off";
  const recent = [...p.logs].slice(-6).reverse();
  const strip = p.logs.slice(-48);

  return (
    <>
      <section className={cn("hero", `is-${netTone}`)}>
        <div className="hero__head">
          <div>
            <p className="kicker">{s?.stale ? "状态可能过期" : s?.observed_at ? `采集于 ${formatTime(s.observed_at)}` : "实时状态"}</p>
            <h2 className="hero__title">
              {online === true ? "已联网" : online === false ? "未联网" : "状态未知"}
            </h2>
            <p className="hero__sub">
              <span className="mono">{s?.username || "未配置账号"}</span>
              <span>{operatorLabel(s?.operator ?? "")}</span>
              <span>{accountTypeLabel(s?.account_type ?? "")}</span>
            </p>
          </div>
          <div className="hero__actions">
            <Btn kind="primary" busy={p.busy === "auth-reauth"} onClick={() => void p.authAction("reauth")}>
              重新认证
            </Btn>
            <Btn busy={p.busy === "auth-logout"} onClick={() => void p.authAction("logout")}>
              下线
            </Btn>
          </div>
        </div>

        <div className="chain" aria-label="连接链路">
          <Node label="守护进程" value={s?.daemon_running ? s.daemon_state || "运行中" : "已停止"} tone={daemonTone} />
          <span className={cn("chain__wire", `is-${daemonTone === "ok" ? authTone : "off"}`)} />
          <Node label="锐捷认证" value={s?.last_auth ? s.last_auth.slice(5, 16) : "—"} tone={authTone} />
          <span className={cn("chain__wire", `is-${netTone}`)} />
          <Node label="互联网" value={online === true ? "可达" : online === false ? "不可达" : "未知"} tone={netTone} />
        </div>
      </section>

      <div className="grid2">
        <Section index="01" title="守护进程">
          <div className="readout">
            <div>
              <span>已运行</span>
              <strong>{s?.daemon_uptime || "—"}</strong>
            </div>
            <div>
              <span>PID</span>
              <strong className="mono">{s?.daemon_pid || "—"}</strong>
            </div>
          </div>
          <Rows items={[["上次认证", s?.last_auth], ["主脚本", s?.version ? `v${s.version}` : ""]]} />
          <div className="actions">
            {s?.daemon_running ? (
              <>
                <Btn busy={p.busy === "daemon-restart"} onClick={() => void p.daemon("restart")}>重启</Btn>
                <Btn kind="danger" busy={p.busy === "daemon-stop"} onClick={() => void p.daemon("stop")}>停止</Btn>
              </>
            ) : (
              <Btn kind="primary" busy={p.busy === "daemon-start"} onClick={() => void p.daemon("start")}>启动</Btn>
            )}
          </div>
        </Section>

        <Section index="02" title="健康监听">
          {p.health?.supported === false ? (
            <p className="muted">{p.health.message || "主脚本版本过低，升级后可用。"}</p>
          ) : (
            <>
              <div className="readout">
                <div>
                  <span>状态</span>
                  <strong>{healthLabel(p.health)}</strong>
                </div>
                <div>
                  <span>采样间隔</span>
                  <strong>{p.health?.baseline_interval ? `${p.health.baseline_interval}s` : "—"}</strong>
                </div>
              </div>
              <Rows
                items={[
                  ["采集器", p.health?.collector_active ? "运行中" : "未运行"],
                  ["最近事件", p.health?.last_event_at]
                ]}
              />
              <div className="actions">
                <div className="seg seg--inline" role="group" aria-label="开启时长">
                  {DURATIONS.map((d) => (
                    <button
                      key={d.value}
                      type="button"
                      className={cn(d.value === "permanent" && p.health?.enabled && p.health.mode === "permanent" && "is-on")}
                      disabled={p.busy !== null}
                      onClick={() => void p.healthAction("enable", d.value)}
                    >
                      {d.label}
                    </button>
                  ))}
                </div>
                {p.health?.enabled ? (
                  <Btn kind="danger" busy={p.busy === "health-off"} onClick={() => void p.healthAction("disable")}>
                    关闭
                  </Btn>
                ) : null}
              </div>
            </>
          )}
        </Section>
      </div>

      <Section
        index="03"
        title="最近事件"
        aside={
          strip.length ? (
            <div className="strip" aria-hidden="true">
              {strip.map((line, i) => (
                <i key={i} className={`strip--${logTone(line.level)}`} />
              ))}
            </div>
          ) : null
        }
      >
        {recent.length ? <LogTable lines={recent} /> : <p className="muted">暂无日志。</p>}
      </Section>
    </>
  );
}

function LogTable(props: { lines: Panel["logs"] }) {
  return (
    <div className="log">
      {props.lines.map((line, i) => (
        <div key={`${line.ts}-${i}`} className={cn("log__row", `log__row--${logTone(line.level)}`)}>
          <time>{line.ts}</time>
          <span className="log__lv">{line.level || "-"}</span>
          <span className="log__msg">
            {line.msg}
            {line.details ? <small>{line.details}</small> : null}
          </span>
        </div>
      ))}
    </div>
  );
}

function AccountPage({ p }: { p: Panel }) {
  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    void p.saveAccount();
  };
  const submitProxy = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    void p.saveSettings();
  };

  return (
    <div className="grid2">
      <Section index="01" title="校园网账号">
        <form className="form" onSubmit={submit}>
          <label>
            <span>用户名</span>
            <input
              name="username"
              autoComplete="username"
              value={p.account.username}
              onChange={(e) => p.editAccount({ username: e.target.value })}
            />
          </label>
          <label>
            <span>密码</span>
            <input
              name="password"
              type="password"
              autoComplete="current-password"
              placeholder={p.accountRevision ? "不修改请留空" : ""}
              value={p.account.password}
              onChange={(e) => p.editAccount({ password: e.target.value })}
            />
          </label>
          <fieldset className="seg">
            <legend>运营商</legend>
            {[
              ["DianXin", "校园电信"],
              ["LianTong", "校园联通"]
            ].map(([value, label]) => (
              <label key={value} className={cn(p.account.operator === value && "is-on")}>
                <input
                  type="radio"
                  name="operator"
                  value={value}
                  checked={p.account.operator === value}
                  onChange={() => p.editAccount({ operator: value })}
                />
                {label}
              </label>
            ))}
          </fieldset>
          <p className="muted small">账号类型：{accountTypeLabel(p.account.accountType)}</p>
          <div className="actions">
            <Btn type="submit" kind="primary" busy={p.busy === "account"}>保存账号配置</Btn>
            {p.accountDirty ? <span className="muted small">有未保存的修改</span> : null}
          </div>
        </form>
      </Section>

      <Section index="02" title="代理">
        <form className="form" onSubmit={submitProxy}>
          <label>
            <span>HTTP 代理</span>
            <input
              name="proxyUrl"
              placeholder="http://host:port"
              value={p.settings.proxyUrl}
              onChange={(e) => p.editSettings({ proxyUrl: e.target.value })}
            />
          </label>
          <label>
            <span>HTTPS 代理</span>
            <input
              name="proxyUrlHttps"
              placeholder="留空则同 HTTP"
              value={p.settings.proxyUrlHttps}
              onChange={(e) => p.editSettings({ proxyUrlHttps: e.target.value })}
            />
          </label>
          <p className="muted small">认证请求通过这里转发。一般不需要设置。</p>
          <div className="actions">
            <Btn type="submit" busy={p.busy === "settings"}>保存代理</Btn>
          </div>
        </form>
      </Section>
    </div>
  );
}

function LogsPage({ p }: { p: Panel }) {
  const lines = [...p.logs].reverse();
  return (
    <Section
      title={p.logSource === "health" ? "健康日志" : "认证日志"}
      aside={<span className="muted small">{p.logs.length} / {p.logTotal} 条</span>}
    >
      <div className="toolbar">
        <div className="seg seg--inline" role="group" aria-label="日志来源">
          <button type="button" className={cn(p.logSource === "daemon" && "is-on")} onClick={() => p.setLogSource("daemon")}>
            认证日志
          </button>
          <button type="button" className={cn(p.logSource === "health" && "is-on")} onClick={() => p.setLogSource("health")}>
            健康日志
          </button>
        </div>
        <select aria-label="级别" value={p.logLevel} onChange={(e) => p.setLogLevel(e.target.value as LogLevel)}>
          {LEVELS.map((l) => <option key={l.value} value={l.value}>{l.label}</option>)}
        </select>
        {p.logSource === "health" ? (
          <select aria-label="类型" value={p.healthLogType} onChange={(e) => p.setHealthLogType(e.target.value)}>
            {HEALTH_TYPES.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
          </select>
        ) : null}
        <select aria-label="条数" value={p.logLimit} onChange={(e) => p.setLogLimit(Number(e.target.value))}>
          {[100, 200, 500].map((n) => <option key={n} value={n}>最近 {n} 条</option>)}
        </select>
        <label className="check">
          <input type="checkbox" checked={p.autoRefreshLogs} onChange={(e) => p.setAutoRefreshLogs(e.target.checked)} />
          自动刷新
        </label>
        <Btn busy={p.logsLoading} onClick={() => void p.refreshLogs()}>刷新</Btn>
      </div>
      {lines.length ? <LogTable lines={lines} /> : <p className="muted">没有符合条件的日志。</p>}
    </Section>
  );
}

function SystemPage({ p, theme, setTheme }: { p: Panel; theme: ThemeMode; setTheme: (t: ThemeMode) => void }) {
  const r = p.runtime;
  const yes = (v?: boolean) => (v === undefined ? "" : v ? "有" : "无");
  return (
    <div className="grid2">
      <Section index="01" title="运行环境">
        {r?.supported === false ? (
          <p className="muted">{r.message || "主脚本版本过低，升级后可用。"}</p>
        ) : (
          <Rows
            items={[
              ["平台", r?.platform],
              ["内核", r?.kernel],
              ["架构", r?.arch],
              ["Shell", r?.shell],
              ["BusyBox / curl / procd", r ? `${yes(r.busybox_present)} / ${yes(r.curl_present)} / ${yes(r.procd_present)}` : ""],
              ["主脚本版本", p.status?.version]
            ]}
          />
        )}
      </Section>
      <Section index="02" title="文件路径">
        <Rows
          items={[
            ["脚本目录", <code>{r?.script_dir}</code>],
            ["配置文件", <code>{r?.config_file}</code>],
            ["守护日志", <code>{r?.daemon_logfile}</code>],
            ["健康日志", <code>{r?.health_logfile}</code>],
            ["面板目录", <code>{r?.panel_web_root}</code>]
          ]}
        />
      </Section>
      <Section index="03" title="界面">
        <div className="actions">
          <div className="seg seg--inline" role="group" aria-label="主题">
            <button type="button" className={cn(theme === "light" && "is-on")} onClick={() => setTheme("light")}>浅色</button>
            <button type="button" className={cn(theme === "dark" && "is-on")} onClick={() => setTheme("dark")}>深色</button>
          </div>
          <Btn busy={p.busy === "logout"} onClick={() => void p.logout()}>退出面板</Btn>
        </div>
      </Section>
    </div>
  );
}

function Login({ p }: { p: Panel }) {
  const [password, setPassword] = useState("");
  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (await p.login(password)) setPassword("");
  };
  return (
    <main className="login">
      <form className="login__box" onSubmit={(e) => void submit(e)}>
        <div className="brand">
          <span className="brand__mark" aria-hidden="true" />
          <strong>RUIJIE</strong>
          <span className="brand__sub">校园网认证</span>
        </div>
        <h1>输入面板密码</h1>
        <p className="muted small">路由器本地面板，登录状态保留 30 天。</p>
        <label>
          <span>密码</span>
          <input
            type="password"
            autoFocus
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </label>
        {p.loginError ? <p className="error small" role="alert">{p.loginError}</p> : null}
        <Btn type="submit" kind="primary" busy={p.busy === "login"} disabled={!password}>登录</Btn>
      </form>
    </main>
  );
}

function App() {
  const p = usePanel();
  const [tab, setTab] = useState<Tab>("status");
  const [theme, setTheme] = useState<ThemeMode>(() =>
    localStorage.getItem(THEME_KEY) === "dark" ? "dark" : "light"
  );

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem(THEME_KEY, theme);
  }, [theme]);

  const { notice, setNotice } = p;
  useEffect(() => {
    if (!notice || notice.tone === "error") return;
    const timer = window.setTimeout(() => setNotice(null), 4000);
    return () => window.clearTimeout(timer);
  }, [notice, setNotice]);

  if (p.authPhase === "checking") {
    return <main className="login"><p className="muted">正在连接路由器…</p></main>;
  }
  if (p.authPhase === "unauthenticated") {
    return <Login p={p} />;
  }

  const current = TABS.find((t) => t.id === tab) ?? TABS[0];

  return (
    <div className="app">
      <header className="top">
        <div className="brand">
          <span className={cn("brand__mark", p.status?.online === true && "is-live")} aria-hidden="true" />
          <strong>RUIJIE</strong>
          <span className="brand__sub">校园网认证</span>
        </div>
        <nav className="tabs" aria-label="页面">
          {TABS.map((t) => (
            <button
              key={t.id}
              type="button"
              className={cn(tab === t.id && "is-on")}
              aria-current={tab === t.id ? "page" : undefined}
              onClick={() => startTransition(() => setTab(t.id))}
            >
              {t.label}
            </button>
          ))}
        </nav>
        <Btn busy={p.refreshing} onClick={() => void p.refresh()}>
          {p.refreshing ? "刷新中" : "刷新"}
        </Btn>
      </header>

      {notice ? (
        <div className={cn("notice", `notice--${notice.tone}`)} role="status">
          <span>{notice.message}</span>
          <button type="button" aria-label="关闭提示" onClick={() => setNotice(null)}>×</button>
        </div>
      ) : null}

      <main className="page">
        <h2 className="sr-only">{current.label}</h2>
        {tab === "status" && <StatusPage p={p} />}
        {tab === "account" && <AccountPage p={p} />}
        {tab === "logs" && <LogsPage p={p} />}
        {tab === "system" && <SystemPage p={p} theme={theme} setTheme={setTheme} />}
      </main>
    </div>
  );
}

export default App;
