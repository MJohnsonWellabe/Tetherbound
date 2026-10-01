#!/usr/bin/env python3
"""Keep the native exit verdict and stop aborted GDScript from idling forever."""

import os
import re
import signal
import subprocess
import sys
import threading

FATAL_SCRIPT = re.compile(r"SCRIPT ERROR:|Parse Error:")


def run(command):
    options = {"stdout": subprocess.PIPE, "stderr": subprocess.STDOUT}
    if os.name == "nt":
        options["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
    else:
        options["start_new_session"] = True
    process = subprocess.Popen(command, **options)
    failed = threading.Event()
    timer = None

    def stop():
        if process.poll() is not None:
            return
        if os.name == "nt":
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass

    try:
        for raw in process.stdout:
            sys.stdout.buffer.write(raw)
            sys.stdout.buffer.flush()
            if FATAL_SCRIPT.search(raw.decode("utf-8", errors="replace")) and not failed.is_set():
                failed.set()
                # Retain the following native backtrace before terminating.
                timer = threading.Timer(1.0, stop)
                timer.start()
        code = process.wait()
        return 1 if failed.is_set() else code
    finally:
        if timer is not None:
            timer.cancel()
        stop()
        process.stdout.close()
        process.wait()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit("usage: run_godot_smoke.py COMMAND [ARG ...]")
    raise SystemExit(run(sys.argv[1:]))
