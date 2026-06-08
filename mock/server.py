#!/usr/bin/env python3
"""
Mock CGI 服务器 - 模拟 OpenWrt 路由器上的锐捷 Web 管理面板
用于本地开发验证，无需真实路由器即可测试前端

启动: python3 mock/server.py
访问: http://127.0.0.1:8080/
默认面板密码: panel-secret
"""

import json
import time
import random
import os
import secrets
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse, unquote_plus

HOST = "127.0.0.1"
PORT = 8080
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SESSION_COOKIE_NAME = "ruijie_panel_session"
SESSION_MAX_AGE = 2592000


def calc_uptime(start_time):
    if not start_time:
        return "—"
    diff = time.time() - start_time
    if diff < 0:
        return "—"
    if diff < 60:
        return f"{int(diff)}秒"
    if diff < 3600:
        return f"{int(diff // 60)}分钟"
    h = int(diff // 3600)
    m = int((diff % 3600) // 60)
    return f"{h}小时{m}分钟"


state = {
    "installed": True,
    "online": True,
    "username": "2023000000",
    "operator": "DianXin",
    "account_type": "student",
    "daemon_running": True,
    "daemon_pid": 12345,
    "daemon_start_time": time.time() - (4 * 3600 + 23 * 60),
    "daemon_state": "ONLINE",
    "last_auth": "",
    "version": "3.1",
    "proxy_url": "",
    "proxy_url_https": "",
    "log_lines": [],
    "panel_password": "panel-secret",
    "sessions": {},
}


def init_log():
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    state["last_auth"] = ts
    state["log_lines"] = [
        {"ts": ts, "level": "OK", "msg": "守护进程已启动 (PID 12345)"},
        {"ts": ts, "level": "INFO", "msg": "加载配置: 用户名=2023000000, 运营商=DianXin"},
        {"ts": ts, "level": "STEP", "msg": "开始网络检测..."},
        {"ts": ts, "level": "OK", "msg": "网络检测正常，已连接"},
        {"ts": ts, "level": "INFO", "msg": "执行锐捷认证 (电信)..."},
        {"ts": ts, "level": "WARN", "msg": "检测到旧版配置文件，正在迁移"},
        {"ts": ts, "level": "ERROR", "msg": "服务器连接超时，将重试"},
    ]


init_log()


def json_esc(s):
    if s is None:
        return ""
    s = str(s)
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("<", "\\u003c").replace(">", "\\u003e")


def parse_form(body):
    params = {}
    if not body:
        return params
    for pair in body.split("&"):
        if "=" in pair:
            k, v = pair.split("=", 1)
            params[unquote_plus(k)] = unquote_plus(v)
    return params


def parse_body(environ):
    try:
        length = int(environ.get("CONTENT_LENGTH", 0) or 0)
        if length <= 0:
            return {}
        body = environ["wsgi_input"].read(length).decode()
        return parse_form(body)
    except Exception:
        return {}


def unauth():
    return json.dumps({"success": False, "message": "请先登录 Web 面板"}), 401, {}


def session_expiry():
    return time.time() + SESSION_MAX_AGE


def create_session():
    token = secrets.token_hex(16)
    state["sessions"][token] = session_expiry()
    return token


def parse_cookies(environ):
    header = environ.get("HTTP_COOKIE", "")
    cookies = {}
    for part in header.split(";"):
        if "=" not in part:
            continue
        key, value = part.split("=", 1)
        cookies[key.strip()] = value.strip()
    return cookies


def current_session_token(environ):
    token = parse_cookies(environ).get(SESSION_COOKIE_NAME, "")
    if not token:
        return ""
    expiry = state["sessions"].get(token)
    if not expiry:
        return ""
    if expiry <= time.time():
        state["sessions"].pop(token, None)
        return ""
    return token


def refresh_session(token):
    state["sessions"][token] = session_expiry()


def session_cookie_header(token, clear=False):
    if clear:
        return (
            f"{SESSION_COOKIE_NAME}=deleted; Path=/; Max-Age=0; "
            "Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly; SameSite=Strict"
        )
    return (
        f"{SESSION_COOKIE_NAME}={token}; Path=/; Max-Age={SESSION_MAX_AGE}; "
        "HttpOnly; SameSite=Strict"
    )


def require_auth(environ):
    token = current_session_token(environ)
    if not token:
        return None, None, unauth()
    refresh_session(token)
    return token, {"Set-Cookie": session_cookie_header(token)}, None


def handle_auth(environ):
    method = environ.get("REQUEST_METHOD", "GET")
    token = current_session_token(environ)
    if method == "GET":
        headers = {}
        if token:
            refresh_session(token)
            headers["Set-Cookie"] = session_cookie_header(token)
        return json.dumps({"success": True, "authenticated": bool(token)}), 200, headers

    params = parse_body(environ)
    if params.get("action") == "logout":
        if token:
            state["sessions"].pop(token, None)
        return json.dumps({"success": True, "message": "已退出登录"}), 200, {
            "Set-Cookie": session_cookie_header("", clear=True)
        }

    if params.get("password") == state["panel_password"]:
        token = create_session()
        return json.dumps({"success": True, "message": "登录成功"}), 200, {
            "Set-Cookie": session_cookie_header(token)
        }

    return json.dumps({"success": False, "message": "面板密码错误"}), 200, {}


def handle_status(environ):
    token, headers, failure = require_auth(environ)
    if failure:
        return failure
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    state["last_auth"] = ts
    return json.dumps({
        "installed": True,
        "online": state["online"],
        "username": state["username"],
        "operator": state["operator"],
        "account_type": state["account_type"],
        "daemon_running": state["daemon_running"],
        "daemon_pid": str(state["daemon_pid"]) if state["daemon_running"] else "",
        "daemon_uptime": calc_uptime(state.get("daemon_start_time")) if state["daemon_running"] else "—",
        "daemon_state": state["daemon_state"],
        "last_auth": state["last_auth"],
        "version": state["version"],
        "message": "",
    }), 200, headers


def handle_account(environ):
    token, headers, failure = require_auth(environ)
    if failure:
        return failure
    method = environ.get("REQUEST_METHOD", "GET")
    if method == "POST":
        try:
            params = parse_body(environ)
        except Exception as exc:
            return json.dumps({"success": False, "message": f"保存失败: {exc}"}), 500, headers
        if "username" in params:
            state["username"] = params["username"]
        if "operator" in params:
            state["operator"] = params["operator"]
        return json.dumps({"success": True, "message": "账号已保存"}), 200, headers
    return json.dumps({
        "username": state["username"],
        "password": "********",
        "operator": state["operator"],
        "account_type": state["account_type"],
        "proxy_url": state["proxy_url"],
    }), 200, headers


def handle_daemon(environ):
    token, headers, failure = require_auth(environ)
    if failure:
        return failure
    params = parse_body(environ)
    action = params.get("action", "")
    ts = time.strftime("%Y-%m-%d %H:%M:%S")

    if action == "start":
        state["daemon_running"] = True
        state["daemon_pid"] = random.randint(10000, 99999)
        state["daemon_state"] = "ONLINE"
        state["daemon_start_time"] = time.time()
        state["log_lines"].append({"ts": ts, "level": "OK", "msg": "守护进程已启动"})
        return json.dumps({"success": True, "pid": str(state["daemon_pid"]), "message": "守护进程已启动"}), 200, headers
    if action == "stop":
        state["daemon_running"] = False
        state["daemon_state"] = "STOPPED"
        state["daemon_start_time"] = None
        state["log_lines"].append({"ts": ts, "level": "INFO", "msg": "守护进程已停止"})
        return json.dumps({"success": True, "message": "守护进程已停止"}), 200, headers
    if action == "restart":
        state["daemon_running"] = True
        state["daemon_pid"] = random.randint(10000, 99999)
        state["daemon_state"] = "ONLINE"
        state["daemon_start_time"] = time.time()
        state["log_lines"].append({"ts": ts, "level": "OK", "msg": "守护进程已重启"})
        return json.dumps({"success": True, "pid": str(state["daemon_pid"]), "message": "守护进程已重启"}), 200, headers
    return json.dumps({"success": False, "message": "未知操作，请使用 start/stop/restart"}), 400, headers


def handle_mode(environ):
    token, headers, failure = require_auth(environ)
    if failure:
        return failure
    params = parse_body(environ)
    operator = params.get("operator", "")
    if operator not in ("DianXin", "LianTong"):
        return json.dumps({"success": False, "message": "运营商参数无效"}), 400, headers

    state["operator"] = operator
    state["online"] = True
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    op_name = "电信" if operator == "DianXin" else "联通"
    state["log_lines"].append({"ts": ts, "level": "OK", "msg": f"已切换到{op_name}，网络已连接"})
    return json.dumps({"success": True, "message": f"已切换到{operator}，网络已连接", "operator": operator}), 200, headers


def handle_log(environ):
    token, headers, failure = require_auth(environ)
    if failure:
        return failure
    qs = parse_qs(environ.get("QUERY_STRING", ""))
    level = qs.get("level", [""])[0]
    try:
        limit = int(qs.get("lines", ["200"])[0])
    except Exception:
        limit = 200

    lines = state["log_lines"][-limit:]
    if level:
        lines = [line for line in lines if line["level"].upper() == level.upper()]

    result = [{"ts": line["ts"], "level": line["level"], "msg": json_esc(line["msg"])} for line in lines]
    return json.dumps({"lines": result, "total": len(result)}), 200, headers


def handle_settings(environ):
    token, headers, failure = require_auth(environ)
    if failure:
        return failure
    method = environ.get("REQUEST_METHOD", "GET")
    if method == "POST":
        try:
            params = parse_body(environ)
        except Exception:
            return json.dumps({"success": False, "message": "保存失败"}), 500, headers
        if "proxy_url" in params:
            state["proxy_url"] = params["proxy_url"]
        if "proxy_url_https" in params:
            state["proxy_url_https"] = params["proxy_url_https"]
        return json.dumps({"success": True, "message": "设置已保存"}), 200, headers
    return json.dumps({
        "proxy_url": state["proxy_url"],
        "proxy_url_https": state["proxy_url_https"],
    }), 200, headers


class RuijieHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path in ("/", "/index.html"):
            self.serve_file(os.path.join(BASE_DIR, "..", "index.html"))
            return
        if parsed.path.startswith("/ruijie-cgi/"):
            self.handle_cgi(parsed.path)
            return
        self.send_error(404)

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path.startswith("/ruijie-cgi/"):
            self.handle_cgi(parsed.path)
            return
        self.send_error(404)

    def handle_cgi(self, path):
        script = path[len("/ruijie-cgi/"):].split("?")[0]
        if script.endswith('.sh'):
            script = script[:-3]

        handlers = {
            "auth": handle_auth,
            "status": handle_status,
            "account": handle_account,
            "daemon": handle_daemon,
            "mode": handle_mode,
            "log": handle_log,
            "settings": handle_settings,
        }

        if script not in handlers:
            self.send_json({"success": False, "message": "未知接口"}, status=404)
            return

        environ = {
            "REQUEST_METHOD": self.command,
            "QUERY_STRING": urlparse(path).query,
            "CONTENT_LENGTH": self.headers.get("Content-Length", ""),
            "HTTP_COOKIE": self.headers.get("Cookie", ""),
            "wsgi_input": self.rfile,
        }

        result, status, headers = handlers[script](environ)
        self.send_json_str(result, status=status, headers=headers)

    def serve_file(self, filepath):
        if not os.path.exists(filepath):
            self.send_error(404, f"File not found: {filepath}")
            return
        with open(filepath, 'rb') as f:
            content = f.read()
        ext = os.path.splitext(filepath)[1].lstrip('.')
        mime = {'html': 'text/html; charset=utf-8', 'css': 'text/css', 'js': 'application/javascript'}
        self.send_response(200)
        self.send_header('Content-Type', mime.get(ext, 'text/plain'))
        self.send_header('Content-Length', len(content))
        self.end_headers()
        self.wfile.write(content)

    def send_json_str(self, text, status=200, headers=None):
        data = text.encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        for key, value in (headers or {}).items():
            self.send_header(key, value)
        self.send_header('Content-Length', len(data))
        self.end_headers()
        self.wfile.write(data)

    def send_json(self, data, status=200):
        self.send_json_str(json.dumps(data), status=status)

<<<<<<< HEAD
# ---------- 入口 ----------
if __name__ == "__main__":
    print("=" * 50)
    print("  锐捷 Web 管理面板 - Mock 服务器")
    print("=" * 50)
    print(f"  访问: http://{HOST}:{PORT}/")
    print()
    print("  模拟场景:")
    print("    [状态]  已连接 | 守护进程运行中 | 账号: 2023000000")
    print("    [日志]  含 1 条 XSS payload 测试行")
    print("    [账号]  保存后实时更新状态")
    print("    [守护]  启动/停止/重启有效，PID 随机生成")
    print("    [模式]  电信/联通切换有效")
    print("    [设置]  代理配置保存有效")
    print()
    print("  按 Ctrl+C 停止")
    print()
=======

if __name__ == '__main__':
    print('=' * 50)
    print('  锐捷 Web 管理面板 - Mock 服务器')
    print('=' * 50)
    print(f'  访问: http://{HOST}:{PORT}/')
    print('')
    print('  模拟场景:')
    print('    [认证]  面板密码: panel-secret')
    print('    [状态]  已连接 | 守护进程运行中 | 账号: 2023000000')
    print('    [日志]  含 1 条 XSS payload 测试行')
    print('    [账号]  保存后实时更新状态')
    print('    [守护]  启动/停止/重启有效，PID 随机生成')
    print('    [模式]  电信/联通切换有效')
    print('    [设置]  代理配置保存有效')
    print('')
    print('  按 Ctrl+C 停止')
    print('')
>>>>>>> e40adb4 (feat: add panel session authentication)
    server = HTTPServer((HOST, PORT), RuijieHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('已停止')
        server.shutdown()
