"""Hermetic tests for tools/setup_steam_runtime.py's archive cache.

    python3 -m unittest tools/test_setup_steam_runtime.py

No network: the downloader is replaced by a counting stub that copies a tiny
local archive.
"""
import hashlib
import importlib.util
import shutil
import tarfile
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("setup_steam_runtime", HERE / "setup_steam_runtime.py")
runtime = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(runtime)


class ArchiveCacheTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="steam-cache-test-"))
        src = self.tmp / "src"
        src.mkdir()
        (src / "payload").write_text("payload")
        self.archive = self.tmp / "archive.tar.xz"
        with tarfile.open(self.archive, "w:xz") as package:
            package.add(src / "payload", arcname="payload")
        self.pin = hashlib.sha256(self.archive.read_bytes()).hexdigest()
        self.cache = self.tmp / "cache"
        self.downloads = 0
        self._real = runtime.urllib.request.urlretrieve

        def fake(_url, destination):
            self.downloads += 1
            shutil.copyfile(self.archive, destination)

        runtime.urllib.request.urlretrieve = fake

    def tearDown(self):
        runtime.urllib.request.urlretrieve = self._real
        shutil.rmtree(self.tmp, ignore_errors=True)

    def fetch(self, cache_dir=None, pin=None):
        with tempfile.TemporaryDirectory(dir=self.tmp) as staging:
            path = runtime._download("stub://archive", pin or self.pin, staging,
                                     self.cache if cache_dir is None else cache_dir)
            inside = Path(staging) in path.parents
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
        return inside, digest

    def entry(self):
        return self.cache / f"{self.pin}.tar.xz"

    def test_download_is_verified_then_cached_and_a_hit_needs_no_download(self):
        self.assertEqual(self.fetch(), (True, self.pin))
        self.assertEqual(self.downloads, 1)
        self.assertTrue(self.entry().is_file())
        self.assertEqual(self.fetch(), (True, self.pin), "a hit returns a verified staging copy")
        self.assertEqual(self.downloads, 1, "a cache hit makes no download")

    def test_corrupt_entry_is_discarded_and_repaired(self):
        self.entry().parent.mkdir(parents=True)
        self.entry().write_bytes(b"corrupt")
        self.assertEqual(self.fetch(), (True, self.pin))
        self.assertEqual(self.downloads, 1)
        self.assertEqual(hashlib.sha256(self.entry().read_bytes()).hexdigest(), self.pin)

    def test_symlinked_entry_is_never_read(self):
        decoy = self.tmp / "decoy.tar.xz"
        decoy.write_bytes(b"not the archive")
        self.entry().parent.mkdir(parents=True)
        self.entry().symlink_to(decoy)
        self.assertEqual(self.fetch(), (True, self.pin))
        self.assertEqual(self.downloads, 1, "the symlink is ignored and the archive fetched")
        self.assertEqual(decoy.read_bytes(), b"not the archive", "the link target is never written")

    def test_unwritable_cache_does_not_fail_the_install(self):
        blocker = self.tmp / "not-a-directory"
        blocker.write_text("x")
        self.assertEqual(self.fetch(cache_dir=blocker / "cache"), (True, self.pin))
        self.assertEqual(list(self.tmp.glob("**/*.part")), [], "no partial cache file is left")

    def test_bad_pin_installs_and_caches_nothing(self):
        bad = "0" * 64
        with self.assertRaises(SystemExit):
            self.fetch(pin=bad)
        self.assertFalse((self.cache / f"{bad}.tar.xz").exists())

    def test_no_cache_always_downloads(self):
        self.fetch(cache_dir="")
        self.fetch(cache_dir="")
        self.assertEqual(self.downloads, 2)
        self.assertFalse(self.cache.exists())


if __name__ == "__main__":
    unittest.main()
