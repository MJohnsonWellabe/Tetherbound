"""Synthetic packaging controls only; no native capture/release proof."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools/net"))
import f48_release_route as release
import f48_profile_fixture as fixture
import save_document


class ReleaseRouteTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="f48-release-UNIT-ONLY-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.original = self.root / "original"
        self.guest = self.root / "captured"
        self.output = self.root / "output"
        self.profile_path = self.root / "profile.json"
        self.character_path = self.guest / "characters/redesign-v28/guest/character.json"
        species = fixture.read(release.ROOT / "data/creatures/species.json")["species"]

        def card(uid, species_id, nickname):
            definition = species[species_id]
            return {"uid": uid, "species_id": species_id, "nickname": nickname,
                    "display_name": definition["display_name"], "level": 9,
                    "creature_type": definition["type"], "secondary_type": definition.get("type_secondary", "")}

        self.character = {"version": 28, "character_id": "guest",
            "party": [card("starter", "terrapup", "B"), card("caught", "nightburrow", "Caught pal")],
            "redesign_character": {"creatures": {"starter": {}, "caught": {"captured_from": {
                "kind": "wild", "world_namespace": "UNIT-ONLY", "spawn_id": "UNIT-ONLY-spawn", "spawn_generation": 1}}},
                "release_receipts": [], "transaction_receipts": []}}
        original = copy.deepcopy(self.character)
        original["party"] = original["party"][:1]
        original["redesign_character"]["creatures"] = {"starter": {}}
        fixture.write(self.original / "characters/redesign-v28/guest/character.json", original)
        configurations = []
        for name in ("essence.json", "traits.json"):
            source = release.ROOT / "data/config" / name
            data = fixture.read(source)
            if name == "traits.json": data["runtime_enabled"] = True
            target = self.root / "configuration" / name
            fixture.write(target, data)
            configurations.append({"file": "res://data/config/" + name, "overlay_file": str(target),
                "source_sha256": fixture.digest(source), "sha256": fixture.digest(target)})
        self.profile = {"configuration_scope": "full", "saves": ["UNIT-ONLY-unused-host", str(self.original)],
            "provenance": "SYNTHETIC UNIT TEST ONLY", "test_configuration": configurations,
            "routes": {"essence_spend_prepare": [{"action": "press", "args": {"action": "interact"}}],
                       "unrelated": [{"action": "wait", "args": {"frames": 3}}]},
            "outcomes": {"unrelated": {"item_delta": {"berries": -1}}}}
        self.write_sources()

    def write_sources(self):
        fixture.write(self.profile_path, self.profile)
        fixture.write(self.character_path, save_document.encode(self.character))
        self.profile_hash = fixture.digest(self.profile_path)
        self.character_hash = fixture.digest(self.character_path)

    def generate(self, uid=None):
        return release.generate(self.profile_path, self.guest, self.output, uid=uid,
            profile_sha256=self.profile_hash, character_sha256=self.character_hash)

    def test_exact_uid_two_confirmation_yield_and_preserved_routes(self):
        originals = {path: path.read_bytes() for path in self.root.rglob("*") if path.is_file()}
        route = self.generate()
        pack = fixture.read(route)
        self.assertEqual(pack["routes"]["unrelated"], self.profile["routes"]["unrelated"])
        self.assertEqual(pack["outcomes"]["unrelated"], self.profile["outcomes"]["unrelated"])
        self.assertEqual(pack["outcomes"]["release_1"], {"released_uid": "caught",
                         "item_delta": {"essence_ground": 4, "essence_dark": 3}})
        prepare = pack["routes"]["release_prepare"]
        self.assertIn({"action": "f48_choice", "args": {"uid": "caught"}}, prepare)
        self.assertEqual(prepare, pack["routes"]["release_reopen"])
        buttons = [step["args"]["text"] for step in pack["routes"]["release_commit"] if step["action"] == "f48_button"]
        self.assertEqual(buttons, ["Release companion and distil chosen trait",
            "Release Caught pal? This can't be undone. A confirms; B leaves."])
        fixture.validate_pack(pack)
        self.assertEqual(fixture.read(self.output / "source.json")["acceptance_credit"], False)
        for path, data in originals.items(): self.assertEqual(path.read_bytes(), data)
        with self.assertRaisesRegex(ValueError, "Fresh"): self.generate()

    def test_ambiguous_capture_requires_explicit_valid_uid_and_duplicate_label_is_safe(self):
        other = copy.deepcopy(self.character["party"][1])
        other["uid"] = "caught-other"
        self.character["party"].append(other)
        self.character["redesign_character"]["creatures"]["caught-other"] = copy.deepcopy(
            self.character["redesign_character"]["creatures"]["caught"])
        self.write_sources()
        with self.assertRaisesRegex(ValueError, "unambiguous"): self.generate()
        with self.assertRaisesRegex(ValueError, "unambiguous"): self.generate("starter")
        with self.assertRaisesRegex(ValueError, "unambiguous"): self.generate("missing")
        result = fixture.read(self.generate("caught-other"))
        self.assertEqual(result["outcomes"]["release_1"]["released_uid"], "caught-other")

    def test_fallback_label_uses_actual_saved_display_name(self):
        self.character["party"][1]["nickname"] = "  "
        self.character["party"][1]["display_name"] = "Original display"
        self.write_sources()
        pack = fixture.read(self.generate())
        self.assertIn("Release Original display?", pack["routes"]["release_commit"][2]["args"]["text"])

    def test_missing_malformed_provenance_and_last_companion_refused(self):
        record = self.character["redesign_character"]["creatures"]["caught"]
        original = copy.deepcopy(record["captured_from"])
        for source in ({}, {**original, "kind": "gift"}, {**original, "world_namespace": ""},
                       {**original, "spawn_id": 4}, {**original, "spawn_generation": True},
                       {**original, "spawn_generation": 1.5}, {**original, "spawn_generation": 0},
                       {**original, "spawn_generation": 2147483648}):
            record["captured_from"] = source
            self.write_sources()
            with self.assertRaisesRegex(ValueError, "unambiguous"): self.generate()
            self.assertFalse(self.output.exists())
        record["captured_from"] = original
        self.character["party"] = self.character["party"][1:]
        del self.character["redesign_character"]["creatures"]["starter"]
        self.write_sources()
        with self.assertRaisesRegex(ValueError, "last companion"): self.generate()

    def test_existing_receipt_and_inconsistent_types_refused(self):
        self.character["redesign_character"]["release_receipts"] = ["release:caught"]
        self.write_sources()
        with self.assertRaisesRegex(ValueError, "already has a release receipt"): self.generate()
        self.character["redesign_character"]["release_receipts"] = []
        self.character["party"][1]["creature_type"] = "fire"
        self.write_sources()
        with self.assertRaisesRegex(ValueError, "species/type/level mismatch"): self.generate()

    def test_caught_marker_never_makes_starter_or_legendary_eligible(self):
        for forbidden in ("terrapup", "ripplet", "galewisp"):
            self.character["party"][1]["species_id"] = forbidden
            self.write_sources()
            with self.assertRaisesRegex(ValueError, "unambiguous"): self.generate("caught")
            self.assertFalse(self.output.exists())
        self.character["party"][1]["species_id"] = "nightburrow"
        self.write_sources()
        read = fixture.read
        def unit_only_legendary_definition(path):
            data = read(path)
            if path.resolve() == (release.ROOT / "data/creatures/species.json").resolve():
                data["species"]["nightburrow"]["legendary"] = True
            return data
        with patch.object(fixture, "read", side_effect=unit_only_legendary_definition):
            with self.assertRaisesRegex(ValueError, "unambiguous"): self.generate("caught")
        self.assertFalse(self.output.exists())

    def test_changed_source_or_configuration_bytes_refused_before_output(self):
        for path in (self.profile_path, self.character_path, Path(self.profile["test_configuration"][0]["overlay_file"])):
            original = path.read_bytes()
            path.write_bytes(original + b" ")
            with self.assertRaisesRegex(ValueError, "Source bytes changed"): self.generate()
            self.assertFalse(self.output.exists())
            path.write_bytes(original)

    def test_changed_bytes_during_build_refused(self):
        digest = fixture.digest
        reads = 0
        def change_on_final_check(path):
            nonlocal reads
            if path.resolve() == self.character_path.resolve():
                reads += 1
                if reads == 2: self.character_path.write_bytes(self.character_path.read_bytes() + b" ")
            return digest(path)
        with patch.object(fixture, "digest", side_effect=change_on_final_check):
            with self.assertRaisesRegex(ValueError, "Source bytes changed before output"): self.generate()
        self.assertFalse(self.output.exists())

    def test_other_owner_and_conflicting_release_route_refused(self):
        original_path = self.original / "characters/redesign-v28/guest/character.json"
        original = fixture.read(original_path)
        original["character_id"] = "other"
        fixture.write(original_path, original)
        with self.assertRaisesRegex(ValueError, "original guest"): self.generate()
        original["character_id"] = "guest"
        fixture.write(original_path, original)
        self.profile["routes"]["release_prepare"] = [{"action": "wait", "args": {"frames": 1}}]
        self.write_sources()
        with self.assertRaisesRegex(ValueError, "existing different release route"): self.generate()


if __name__ == "__main__":
    unittest.main()
