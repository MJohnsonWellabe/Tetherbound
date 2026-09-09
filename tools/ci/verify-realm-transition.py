#!/usr/bin/env python3
"""First-attempt Linux CI receipts for the real Game and native realm fixtures."""

import collections
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time


ROOT = Path(__file__).resolve().parents[2]
ARTIFACTS = Path(tempfile.mkdtemp(prefix="realm-transition-", dir=os.environ.get("RUNNER_TEMP", "/tmp")))
EXPECTED_GAME_ERRORS = collections.Counter({
    "ERROR: realm 'water' did not become ready within 120.0 seconds": 2,
    "ERROR: realm transition rollback entered guarded recovery": 1,
    "ERROR: realm 'water' transition autosave failed; crossing cancelled": 1,
})


def read(row, stream):
    return row[stream].read_text(encoding="utf-8", errors="replace")


def launch(folder, role, script, args):
    profile = folder / (role + "-profile")
    env = os.environ.copy()
    for variable, leaf in (("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache")):
        target = profile / leaf
        target.mkdir(parents=True)
        env[variable] = str(target)
    row = {"role": role, "stdout": folder / (role + ".stdout.log"), "stderr": folder / (role + ".stderr.log")}
    with row["stdout"].open("wb") as out, row["stderr"].open("wb") as err:
        row["process"] = subprocess.Popen(
            ["godot", "--headless", "--path", str(ROOT), "--script", script, "--", *args],
            cwd=ROOT, env=env, stdout=out, stderr=err, start_new_session=True,
        )
    return row


def errors(row):
    found = []
    for stream in ("stdout", "stderr"):
        for line in read(row, stream).splitlines(keepends=True):
            if row["process"].poll() is None and not line.endswith("\n"):
                continue  # A concurrently written partial line is not a diagnostic yet.
            if line.startswith(("ERROR:", "SCRIPT ERROR:")):
                found.append(line.rstrip("\r\n"))
    return found


def stop_and_record(folder, rows, started, failure):
    # Each subprocess owns its own POSIX group. Never kill an unrelated engine.
    for row in rows:
        process = row["process"]
        if process.poll() is None:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        process.wait()
    receipt = {"elapsed_seconds": time.monotonic() - started, "failure": failure,
               "processes": [{"role": row["role"], "pid": row["process"].pid,
                              "exit_code": row["process"].returncode} for row in rows]}
    (folder / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    for row in rows:
        for stream in ("stdout", "stderr"):
            print(f"::group::{folder.name}/{row[stream].name}", flush=True)
            print(read(row, stream), end="", flush=True)
            print("::endgroup::", flush=True)
    print(json.dumps(receipt), flush=True)


def game():
    folder = ARTIFACTS / "game"
    folder.mkdir()
    started = time.monotonic()
    rows = []
    failure = ""
    try:
        row = launch(folder, "game", "tools/probe_realm_transition_game.gd", [])
        rows.append(row)
        while row["process"].poll() is None:
            if collections.Counter(errors(row)) - EXPECTED_GAME_ERRORS:
                raise RuntimeError("Game fixture emitted an unexpected native error")
            if time.monotonic() - started >= 45:
                raise RuntimeError("Game fixture exceeded 45 seconds")
            time.sleep(0.04)
        if row["process"].returncode != 0:
            raise RuntimeError("Game fixture exited nonzero")
        if "GAME LIFECYCLE RESULT checks=108 failed=false" not in read(row, "stdout").splitlines():
            raise RuntimeError("Game fixture did not complete all 108 checks")
        if collections.Counter(errors(row)) != EXPECTED_GAME_ERRORS:
            raise RuntimeError("Game fixture native errors differ from the four explicit injected failures")
    except Exception as exc:
        failure = str(exc)
    finally:
        stop_and_record(folder, rows, started, failure)
    return not failure


def native(mode, port):
    folder = ARTIFACTS / mode
    folder.mkdir()
    started = time.monotonic()
    rows = []
    failure = ""
    try:
        extra = [] if mode == "baseline" else [mode]
        host = launch(folder, "host", "tools/probe_realm_transition_adapter.gd", ["host", str(port), *extra])
        rows.append(host)
        while "ADAPTER BOOT host" not in read(host, "stdout"):
            if host["process"].poll() is not None or errors(host) or time.monotonic() - started > 8:
                raise RuntimeError("Native host failed before boot marker")
            time.sleep(0.04)
        if errors(host) or host["process"].poll() is not None:
            raise RuntimeError("Native host was not clean and live at boot marker")
        rows.append(launch(folder, "departing", "tools/probe_realm_transition_adapter.gd", ["departing", str(port), *extra]))
        if mode == "latejoin":
            while "ADAPTER LATEJOIN READY" not in read(host, "stdout"):
                if time.monotonic() - started >= 60 or any(errors(row) or row["process"].poll() is not None for row in rows):
                    raise RuntimeError("Existing peers did not reach the actual latejoin-ready milestone")
                time.sleep(0.04)
            if any(errors(row) or row["process"].poll() is not None for row in rows):
                raise RuntimeError("Existing peers were not clean and live at latejoin marker")
        final_role = "latejoin" if mode == "latejoin" else "staying"
        rows.append(launch(folder, final_role, "tools/probe_realm_transition_adapter.gd", [final_role, str(port), *extra]))
        while any(row["process"].poll() is None for row in rows):
            if time.monotonic() - started >= 90:
                raise RuntimeError("Native fixture exceeded 90 seconds")
            for row in rows:
                if errors(row):
                    raise RuntimeError(row["role"] + " emitted a native error")
                if row["process"].poll() not in (None, 0):
                    raise RuntimeError(row["role"] + " exited nonzero")
            time.sleep(0.05)
        fixed_counts = {"baseline": {"host": 29, "departing": 29, "staying": 23},
                        "cancel": {"host": 22, "departing": 32, "staying": 23},
                        "latejoin": {"host": 26, "departing": 29, "latejoin": 27}}
        for row in rows:
            count = str(fixed_counts[mode][row["role"]])
            expected = rf"^ADAPTER RESULT {row['role']} checks={count} failed=false$"
            if row["process"].returncode != 0 or errors(row) or not re.search(expected, read(row, "stdout"), re.M):
                raise RuntimeError(row["role"] + " did not complete a clean native result")
    except Exception as exc:
        failure = str(exc)
    finally:
        stop_and_record(folder, rows, started, failure)
    return not failure


if __name__ == "__main__":
    print(f"Realm transition receipts: {ARTIFACTS} (one invocation per case)", flush=True)
    if os.environ.get("GITHUB_ENV"):
        with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as output:
            output.write(f"REALM_TRANSITION_RECEIPTS={ARTIFACTS}\n")
    outcomes = [game()]
    for index, mode in enumerate(("baseline", "cancel", "latejoin")):
        outcomes.append(native(mode, 39831 + index))
    sys.exit(0 if all(outcomes) else 1)
