#!/usr/bin/env python3
"""Mobile-mcp helpers for FlutterFire demo automation (Android + iOS)."""

from __future__ import annotations

import json
import re
import select
import subprocess
import sys
import time
from typing import Any

MCP = ["mcp-server-mobile", "--stdio"]


def _mcp_session() -> tuple[subprocess.Popen[str], Any]:
    proc = subprocess.Popen(
        MCP,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )

    def send(msg: dict[str, Any]) -> None:
        assert proc.stdin is not None
        proc.stdin.write(json.dumps(msg) + "\n")
        proc.stdin.flush()

    def read_response(timeout: float = 30) -> dict[str, Any] | None:
        assert proc.stdout is not None
        buf = ""
        deadline = time.time() + timeout
        while time.time() < deadline:
            ready, _, _ = select.select([proc.stdout], [], [], 0.5)
            if not ready:
                continue
            chunk = proc.stdout.readline()
            if not chunk:
                continue
            buf += chunk
            try:
                return json.loads(buf.strip())
            except json.JSONDecodeError:
                continue
        return None

    send(
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "famon-demo", "version": "1.0"},
            },
        }
    )
    read_response(10)
    return proc, (send, read_response)


def _call_tool(name: str, arguments: dict[str, Any] | None = None) -> str:
    proc, (send, read_response) = _mcp_session()
    send(
        {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {"name": name, "arguments": arguments or {}},
        }
    )
    resp = read_response(45)
    proc.terminate()
    if not resp:
        return ""
    content = resp.get("result", {}).get("content", [])
    parts: list[str] = []
    for block in content:
        if block.get("type") == "text":
            parts.append(block.get("text", ""))
    return "\n".join(parts).strip()


def _call_tool_in_session(
    send: Any,
    read_response: Any,
    name: str,
    arguments: dict[str, Any] | None = None,
    request_id: int = 2,
) -> str:
    send(
        {
            "jsonrpc": "2.0",
            "id": request_id,
            "method": "tools/call",
            "params": {"name": name, "arguments": arguments or {}},
        }
    )
    resp = read_response(45)
    if not resp:
        return ""
    content = resp.get("result", {}).get("content", [])
    parts: list[str] = []
    for block in content:
        if block.get("type") == "text":
            parts.append(block.get("text", ""))
    return "\n".join(parts).strip()


def _parse_devices(text: str) -> list[dict[str, str]]:
    """Parse mobile_list_available_devices output into {id, label, kind}."""
    devices: list[dict[str, str]] = []
    if not text.strip():
        return devices
    try:
        data = json.loads(text)
        raw = data.get("devices") or data.get("result") or []
        if isinstance(raw, list):
            for item in raw:
                if isinstance(item, str):
                    devices.append({"id": item, "label": item, "kind": "unknown"})
                elif isinstance(item, dict):
                    devices.append(
                        {
                            "id": str(item.get("id") or item.get("device") or ""),
                            "label": str(item.get("name") or item.get("label") or item.get("id") or ""),
                            "kind": str(item.get("type") or item.get("platform") or "unknown"),
                        }
                    )
            return [d for d in devices if d["id"]]
    except json.JSONDecodeError:
        pass

    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        # "iPhone 16 Pro (ABC-UUID)" or bare id
        m = re.match(r"^(?P<label>.+?)\s+\((?P<id>[0-9A-Fa-f-]{8,})\)$", line)
        if m:
            label = m.group("label").strip()
            kind = "ios-simulator" if "simulator" in label.lower() else "unknown"
            if "android" in label.lower() or "emulator" in label.lower():
                kind = "android"
            devices.append({"id": m.group("id"), "label": label, "kind": kind})
            continue
        if re.match(r"^[0-9A-Fa-f-]{8,}$", line):
            devices.append({"id": line, "label": line, "kind": "unknown"})
    return devices


def pick_device(platform: str) -> str:
    text = _call_tool("mobile_list_available_devices", {})
    return _pick_device_from_text(platform, text)


