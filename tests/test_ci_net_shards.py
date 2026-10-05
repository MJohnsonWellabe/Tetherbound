"""tools/ci/net_shards.py: the verify-multiplayer-shard plan.

    python3 tests/test_ci_net_shards.py
"""
import os
import re
import sys
import unittest

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "ci"))
import net_shards as N  # noqa: E402

CI = open(os.path.join(ROOT, ".github", "workflows", "ci.yml"), encoding="utf-8").read()


def files(*names):
    return ["tests/smoke_net_%s.gd" % n for n in names]


class Cover(unittest.TestCase):
    def test_a_smoke_assigned_twice_fails(self):
        f = files("a", "b")
        with self.assertRaisesRegex(N.PlanError, "assigned twice"):
            N.check_cover(f, [[f[0]], [f[0], f[1]]])

    def test_an_unassigned_smoke_fails(self):
        f = files("a", "b")
        with self.assertRaisesRegex(N.PlanError, "unassigned .*smoke_net_b"):
            N.check_cover(f, [[f[0]], []])

    def test_an_undiscovered_smoke_in_a_shard_fails(self):
        with self.assertRaisesRegex(N.PlanError, "not discovered .*smoke_net_z"):
            N.check_cover(files("a"), [files("a"), files("z")])

    def test_unmeasured_smokes_are_planned_as_the_slowest(self):
        shards = N.plan(files("never_measured", "fly"), shard_count=2, isolated=())
        self.assertEqual(sorted(load for _, load in shards), [N.MEASURED_SECONDS["fly"], N.UNMEASURED_SECONDS])


class RealRepository(unittest.TestCase):
    def setUp(self):
        self.files, _ = N.discover()

    def test_roster_and_floor_hold(self):
        N.check_roster(self.files)

    def test_every_discovered_smoke_runs_in_exactly_one_shard(self):
        shards = N.plan(self.files)
        assigned = [p for group, _ in shards for p in group]
        self.assertEqual(sorted(assigned), sorted(self.files))
        self.assertEqual(len(assigned), len(set(assigned)))

    def test_every_discovered_smoke_is_measured_and_every_shard_fits_the_budget(self):
        self.assertEqual([p for p in self.files if N.smoke_name(p) not in N.MEASURED_SECONDS], [])
        self.assertLessEqual(max(load for _, load in N.plan(self.files)), N.BIN_SMOKE_BUDGET_SECONDS)

    def test_job_lanes_cover_every_bin_exactly_once(self):
        bins = N.plan(self.files)
        self.assertEqual(N.BIN_COUNT, N.SHARD_COUNT * N.LANES)
        lanes = [id(b) for job in range(1, N.SHARD_COUNT + 1) for b in N.job_lanes(bins, job)]
        self.assertEqual(sorted(lanes), sorted(id(b) for b in bins))
        self.assertEqual(len(lanes), len(set(lanes)))

    def test_lane_output_names_every_smoke_of_the_job(self):
        out = os.path.join(os.environ.get("TMPDIR", "/tmp"), "net_shards_test_output")
        bins = N.plan(self.files)
        seen = []
        for job in range(1, N.SHARD_COUNT + 1):
            open(out, "w").close()
            os.environ["GITHUB_OUTPUT"] = out
            try:
                self.assertEqual(N.main(["--shard", str(job)]), 0)
            finally:
                del os.environ["GITHUB_OUTPUT"]
            kv = dict(line.rstrip("\n").split("=", 1) for line in open(out))
            seen += kv["files_a"].split() + kv["files_b"].split()
        os.remove(out)
        self.assertEqual(sorted(seen), sorted(self.files))

    def test_isolated_smokes_run_alone(self):
        shards = N.plan(self.files)
        for name in N.ISOLATED:
            group = next(g for g, _ in shards if any(N.smoke_name(p) == name for p in g))
            self.assertEqual([N.smoke_name(p) for p in group], [name])

    def test_ci_matrix_matches_shard_count(self):
        block = CI[CI.index("  verify-multiplayer-shard:\n"):]
        matrix = re.search(r"shard: \[([0-9, ]+)\]", block).group(1)
        self.assertEqual([int(x) for x in matrix.split(",")], list(range(1, N.SHARD_COUNT + 1)))

    def test_shards_do_not_wait_for_discovery(self):
        block = CI[CI.index("  verify-multiplayer-shard:\n"):CI.index("  verify-solo-regression:\n")]
        header = [l for l in block.split("    steps:")[0].splitlines() if not l.strip().startswith("#")]
        self.assertIn("    needs: changes", header)
        self.assertNotIn("discover-net-smokes", "\n".join(header))


if __name__ == "__main__":
    unittest.main()
