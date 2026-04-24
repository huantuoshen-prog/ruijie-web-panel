export function operatorLabel(operator: string): string {
  if (operator === "DianXin") {
    return "校园电信";
  }

  if (operator === "LianTong") {
    return "校园联通";
  }

  return operator || "未设置";
}

export function accountTypeLabel(accountType: string): string {
  if (accountType === "teacher") {
    return "教师账号";
  }

  if (accountType === "student") {
    return "学生账号";
  }

  return accountType || "未知类型";
}

export function networkTone(online: boolean): "positive" | "warning" {
  return online ? "positive" : "warning";
}

export function daemonTone(
  daemonState: string,
  daemonRunning: boolean
): "positive" | "warning" | "neutral" {
  if (!daemonRunning) {
    return "neutral";
  }

  if (daemonState === "ONLINE") {
    return "positive";
  }

  return "warning";
}

export function logTone(level: string): "positive" | "warning" | "error" | "info" | "neutral" {
  switch (level.toUpperCase()) {
    case "OK":
      return "positive";
    case "WARN":
      return "warning";
    case "ERROR":
      return "error";
    case "INFO":
    case "STEP":
      return "info";
    default:
      return "neutral";
  }
}

export function metricValue(value: string | number | boolean | null | undefined): string {
  if (value === null || value === undefined || value === "") {
    return "—";
  }

  if (typeof value === "boolean") {
    return value ? "是" : "否";
  }

  return String(value);
}