def _pick_device_from_text(platform: str, text: str) -> str:
    devices = _parse_devices(text)
    if not devices:
        raise SystemExit(
            "No mobile-mcp devices found. "
            "Android: start emulator or connect USB device (adb devices). "
            "iOS: boot a simulator (open Simulator.app) or connect a device."
        )

    def is_android(d: dict[str, str]) -> bool:
        blob = f"{d['label']} {d['id']} {d['kind']}".lower()
        return "android" in blob or "emulator" in blob or re.match(r"^[0-9a-f]{8}$", d["id"])

    def is_ios_sim(d: dict[str, str]) -> bool:
        blob = f"{d['label']} {d['id']} {d['kind']}".lower()
        return "simulator" in blob or "ios" in blob and "sim" in blob

    def is_ios_device(d: dict[str, str]) -> bool:
        blob = f"{d['label']} {d['id']} {d['kind']}".lower()
        return "iphone" in blob or "ipad" in blob

    if platform == "android":
        for d in devices:
            if is_android(d):
                return d["id"]
        return devices[0]["id"]
    if platform == "ios-simulator":
        for d in devices:
            if is_ios_sim(d):
                return d["id"]
        for d in devices:
            if "ios" in f"{d['label']} {d['id']}".lower():
                return d["id"]
        raise SystemExit("No iOS Simulator in mobile-mcp device list — boot one in Simulator.app")
    if platform == "ios-device":
        for d in devices:
            if is_ios_device(d) and "simulator" not in d["label"].lower():
                return d["id"]
        raise SystemExit("No physical iOS device in mobile-mcp device list")

    raise SystemExit(f"Unknown FAMON_DEMO_PLATFORM: {platform}")


def _parse_screen_size(text: str) -> tuple[int, int]:
    """Parse mobile_get_screen_size output → (width, height)."""
    try:
        data = json.loads(text.strip())
        if isinstance(data, dict):
            w = int(data.get("width") or data.get("w") or 0)
            h = int(data.get("height") or data.get("h") or 0)
            if w > 0 and h > 0:
                return w, h
    except json.JSONDecodeError:
        pass
    m = re.search(r"width[=:\s]+(\d+).*height[=:\s]+(\d+)", text, re.I | re.S)
    if m:
        return int(m.group(1)), int(m.group(2))
    m = re.search(r"(\d+)\s*x\s*(\d+)", text, re.I)
    if m:
        return int(m.group(1)), int(m.group(2))
    raise SystemExit(f"Could not parse screen size from:\n{text[:500]}")


def tap_coordinates(device: str, x: int, y: int) -> None:
    _call_tool(
        "mobile_click_on_screen_at_coordinates",
        {"device": device, "x": x, "y": y},
    )


def tap_coordinates_with_call(call_tool: Any, device: str, x: int, y: int) -> None:
    call_tool(
        "mobile_click_on_screen_at_coordinates",
        {"device": device, "x": x, "y": y},
    )


def open_tabs_and_switch(device: str, gap_seconds: float = 2.1) -> None:
    """FAB → TabsPage; switch tabs so logScreenView fires (screen_view events)."""
    # Prefer accessibility label if the FAB is exposed; else bottom-right heuristic.
    text = _call_tool("mobile_list_elements_on_screen", {"device": device})
    opened = False
    if text.strip():
        blob = text.strip()
        if blob.startswith("Found these elements"):
            blob = blob.split(":", 1)[-1].strip()
        try:
            elements = json.loads(blob)
            if isinstance(elements, list):
                fallback_button: tuple[int, int] | None = None
                for el in elements:
                    if not isinstance(el, dict):
                        continue
                    label = str(el.get("label") or el.get("name") or "").lower()
                    el_type = str(el.get("type") or el.get("class") or "").lower()
                    coords = el.get("coordinates") or {}
                    if (
                        fallback_button is None
                        and el_type == "button"
                        and not label
                        and isinstance(coords, dict)
                        and "x" in coords
                        and "y" in coords
                    ):
                        x = int(coords["x"]) + int(coords.get("width", 0)) // 2
                        y = int(coords["y"]) + int(coords.get("height", 0)) // 2
                        fallback_button = (x, y)
                    if "floating" in el_type or label in ("tab", "tabs"):
                        if isinstance(coords, dict) and "x" in coords and "y" in coords:
                            x = int(coords["x"]) + int(coords.get("width", 0)) // 2
                            y = int(coords["y"]) + int(coords.get("height", 0)) // 2
                            tap_coordinates(device, x, y)
                            opened = True
                            break
                if not opened and fallback_button is not None:
                    tap_coordinates(device, fallback_button[0], fallback_button[1])
                    opened = True
        except json.JSONDecodeError:
            pass

    if not opened:
        size_text = _call_tool("mobile_get_screen_size", {"device": device})
        w, h = _parse_screen_size(size_text)
        tap_coordinates(device, int(w * 0.92), int(h * 0.88))

    time.sleep(gap_seconds)
    tap_by_label(device, "RIGHT")
    time.sleep(gap_seconds)
    tap_by_label(device, "LEFT")


