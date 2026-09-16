"""Run the real Bash entrypoint against fake engine/display processes, without Godot.

Set BASH to a GNU Bash executable if it is not on PATH (Git for Windows sh.exe
is GNU Bash too). Run with: python tests/test_gate_f_runner_verdict.py
"""
import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

RUNNER = Path(__file__).resolve().parents[1] / "tools/gate_f/run_segment.sh"
BASH = os.environ.get("BASH") or shutil.which("bash")
CLEAN = {
    "complete": True, "blocked": "", "derailed": "", "derails": [],
    "harness_errors": [], "uncommittable": [],
    "steps": {"total": 3, "ran": 3, "pass": 2, "delegated": 1,
              "fail": 0, "refused": 0, "skipped": 0},
}


@unittest.skipUnless(BASH, "GNU Bash not available; set BASH to its executable")
class RunnerVerdictTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="tetherbound-bash-verdict-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "tools/gate_f/segments").mkdir(parents=True)
        (self.root / ".godot/imported").mkdir(parents=True)
        self.runner = self.root / "tools/gate_f/run_segment.sh"
        self.runner.write_text(RUNNER.read_text(), encoding="utf-8", newline="\n")
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.engine = self.bin / "fake-godot"
        self.write_script(self.engine, '''#!/bin/sh
if [ "$1" = "--version" ]; then echo "fixture-engine"; exit 0; fi
out=""
smoke=no
for arg in "$@"; do
    case "$arg" in
        --gatef-out=*) out="${arg#--gatef-out=}" ;;
        tools/capture_diag_minimal.gd) smoke=yes ;;
    esac
done
if [ "$smoke" = yes ]; then printf fixture > "$out/capture_smoke.png"; exit 0; fi
if [ -f "$FIXTURE_INVENTORY" ]; then cp "$FIXTURE_INVENTORY" "$out/INVENTORY.json"; fi
if [ -f "$FIXTURE_METADATA" ]; then cp "$FIXTURE_METADATA" "$out/RUN_METADATA.json"; fi
if [ -n "$FIXTURE_MARKER" ]; then printf fixture > "$out/$FIXTURE_MARKER"; fi
printf 'skipped press: skip_if already holds\n' > "$out/notes.md"
exit "$FIXTURE_EXIT"
''')
        self.write_script(self.bin / "xvfb-run", '''#!/bin/sh
[ "$1" = "-a" ] && shift
if [ "$1" = "-s" ]; then shift 2; fi
exec "$@"
''')
        self.write_script(self.bin / "timeout", '#!/bin/sh\nshift\nexec "$@"\n')
        self.serial = 0

    def write_script(self, path, text):
        path.write_text(text, encoding="utf-8", newline="\n")
        path.chmod(0o755)

    def run_case(self, inventory=CLEAN, raw_exit=0, marker="", capture=False, overhead=False, metadata=None):
        self.serial += 1
        segment = self.root / "tools/gate_f/segments/TEST.json"
        segment.write_text(json.dumps({"id": "TEST", "evidence_lane": "capture" if capture else "logic", "steps": []}))
        fixture = self.root / f"inventory-{self.serial}.json"
        if inventory is not None:
            fixture.write_text(inventory if isinstance(inventory, str) else json.dumps(inventory), encoding="utf-8")
        metadata_path = self.root / f"metadata-{self.serial}.json"
        if metadata is not None:
            metadata_path.write_text(json.dumps(metadata), encoding="utf-8")
        run = self.root / f"run-{self.serial}"
        env = dict(os.environ, GODOT=self.engine.as_posix(), PYTHON=sys.executable,
                   FIXTURE_INVENTORY=fixture.as_posix(), FIXTURE_EXIT=str(raw_exit),
                   FIXTURE_MARKER=marker, FIXTURE_METADATA=metadata_path.as_posix())
        env["PATH"] = str(self.bin) + os.pathsep + str(Path(BASH).resolve().parent) + os.pathsep + env.get("PATH", "")
        command = [BASH, str(self.runner), "--run-dir", run.as_posix()]
        if capture:
            command.append("--capture")
        command.append("--overhead" if overhead else "TEST")
        result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=30)
        record_path = run / ("overhead" if overhead else "TEST") / "SEGMENT_RESULT.json"
        self.assertTrue(record_path.is_file(), result.stdout + result.stderr)
        record = json.loads(record_path.read_text())
        self.assertEqual(record["process_exit"], raw_exit, result.stdout + result.stderr)
        self.assertEqual(record["effective_exit"], result.returncode, result.stdout + result.stderr)
        if capture:
            self.assertTrue((run / "TEST/capture_smoke.png").is_file())
            self.assertTrue((run / "TEST/CAPTURE_RESOLUTION.json").is_file())
        return result.returncode, record

    def test_complete_logic_and_capture_with_delegation_and_conditional_noop(self):
        for capture in (False, True):
            with self.subTest(capture=capture):
                code, record = self.run_case(capture=capture)
                self.assertEqual(code, 0)
                self.assertEqual(record["reasons"], [])

    def test_zero_exit_failed_expectations_and_incomplete_evidence_fail(self):
        for capture in (False, True):
            for field in ("fail", "refused", "skipped"):
                inventory = copy.deepcopy(CLEAN)
                inventory["steps"][field] = 1
                with self.subTest(capture=capture, field=field):
                    code, record = self.run_case(inventory, capture=capture)
                    self.assertEqual(code, 1)
                    self.assertIn(f"steps.{field}=1", record["reasons"])
        inventory = copy.deepcopy(CLEAN)
        inventory.update(complete=False, derailed="missing narrative modal", derails=[{"at": "S03-25", "skipped": 541}])
        inventory["steps"].update(total=567, ran=26, fail=1, skipped=541)
        code, record = self.run_case(inventory)
        self.assertEqual(code, 1)
        self.assertIn("steps.skipped=541", record["reasons"])

    def test_failure_markers_inconsistent_and_malformed_records(self):
        for marker in ("INCOMPLETE.md", "BLOCKER.md"):
            code, record = self.run_case(marker=marker)
            self.assertEqual(code, 1)
            self.assertIn(marker, record["reasons"])
        for field in ("blocked", "derailed", "derails", "harness_errors", "uncommittable"):
            inventory = copy.deepcopy(CLEAN)
            inventory[field] = "problem"
            with self.subTest(field=field):
                self.assertEqual(self.run_case(inventory)[0], 1)
        for inventory in (None, "bad json", "[]", {}, {**CLEAN, "complete": "true"},
                          {**CLEAN, "steps": {}}, {**CLEAN, "steps": {**CLEAN["steps"], "ran": 2}}):
            with self.subTest(inventory=inventory):
                self.assertEqual(self.run_case(inventory)[0], 1)

    def test_overhead_uses_measurement_receipt_without_segment_inventory(self):
        metadata = {"instrumentation_overhead_note": "scene=title. Means: off 1.0, telemetry 1.1 ms/frame.",
                    "blocked": "", "harness_errors": []}
        code, record = self.run_case(None, overhead=True, metadata=metadata)
        self.assertEqual(code, 0)
        self.assertFalse(record["inventory_required"])
        self.assertEqual(record["diagnostic_receipt"]["instrumentation_overhead_note"], metadata["instrumentation_overhead_note"])
        self.assertEqual(self.run_case(None, overhead=True)[0], 1)
        self.assertEqual(self.run_case(None, overhead=True, metadata={"instrumentation_overhead_note": "not measured in this run"})[0], 1)
        self.assertEqual(self.run_case(None, overhead=True, metadata=metadata, raw_exit=124)[0], 124)

    def test_nonzero_process_exit_is_preserved(self):
        for inventory in (CLEAN, {**CLEAN, "complete": False}):
            code, record = self.run_case(inventory, raw_exit=124)
            self.assertEqual(code, 124)
            self.assertIn("process exited 124", record["reasons"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
