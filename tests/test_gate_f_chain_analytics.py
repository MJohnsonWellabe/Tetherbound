"""Synthetic raw-phase evidence fixtures; no engine and no acceptance claims."""
import contextlib
import importlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools/gate_f"))
from chain_evidence import executions
from chain_pacing import segment_report


class PhaseAnalyticsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.order = ["S03p1", "S03p2", "S03p3"]
        for i, name in enumerate(self.order):
            phase = {"parent": "S03", "order": self.order, "index": i,
                     "added_step_ids": [name + "-save"], "original_step_ids": ["original"],
                     "output_save": "S03-exit.json" if i == 2 else name + "-exit.json",
                     "metrics": {"distance_m": (i + 1) * 100}}
            self.write(name + "/INVENTORY.json", {"phase": phase, "complete": True,
                       "steps": {"pass": 2, "fail": 0, "total": 2}})
            self.write(name + "/RUN_METADATA.json", {"phase_parent": "S03", "clocks": {
                "play_seconds_elapsed": 220, "wall_seconds_elapsed": 300}})
            self.write(name + "/saves/" + phase["output_save"], {"party": [{"nickname": name,
                "species_id": "test", "level": 1, "hp": 10, "max_hp": 10}]})
            self.text(name + "/telemetry/route.csv", "t,x,z,dead_travel_m,frame_ms,region\n180,0,0,0,16,test\n190,3,0,3,16,test\n200,6,0,6,16,test\n")
            self.text(name + "/telemetry/events.jsonl", '{"type":"dialogue","t":10}\n{"type":"gather","t":190}\n')
            self.text(name + "/notes/" + name + ".md", "### original — gameplay\n- verdict: PASS\n"
                      "### " + name + "-save — save\n- verdict: FAIL\n- actual: boundary failed\n")
        self.write("S03/INVENTORY.json", {"execution": "save_linked_phases", "aggregate": {"order": self.order}})

    def text(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def write(self, name, obj):
        self.text(name, json.dumps(obj))

    def test_parent_omitted_and_cumulative_distance_not_summed(self):
        entries = list(executions(self.root))
        self.assertNotIn("S03", [e["id"] for e in entries])
        phases = [e for e in entries if e["is_phase"]]
        self.assertEqual([e["id"] for e in phases], self.order)
        reports = [segment_report(self.root, e["id"], e) for e in phases]
        self.assertEqual(sum(r["walk_m"] for r in reports), 18)
        self.assertEqual(sum(r["raw_play_s"] for r in reports), 660)
        self.assertEqual(reports[1]["route_span_s"], 20)
        self.assertNotIn("play_s", reports[1])
        self.assertNotIn("cadence", reports[1])
        self.assertNotIn("dead_peak_s", reports[1])

    def test_partial_unpublished_phases_remain_visible(self):
        (self.root / "S03/INVENTORY.json").unlink()
        (self.root / "S03p3/INVENTORY.json").unlink()
        entries = [e for e in executions(self.root) if e["is_phase"]]
        self.assertEqual([e["id"] for e in entries], self.order)
        self.assertFalse(any(e["aggregate_published"] for e in entries))
        self.assertEqual(entries[-1]["inventory"], {})

    def test_explicit_event_ownership_excludes_boundary_cadence(self):
        events = [{"type": "dialogue", "phase_parent": "S03", "phase_added": True},
                  {"type": "gather", "phase_parent": "S03", "phase_added": False}]
        self.text("S03p1/telemetry/events.jsonl", "\n".join(map(json.dumps, events)))
        entry = next(e for e in executions(self.root) if e["id"] == "S03p1")
        r = segment_report(self.root, "S03p1", entry)
        self.assertEqual(r["cadence"], {"resource": 1})
        del events[0]["phase_added"]
        self.text("S03p1/telemetry/events.jsonl", "\n".join(map(json.dumps, events)))
        self.assertNotIn("cadence", segment_report(self.root, "S03p1", entry))

    def test_all_clis_traverse_raw_paths_and_label_seams(self):
        outputs = {}
        for name in ("chain_pacing", "chain_party", "chain_defects"):
            stream = io.StringIO()
            with patch.object(sys, "argv", [name, str(self.root)]), contextlib.redirect_stdout(stream):
                importlib.import_module(name).main()
            outputs[name] = stream.getvalue()
            self.assertIn("S03p3", outputs[name])
            self.assertNotIn("| S03 |", outputs[name])
        self.assertIn("660.00 s", outputs["chain_pacing"])
        self.assertIn("**900**", outputs["chain_pacing"])
        self.assertIn("3 failing steps", outputs["chain_defects"])
        self.assertIn("[added save/load boundary]", outputs["chain_defects"])

    def test_conflicting_parent_and_path_escape_fail_closed(self):
        self.write("S03/INVENTORY.json", {"complete": True})
        with self.assertRaises(ValueError):
            list(executions(self.root))
        self.write("S03/INVENTORY.json", {"execution": "save_linked_phases", "aggregate": {"order": ["../outside"]}})
        with self.assertRaises(ValueError):
            list(executions(self.root))


if __name__ == "__main__":
    unittest.main()
