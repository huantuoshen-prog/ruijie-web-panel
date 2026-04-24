import { describe, expect, it } from "vitest";
import {
  accountTypeLabel,
  daemonTone,
  logTone,
  metricValue,
  networkTone,
  operatorLabel
} from "./presenters";

describe("presenters", () => {
  it("maps operator labels for campus carriers", () => {
    expect(operatorLabel("DianXin")).toBe("校园电信");
    expect(operatorLabel("LianTong")).toBe("校园联通");
  });

  it("keeps teacher account types intact", () => {
    expect(accountTypeLabel("teacher")).toBe("教师账号");
  });

  it("returns stable tones for status indicators", () => {
    expect(networkTone(true)).toBe("positive");
    expect(daemonTone("ONLINE", true)).toBe("positive");
    expect(daemonTone("STOPPED", false)).toBe("neutral");
    expect(logTone("ERROR")).toBe("error");
  });

  it("renders fallbacks for empty metrics", () => {
    expect(metricValue("")).toBe("—");
    expect(metricValue(false)).toBe("否");
  });
});
