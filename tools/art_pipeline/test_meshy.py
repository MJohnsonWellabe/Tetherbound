import importlib.util
import pathlib
import tempfile
import unittest


MODULE_PATH = pathlib.Path(__file__).with_name("meshy.py")
SPEC = importlib.util.spec_from_file_location("tetherbound_meshy", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
meshy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(meshy)


class ExplicitReferenceImageTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
