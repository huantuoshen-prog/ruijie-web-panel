import type {
  AccountResponse,
  ActionResponse,
  AuthState,
  HealthDuration,
  HealthLogResponse,
  HealthStatusResponse,
  LogLevel,
  LogResponse,
  RuntimeStatusResponse,
  SettingsResponse,
  StatusResponse
} from "./types";

const API_ROOT = "/ruijie-cgi";

export class ApiError extends Error {
  status: number;

  payload: unknown;

  constructor(message: string, status: number, payload?: unknown) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.payload = payload;
  }
}

async function parseJsonResponse(response: Response): Promise<unknown> {
  const text = await response.text();

  if (!text) {
    return null;
  }

  try {
    return JSON.parse(text) as unknown;
  } catch {
    throw new ApiError("服务端返回了无法解析的 JSON。", response.status);
  }
}

async function requestJson<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API_ROOT}/${path}`, {
    credentials: "same-origin",
    ...init
  });

  const payload = await parseJsonResponse(response);

  if (!response.ok) {
    const message =
      typeof payload === "object" && payload !== null && "message" in payload
        ? String((payload as { message?: string }).message ?? "请求失败。")
        : "请求失败。";

    throw new ApiError(message, response.status, payload);
  }

  return payload as T;
}

function formRequest(body: Record<string, string>): RequestInit {
  const params = new URLSearchParams();

  Object.entries(body).forEach(([key, value]) => {
    params.set(key, value);
  });

  return {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8"
    },
    body: params.toString()
  };
}

export const panelApi = {
  checkAuth(): Promise<AuthState> {
    return requestJson<AuthState>("auth");
  },
  login(password: string): Promise<AuthState> {
    return requestJson<AuthState>("auth", formRequest({ password }));
  },
  logout(): Promise<ActionResponse> {
    return requestJson<ActionResponse>("auth", formRequest({ action: "logout" }));
  },
  getStatus(): Promise<StatusResponse> {
    return requestJson<StatusResponse>("status");
  },
  getAccount(): Promise<AccountResponse> {
    return requestJson<AccountResponse>("account");
  },
  saveAccount(payload: {
    username: string;
    password: string;
    operator: string;
  }): Promise<ActionResponse> {
    return requestJson<ActionResponse>("account", formRequest(payload));
  },
  getSettings(): Promise<SettingsResponse> {
    return requestJson<SettingsResponse>("settings");
  },
  saveSettings(payload: {
    proxy_url: string;
    proxy_url_https: string;
  }): Promise<ActionResponse> {
    return requestJson<ActionResponse>("settings", formRequest(payload));
  },
  getLogs(level: LogLevel, lines: number): Promise<LogResponse> {
    const params = new URLSearchParams();
    if (level) {
      params.set("level", level);
    }
    params.set("lines", String(lines));
    return requestJson<LogResponse>(`log?${params.toString()}`);
  },
  getHealth(): Promise<HealthStatusResponse> {
    return requestJson<HealthStatusResponse>("health");
  },
  updateHealth(action: "enable" | "disable", duration?: HealthDuration): Promise<HealthStatusResponse> {
    const body: Record<string, string> = { action };
    if (duration) {
      body.duration = duration;
    }
    return requestJson<HealthStatusResponse>("health", formRequest(body));
  },
  getHealthLogs(level: LogLevel, type: string, lines: number): Promise<HealthLogResponse> {
    const params = new URLSearchParams();
    if (level) {
      params.set("level", level);
    }
    if (type) {
      params.set("type", type);
    }
    params.set("lines", String(lines));
    return requestJson<HealthLogResponse>(`health-log?${params.toString()}`);
  },
  getRuntime(): Promise<RuntimeStatusResponse> {
    return requestJson<RuntimeStatusResponse>("runtime");
  },
  runDaemon(action: "start" | "stop" | "restart"): Promise<ActionResponse> {
    return requestJson<ActionResponse>("daemon", formRequest({ action }));
  },
  switchOperator(operator: "DianXin" | "LianTong"): Promise<ActionResponse> {
    return requestJson<ActionResponse>("mode", formRequest({ operator }));
  }
};
