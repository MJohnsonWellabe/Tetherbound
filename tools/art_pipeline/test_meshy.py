import importlib.util
import argparse
import json
import pathlib
import tempfile
import unittest
from unittest.mock import patch


MODULE_PATH = pathlib.Path(__file__).with_name("meshy.py")
SPEC = importlib.util.spec_from_file_location("tetherbound_meshy", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
meshy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(meshy)


class ExplicitReferenceImageTests(unittest.TestCase):
    def test_stormursa_submission_keeps_reference_and_pinned_options(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            source = root / "stormursa.png"
            source.write_bytes(b"inspected reference fixture")
            calls = []

            def request(method, endpoint, body=None):
                calls.append((method, endpoint, body))
                return {"balance": 100} if method == "GET" else {"result": "mock-only-stormursa"}

            args = argparse.Namespace(species="stormursa", image=str(source), candidates=1,
                                      tier="refine", polycount=30000, budget=30, yes=False,
                                      ai_model="meshy-7.1", enable_pbr=True, preserve_reference=True)
            with patch.object(meshy, "request", request), patch.object(meshy, "RAW_ROOT", root / "raw"):
                meshy.cmd_generate(args)
            submissions = [call for call in calls if call[0] == "POST"]
            self.assertEqual(len(submissions), 1)
            self.assertEqual(submissions[0][1], "/openapi/v1/multi-image-to-3d")
            payload = submissions[0][2]
            self.assertEqual(payload["ai_model"], "meshy-7.1")
            self.assertTrue(payload["enable_pbr"])
            self.assertFalse(payload["image_enhancement"])
            self.assertTrue(payload["should_texture"])
            self.assertEqual(payload["image_urls"], [meshy.data_uri(source)])
            manifest = json.loads((root / "raw/stormursa/manifest.json").read_text())
            self.assertEqual(manifest["generation_options"]["ai_model"], "meshy-7.1")
            self.assertFalse(manifest["generation_options"]["image_enhancement"])
            self.assertEqual(manifest["tasks"][0]["task_id"], "mock-only-stormursa")

    def test_explicit_png_replaces_the_authored_view_set(self):
        with tempfile.TemporaryDirectory() as directory:
            source = pathlib.Path(directory) / "winner.png"
            source.write_bytes(b"not decoded by the resolver")
            self.assertEqual(meshy.generation_views("galecrest", str(source)),
                             {"source": source.resolve()})

    def test_missing_explicit_image_is_refused(self):
        with self.assertRaises(SystemExit):
            meshy.generation_views("galecrest", "missing-pilot-image.png")

    def test_non_png_explicit_image_is_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            source = pathlib.Path(directory) / "winner.jpg"
            source.write_bytes(b"jpeg")
            with self.assertRaises(SystemExit):
                meshy.generation_views("galecrest", str(source))

    def test_skyrill_replacement_prompt_guards_against_old_winged_body(self):
        prompt = meshy.prompt_for("skyrill")
        negative = meshy.negative_for("skyrill")
        self.assertIn("ONE CONTINUOUS ORANGE-AND-BLUE DORSAL SAIL", prompt)
        self.assertIn("LARGE READABLE AMBER EYE", prompt)
        self.assertIn("winged dragon", negative)
        self.assertIn("fused legs", negative)
        self.assertNotIn("winged dragon", meshy.negative_for("ribbonray"))


if __name__ == "__main__":
    unittest.main()
