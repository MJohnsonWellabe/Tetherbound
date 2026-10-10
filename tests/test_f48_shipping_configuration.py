"""Engine-free config integrity only; no gameplay or READY evidence."""
from pathlib import Path
import hashlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools/net"))
import f48_configuration as configuration


class ShippingConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="f48-shipping-integrity-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        pins = []
        for name in sorted(configuration.FILES):
            path = self.root / "data/config" / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b'{"runtime_enabled":false}\n')
            pins.append({"file": "res://data/config/" + name,
                         "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
        self.profile = {"production_configuration_pins": pins,
                        "test_configuration": [row.copy() for row in pins if not row["file"].endswith("/combat.json")]}

    def test_native_shipping_context_preserves_off_flags_without_overlay_write(self):
        before = {path: path.read_bytes() for path in (self.root / "data/config").iterdir()}
        with configuration.shipping_configuration(self.root, self.profile) as pins:
            self.assertEqual(len(pins), 7)
            self.assertEqual({path: path.read_bytes() for path in before}, before)
        self.assertEqual({path: path.read_bytes() for path in before}, before)
        self.assertFalse((self.root / ".tmp/f48-native-overlay.lock").exists())

    def test_current_or_midrun_combat_flag_change_refuses(self):
        path = self.root / "data/config/combat.json"
        original = path.read_bytes()
        path.write_bytes(b'{"runtime_enabled":true}\n')
        with self.assertRaisesRegex(ValueError, "differs from original"):
            with configuration.shipping_configuration(self.root, self.profile):
                self.fail("Changed combat bytes admitted native run")
        path.write_bytes(original)
        with self.assertRaisesRegex(ValueError, "changed during"):
            with configuration.shipping_configuration(self.root, self.profile):
                path.write_bytes(b'{"runtime_enabled":true}\n')

    def test_duplicate_or_mismatched_guard_pin_refuses(self):
        last = self.profile["production_configuration_pins"][-1].copy()
        self.profile["production_configuration_pins"][-1] = self.profile["production_configuration_pins"][0].copy()
        with self.assertRaisesRegex(ValueError, "duplicate"):
            configuration.shipping_pins(self.profile)
        self.profile["production_configuration_pins"][-1] = last
        self.profile["test_configuration"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "native guard pins differ"):
            configuration.shipping_pins(self.profile)


if __name__ == "__main__":
    unittest.main()
