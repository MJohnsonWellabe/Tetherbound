"""Exercise real process exits and fatal-script cleanup without a game boot."""

import pathlib
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


if __name__ == "__main__":
    unittest.main()
