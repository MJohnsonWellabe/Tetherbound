#!/usr/bin/env python3
"""Ubuntu CI: preserve native verdicts and terminate the owned process group."""

import os
import re
import signal
import subprocess
import sys
import threading

FATAL_SCRIPT = re.compile(r"SCRIPT ERROR:|Parse Error:")


def run(command):
    if os.name != "posix":
        raise SystemExit("run_godot_smoke.py requires the Ubuntu/POSIX CI runner")
    process = subprocess.Popen(command, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, start_new_session=True)
    failed = threading.Event()
    timer = None

    def stop():
        # The leader can exit while descendants still hold the output pipe.
        # Its session/group remains ours until every descendant has exited.
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass

    def terminated(signum, _frame):
        stop()
        raise SystemExit(128 + signum)

    previous_handlers = {sig: signal.signal(sig, terminated)
                         for sig in (signal.SIGTERM, signal.SIGINT)}

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
        for sig, handler in previous_handlers.items():
            signal.signal(sig, handler)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit("usage: run_godot_smoke.py COMMAND [ARG ...]")
    raise SystemExit(run(sys.argv[1:]))
