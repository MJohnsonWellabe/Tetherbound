"""Engine-free integrity tests. Temporary synthetic carriers are NOT proof inputs."""
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools/net"))
import f48_ci_ready as gate
import f48_ci_runner as runner
import f48_profile_fixture as fixture
import f48_relocate_profile as relocate


class ReadinessTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="f48-integrity-unit-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bundle = self.root / "bundle"
        self.profile = {"provenance": "SYNTHETIC UNIT TEST ONLY", "configuration_scope": "full",
                        "test_configuration": [], "suite_profiles": {}, "transaction_profiles": {},
                        "routes": {}, "outcomes": {}}
        self.manifest = {"acceptance_credit": False, "earned_checkpoint": False, "mutations": [], "starts": {}}
        for name in sorted(gate.SUITES | gate.OPERATIONS):
            roots, documents = [], []
            for peer in range(4 if name == "boss_four" else 2):
                root = self.bundle / "starts" / name / f"peer-{peer}"
                identity = f"unit-{peer}"
                uid = f"unit-card-{peer}"
                personal = {"creatures": {uid: {}}, "transaction_receipts": ["unit-altar"],
                            "relics_held": [], "relics_hung": [], "portal_unlocks": [],
                            "master_wins": ["master_t1"], "feast_recipes": ["feast_t1"]}
                inventory = [{"id": item, "n": count} for item, count in
                             (("rootstone", 2), ("ironwood", 1), ("feast_t1_ground", 1))]
                party = [{"uid": uid}]
                if name == "release":
                    caught = f"unit-caught-{peer}"
                    party.append({"uid": caught})
                    personal["creatures"][caught] = {"captured_from": {
                        "kind": "wild", "world_namespace": "unit", "spawn_id": "unit", "spawn_generation": 1}}
                if name == "key": inventory.append({"id": "tidewake_portal_key", "n": 1})
                if name == "relic": personal["relics_held"] = ["meadows"]
                character = {"version": 28, "character_id": identity, "party": party,
                             "inventory": inventory, "redesign_character": personal}
                files = {f"characters/redesign-v28/{identity}/character.json": character}
                if peer == 0:
                    altar = {"id": "altar", "paid": True}
                    files["worlds/redesign-v28/unit-world/world.json"] = {
                        "version": 28, "world_id": "unit-world", "flags": {"flags": []},
                        "placed_buildings": [altar, {"id": "forge", "paid": True}],
                        "reward_deliveries": {"unit": {"kind": "altar_building", "status": "accepted",
                            "intent": {"record": altar}, "receipt": "unit-altar"}}}
                    files["saves/redesign-v28/slot_0.json"] = {"version": 28,
                        "split_locator": {"character_id": identity, "world_id": "unit-world"}}
                for relative, value in files.items():
                    path = root / relative
                    fixture.write(path, value)
                    documents.append({"source": "SYNTHETIC UNIT TEST", "path": str(path), "sha256": fixture.digest(path)})
                roots.append(str(root))
            route_names = {f"{operation}{suffix}" for operation in gate.OPERATIONS
                           for suffix in ("_prepare", "_commit", "_reopen")}
            route_names |= {f"{stage}_{peer}" for stage in
                            ("hub", "craft", "portal", "master", "feast_cook", "feast", "relic", "boss_prepare", "boss_join")
                            for peer in range(4)}
            route_names |= {"boss_start", "boss_fight", "host_unlock_tidewake", "host_enter_tidewake", "behind_enter_tidewake"}
            outcomes = {key: {"item_delta": {"unit": -1}, "creature": {"uid": "unit-card-1", "level": 10, "breakthroughs": 1}}
                        for key in ("feast_0", "feast_1", "essence_spend_1")}
            outcomes["release_1"] = {"item_delta": {"unit": 1}, "released_uid": "unit-caught-1"}
            start = {"saves": roots, "routes": {key: [{"action": "wait", "args": {"frames": 1}}]
                                                for key in route_names},
                     "outcomes": outcomes, "provenance": "SYNTHETIC UNIT TEST"}
            self.profile["suite_profiles" if name in gate.SUITES else "transaction_profiles"][name] = start
            self.manifest["starts"][name] = {"documents": documents}
        self.profile["saves"] = self.profile["suite_profiles"]["loop"]["saves"][:]
        for name in sorted(gate.ready.CONFIGURATION_FILES):
            source = fixture.ROOT / "data/config" / name
            target = self.bundle / "test-configuration/data/config" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
            self.profile["test_configuration"].append({"file": "res://data/config/" + name,
                "overlay_file": str(target), "sha256": fixture.digest(target), "source_sha256": fixture.digest(source)})
        self.save()

    def save(self):
        fixture.write(self.bundle / "profile.json", self.profile)
        self.manifest["profile_sha256"] = fixture.digest(self.bundle / "profile.json")
        fixture.write(self.bundle / "producer-manifest.json", self.manifest)

    def test_complete_and_relocated_bundle_retain_all_bytes_and_routes(self):
        self.assertEqual(gate.validate(self.bundle / "profile.json")["transaction_cases"], 24)
        moved = self.root / "other-machine" / "bundle"
        shutil.copytree(self.bundle, moved)
        # Model a Windows-authored artifact consumed on any native platform.
        original = fixture.read(moved / "profile.json")
        for group in ("suite_profiles", "transaction_profiles"):
            for start in original[group].values():
                start["saves"] = ["Z:\\author\\" + str(relocate.tail(raw, "starts")).replace("/", "\\")
                                  for raw in start["saves"]]
        original["saves"] = original["suite_profiles"]["loop"]["saves"][:]
        fixture.write(moved / "profile.json", original)
        manifest = fixture.read(moved / "producer-manifest.json")
        manifest["profile_sha256"] = fixture.digest(moved / "profile.json")
        fixture.write(moved / "producer-manifest.json", manifest)
        local = self.root / "relocated.json"
        relocate.relocate(moved, local)
        self.assertEqual(gate.validate(local)["saved_documents"], 38)
        altered = fixture.read(local)
        altered["transaction_profiles"]["craft"]["routes"]["craft_commit"][0]["args"]["frames"] = 2
        fixture.write(local, altered)
        with self.assertRaisesRegex(ValueError, "beyond verified local path relocation"):
            gate.validate(local)

    def test_missing_boss_refused_for_even_two_peer_smoke(self):
        del self.profile["suite_profiles"]["boss_four"]
        self.save()
        with self.assertRaisesRegex(ValueError, "nine original starts"):
            gate.validate(self.bundle / "profile.json")
        with self.assertRaises(ValueError):
            runner.validate_ready_profile(self.profile, "tests/smoke_net_f48_loop.gd")

    def test_modified_and_unlisted_save_bytes_refused(self):
        path = Path(self.manifest["starts"]["craft"]["documents"][0]["path"])
        original = path.read_bytes()
        path.write_bytes(original + b" ")
        with self.assertRaisesRegex(ValueError, "byte mismatch"):
            gate.validate(self.bundle / "profile.json")
        path.write_bytes(original)
        (path.parent / "extra.json").write_text("{}")
        with self.assertRaisesRegex(ValueError, "Unlisted or missing"):
            gate.validate(self.bundle / "profile.json")

    def test_missing_cut_route_refused(self):
        del self.profile["transaction_profiles"]["craft"]["routes"]["craft_reopen"]
        self.save()
        with self.assertRaisesRegex(ValueError, "Missing original routes"):
            gate.validate(self.bundle / "profile.json")

    def test_overlay_bytes_and_original_source_pins_are_enforced(self):
        row = self.profile["test_configuration"][0]
        path = Path(row["overlay_file"])
        original = path.read_bytes()
        path.write_bytes(original + b" ")
        with self.assertRaisesRegex(ValueError, "overlay byte mismatch"):
            gate.validate(self.bundle / "profile.json")
        path.write_bytes(original)
        row["source_sha256"] = "0" * 64
        self.save()
        with self.assertRaisesRegex(ValueError, "original source pins"):
            gate.validate(self.bundle / "profile.json")

    def test_cross_peer_document_pin_is_refused(self):
        docs = self.manifest["starts"]["craft"]["documents"]
        docs[0]["path"] = self.manifest["starts"]["feast"]["documents"][0]["path"]
        self.save()
        with self.assertRaisesRegex(ValueError, "cross-start document"):
            gate.validate(self.bundle / "profile.json")

    def test_runner_refuses_before_creating_output_or_launching_engine(self):
        path = Path(self.manifest["starts"]["craft"]["documents"][0]["path"])
        path.write_bytes(path.read_bytes() + b" ")
        output = self.root / "native-must-not-exist"
        with patch.object(sys, "argv", ["runner", "--profile", str(self.bundle / "profile.json"),
                "--godot", "NEVER-LAUNCH", "--script", "tests/smoke_net_f48_loop.gd", "--proof-out", str(output)]), \
                patch.object(runner.subprocess, "run") as launch:
            self.assertEqual(runner.main(), 1)
            launch.assert_not_called()
        self.assertFalse(output.exists())

    def test_terminal_producer_requires_actual_clean_end_and_original_pins(self):
        producer = self.root / "producer"
        invocation = {"profile_sha256": fixture.digest(self.bundle / "profile.json"),
                      "effective_configuration": [{"file": row["file"], "sha256": row["sha256"]}
                                                  for row in self.profile["test_configuration"]]}
        fixture.write(producer / "invocation.json", invocation)
        run = {"failures": [], "fatal": "", "peers": [
            {"index": peer, "exited": True, "unexpected_exit": False} for peer in range(2)]}
        fixture.write(producer / "net-run/NET_RUN.json", run)
        log = producer / "coordinator.log"
        log.write_text("ALL CHECKS PASSED\n")
        args = (producer, self.bundle / "profile.json", invocation["profile_sha256"])
        self.assertEqual(len(gate.terminal_producer(*args)), 3)
        for bad_log in ("ALL CHECKS PASSED\nFAIL: later failure\n", "quoted ALL CHECKS PASSED\n", "unfinished\n"):
            log.write_text(bad_log)
            with self.assertRaises(ValueError): gate.terminal_producer(*args)
        log.write_text("ALL CHECKS PASSED\n")
        for mutation in ({"failures": ["actual failed admission"]}, {"fatal": "timeout"}, {"peers": []}):
            fixture.write(producer / "net-run/NET_RUN.json", dict(run, **mutation))
            with self.assertRaises(ValueError): gate.terminal_producer(*args)


if __name__ == "__main__":
    unittest.main()
