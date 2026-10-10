#!/usr/bin/env python3
"""Integration tests: boot the real server image and drive the HLDS console over stdin.

Python 3 stdlib only. Each scenario runs in its own container; the cases of a scenario share it.
Prints PASS/FAIL per case and exits 1 if any case fails.
"""
import os
import re
import signal
import subprocess
import sys
import threading
import time
import uuid

IMAGE = os.environ.get("IMAGE", "cstrike-server-multimod-cstrike")
SCENARIO_TIMEOUT = 150  # seconds, per scenario container

# `amxx plugins` truncates the name column to 20 characters; match on the displayed prefix.
PLUGINS = [
    "Nostalgia Mode Rules",
    "Nostalgia Drain",
    "Nostalgia Punish",
    "PodBot Admin",
    "Autoresponder/Advertis",
    "ADV. QUAKE SOUNDS",
]
BOT_LINE = re.compile(r'^#\s*\d+ "\[BOT\]')
SUICIDE = 'committed suicide with "world"'
DRAIN_MESSAGE = "SIGTERM received: draining"

DM_CVARS = {"mp_forcerespawn": "1.5", "mp_round_infinite": "1", "mp_startmoney": "16000"}
CLASSIC_CVARS = {"mp_forcerespawn": "0.000000", "mp_round_infinite": "0", "mp_startmoney": "800"}

results = []


class ScenarioTimeout(BaseException):
    """BaseException so a case's `except Exception` cannot swallow it."""


def on_alarm(signum, frame):
    raise ScenarioTimeout()


def report(name, ok, detail=""):
    results.append((name, ok))
    suffix = f" ({detail})" if detail else ""
    print(f"{'PASS' if ok else 'FAIL'} {name}{suffix}", flush=True)


class Server:
    def __init__(self, map_name):
        self.name = f"it-{uuid.uuid4().hex[:12]}"
        self.lines = []
        self.cv = threading.Condition()
        self.proc = subprocess.Popen(
            [
                "docker", "run", "--rm", "-i", "--name", self.name,
                "-e", "RCON_PASSWORD=test",
                "-e", f"START_MAP={map_name}",
                IMAGE,
            ],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            errors="replace",
        )
        self.reader = threading.Thread(target=self._read, daemon=True)
        self.reader.start()

    def _read(self):
        for line in self.proc.stdout:
            with self.cv:
                self.lines.append(line.rstrip("\r\n"))
                self.cv.notify_all()

    def mark(self):
        with self.cv:
            return len(self.lines)

    def since(self, start):
        with self.cv:
            return list(self.lines[start:])

    def send(self, text):
        self.proc.stdin.write(text + "\n")
        self.proc.stdin.flush()

    def cmd(self, text, wait):
        """Send one console command; return the lines printed during `wait` seconds after it."""
        start = self.mark()
        self.send(text)
        time.sleep(wait)
        return self.since(start)

    def docker_exec(self, shell):
        return subprocess.run(
            ["docker", "exec", self.name, "sh", "-c", shell],
            capture_output=True,
            text=True,
        ).stdout

    def stop(self):
        subprocess.run(["docker", "kill", "-s", "KILL", self.name], capture_output=True)
        if self.proc.poll() is None:
            self.proc.kill()
        self.proc.wait()
        self.reader.join(5)


def run_case(fn, srv):
    try:
        return fn(srv)
    except Exception as exc:  # a broken pipe or docker error fails the case, not the run
        return False, f"error: {exc!r}"


def run_scenario(map_name, boot_wait, cases):
    print(f"-- scenario map={map_name} boot_wait={boot_wait}s", flush=True)
    srv = Server(map_name)
    done = 0
    try:
        signal.alarm(SCENARIO_TIMEOUT)
        time.sleep(boot_wait)
        for name, fn in cases:
            ok, detail = run_case(fn, srv)
            report(name, ok, detail)
            done += 1
    except ScenarioTimeout:
        for name, _ in cases[done:]:
            report(name, False, f"scenario exceeded {SCENARIO_TIMEOUT}s")
    finally:
        signal.alarm(0)
        srv.stop()


def check_cvars(srv, expected):
    bad = []
    for name, value in expected.items():
        pattern = re.compile(rf'"{re.escape(name)}"\s+(?:is|=)\s+"{re.escape(value)}"')
        lines = srv.cmd(name, 1)
        if not any(pattern.search(line) for line in lines):
            got = next((line for line in lines if name in line), "no output")
            bad.append(f"{name} want {value!r}, got {got!r}")
    return (not bad), ("; ".join(bad) if bad else "all match")


def dm_rules(srv):
    return check_cvars(srv, DM_CVARS)


def classic_rules(srv):
    return check_cvars(srv, CLASSIC_CVARS)


def plugins_running(srv):
    lines = srv.cmd("amxx plugins", 3)
    problems = []
    for name in PLUGINS:
        matched = [line for line in lines if name in line]
        if not matched or any("running" not in line for line in matched):
            problems.append(f"{name} not running")
    if any("bad load" in line for line in lines):
        problems.append("bad load reported")
    error_log = srv.docker_exec("cat /opt/hlds/cstrike/addons/amxmodx/logs/error_*.log 2>/dev/null")
    if error_log.strip():
        problems.append("AMXX error log is not empty")
    return (not problems), ("; ".join(problems) if problems else "all running, no errors")


def bot_fill(srv):
    lines = srv.cmd("status", 3)
    bots = [line for line in lines if BOT_LINE.match(line)]
    return len(bots) == 9, f"{len(bots)} bots, want 9"


def count_suicides(lines):
    return sum(SUICIDE in line for line in lines)


def punish_light(srv):
    srv.cmd("log on", 1)
    start = srv.mark()
    srv.send("amx_punish light todos")
    # Suicide lines can trail the command on a loaded server: poll up to 10 s for all 9,
    # then settle 1 s so any extra line lands before the exact count is taken.
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline and count_suicides(srv.since(start)) < 9:
        time.sleep(0.25)
    time.sleep(1)
    count = count_suicides(srv.since(start))
    return count == 9, f"{count} suicide lines, want 9"


def drain_bots_only(srv):
    subprocess.run(["docker", "kill", "-s", "TERM", srv.name], capture_output=True)
    try:
        rc = srv.proc.wait(timeout=30)
    except subprocess.TimeoutExpired:
        return False, "still running 30s after SIGTERM"
    srv.reader.join(5)
    saw_drain = any(DRAIN_MESSAGE in line for line in srv.since(0))
    ok = rc == 0 and saw_drain
    return ok, f"rc={rc}, drain message {'seen' if saw_drain else 'missing'}"


def main():
    signal.signal(signal.SIGALRM, on_alarm)

    run_scenario("as_oilrig", 25, [("dm_rules", dm_rules)])
    run_scenario(
        "de_dust2",
        25,
        [("classic_rules", classic_rules), ("plugins_running", plugins_running)],
    )
    run_scenario(
        "as_oilrig",
        75,
        [("bot_fill", bot_fill), ("punish_light", punish_light), ("drain_bots_only", drain_bots_only)],
    )

    failed = [name for name, ok in results if not ok]
    print(f"{len(results) - len(failed)}/{len(results)} integration cases passed", flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
