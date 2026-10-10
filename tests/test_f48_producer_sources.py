"""Integrity checks for preserved originals; these tests award no gameplay proof."""
import hashlib
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools/net"))
import f48_produce_actual as producer
import f48_profile_fixture as fixture
import f48_profile_ready as ready
import f48_prepare_profile as prepare


class OriginalSourcesTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="f48-original-integrity-")
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.bundle = self.root / "bundle"
        shutil.copytree(producer.ROOT / "tests/fixtures/f48-producer-seeds", self.bundle)
        self.output = self.root / "restored"
        self.manifest = fixture.read(self.bundle / "manifest.json")

    def save_manifest(self):
        fixture.write(self.bundle / "manifest.json", self.manifest)

    def test_restore_retains_exact_original_bytes_and_distinct_identities(self):
        roots = producer.restore_seeds(self.bundle, self.output)
        self.assertEqual(len(roots), 4)
        for peer, root in zip(self.manifest["peers"], roots):
            for row in peer["documents"]:
                original = (root / row["relative"]).read_bytes()
                self.assertEqual(hashlib.sha256(original).hexdigest(), row["source_sha256"])
        with self.assertRaisesRegex(ValueError, "Fresh original-source output"):
            producer.restore_seeds(self.bundle, self.output)

    def test_corrupted_last_archive_is_rejected_before_any_save_is_written(self):
        row = self.manifest["peers"][-1]["documents"][-1]
        archive = self.bundle / row["path"]
        archive.write_bytes(archive.read_bytes() + b"corrupt")
        with self.assertRaisesRegex(ValueError, "Compressed original changed"):
            producer.restore_seeds(self.bundle, self.output)
        self.assertFalse(self.output.exists())

    def test_duplicate_identity_is_rejected(self):
        self.manifest["peers"][3]["character_id"] = self.manifest["peers"][0]["character_id"]
        self.save_manifest()
        with self.assertRaisesRegex(ValueError, "Never clone"):
            producer.restore_seeds(self.bundle, self.output)
        self.assertFalse(self.output.exists())

    def test_source_and_destination_cannot_escape_their_roots(self):
        row = self.manifest["peers"][0]["documents"][0]
        for field in ("path", "relative"):
            original = row[field]
            row[field] = "../escaped.json"
            self.save_manifest()
            with self.assertRaisesRegex(ValueError, "inside its declared root"):
                producer.restore_seeds(self.bundle, self.output)
            self.assertFalse(self.output.exists())
            row[field] = original

    def test_complete_pack_requires_four_peer_boss_start(self):
        pack = self.root / "incomplete.json"
        fixture.write(pack, {"provenance": "UNIT TEST ONLY", "configuration_profile": "unused.json",
                             "starts": {name: {} for name in ready.SUITES | ready.OPERATIONS if name != "boss_four"}})
        with self.assertRaisesRegex(ValueError, "lacks an original suite/transaction"):
            ready.generate(pack, self.output, True)
        self.assertFalse(self.output.exists())

    def test_prepared_routes_deploy_original_companion_before_every_approach(self):
        saves = []
        for peer in range(2):
            root = self.root / f"synthetic-peer-{peer}"
            fixture.write(root / "character.json", {"party": [{"uid": f"unit-{peer}",
                "species_id": "terrapup", "level": 9, "nickname": "A" if peer == 0 else "B"}]})
            saves.append(str(root))
        source = self.root / "synthetic-profile.json"
        fixture.write(source, {"saves": saves, "configuration_scope": "full", "routes": {},
                               "outcomes": {}, "provenance": "SYNTHETIC ROUTE UNIT TEST ONLY"})
        path = prepare.produce(source, self.root / "prepared")
        routes = fixture.read(path)["routes"]
        self.assertIn("craft_reopen", routes)
        self.assertIn("key_reopen", routes)
        self.assertIn("essence_spend_reopen", routes)
        for name, route in routes.items():
            for index, row in enumerate(route):
                if row["action"] == "f48_fixture_approach":
                    with self.subTest(route=name):
                        self.assertGreater(index, 0)
                        self.assertEqual(route[index - 1], {"action": "f48_deploy_owned", "args": {}})

    def test_four_peer_route_keeps_one_deployment_before_actual_approach(self):
        source = self.root / "synthetic-four-profile.json"
        fixture.write(source, {"saves": [f"synthetic-{peer}" for peer in range(4)],
                               "provenance": "SYNTHETIC ROUTE UNIT TEST ONLY"})
        path = producer.boss_profile(source, self.root / "boss-profile")
        routes = fixture.read(path)["routes"]
        for peer in range(4):
            actions = [row["action"] for row in routes[f"boss_prepare_{peer}"]]
            self.assertEqual(actions, ["f48_deploy_owned", "f48_fixture_approach"])

    def test_only_named_warden_requests_readiness_gated_physical_input_cadence(self):
        warden = prepare.fight("warden_aldis")["args"]
        self.assertEqual(warden["input_cadence"], {"stride_frames": 4, "stage_when_ready": True})
        self.assertEqual(warden["budget_frames"], 9000)
        self.assertEqual(warden["fixture_disclosure"]["enemy_hp_ceiling"], 0)
        self.assertFalse(warden["fixture_disclosure"]["earned_campaign_credit"])
        master = prepare.fight("master_t1")["args"]
        self.assertNotIn("input_cadence", master)
        self.assertEqual(master["budget_frames"], 3000)

    def _shipping_profile(self):
        project = self.root / "shipping-project"
        for name in set(producer.FIELDS) | {"combat.json"}:
            target = project / "data/config" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(producer.ROOT / "data/config" / name, target)
        alpha_path = project / "data/config/alpha_respawns.json"
        alpha = fixture.read(alpha_path)
        alpha["runtime_enabled"] = False # Synthetic OFF input, independent of future shipping defaults.
        fixture.write(alpha_path, alpha)
        source = self.root / "shipping-source.json"
        fixture.write(source, {"saves": [f"synthetic-{peer}" for peer in range(4)],
                               "provenance": "SYNTHETIC SHIPPING-CONFIG UNIT TEST ONLY"})
        with patch.object(producer, "ROOT", project):
            profile_path = producer.boss_profile(source, self.root / "shipping-profile", True)
        return project, fixture.read(profile_path)

    def test_shipping_boss_pins_actual_off_flags_without_writing_configuration(self):
        project, profile = self._shipping_profile()
        originals = {path: path.read_bytes() for path in (project / "data/config").glob("*.json")}
        alpha = fixture.read(project / "data/config/alpha_respawns.json")
        self.assertFalse(alpha["runtime_enabled"], "synthetic shipping alpha gate stays OFF")
        with producer.shipping_configuration(project, profile) as pins:
            self.assertEqual(len(pins), 7)
            self.assertEqual(len(profile["test_configuration"]), 6)
            for row in profile["test_configuration"]:
                self.assertEqual(row["sha256"], fixture.digest(project / row["file"].removeprefix("res://")))
        self.assertEqual({path: path.read_bytes() for path in originals}, originals)

    def test_changed_shipping_configuration_refuses_before_native_execution(self):
        project, profile = self._shipping_profile()
        path = project / "data/config/combat.json"
        path.write_bytes(path.read_bytes() + b" ")
        executed = False
        with self.assertRaisesRegex(ValueError, "differs from original producer pins"):
            with producer.shipping_configuration(project, profile):
                executed = True
        self.assertFalse(executed)

    def test_shipping_guard_detects_mid_run_change_without_repairing_evidence(self):
        project, profile = self._shipping_profile()
        path = project / "data/config/alpha_respawns.json"
        changed = path.read_bytes() + b" "
        with self.assertRaisesRegex(ValueError, "changed during native run"):
            with producer.shipping_configuration(project, profile):
                path.write_bytes(changed)
        self.assertEqual(path.read_bytes(), changed)

    def test_shipping_guard_refuses_duplicate_pins(self):
        project, profile = self._shipping_profile()
        profile["production_configuration_pins"][-1] = profile["production_configuration_pins"][0].copy()
        with self.assertRaisesRegex(ValueError, "duplicate shipping configuration pin"):
            with producer.shipping_configuration(project, profile):
                self.fail("malformed pins admitted native execution")

    def test_shipping_producer_refuses_native_guard_parity_mismatch_before_subprocess_boundary(self):
        project, profile = self._shipping_profile()
        profile["test_configuration"][0]["sha256"] = "0" * 64
        executed = False
        with self.assertRaisesRegex(ValueError, "native guard pins differ"):
            with producer.shipping_configuration(project, profile): executed = True
        self.assertFalse(executed)

    def test_shipping_loop_retains_off_config_and_refreshes_generated_profile_digest(self):
        project, shipping = self._shipping_profile()
        saves = []
        for peer in range(2):
            root = self.root / f"loop-peer-{peer}"
            fixture.write(root / "character.json", {"party": [{"uid": f"unit-{peer}",
                "species_id": "terrapup", "level": 9, "nickname": "A" if peer == 0 else "B"}]})
            saves.append(str(root))
        source = self.root / "loop-source.json"
        fixture.write(source, {"saves": saves, "configuration_scope": "full", "routes": {},
                               "outcomes": {}, "provenance": "SYNTHETIC LOOP ONLY"})
        originals = {path: path.read_bytes() for path in (project / "data/config").glob("*.json")}
        with patch.object(producer, "ROOT", project):
            path = producer.loop_profile(source, self.root / "loop-profile", True)
        profile = fixture.read(path)
        self.assertEqual(profile["production_configuration_pins"], shipping["production_configuration_pins"])
        self.assertEqual(fixture.read(path.parent / "source.json")["profile_sha256"], fixture.digest(path))
        self.assertTrue(profile["prepare_alpha_capture"], "No replacement for the original native capture")
        self.assertFalse(fixture.read(project / "data/config/alpha_respawns.json")["runtime_enabled"])
        with producer.shipping_configuration(project, profile): pass
        self.assertEqual({path: path.read_bytes() for path in originals}, originals)


if __name__ == "__main__":
    unittest.main()
