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
        shards = N.plan(files("never_measured", "fly"), shard_count=2, isolated=(), lanes_per_shard=1,
                        exclusive=())
        self.assertEqual(sorted(load for _, load in shards), [N.MEASURED_SECONDS["fly"], N.UNMEASURED_SECONDS])


class RealRepository(unittest.TestCase):
    def setUp(self):
        self.files, _ = N.discover()

    def test_roster_and_floor_hold(self):
        N.check_roster(self.files)

    def test_every_discovered_smoke_runs_in_exactly_one_shard(self):
        shards = N.plan(self.files)
        assigned = [p for group, _ in shards for p in group] + \
            [p for group in N.solo_plan(self.files).values() for p in group]
        self.assertEqual(sorted(assigned), sorted(self.files))
        self.assertEqual(len(assigned), len(set(assigned)))

    def test_every_discovered_smoke_is_measured_and_every_shard_fits_the_budget(self):
        self.assertEqual([p for p in self.files if N.smoke_name(p) not in N.MEASURED_SECONDS], [])
        # The budget is the PR gate's (test_gate_plan_fits_the_budget); the
        # 8-hourly tier also runs NIGHTLY_ONLY and has no wall-time target.
        self.assertLessEqual(max(load for _, load in N.plan(N.gate_files(self.files))), N.SHARD_SMOKE_BUDGET_SECONDS)

    def test_isolated_smokes_run_alone(self):
        shards = N.plan(self.files)
        for name in N.ISOLATED:
            group = next(g for g, _ in shards if any(N.smoke_name(p) == name for p in g))
            self.assertEqual([N.smoke_name(p) for p in group], [name])

    def test_nightly_only_smokes_are_discovered_and_kept_off_the_gate(self):
        names = {N.smoke_name(p) for p in self.files}
        self.assertLessEqual(set(N.NIGHTLY_ONLY), names)
        gate = {N.smoke_name(p) for p in N.gate_files(self.files)}
        self.assertFalse(gate & set(N.NIGHTLY_ONLY))
        # The owner's keep list (2026-10-07) never moves off the PR gate.
        for keep in ("shared_boss", "boss_rewards_each_participant", "catch_race", "reconnect_keeps_character",
                     "host_exit_saves", "split_realms", "client_trainer_rewards", "late_join_modified_world"):
            self.assertIn(keep, gate)

    def test_gate_plan_fits_the_budget(self):
        self.assertLessEqual(max(load for _, load in N.plan(N.gate_files(self.files))),
                             N.SHARD_SMOKE_BUDGET_SECONDS)

    def test_exclusive_smokes_run_alone_once(self):
        solo = N.solo_plan(self.files)
        alone = [p for group in solo.values() for p in group]
        self.assertEqual(sorted(N.smoke_name(p) for p in alone), sorted(N.EXCLUSIVE))
        on_lanes = [p for group, _ in N.plan(self.files) for p in group]
        self.assertFalse(set(alone) & set(on_lanes))

    def test_each_shard_owns_its_own_lanes(self):
        lanes = N.plan(self.files)
        self.assertEqual(len(lanes), N.SHARD_COUNT * N.LANES_PER_SHARD)
        owned = [lane for s in range(1, N.SHARD_COUNT + 1) for lane in N.shard_lanes(lanes, s)]
        self.assertEqual(owned, lanes)

    def test_ci_runs_each_shards_lanes_together(self):
        block = CI[CI.index("  verify-multiplayer-shard:\n"):CI.index("  export:\n")]
        self.assertIn("steps.select.outputs.lanes", block)
        self.assertIn("tools/ci/run_net_lanes.sh", block)

    def test_ci_matrix_matches_shard_count(self):
        block = CI[CI.index("  verify-multiplayer-shard:\n"):]
        matrix = re.search(r"shard: \[([0-9, ]+)\]", block).group(1)
        self.assertEqual([int(x) for x in matrix.split(",")], list(range(1, N.SHARD_COUNT + 1)))

    def test_shards_do_not_wait_for_discovery(self):
        block = CI[CI.index("  verify-multiplayer-shard:\n"):CI.index("  export:\n")]
        header = [l for l in block.split("    steps:")[0].splitlines() if not l.strip().startswith("#")]
        self.assertIn("    needs: changes", header)
        self.assertNotIn("discover-net-smokes", "\n".join(header))


if __name__ == "__main__":
    unittest.main()
