#!/usr/bin/env python3
"""Ubuntu CI: preserve native verdicts and terminate the owned process group."""

import os
import gzip
import math
import re
import signal
import subprocess
import sys
import threading
import time

FATAL_SCRIPT = re.compile(r"SCRIPT ERROR:|Parse Error:")


def run(command, timeout_seconds=None, log_path=None):
    if os.name != "posix":
        raise SystemExit("run_godot_smoke.py requires the Ubuntu/POSIX CI runner")
    signals = (signal.SIGTERM, signal.SIGINT)
    previous_mask = signal.pthread_sigmask(signal.SIG_BLOCK, signals)
    process = None
    previous_handlers = {}
    failed = threading.Event()
    timer = None
    deadline = None
    timed_out = threading.Event()
    native_log = None

    def stop():
        if process is None:
            return
        # The leader can exit while descendants still hold the output pipe.
        # Its session/group remains ours until every descendant has exited.
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass

    def terminated(signum, _frame):
        stop()
        raise SystemExit(128 + signum)

    def expired():
        timed_out.set()
        stop()

    try:
        if timeout_seconds is not None and (not math.isfinite(timeout_seconds) or timeout_seconds <= 0):
            raise ValueError("native timeout must be finite and positive")
        if log_path is not None:
            os.makedirs(os.path.dirname(os.path.abspath(log_path)), exist_ok=True)
            native_log = gzip.open(log_path, "wb")
        started = time.monotonic()
        # This CLI is single-threaded at spawn. Restore the child's original
        # mask before exec; keep the parent protected through handler install.
        process = subprocess.Popen(command, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, start_new_session=True,
                                   preexec_fn=lambda: signal.pthread_sigmask(
                                       signal.SIG_SETMASK, previous_mask))
        previous_handlers = {sig: signal.signal(sig, terminated) for sig in signals}
        signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask)
        if timeout_seconds is not None:
            deadline = threading.Timer(max(0, timeout_seconds - (time.monotonic() - started)), expired)
            deadline.daemon = True
            deadline.start()
        for raw in process.stdout:
            if native_log is not None:
                native_log.write(raw)
            # A full snapshot refusal can be megabytes on one line. Preserve
            # it losslessly in the artifact without blocking the CI log pipe.
            if native_log is not None and len(raw) > 8192:
                sys.stdout.buffer.write(raw[:8192])
                sys.stdout.buffer.write(b"\nSMOKE-RUNNER: oversized native line retained in lossless gzip artifact\n")
            else:
                sys.stdout.buffer.write(raw)
            sys.stdout.buffer.flush()
            if FATAL_SCRIPT.search(raw.decode("utf-8", errors="replace")) and not failed.is_set():
                failed.set()
                # Retain the following native backtrace before terminating.
                timer = threading.Timer(1.0, stop)
                timer.start()
        code = process.wait()
        if timed_out.is_set():
            print("SMOKE-RUNNER: original native deadline exceeded; owned process group stopped", flush=True)
            return 124
        return 1 if failed.is_set() else code
    finally:
        signal.pthread_sigmask(signal.SIG_BLOCK, signals)
        if timer is not None:
            timer.cancel()
        if deadline is not None:
            deadline.cancel()
        stop()
        if process is not None:
            process.stdout.close()
            process.wait()
        if native_log is not None:
            native_log.close()
        for sig, handler in previous_handlers.items():
            signal.signal(sig, handler)
        signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask)


if __name__ == "__main__":
    arguments = sys.argv[1:]
    timeout_seconds = None
    log_path = None
    while arguments and arguments[0].startswith(("--native-timeout-seconds=", "--native-log=")):
        option = arguments.pop(0)
        if option.startswith("--native-timeout-seconds="):
            timeout_seconds = float(option.split("=", 1)[1])
        else:
            log_path = option.split("=", 1)[1]
    if not arguments:
        raise SystemExit("usage: run_godot_smoke.py COMMAND [ARG ...]")
    raise SystemExit(run(arguments, timeout_seconds, log_path))
