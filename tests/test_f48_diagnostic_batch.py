"""CPU-only diagnostic planning tests. These tests execute no engine or gameplay."""
from pathlib import Path
import json
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools/net"))
import f48_diagnostic_batch as batch


class DiagnosticBatchTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="f48-diagnostic-python-")
        cls.output = Path(cls.temp.name) / "plan"
        cls.profile = batch.prepare(cls.output)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def test_real_canonical_starters_are_isolated_and_never_claim_original_coverage(self):
        source = batch.fixture.source_input(Path(self.profile["saves"][0]), True)
        for name in batch.CASES:
            root = self.output / "cases" / name
            scenario = batch.fixture.read(root / "scenario.json")
            self.assertLessEqual(scenario["_comment_substantive_actions"], 10)
            self.assertTrue(all(row["continue_on_fail"] is True for row in scenario["steps"]))
            self.assertFalse({"f48_capture_durable", "f48_arm_boundary", "f48_boundary_transaction"}
                             & {row["action"] for row in scenario["steps"]})
            self.assertEqual(batch.fixture.source_input(root / "sources/peer-0", True)["character"], source["character"])
            disclosure = batch.fixture.read(root / "fixture-source.json")
            self.assertFalse(disclosure["acceptance_credit"])
            for row in disclosure["sources"]:
                actual = root / "sources" / f"peer-{row['peer']}"
                for doc in row["documents"]:
                    self.assertEqual(batch.fixture.digest(actual / doc["relative"]), doc["sha256"])
        coverage = batch.fixture.read(self.output / "original-step-coverage.json")
        self.assertFalse(coverage["original_step_execution_claim"])
        self.assertEqual(coverage["validated_original_steps"], [])
        self.assertEqual(coverage["uncovered_original_steps"], list(range(1, 266)))
        # Real directories must contain independent files, not hard-linked originals.
        a = self.output / "cases/craft/sources/peer-0"
        b = self.output / "cases/relic/sources/peer-0"
        doc = next(a.rglob("character.json"))
        other = b / doc.relative_to(a)
        self.assertFalse(doc.samefile(other))
        self.assertEqual(doc.read_bytes(), other.read_bytes())

    def test_each_operation_routes_to_actual_controller_or_existing_canonical_driver(self):
        expected_seeds = {"feast_cook": "feast_ready", "feast": "feast_ready", "key": "key_ready",
                          "relic": "relic_ready", "ordinary_round": "round_ready"}
        for name in batch.CASES:
            actions, seed, outcome = batch.case_actions(name, self.profile)
            self.assertEqual(seed, expected_seeds.get(name, "none"))
            self.assertTrue(actions)
            self.assertFalse(any(row["action"] in {"set_state", "teleport", "grant_reward", "fake_ack"} for row in actions))
            if name in {"craft", "release", "feast_cook", "feast", "key", "relic", "essence_spend"}:
                self.assertIsInstance(outcome, dict)
                self.assertTrue(any(row["action"] in {"press", "f48_button", "f48_diagnostic"} for row in actions))
        actions, _, _ = batch.case_actions("ordinary_round", self.profile)
        self.assertEqual([row["args"]["phase"] for row in actions if row["action"] == "f48_diagnostic"], ["ordinary_round"])

    def test_failure_and_launch_error_preserve_all_later_cases(self):
        # Deliberately simulated process results test orchestration, not gameplay.
        called = []
        def simulated_runner(output, name, profile, godot, render):
            called.append(name)
            if name == "release":
                raise OSError("disclosed simulated launch refusal")
            return {"case": name, "exit_code": 17 if name == "craft" else 0,
                    "acceptance_credit": False, "simulation_only": True}
        results = batch.run_all(self.output, self.profile, runner=simulated_runner)
        self.assertEqual(called, ["preparation", *batch.CASES])
        self.assertEqual(len(results), 11)
        self.assertEqual(results[1]["exit_code"], 17)
        self.assertEqual(results[2]["exit_code"], None)
        self.assertIn("simulated launch refusal", results[2]["error"])
        self.assertEqual(results[-1]["case"], "snapshot_care")
        raw = batch.fixture.read(self.output / "diagnostic-results.json")
        self.assertEqual(raw["results"], results)
        self.assertFalse(raw["acceptance_credit"])
        self.assertEqual(results[0]["downstream_source"], "canonical_generated_starter_fixture")

    def test_exact_original_recipe_mapping_never_turns_into_original_validation(self):
        original = self.output / "cpu-test-original-scenario.json"
        case = batch.fixture.read(self.output / "cases/craft/scenario.json")
        button = next(row for row in case["steps"] if row["action"] == "f48_button")
        batch.fixture.write(original, {"steps": [button, {"peer": 0, "action": "unrelated", "args": {}}]})
        mapped = batch.coverage_manifest(self.output, original)
        craft = next(row for row in mapped["cases"] if row["case"] == "craft")
        self.assertTrue(any(row["original_steps"] == [1] for row in craft["action_recipe_correspondences"]))
        self.assertEqual(mapped["uncovered_original_steps"], [1, 2])
        self.assertEqual(mapped["validated_original_steps"], [])
        self.assertEqual(mapped["original_scenario_sha256"], batch.fixture.digest(original))
        batch.coverage_manifest(self.output)

    def test_existing_output_and_overlong_case_refuse(self):
        with self.assertRaisesRegex(ValueError, "Fresh diagnostic output"):
            batch.prepare(self.output)
        with self.assertRaisesRegex(ValueError, "maximum10"):
            batch.scenario("craft", self.profile["saves"], self.profile,
                           [batch.entry(1, "press", {"action": "interact"}) for _ in range(11)])

    def test_selected_group_continues_and_reports_other_stages_unattempted(self):
        calls = []
        group = batch.selected_cases("key,relic,essence_spend")
        def simulated_runner(output, name, profile, godot, render):
            calls.append(name)
            return {"case": name, "exit_code": 9 if name == "key" else 0,
                    "acceptance_credit": False, "simulation_only": True}
        results = batch.run_all(self.output, self.profile, runner=simulated_runner, cases=group)
        self.assertEqual(calls, ["preparation", "key", "relic", "essence_spend"])
        self.assertEqual(results[1]["exit_code"], 9)
        self.assertEqual(results[-1]["case"], "essence_spend")
        raw = batch.fixture.read(self.output / "diagnostic-results.json")
        self.assertEqual(raw["selected_cases"], list(group))
        self.assertEqual(raw["unattempted_cases"], [name for name in batch.CASES if name not in group])
        for invalid in ["", "craft,craft", "craft,", "forged_case"]:
            with self.assertRaises(ValueError): batch.selected_cases(invalid)


if __name__ == "__main__":
    unittest.main()
