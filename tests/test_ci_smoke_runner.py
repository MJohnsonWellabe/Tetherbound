"""Exercise real process exits and fatal-script cleanup without a game boot."""

import pathlib
import os
import signal
import select
import subprocess
import sys
import time
import unittest

RUNNER = pathlib.Path(__file__).resolve().parents[1] / "tools/ci/run_godot_smoke.py"


class SmokeRunnerTests(unittest.TestCase):
    def invoke(self, source):
        return subprocess.run([sys.executable, str(RUNNER), sys.executable, "-u", "-c", source],
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=8)

    def test_native_success_and_failure_keep_their_exit_codes(self):
        self.assertEqual(self.invoke("print('smoke PASS')").returncode, 0)
        self.assertEqual(self.invoke("raise SystemExit(7)").returncode, 7)

    def test_expected_non_script_refusal_remains_visible(self):
        result = self.invoke("print('ERROR: expected corrupt save refusal')")
        self.assertEqual(result.returncode, 0)
        self.assertIn(b"expected corrupt save refusal", result.stdout)

    def test_script_error_cannot_be_hidden_by_a_zero_exit(self):
        result = self.invoke("print('SCRIPT ERROR: Invalid call'); print('native backtrace')")
        self.assertEqual(result.returncode, 1)
        self.assertIn(b"native backtrace", result.stdout)

    def test_aborted_script_is_stopped_with_its_child_and_backtrace_retained(self):
        started = time.monotonic()
        result = self.invoke("import subprocess,sys,time; subprocess.Popen([sys.executable,'-u','-c','import time; print(\"child alive\"); time.sleep(60)']); print('SCRIPT ERROR: Invalid call'); print('native backtrace'); time.sleep(60)")
        self.assertEqual(result.returncode, 1)
        self.assertLess(time.monotonic() - started, 5)
        self.assertIn(b"child alive", result.stdout)
        self.assertIn(b"native backtrace", result.stdout)

    def test_parse_error_also_stops_idle_native_process(self):
        result = self.invoke("import time; print('Parse Error: unexpected token'); time.sleep(60)")
        self.assertEqual(result.returncode, 1)
        self.assertIn(b"unexpected token", result.stdout)

    def test_exited_leader_does_not_leave_a_pipe_holding_descendant(self):
        started = time.monotonic()
        result = self.invoke("import subprocess,sys; subprocess.Popen([sys.executable,'-u','-c','import time; print(\"child alive\"); time.sleep(60)']); print('SCRIPT ERROR: Invalid call'); print('leader exiting'); raise SystemExit(0)")
        self.assertEqual(result.returncode, 1)
        self.assertLess(time.monotonic() - started, 5)
        self.assertIn(b"leader exiting", result.stdout)
        self.assertIn(b"child alive", result.stdout)

    def test_outer_timeout_cleans_the_separate_native_session(self):
        source = "import subprocess,sys,time; subprocess.Popen([sys.executable,'-u','-c','import time; print(\"child ready\"); time.sleep(60)']); print('native ready'); time.sleep(60)"
        process = subprocess.Popen([sys.executable, str(RUNNER), sys.executable, "-u", "-c", source],
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=0)
        try:
            observed = []
            for _ in range(2):
                self.assertTrue(select.select([process.stdout], [], [], 5)[0], "native startup output timed out")
                observed.append(process.stdout.readline())
            self.assertIn(b"native ready\n", observed)
            self.assertIn(b"child ready\n", observed)
            # GNU timeout sends SIGTERM to the wrapper at the existing deadline.
            process.send_signal(signal.SIGTERM)
            output, _ = process.communicate(timeout=5)
            self.assertEqual(process.returncode, 128 + signal.SIGTERM)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()

    def test_pending_cancellation_during_spawn_is_delivered_after_handler_install(self):
        # Send the signal at the exact formerly unprotected boundary, after
        # native spawn returns and before run() can install its handlers.
        source = """
import importlib.util,os,signal,subprocess,sys
spec=importlib.util.spec_from_file_location('smoke_runner',sys.argv[1])
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
original=module.subprocess.Popen
def spawn(*args,**kwargs):
    process=original(*args,**kwargs)
    os.kill(os.getpid(),signal.SIGTERM)
    return process
module.subprocess.Popen=spawn
raise SystemExit(module.run([sys.executable,'-u','-c','import time; time.sleep(60)']))
"""
        result = subprocess.run([sys.executable, "-u", "-c", source, str(RUNNER)],
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=5)
        self.assertEqual(result.returncode, 128 + signal.SIGTERM)


if __name__ == "__main__":
    if os.name != "posix":
        raise SystemExit("Run these process-group proofs on Ubuntu/POSIX, as CI does")
    unittest.main()
