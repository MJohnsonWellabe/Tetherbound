#!/usr/bin/env python3
"""tools/ci/assets_cache.py against a real blobless sparse clone of a small
synthetic repository: a warm cache restores with no git fetch, a missing chunk
falls back to git, and a stale, malformed or tampered cache never survives
verification. Run in ci.yml's `changes` job: python3 tests/test_ci_assets_cache.py
"""
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, "tools", "ci", "assets_cache.py")
sys.path.insert(0, os.path.join(ROOT, "tools", "ci"))
import assets_cache as A  # noqa: E402

ENV = dict(os.environ, GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@t", GIT_COMMITTER_NAME="t",
           GIT_COMMITTER_EMAIL="t@t", GITHUB_OUTPUT="")


def run(cwd, *cmd, check=True):
    return subprocess.run(cmd, cwd=cwd, env=ENV, check=check, capture_output=True, text=True)


class AssetsCache(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="assets-cache-")
        origin = os.path.join(cls.tmp, "origin")
        os.makedirs(origin)
        run(origin, "git", "init", "-q")
        n = 0
        for d in ("creatures/tetherbound/a", "creatures/tetherbound/b", "creatures/tetherbound/c",
                  "props/meshy-1/x", "props/meshy-1/y", "ui"):
            os.makedirs(os.path.join(origin, "assets", d))
            for f in ("m.glb", "m.glb.import", "t.png"):
                n += 1
                with open(os.path.join(origin, "assets", d, f), "wb") as fh:
                    fh.write(os.urandom(3000) + str(n).encode())
        os.makedirs(os.path.join(origin, "tools", "ci"))
        shutil.copy(SCRIPT, os.path.join(origin, "tools", "ci"))
        run(origin, "git", "add", "-A")
        run(origin, "git", "commit", "-qm", "init")
        run(origin, "git", "config", "uploadpack.allowFilter", "true")
        run(origin, "git", "config", "uploadpack.allowAnySHA1InWant", "true")
        cls.origin = origin
        cls.count = 0

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def clone(self):
        AssetsCache.count += 1
        w = os.path.join(self.tmp, "w%d" % self.count)
        run(self.tmp, "git", "clone", "-q", "--no-local", "--filter=blob:none", "--no-checkout",
            "file://" + self.origin, w)
        run(w, "git", "sparse-checkout", "set", "--no-cone", "/*", "!/assets/")
        run(w, "git", "checkout", "-q")
        self.assertFalse(os.path.exists(os.path.join(w, "assets")))
        return w

    def cache(self, hit=""):
        w = self.clone()
        c = os.path.join(self.tmp, "cache%d" % self.count)
        run(w, sys.executable, SCRIPT, "materialize", "--cache-dir", c, "--hit", hit)
        self.assertFalse(run(w, "git", "ls-files", "-o", "assets").stdout.strip())
        return c

    def restore(self, c, check=True):
        w = self.clone()
        packs = len(os.listdir(os.path.join(w, ".git", "objects", "pack")))
        res = run(w, sys.executable, SCRIPT, "restore", "--cache-dir", c, check=check)
        fetched = len(os.listdir(os.path.join(w, ".git", "objects", "pack"))) != packs
        return w, res, fetched

    def assert_like_full_checkout(self, w):
        self.assertEqual(run(w, "git", "status", "--porcelain").stdout, "")
        flags = {l[:1] for l in run(w, "git", "ls-files", "-t", "assets").stdout.splitlines()}
        self.assertEqual(flags, {"H"}, "assets/ must be ordinary checked-out paths")
        listed = run(w, "git", "ls-files", "assets").stdout.split()
        on_disk = [os.path.relpath(os.path.join(r, f), w)
                   for r, _d, fs in os.walk(os.path.join(w, "assets")) for f in fs]
        self.assertEqual(sorted(listed), sorted(on_disk))
        # every byte equals git's blob, hashed independently of the script
        for line in run(w, "git", "ls-files", "-s", "assets").stdout.splitlines():
            meta, path = line.split("\t", 1)
            oid = meta.split()[1]
            self.assertEqual(run(w, "git", "hash-object", path).stdout.strip(), oid, path)

    def test_plan_is_stable_and_covers_every_file_once(self):
        w = self.clone()
        os.chdir(w)
        try:
            rows = A.listing()
            p = A.plan(rows)
            self.assertEqual(sorted(r for i in p for r in p[i][1]), sorted(rows))
            self.assertEqual(len(p), A.CHUNKS)
            self.assertEqual(p, A.plan(list(reversed(rows))))
            # one folder's files share a chunk
            self.assertEqual(len({A.chunk_of(r[2]) for r in rows if "/tetherbound/a/" in r[2]}), 1)
        finally:
            os.chdir(ROOT)

    def test_warm_cache_restores_without_any_git_fetch(self):
        w, res, fetched = self.restore(self.cache())
        self.assertIn("0 chunk(s) from git", res.stdout)
        self.assertFalse(fetched, "a warm restore must not touch the git server")
        self.assert_like_full_checkout(w)

    def test_missing_chunk_falls_back_to_git(self):
        c = self.cache()
        victim = next(i for i in range(A.CHUNKS) if os.path.getsize(A.tar_path(c, i)) > 10240)
        os.remove(A.tar_path(c, victim))
        w, res, fetched = self.restore(c)
        self.assertIn("missed chunk(s) %d" % victim, res.stdout)
        self.assertTrue(fetched)
        self.assert_like_full_checkout(w)

    def test_malformed_tar_is_ignored_and_fetched(self):
        c = self.cache()
        victim = next(i for i in range(A.CHUNKS) if os.path.getsize(A.tar_path(c, i)) > 10240)
        with tarfile.open(A.tar_path(c, victim), "a") as tf:
            extra = os.path.join(self.tmp, "extra.txt")
            with open(extra, "w") as fh:
                fh.write("x")
            tf.add(extra, arcname="assets/extra.txt")
        w, res, _f = self.restore(c)
        self.assertIn("does not list exactly its files", res.stdout)
        self.assertFalse(os.path.exists(os.path.join(w, "assets", "extra.txt")))
        self.assert_like_full_checkout(w)

    def test_tampered_bytes_are_detected_and_rewritten_from_git(self):
        c = self.cache()
        victim = next(i for i in range(A.CHUNKS) if os.path.getsize(A.tar_path(c, i)) > 10240)
        x = os.path.join(self.tmp, "x%d" % self.count)
        os.makedirs(x)
        with tarfile.open(A.tar_path(c, victim)) as tf:
            names = tf.getnames()
            tf.extractall(x)
        with open(os.path.join(x, names[0]), "ab") as fh:
            fh.write(b"stale")
        with tarfile.open(A.tar_path(c, victim), "w") as tf:
            for n in names:
                tf.add(os.path.join(x, n), arcname=n)
        w, res, _f = self.restore(c)
        self.assertIn("did not match git", res.stdout)
        self.assertIn(names[0], res.stdout)
        self.assert_like_full_checkout(w)

    def test_prep_skips_chunks_the_cache_holds(self):
        c = self.cache(hit="0,1,2")
        for i in range(A.CHUNKS):
            self.assertEqual(os.path.exists(A.tar_path(c, i)), i > 2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