def open_tabs_and_switch_with_call(
    call_tool: Any,
    device: str,
    gap_seconds: float = 2.1,
) -> None:
    text = call_tool("mobile_list_elements_on_screen", {"device": device})
    opened = False
    if text.strip():
        blob = text.strip()
        if blob.startswith("Found these elements"):
            blob = blob.split(":", 1)[-1].strip()
        try:
            elements = json.loads(blob)
            if isinstance(elements, list):
                fallback_button: tuple[int, int] | None = None
                for el in elements:
                    if not isinstance(el, dict):
                        continue
                    label = str(el.get("label") or el.get("name") or "").lower()
                    el_type = str(el.get("type") or el.get("class") or "").lower()
                    coords = el.get("coordinates") or {}
                    if (
                        fallback_button is None
                        and el_type == "button"
                        and not label
                        and isinstance(coords, dict)
                        and "x" in coords
                        and "y" in coords
                    ):
                        x = int(coords["x"]) + int(coords.get("width", 0)) // 2
                        y = int(coords["y"]) + int(coords.get("height", 0)) // 2
                        fallback_button = (x, y)
                    if "floating" in el_type or label in ("tab", "tabs"):
                        if isinstance(coords, dict) and "x" in coords and "y" in coords:
                            x = int(coords["x"]) + int(coords.get("width", 0)) // 2
                            y = int(coords["y"]) + int(coords.get("height", 0)) // 2
                            tap_coordinates_with_call(call_tool, device, x, y)
                            opened = True
                            break
                if not opened and fallback_button is not None:
                    tap_coordinates_with_call(call_tool, device, fallback_button[0], fallback_button[1])
                    opened = True
        except json.JSONDecodeError:
            pass

    if not opened:
        size_text = call_tool("mobile_get_screen_size", {"device": device})
        w, h = _parse_screen_size(size_text)
        tap_coordinates_with_call(call_tool, device, int(w * 0.92), int(h * 0.88))

    time.sleep(gap_seconds)
    tap_by_label_with_call(call_tool, device, "RIGHT")
    time.sleep(gap_seconds)
    tap_by_label_with_call(call_tool, device, "LEFT")


def tap_by_label(device: str, label_substring: str) -> tuple[int, int]:
    text = _call_tool("mobile_list_elements_on_screen", {"device": device})
    return _tap_by_label_from_text(_call_tool, device, label_substring, text)


def tap_by_label_with_call(
    call_tool: Any,
    device: str,
    label_substring: str,
) -> tuple[int, int]:
    text = call_tool("mobile_list_elements_on_screen", {"device": device})
    return _tap_by_label_from_text(call_tool, device, label_substring, text)


def _tap_by_label_from_text(
    call_tool: Any,
    device: str,
    label_substring: str,
    text: str,
) -> tuple[int, int]:
    if not text:
        raise SystemExit("mobile_list_elements_on_screen returned empty output")

    needle = label_substring.lower()

    # mobile-mcp often returns one JSON array of elements on a single line.
    blob = text.strip()
    if blob.startswith("Found these elements"):
        blob = blob.split(":", 1)[-1].strip()
    try:
        elements = json.loads(blob)
        if isinstance(elements, list):
            for el in elements:
                if not isinstance(el, dict):
                    continue
                label = str(el.get("label") or el.get("name") or "").lower()
                if needle not in label:
                    continue
                coords = el.get("coordinates") or {}
                if isinstance(coords, dict) and "x" in coords and "y" in coords:
                    x = int(coords["x"]) + int(coords.get("width", 0)) // 2
                    y = int(coords["y"]) + int(coords.get("height", 0)) // 2
                    call_tool(
                        "mobile_click_on_screen_at_coordinates",
                        {"device": device, "x": x, "y": y},
                    )
                    return x, y
    except json.JSONDecodeError:
        pass

    for line in text.splitlines():
        if needle not in line.lower():
            continue
        coords = re.search(
            r'"?x"?\s*[:=]\s*(\d+).*?"?y"?\s*[:=]\s*(\d+)',
            line,
            re.IGNORECASE,
        )
        if coords:
            x, y = int(coords.group(1)), int(coords.group(2))
            call_tool(
                "mobile_click_on_screen_at_coordinates",
                {"device": device, "x": x, "y": y},
            )
            return x, y

    raise SystemExit(
        f'Could not find "{label_substring}" on screen. '
        "Open the FlutterFire example home screen and retry.\n"
        f"Elements snapshot:\n{text[:2000]}"
    )


