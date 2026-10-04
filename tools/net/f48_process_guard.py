"""F48-only process witness. Never infer death from Godot's child PID map.

Windows retains one kernel handle across identity check, TerminateProcess and
WaitForSingleObject. Linux binds /proc start ticks and treats zombie as exited.
No save files or gameplay state are touched. Missing identity is a hard failure.
"""
import argparse
import ctypes
import json
import os
import signal
import time


def inspect_or_stop(pid, expected_image, identity, stop):
    if pid <= 0 or pid == os.getpid():
        raise ValueError("invalid target PID")
    if os.name == "nt":
        from ctypes import wintypes
        kernel = ctypes.WinDLL("kernel32", use_last_error=True)
        kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
        kernel.OpenProcess.restype = wintypes.HANDLE
        kernel.CloseHandle.argtypes = [wintypes.HANDLE]
        kernel.GetProcessTimes.argtypes = [wintypes.HANDLE] + [ctypes.POINTER(wintypes.FILETIME)] * 4
        kernel.QueryFullProcessImageNameW.argtypes = [wintypes.HANDLE, wintypes.DWORD, wintypes.LPWSTR, ctypes.POINTER(wintypes.DWORD)]
        kernel.TerminateProcess.argtypes = [wintypes.HANDLE, wintypes.UINT]
        kernel.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD]
        kernel.WaitForSingleObject.restype = wintypes.DWORD
        handle = kernel.OpenProcess(0x100000 | 0x1000 | (1 if stop else 0), False, pid)
        if not handle:
            raise OSError(ctypes.get_last_error(), "OpenProcess failed")
        try:
            created, exited, cpu_kernel, cpu_user = [wintypes.FILETIME() for _ in range(4)]
            if not kernel.GetProcessTimes(handle, *[ctypes.byref(x) for x in (created, exited, cpu_kernel, cpu_user)]):
                raise OSError(ctypes.get_last_error(), "GetProcessTimes failed")
            actual_identity = str((created.dwHighDateTime << 32) | created.dwLowDateTime)
            image, size = ctypes.create_unicode_buffer(32768), wintypes.DWORD(32768)
            if not kernel.QueryFullProcessImageNameW(handle, 0, image, ctypes.byref(size)):
                raise OSError(ctypes.get_last_error(), "QueryFullProcessImageNameW failed")
            if os.path.normcase(os.path.realpath(image.value)) != os.path.normcase(os.path.realpath(expected_image)):
                raise ValueError("target executable mismatch")
            if identity and identity != actual_identity:
                raise ValueError("PID reused: creation identity mismatch")
            if stop:
                if not kernel.TerminateProcess(handle, 137):
                    raise OSError(ctypes.get_last_error(), "TerminateProcess failed")
                if kernel.WaitForSingleObject(handle, 5000) != 0:
                    raise TimeoutError("kernel process handle did not signal exit")
            elif kernel.WaitForSingleObject(handle, 0) != 258:
                raise ValueError("target already exited before boundary arm")
            return {"identity": actual_identity, "image": image.value, "exited": bool(stop), "witness": "Windows kernel process handle"}
        finally:
            kernel.CloseHandle(handle)
    if not os.path.isdir("/proc"):
        raise ValueError("unsupported process witness platform")
    path = f"/proc/{pid}"
    def sample():
        with open(path + "/stat", encoding="utf-8") as source:
            fields = source.read().rsplit(")", 1)[1].split()
        return fields[0], fields[19]  # state (3), starttime (22)
    state, actual_identity = sample()
    image = os.readlink(path + "/exe")
    if os.path.realpath(image) != os.path.realpath(expected_image):
        raise ValueError("target executable mismatch")
    if identity and identity != actual_identity:
        raise ValueError("PID reused: start identity mismatch")
    if state in ("Z", "X"):
        raise ValueError("target already exited before boundary arm")
    if stop:
        # pidfd pins the original kernel task, eliminating the check/kill PID race.
        if not hasattr(os, "pidfd_open") or not hasattr(signal, "pidfd_send_signal"):
            raise ValueError("Linux pidfd witness unavailable")
        fd = os.pidfd_open(pid)
        try:
            if sample()[1] != actual_identity:
                raise ValueError("PID reused before pidfd acquisition")
            signal.pidfd_send_signal(fd, signal.SIGKILL)
            import select
            if not select.select([fd], [], [], 5.0)[0]:
                raise TimeoutError("kernel pidfd did not signal exit")
        finally:
            os.close(fd)
    return {"identity": actual_identity, "image": image, "exited": bool(stop), "witness": "Linux kernel pidfd"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pid", type=int, required=True)
    parser.add_argument("--image", required=True)
    parser.add_argument("--identity", default="")
    parser.add_argument("--stop", action="store_true")
    args = parser.parse_args()
    try:
        if args.stop and not args.identity:
            raise ValueError("stop requires previously captured process identity")
        result = inspect_or_stop(args.pid, args.image, args.identity, args.stop)
        result.update(ok=True, pid=args.pid, observed_monotonic_ns=str(time.monotonic_ns()))
        print(json.dumps(result))
        return 0
    except Exception as error:
        print(json.dumps({"ok": False, "pid": args.pid, "error": str(error)}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
