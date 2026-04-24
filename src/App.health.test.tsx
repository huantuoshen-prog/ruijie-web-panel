import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import App from "./App";

function buildJsonResponse(body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { "Content-Type": "application/json" }
  });
}

afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe("App health monitor surfaces", () => {
  it("renders health controls and runtime details when backend supports them", async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = String(input);

      if (url.includes("/ruijie-cgi/auth")) {
        return buildJsonResponse({ success: true, authenticated: true });
      }

      if (url.includes("/ruijie-cgi/status")) {
        return buildJsonResponse({
          installed: true,
          online: true,
          username: "1720240564",
          operator: "DianXin",
          account_type: "student",
          daemon_running: true,
          daemon_pid: "12345",
          daemon_uptime: "4小时23分钟",
          daemon_state: "ONLINE",
          last_auth: "2026-04-22 14:00:00",
          version: "3.1",
          message: ""
        });
      }

      if (url.includes("/ruijie-cgi/account")) {
        return buildJsonResponse({
          username: "1720240564",
          operator: "DianXin",
          account_type: "student"
        });
      }

      if (url.includes("/ruijie-cgi/settings")) {
        return buildJsonResponse({
          proxy_url: "",
          proxy_url_https: ""
        });
      }

      if (url.includes("/ruijie-cgi/log")) {
        return buildJsonResponse({
          lines: [],
          total: 0
        });
      }

      if (url.includes("/ruijie-cgi/health-log")) {
        return buildJsonResponse({
          entries: [],
          total: 0
        });
      }

      if (url.includes("/ruijie-cgi/health")) {
        return buildJsonResponse({
          supported: true,
          enabled: true,
          mode: "timed",
          until: "1999999999",
          remaining_seconds: 12345,
          collector_active: true,
          baseline_interval: 900,
          redaction: "mask_password_and_session_only",
          last_event_at: "2026-04-22 14:10:00",
          snapshot: {
            online: true,
            daemon_running: true,
            daemon_state: "ONLINE",
            daemon_pid: "12345",
            username: "1720240564",
            account_type: "student",
            operator: "DianXin"
          }
        });
      }

      if (url.includes("/ruijie-cgi/runtime")) {
        return buildJsonResponse({
          supported: true,
          platform: "openwrt",
          kernel: "5.10.0",
          arch: "aarch64",
          shell: "sh",
          busybox_present: true,
          curl_present: true,
          nohup_backend: "nohup",
          script_dir: "/etc/ruijie",
          config_file: "/root/.config/ruijie/ruijie.conf",
          daemon_pidfile: "/var/run/ruijie-daemon.pid",
          daemon_logfile: "/var/log/ruijie-daemon.log",
          health_logfile: "/var/log/ruijie-health.log",
          panel_installed: true,
          panel_web_root: "/www/ruijie-panel",
          daemon_running: true,
          health_collector_active: true
        });
      }

      throw new Error(`Unexpected fetch: ${url}`);
    });

    vi.stubGlobal("fetch", fetchMock);

    render(<App />);

    await screen.findByRole("heading", { name: "总览", level: 2 });
    expect(screen.getAllByText(/健康监听/i).length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole("button", { name: "守护进程 服务控制与运行指标" }));
    await screen.findByRole("heading", { name: "守护进程", level: 2 });
    expect(screen.getByRole("button", { name: "开启 3 天" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "永久开启" })).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "日志 实时事件与筛选" }));
    await screen.findByRole("heading", { name: "日志", level: 2 });
    expect(screen.getByRole("button", { name: "健康日志" })).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "设置 代理、主题与个性化" }));
    await screen.findByRole("heading", { name: "设置", level: 2 });
    expect(screen.getAllByText("运行环境").length).toBeGreaterThan(0);
    expect(screen.getByText("openwrt")).toBeInTheDocument();
  });

  it("shows an upgrade notice when health monitoring is unsupported", async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = String(input);

      if (url.includes("/ruijie-cgi/auth")) {
        return buildJsonResponse({ success: true, authenticated: true });
      }

      if (url.includes("/ruijie-cgi/status")) {
        return buildJsonResponse({
          installed: true,
          online: true,
          username: "1720240564",
          operator: "DianXin",
          account_type: "student",
          daemon_running: true,
          daemon_pid: "12345",
          daemon_uptime: "4小时23分钟",
          daemon_state: "ONLINE",
          last_auth: "2026-04-22 14:00:00",
          version: "3.1",
          message: ""
        });
      }

      if (url.includes("/ruijie-cgi/account")) {
        return buildJsonResponse({
          username: "1720240564",
          operator: "DianXin",
          account_type: "student"
        });
      }

      if (url.includes("/ruijie-cgi/settings")) {
        return buildJsonResponse({
          proxy_url: "",
          proxy_url_https: ""
        });
      }

      if (url.includes("/ruijie-cgi/log")) {
        return buildJsonResponse({
          lines: [],
          total: 0
        });
      }

      if (url.includes("/ruijie-cgi/health-log")) {
        return buildJsonResponse({
          entries: [],
          total: 0
        });
      }

      if (url.includes("/ruijie-cgi/health")) {
        return buildJsonResponse({
          supported: false,
          message: "主脚本版本过低，需升级后使用"
        });
      }

      if (url.includes("/ruijie-cgi/runtime")) {
        return buildJsonResponse({
          supported: false,
          message: "主脚本版本过低，需升级后使用"
        });
      }

      throw new Error(`Unexpected fetch: ${url}`);
    });

    vi.stubGlobal("fetch", fetchMock);

    render(<App />);

    await screen.findByRole("heading", { name: "总览", level: 2 });
    expect(screen.getAllByText("主脚本版本过低，需升级后使用").length).toBeGreaterThan(0);
  });
});
