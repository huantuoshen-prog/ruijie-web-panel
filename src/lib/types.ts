export type SectionId = "overview" | "account" | "daemon" | "logs" | "settings";
export type ThemeMode = "dark" | "light";
export type LogLevel = "" | "INFO" | "OK" | "WARN" | "ERROR" | "STEP";
export type HealthDuration = "1d" | "3d" | "7d" | "permanent";
export type HealthLogType =
  | ""
  | "baseline"
  | "event"
  | "state_transition"
  | "auth_success"
  | "auth_failed"
  | "network_error"
  | "daemon"
  | "monitor";

export interface AuthState {
  success: boolean;
  authenticated?: boolean;
  message?: string;
}

export interface StatusResponse {
  installed: boolean;
  online: boolean;
  username: string;
  operator: string;
  account_type: string;
  daemon_running: boolean;
  daemon_pid: string;
  daemon_uptime: string;
  daemon_state: string;
  last_auth: string;
  version: string;
  message: string;
}

export interface AccountResponse {
  username: string;
  operator: string;
  account_type: string;
  proxy_url?: string;
}

export interface SettingsResponse {
  proxy_url: string;
  proxy_url_https: string;
}

export interface LogLine {
  ts: string;
  level: string;
  msg: string;
  type?: string;
  details?: string;
}

export interface LogResponse {
  lines: LogLine[];
  total: number;
}

export interface ActionResponse {
  success: boolean;
  message: string;
  operator?: string;
  pid?: string;
}

export interface HealthSnapshot {
  online: boolean;
  daemon_running: boolean;
  daemon_state: string;
  daemon_pid: string;
  username: string;
  account_type: string;
  operator: string;
}

export interface HealthStatusResponse {
  supported: boolean;
  message?: string;
  enabled?: boolean;
  mode?: string;
  until?: string;
  remaining_seconds?: number | null;
  collector_active?: boolean;
  baseline_interval?: number;
  redaction?: string;
  last_event_at?: string;
  snapshot?: HealthSnapshot;
}

export interface HealthLogEntry {
  ts: string;
  level: string;
  type: string;
  message: string;
  details?: Record<string, unknown> | string;
}

export interface HealthLogResponse {
  success?: boolean;
  supported?: boolean;
  message?: string;
  entries: HealthLogEntry[];
  total: number;
}

export interface RuntimeStatusResponse {
  supported: boolean;
  message?: string;
  platform?: string;
  kernel?: string;
  arch?: string;
  shell?: string;
  busybox_present?: boolean;
  curl_present?: boolean;
  nohup_backend?: string;
  script_dir?: string;
  config_file?: string;
  daemon_pidfile?: string;
  daemon_logfile?: string;
  health_logfile?: string;
  panel_installed?: boolean;
  panel_web_root?: string;
  daemon_running?: boolean;
  health_collector_active?: boolean;
}
