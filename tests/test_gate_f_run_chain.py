"""Exercise the real Bash chain in an isolated repository with fake producers.

No engine is launched. Requires Bash and its standard Unix utilities.
"""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1] / "tools/gate_f/run_chain.sh"
BASH = os.environ.get("BASH") or os.environ.get("BASH_BIN") or shutil.which("bash")


@unittest.skipUnless(BASH, "Bash runtime unavailable; fake-runner integration requires Bash")
class ChainTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        tool = self.root / "tools/gate_f"
        tool.mkdir(parents=True)
        (tool / "run_chain.sh").write_text(SOURCE.read_text(), encoding="utf-8", newline="\n")
        runner = tool / "run_segment.sh"
        runner.write_text('''#!/bin/sh
run="$2"; seg="$3"
echo "$seg" >> "$run/order"
mkdir -p "$run/$seg/saves"
echo '{"steps":{"pass":1,"fail":0,"skipped":0}}' > "$run/$seg/INVENTORY.json"
name="$seg-exit.json"
[[ "$seg" == S03p3 ]] && name=S03-exit.json
[[ "${MISSING_SAVE:-}" != "$seg" ]] && echo '{}' > "$run/$seg/saves/$name"
[[ "${FAIL_SEG:-}" == "$seg" ]] && exit 7
exit 0
''', encoding="utf-8", newline="\n")
        runner.chmod(0o755)
        (tool / "aggregate_segment_phases.py").write_text('''import os, pathlib, sys
run = pathlib.Path(sys.argv[1])
with (run / "order").open("a") as f: f.write("AGGREGATE\\n")
if os.environ.get("FAIL_AGG"): sys.exit(9)
assert (run / "S03p3/saves/S03-exit.json").is_file()
(run / "S03/saves").mkdir(parents=True)
(run / "S03/saves/S03-exit.json").write_text("{}")
''', encoding="utf-8")

    def run_chain(self, *segments, **overrides):
        env = dict(os.environ, PYTHON=Path(sys.executable).as_posix(), **overrides)
        env["PATH"] = str(Path(BASH).parent) + os.pathsep + env.get("PATH", "")
        proc = subprocess.run([BASH, "tools/gate_f/run_chain.sh", "--run-dir", "receipt", *segments],
                              cwd=self.root, env=env, text=True, capture_output=True, timeout=30)
        self.assertTrue((self.root / "receipt/order").exists(), proc.stdout + proc.stderr)
        order = (self.root / "receipt/order").read_text().splitlines()
        return proc, order

    def test_default_phases_aggregate_before_s04(self):
        proc, order = self.run_chain()
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertEqual(order[:7], ["S01", "S02", "S03p1", "S03p2", "S03p3", "AGGREGATE", "S04"])
        self.assertEqual(order[-1], "S10e")
        self.assertTrue((self.root / "receipt/S03/saves/S03-exit.json").is_file())

    def test_failed_verdict_stops_even_with_exit_save(self):
        proc, order = self.run_chain("S03p1", "S03p2", FAIL_SEG="S03p1")
        self.assertEqual(proc.returncode, 7)
        self.assertEqual(order, ["S03p1"])
        self.assertIn("\t7\t", (self.root / "receipt/CHAIN_LOG.tsv").read_text())

    def test_missing_phase_save_stops(self):
        proc, order = self.run_chain("S03p2", "S03p3", MISSING_SAVE="S03p2")
        self.assertEqual(proc.returncode, 3)
        self.assertEqual(order, ["S03p2"])

    def test_aggregate_failure_blocks_s04_on_resume(self):
        proc, order = self.run_chain("S03p3", "S04", FAIL_AGG="1")
        self.assertEqual(proc.returncode, 9)
        self.assertEqual(order, ["S03p3", "AGGREGATE"])
        self.assertFalse((self.root / "receipt/S04").exists())


if __name__ == "__main__":
    unittest.main()
