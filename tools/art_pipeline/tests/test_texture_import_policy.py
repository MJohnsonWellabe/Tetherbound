import pathlib
import tempfile
import unittest

import sys


HERE = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))

import texture_import_policy as policy  # noqa: E402


SIDECAR_LOSSLESS = '''[remap]

importer="texture"
type="CompressedTexture2D"
path="res://.godot/imported/albedo.ctex"
metadata={{
"vram_texture": false
}}

[params]

compress/mode=0
detect_3d/compress_to=1
'''

SIDECAR_VRAM = '''[remap]

importer="texture"
type="CompressedTexture2D"
path.s3tc="res://.godot/imported/albedo.s3tc.ctex"
metadata={{
"imported_formats": ["s3tc_bptc"],
"vram_texture": true
}}

[params]

compress/mode=2
detect_3d/compress_to=0
'''


class TextureImportPolicyTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.temporary.name)

    def tearDown(self):
        self.temporary.cleanup()

    def write_sidecar(self, relative: str, mode: int = 0) -> pathlib.Path:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        contents = SIDECAR_VRAM if mode == 2 else SIDECAR_LOSSLESS
        path.write_text(contents, encoding="utf-8")
        return path

    def test_only_shipped_3d_textures_are_selected(self):
        creature = self.write_sidecar("assets/creatures/tetherbound/test/models/albedo.png.import")
        character = self.write_sidecar("assets/characters/test/body.png.import")
        ui = self.write_sidecar("assets/ui/portraits/test.png.import")
        reference = self.write_sidecar("assets/creatures/tetherbound/test/reference/front.png.import")
        generator_input = self.write_sidecar(
            "assets/creatures/tetherbound/test/models/test_extracted_base_color.png.import"
        )

        selected = policy.sidecars([self.root / "assets"], self.root)

        self.assertEqual(selected, sorted([character, creature]))
        self.assertNotIn(ui, selected)
        self.assertNotIn(reference, selected)
        self.assertNotIn(generator_input, selected)

    def test_apply_is_narrow_and_idempotent(self):
        runtime = self.write_sidecar("assets/environment/test/albedo.png.import")
        ui = self.write_sidecar("assets/ui/icons/test.png.import")

        self.assertEqual(policy.apply_policy([self.root / "assets"], self.root), [runtime])
        self.assertEqual(policy.mode(runtime), 2)
        self.assertIn("detect_3d/compress_to=0", runtime.read_text(encoding="utf-8"))
        self.assertFalse(policy.is_reimported_for_vram(runtime))
        self.assertEqual(policy.mode(ui), 0)
        self.assertEqual(policy.apply_policy([self.root / "assets"], self.root), [])
        self.assertTrue(runtime.read_bytes().endswith(b"\n"))

    def test_check_reports_only_non_vram_runtime_imports(self):
        broken = self.write_sidecar("assets/props/test/albedo.png.import")
        self.write_sidecar("assets/buildings/test/albedo.png.import", mode=2)
        self.write_sidecar("assets/ui/test.png.import")

        self.assertEqual(policy.violations([self.root / "assets"], self.root), [broken])

    def test_check_rejects_mode_two_until_generated_fields_are_reimported(self):
        stale = self.write_sidecar("assets/characters/test/albedo.png.import")
        stale.write_text(stale.read_text(encoding="utf-8").replace("compress/mode=0", "compress/mode=2"))

        self.assertEqual(policy.mode(stale), 2)
        self.assertFalse(policy.is_reimported_for_vram(stale))
        self.assertEqual(policy.violations([self.root / "assets"], self.root), [stale])

    def test_apply_rejects_an_incomplete_import_sidecar(self):
        malformed = self.write_sidecar("assets/characters/test/albedo.png.import")
        malformed.write_text(
            malformed.read_text(encoding="utf-8").replace("detect_3d/compress_to=1\n", ""),
            encoding="utf-8",
        )

        with self.assertRaisesRegex(ValueError, "detect_3d/compress_to"):
            policy.apply_policy([self.root / "assets"], self.root)


if __name__ == "__main__":
    unittest.main()
