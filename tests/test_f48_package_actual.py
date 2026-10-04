"""Synthetic temporary packaging controls only; these files are never native evidence."""
from pathlib import Path
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/net"))
sys.path.insert(0, str(ROOT / "tests"))
import f48_package_actual as package
import f48_profile_fixture as fixture
import f48_ci_ready as gate
import test_f48_ci_ready as readiness_fixture


class ActualPackageTests(unittest.TestCase):
    def setUp(self):
        self.seed = readiness_fixture.ReadinessTests("test_missing_cut_route_refused")
        self.seed.setUp()
        self.addCleanup(self.seed.doCleanups)
        self.root = self.seed.root
        self.output = self.root / "packaged"
        self.spec = {"provenance": "SYNTHETIC UNIT TEST ONLY, NO NATIVE OR GAMEPLAY CLAIM",
                     "producers": {}, "starts": {}}
        for producer, script in package.SCRIPTS.items():
            root = self.root / ("synthetic-" + producer)
            start = self.seed.profile["suite_profiles"][producer]
            profile = {"provenance": self.spec["provenance"], "saves": start["saves"],
                       "routes": start["routes"], "outcomes": start["outcomes"],
                       "configuration_scope": "full", "test_configuration": []}
            for row in self.seed.profile["test_configuration"]:
                target = root / "mechanics-start/test-configuration/data/config" / Path(row["file"]).name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(row["overlay_file"], target)
                profile["test_configuration"].append(dict(row, overlay_file=str(target)))
            profile_path = root / "producer-profile/profile.json"
            fixture.write(profile_path, profile)
            self.spec["producers"][producer] = {"root": str(root), "profile": "producer-profile/profile.json",
                                                "profile_sha256": fixture.digest(profile_path)}
            fixture.write(root / "invocation.json", {"profile_sha256": fixture.digest(profile_path),
                "command": ["SYNTHETIC-NOT-AN-ENGINE", "--script", script],
                "effective_configuration": [{"file": row["file"], "sha256": row["sha256"]}
                                            for row in profile["test_configuration"]]})
            fixture.write(root / "net-run/NET_RUN.json", {"failures": [], "fatal": "",
                "peers": [{"index": peer, "exited": True, "unexpected_exit": False}
                          for peer in range(len(start["saves"]))]})
            (root / "coordinator.log").write_text("SYNTHETIC UNIT TEST ONLY\nALL CHECKS PASSED\n", encoding="utf-8")
            report = ["SYNTHETIC UNIT TEST ONLY", "**Verdict: PASS**"]
            for name, (expected_producer, capture) in package.CAPTURES.items():
                if expected_producer != producer: continue
                source_start = self.seed.profile["suite_profiles" if name in gate.SUITES else "transaction_profiles"][name]
                for peer, source in enumerate(source_start["saves"]):
                    destination = root / "proof" / f"peer-{peer}" / capture
                    shutil.copytree(source, destination)
                    inputs = fixture.source_input(destination, peer == 0)
                    observation = {"action": "f48_assert_snapshot", "result": {"verdict": "PASS", "data": {
                        "character_id": inputs["id"], "character_sha256": fixture.digest(inputs["character_path"]),
                        "world_sha256": fixture.digest(inputs["world_path"]) if peer == 0 else "",
                        "snapshot_source": "actual_owner_BOOL_edge_full_canonical_after_and_accepted_ACK"}}}
                    fixture.write(root / "proof/f48-observations" / f"f48_assert_snapshot-{name}-{peer}.json", observation)
                    for path in destination.rglob("*"):
                        if path.is_file(): report.append(f"- `{path.relative_to(root / 'proof').as_posix()}`")
                route_path = self.root / "synthetic-routes" / (name + ".json")
                fixture.write(route_path, {key: source_start[key] for key in ("provenance", "routes", "outcomes")})
                self.spec["starts"][name] = {"producer": producer, "capture": capture, "route_pack": str(route_path),
                                             "route_pack_sha256": fixture.digest(route_path)}
            (root / "proof/PROOF.md").write_text("\n".join(report) + "\n", encoding="utf-8")
        self.input = self.root / "synthetic-package.json"
        self.save()

    def save(self):
        fixture.write(self.input, self.spec)

    def test_complete_package_delegates_original_gate_and_preserves_source_bytes(self):
        originals = {path: fixture.digest(path) for path in self.root.rglob("*") if path.is_file()}
        result = package.package(self.input, self.output)
        self.assertTrue(result["ok"])
        self.assertFalse(result["acceptance_credit"])
        self.assertFalse(result["earned_checkpoint"])
        self.assertTrue(result["native_oracles_required"])
        self.assertEqual(result["transaction_cases"], 24)
        self.assertEqual(gate.validate(self.output / "profile.json")["saved_documents"], 38)
        for path, digest in originals.items(): self.assertEqual(fixture.digest(path), digest)
        self.assertTrue((self.output / "producer-evidence/behind/proof/PROOF.md").is_file())

    def test_missing_behind_refused_before_any_output(self):
        del self.spec["producers"]["behind"]
        self.save()
        with self.assertRaisesRegex(ValueError, "behind"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_failed_terminal_and_wrong_producer_cannot_be_packaged(self):
        root = Path(self.spec["producers"]["loop"]["root"])
        run = fixture.read(root / "net-run/NET_RUN.json")
        run["fatal"] = "SYNTHETIC FAILURE"
        fixture.write(root / "net-run/NET_RUN.json", run)
        with self.assertRaisesRegex(ValueError, "producer failed"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())
        run["fatal"] = ""
        fixture.write(root / "net-run/NET_RUN.json", run)
        invocation = fixture.read(root / "invocation.json")
        invocation["command"] = ["SYNTHETIC WRONG SCRIPT"]
        fixture.write(root / "invocation.json", invocation)
        with self.assertRaisesRegex(ValueError, "different producer"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_changed_saved_bytes_need_sealed_native_hash_not_just_a_directory(self):
        root = Path(self.spec["producers"]["behind"]["root"])
        path = fixture.source_input(root / "proof/peer-1/f48-behind-input", False)["character_path"]
        path.write_bytes(path.read_bytes() + b" ")
        with self.assertRaisesRegex(ValueError, "sealed native snapshot hashes"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_route_hash_and_named_capture_are_not_replaceable(self):
        row = self.spec["starts"]["release"]
        row["route_pack_sha256"] = "0" * 64
        self.save()
        with self.assertRaisesRegex(ValueError, "Reviewed source hash mismatch"):
            package.package(self.input, self.output)
        row["route_pack_sha256"] = fixture.digest(Path(row["route_pack"]))
        row["capture"] = "f48-loop-input"
        self.save()
        with self.assertRaisesRegex(ValueError, "Wrong original capture"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_missing_original_route_and_parent_path_refused(self):
        row = self.spec["starts"]["behind"]
        routes = fixture.read(Path(row["route_pack"]))
        del routes["routes"]["behind_enter_tidewake"]
        fixture.write(Path(row["route_pack"]), routes)
        row["route_pack_sha256"] = fixture.digest(Path(row["route_pack"]))
        self.save()
        with self.assertRaisesRegex(ValueError, "Missing original routes"):
            package.package(self.input, self.output)
        with self.assertRaisesRegex(ValueError, "Unsafe producer-relative"):
            package.checked(self.root, "../outside")
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
