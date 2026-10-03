"""Integrity checks for preserved originals; these tests award no gameplay proof."""
import hashlib
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

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


if __name__ == "__main__":
    unittest.main()
