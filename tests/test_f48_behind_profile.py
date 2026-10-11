"""Synthetic packaging controls only; never native portal or behind proof."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools/net"))
import f48_behind_profile as behind
import f48_profile_fixture as fixture
import f48_produce_actual as producer
import f48_configuration as configuration
import save_document


class BehindProfileTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="f48-behind-UNIT-ONLY-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.loop = self.root / "synthetic-loop"
        self.output = self.root / "behind"
        self.capture = self.loop / "proof/peer-0/f48-before-key"
        self.char_path = self.capture / "characters/redesign-v28/UNIT-host/character.json"
        self.world_path = self.capture / "worlds/redesign-v28/slot-0/world.json"
        self.slot_path = self.capture / "saves/redesign-v28/slot_0.json"
        self.profile_path = self.loop / "producer-profile/profile.json"
        self.character = {"version": 28, "character_id": "UNIT-host", "realm": "meadows",
            "party": [{"uid": "UNIT-companion"}], "inventory": [{"id": "tidewake_portal_key", "n": 1}],
            "redesign_character": {"creatures": {"UNIT-companion": {}},
                                   "relics_held": ["meadows"], "portal_unlocks": []}}
        self.world = {"version": 28, "world_id": "slot-0", "redesign_world": {"portal_unlocks": []}}
        fixture.write(self.slot_path, {"version": 28, "split_locator": {"character_id": "UNIT-host", "world_id": "slot-0"}})
        configurations = []
        for name in sorted(behind.ready.CONFIGURATION_FILES):
            original = behind.ROOT / "data/config" / name
            target = self.loop / "mechanics-start/test-configuration/data/config" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(original.read_bytes())
            configurations.append({"file": "res://data/config/" + name, "overlay_file": str(target),
                                   "sha256": fixture.digest(target), "source_sha256": fixture.digest(original)})
        self.profile = {"provenance": "SYNTHETIC UNIT TEST ONLY; NO NATIVE CREDIT", "configuration_scope": "full",
                        "test_configuration": configurations, "saves": ["UNIT-host", "UNIT-guest"]}
        fixture.write(self.profile_path, self.profile)
        self.profile_hash = fixture.digest(self.profile_path)
        fixture.write(self.loop / "invocation.json", {"profile_sha256": self.profile_hash,
            "command": ["UNIT-NO-ENGINE", "tools/net/f48_prepare.gd"],
            "effective_configuration": [{"file": row["file"], "sha256": row["sha256"]} for row in configurations]})
        fixture.write(self.loop / "net-run/NET_RUN.json", {"failures": [], "fatal": "",
            "peers": [{"index": index, "exited": True, "unexpected_exit": False} for index in range(2)]})
        (self.loop / "coordinator.log").write_text("SYNTHETIC UNIT TEST ONLY\nALL CHECKS PASSED\n", encoding="utf-8")
        report = self.loop / "proof/PROOF.md"
        report.write_text("SYNTHETIC UNIT TEST ONLY\n**Verdict: PASS**\n" + "\n".join(
            "`" + path.relative_to(self.loop / "proof").as_posix() + "`"
            for path in [self.char_path, self.world_path, self.slot_path]), encoding="utf-8")
        self.write_snapshot()

    def write_snapshot(self):
        fixture.write(self.char_path, save_document.encode(self.character))
        fixture.write(self.world_path, save_document.encode(self.world))
        fixture.write(self.loop / "proof/f48-observations/f48_assert_snapshot-UNIT.json", {
            "action": "f48_assert_snapshot", "result": {"verdict": "PASS", "data": {
                "character_id": "UNIT-host", "character_sha256": fixture.digest(self.char_path),
                "world_sha256": fixture.digest(self.world_path),
                "snapshot_source": "actual_owner_BOOL_edge_full_canonical_after_and_accepted_ACK"}}})

    def generate(self, guest_peer=2, shipping_config=False):
        return behind.generate(self.loop, self.profile_path, self.profile_hash, self.output, guest_peer,
                               shipping_config=shipping_config)

    def shipping_loop(self):
        producer.pin_shipping_profile(self.profile, behind.ROOT)
        fixture.write(self.profile_path, self.profile)
        self.profile_hash = fixture.digest(self.profile_path)
        invocation = fixture.read(self.loop / "invocation.json")
        invocation.update(profile_sha256=self.profile_hash, shipping_configuration=True,
                          effective_configuration=self.profile["production_configuration_pins"])
        fixture.write(self.loop / "invocation.json", invocation)

    def test_shipping_behind_inherits_all_seven_pins_without_overlay_or_source_mutation(self):
        self.shipping_loop()
        original = {path: path.read_bytes() for path in self.loop.rglob("*") if path.is_file()}
        profile = fixture.read(self.generate(shipping_config=True))
        self.assertEqual(profile["production_configuration_pins"], self.profile["production_configuration_pins"])
        self.assertEqual(profile["test_configuration"], self.profile["test_configuration"])
        self.assertFalse((self.output / "mechanics-start/test-configuration").exists())
        configuration.shipping_files(behind.ROOT, profile)
        manifest = fixture.read(self.output / "producer-profile/source.json")
        sources = {row["path"]: row["sha256"] for row in manifest["sources"]}
        for row in profile["production_configuration_pins"]:
            self.assertEqual(sources[str(behind.ROOT / row["file"].removeprefix("res://"))], row["sha256"])
        for path, raw in original.items(): self.assertEqual(path.read_bytes(), raw)

    def test_shipping_mode_cannot_relabel_overlay_loop_or_silently_apply_overlay_to_shipping_loop(self):
        with self.assertRaisesRegex(ValueError, "mode must match"): self.generate(shipping_config=True)
        self.assertFalse(self.output.exists())
        self.shipping_loop()
        with self.assertRaisesRegex(ValueError, "mode must match"): self.generate()
        self.assertFalse(self.output.exists())

    def test_shipping_behind_refuses_changed_combat_without_writing_output(self):
        self.shipping_loop()
        self.profile["production_configuration_pins"] = [dict(row, sha256="0" * 64)
            if row["file"].endswith("/combat.json") else row for row in self.profile["production_configuration_pins"]]
        fixture.write(self.profile_path, self.profile)
        self.profile_hash = fixture.digest(self.profile_path)
        with self.assertRaisesRegex(ValueError, "differs from original"): self.generate(shipping_config=True)
        self.assertFalse(self.output.exists())

    def test_shipping_behind_declared_invocation_must_match_actual_shipping_pins(self):
        self.shipping_loop()
        invocation = fixture.read(self.loop / "invocation.json")
        invocation["shipping_configuration"] = False
        fixture.write(self.loop / "invocation.json", invocation)
        with self.assertRaisesRegex(ValueError, "declaration differs"): self.generate(shipping_config=True)
        self.assertFalse(self.output.exists())

    def test_original_bytes_real_input_routes_and_standard_layout(self):
        original = {path: path.read_bytes() for path in self.loop.rglob("*") if path.is_file()}
        path = self.generate()
        profile = fixture.read(path)
        self.assertEqual(path, self.output / "producer-profile/profile.json")
        host = fixture.source_input(Path(profile["saves"][0]), True)
        guest = fixture.source_input(Path(profile["saves"][1]), False)
        self.assertEqual(host["character_path"].read_bytes(), self.char_path.read_bytes())
        self.assertEqual(host["world_path"].read_bytes(), self.world_path.read_bytes())
        self.assertEqual(host["slot_path"].read_bytes(), self.slot_path.read_bytes())
        seed = fixture.read(behind.SEEDS / "manifest.json")["peers"][2]
        self.assertEqual(fixture.digest(guest["character_path"]), seed["documents"][0]["source_sha256"])
        self.assertFalse((Path(profile["saves"][1]) / "worlds").exists())
        behind.gate.validate_routes("behind", profile)
        for name, route in profile["routes"].items():
            self.assertEqual(sum(step["action"] == "press" for step in route), 1)
            self.assertEqual([step["args"]["action"] for step in route if step["action"] == "press"], ["interact"])
            if name != "host_enter_tidewake":
                self.assertEqual(route[0]["action"], "f48_deploy_owned")
                self.assertEqual(route[1]["args"]["target"], "tidewake_arch")
        self.assertEqual(profile["outcomes"], {})
        manifest = fixture.read(self.output / "producer-profile/source.json")
        self.assertEqual(manifest["saved_mutations"], [])
        self.assertFalse(manifest["acceptance_credit"])
        for source, raw in original.items(): self.assertEqual(source.read_bytes(), raw)
        with self.assertRaisesRegex(ValueError, "Fresh"): self.generate()

    def test_second_distinct_original_guest_and_no_boss_guest_reuse(self):
        for peer in (0, 1, True, 4):
            with self.assertRaisesRegex(ValueError, "nonparticipant"): self.generate(peer)
        profile = fixture.read(self.generate(3))
        guest = fixture.source_input(Path(profile["saves"][1]), False)
        self.assertEqual(guest["id"], fixture.read(behind.SEEDS / "manifest.json")["peers"][3]["character_id"])

    def test_failed_terminal_and_missing_native_snapshot_refused(self):
        terminal = self.loop / "net-run/NET_RUN.json"
        row = fixture.read(terminal)
        row["failures"] = ["UNIT actual failure"]
        fixture.write(terminal, row)
        with self.assertRaisesRegex(ValueError, "producer failed"): self.generate()
        row["failures"] = []
        fixture.write(terminal, row)
        self.char_path.write_bytes(self.char_path.read_bytes() + b" ")
        with self.assertRaisesRegex(ValueError, "sealed native"): self.generate()
        self.assertFalse(self.output.exists())

    def test_real_key_unspent_unopened_and_owned_relic_required(self):
        original = copy.deepcopy(self.character)
        for change in (lambda c: c.update(inventory=[]),
                       lambda c: c.update(realm="water"),
                       lambda c: c["redesign_character"].update(relics_held=[]),
                       lambda c: c["redesign_character"].update(portal_unlocks=["tidewake"])):
            self.character = copy.deepcopy(original)
            change(self.character)
            self.write_snapshot()
            with self.assertRaisesRegex(ValueError, "unspent key/relic"): self.generate()
        self.character = original
        self.world["redesign_world"]["portal_unlocks"] = ["tidewake"]
        self.write_snapshot()
        with self.assertRaisesRegex(ValueError, "unspent key/relic"): self.generate()
        self.assertFalse(self.output.exists())

    def test_hash_and_concurrent_source_changes_refused(self):
        with self.assertRaisesRegex(ValueError, "hash mismatch"):
            behind.generate(self.loop, self.profile_path, "0" * 64, self.output)
        original = behind.gate.validate_routes
        def mutate_after_reads(*args):
            original(*args)
            self.world_path.write_bytes(self.world_path.read_bytes() + b" ")
        with patch.object(behind.gate, "validate_routes", side_effect=mutate_after_reads):
            with self.assertRaisesRegex(ValueError, "changed before copy"): self.generate()
        self.assertFalse(self.output.exists())

    def test_prepare_only_launcher_reuses_completed_artifact(self):
        args = ["f48_produce_actual.py", "--producer", "behind", "--prepare-only", "--output", str(self.output),
                "--loop-output", str(self.loop), "--loop-profile", str(self.profile_path),
                "--loop-profile-sha256", self.profile_hash]
        with patch.object(sys, "argv", args), patch.object(producer.subprocess, "run") as native:
            self.assertEqual(producer.main(), 0)
            native.assert_not_called()
        self.assertTrue((self.output / "producer-profile/profile.json").is_file())
        self.assertFalse((self.output / "originals").exists())


if __name__ == "__main__":
    unittest.main()
