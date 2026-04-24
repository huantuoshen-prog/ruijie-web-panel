import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import App from "./App";

afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe("App bootstrap", () => {
  it("checks auth only once while showing the login layer", async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = String(input);

      if (url.includes("/ruijie-cgi/auth")) {
        return new Response(JSON.stringify({ success: true, authenticated: false }), {
          status: 200,
          headers: { "Content-Type": "application/json" }
        });
      }

      if (url.includes("api.github.com")) {
        return new Response(JSON.stringify({}), {
          status: 403,
          headers: { "Content-Type": "application/json" }
        });
      }

      throw new Error(`Unexpected fetch: ${url}`);
    });

    vi.stubGlobal("fetch", fetchMock);

    render(<App />);

    await screen.findByRole("heading", { name: "输入面板密码" });

    await waitFor(() => {
      const authCalls = fetchMock.mock.calls.filter(([input]) =>
        String(input).includes("/ruijie-cgi/auth")
      );

      expect(authCalls).toHaveLength(1);
    });
  });

  it("does not fetch external release metadata when opening settings", async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const url = String(input);

      if (url.includes("/ruijie-cgi/auth")) {
        return new Response(JSON.stringify({ success: true, authenticated: true }), {
          status: 200,
          headers: { "Content-Type": "application/json" }
        });
      }

      if (url.includes("/ruijie-cgi/status")) {
        return new Response(
          JSON.stringify({
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
          }),
          {
            status: 200,
            headers: { "Content-Type": "application/json" }
          }
        );
      }

      if (url.includes("/ruijie-cgi/account")) {
        return new Response(
          JSON.stringify({
            username: "1720240564",
            operator: "DianXin",
            account_type: "student"
          }),
          {
            status: 200,
            headers: { "Content-Type": "application/json" }
          }
        );
      }

      if (url.includes("/ruijie-cgi/settings")) {
        return new Response(
          JSON.stringify({
            proxy_url: "",
            proxy_url_https: ""
          }),
          {
            status: 200,
            headers: { "Content-Type": "application/json" }
          }
        );
      }

      if (url.includes("/ruijie-cgi/log")) {
        return new Response(
          JSON.stringify({
            lines: [],
            total: 0
          }),
          {
            status: 200,
            headers: { "Content-Type": "application/json" }
          }
        );
      }

      throw new Error(`Unexpected fetch: ${url}`);
    });

    vi.stubGlobal("fetch", fetchMock);

    render(<App />);

    await screen.findByRole("heading", { name: "总览", level: 2 });

    fireEvent.click(screen.getByRole("button", { name: "设置 代理、主题与个性化" }));

    await screen.findByRole("heading", { name: "设置", level: 2 });

    const externalCalls = fetchMock.mock.calls.filter(([input]) =>
      String(input).includes("api.github.com")
    );

    expect(externalCalls).toHaveLength(0);
  });
});