def run_button_tour(platform: str, gap_seconds: float = 2.1) -> None:
    labels = [
        "Test logEvent",
        "Test standard event types",
        "Test setUserId",
        "Test setAnalyticsCollectionEnabled",
        "Test setSessionTimeoutDuration",
        "Test setUserProperty",
        "Test appInstanceId",
        "Test resetAnalyticsData",
        "Test setConsent",
        "Test setDefaultEventParameters",
        "Test initiateOnDeviceConversionMeasurement",
        "Test logTransaction",
    ]
    proc, (send, read_response) = _mcp_session()
    request_id = 2

    def call_tool(name: str, arguments: dict[str, Any] | None = None) -> str:
        nonlocal request_id
        request_id += 1
        return _call_tool_in_session(send, read_response, name, arguments, request_id)

    try:
        device = _pick_device_from_text(
            platform,
            call_tool("mobile_list_available_devices", {}),
        )
        for _ in range(3):
            text = call_tool("mobile_list_elements_on_screen", {"device": device})
            if "Test logEvent" in text:
                break
            if '"Back"' in text or "Back" in text:
                tap_by_label_with_call(call_tool, device, "Back")
                time.sleep(0.5)
        text = call_tool("mobile_list_elements_on_screen", {"device": device})
        button_centers: dict[str, tuple[int, int]] = {}
        blob = text.strip()
        if blob.startswith("Found these elements"):
            blob = blob.split(":", 1)[-1].strip()
        try:
            elements = json.loads(blob)
            if isinstance(elements, list):
                for el in elements:
                    if not isinstance(el, dict):
                        continue
                    label = str(el.get("label") or el.get("name") or "")
                    coords = el.get("coordinates") or {}
                    if not isinstance(coords, dict) or "x" not in coords or "y" not in coords:
                        continue
                    x = int(coords["x"]) + int(coords.get("width", 0)) // 2
                    y = int(coords["y"]) + int(coords.get("height", 0)) // 2
                    button_centers[label] = (x, y)
        except json.JSONDecodeError:
            pass

        for label in labels:
            center = next(
                (value for key, value in button_centers.items() if label in key),
                None,
            )
            if center is None:
                tap_by_label_with_call(call_tool, device, label)
            else:
                tap_coordinates_with_call(call_tool, device, center[0], center[1])
            time.sleep(gap_seconds)
        open_tabs_and_switch_with_call(call_tool, device, gap_seconds)
        print(f"device={device} completed button tour and tabs")
    finally:
        proc.terminate()


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: flutterfire-demo-mobile.py pick-device <platform>", file=sys.stderr)
        print("       flutterfire-demo-mobile.py tap-standard-events <platform>", file=sys.stderr)
        print(
            "       flutterfire-demo-mobile.py tap-label <platform> <button label substring>",
            file=sys.stderr,
        )
        print(
            "       flutterfire-demo-mobile.py open-tabs <platform>",
            file=sys.stderr,
        )
        print(
            "       flutterfire-demo-mobile.py button-tour <platform> [gap]",
            file=sys.stderr,
        )
        raise SystemExit(2)

    cmd = sys.argv[1]
    platform = sys.argv[2] if len(sys.argv) > 2 else "android"

    if cmd == "pick-device":
        print(pick_device(platform))
        return
    if cmd == "tap-standard-events":
        device = pick_device(platform)
        x, y = tap_by_label(device, "Test standard event types")
        print(f"device={device} tapped=({x},{y})")
        return
    if cmd == "tap-label":
        if len(sys.argv) < 4:
            raise SystemExit("tap-label requires a button label substring")
        device = pick_device(platform)
        label = sys.argv[3]
        x, y = tap_by_label(device, label)
        print(f"device={device} label={label!r} tapped=({x},{y})")
        return
    if cmd == "open-tabs":
        device = pick_device(platform)
        gap = float(sys.argv[3]) if len(sys.argv) > 3 else 2.1
        open_tabs_and_switch(device, gap)
        print(f"device={device} opened TabsPage and switched tabs")
        return
    if cmd == "button-tour":
        gap = float(sys.argv[3]) if len(sys.argv) > 3 else 2.1
        run_button_tour(platform, gap)
        return

    raise SystemExit(f"Unknown command: {cmd}")


if __name__ == "__main__":
    main()
