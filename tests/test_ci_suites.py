"""tools/ci/run_suite.py: the verify-suite plan and group files.

    python3 tests/test_ci_suites.py
"""
import os
import re
import sys
import tempfile
import unittest

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "ci"))
import run_suite as R  # noqa: E402
import select_jobs as S  # noqa: E402

CI = open(os.path.join(ROOT, ".github", "workflows", "ci.yml"), encoding="utf-8").read()


class RealRepository(unittest.TestCase):
    def setUp(self):
        self.groups = R.load()

    def test_every_group_is_planned_exactly_once(self):
        bins, _ = R.plan(self.groups)
        self.assertEqual(len(bins), R.SUITE_COUNT * R.LANES)
        labels = [g.label for lane in bins for g in lane]
        self.assertEqual(sorted(labels), sorted(g.label for g in self.groups))
        owned = [lane for n in range(1, R.SUITE_COUNT + 1) for lane in R.suite_lanes(bins, n)]
        self.assertEqual(owned, bins)

    def test_every_group_has_steps_and_no_unresolved_expression(self):
        for g in self.groups:
            self.assertTrue(g.steps, g.file)
            for step in g.steps:
                self.assertNotIn("${{", "\n".join(step["body"]), (g.file, step["name"]))

    def test_full_tier_with_everything_runs_every_suite(self):
        self.assertEqual(R.suites_with_work(self.groups, "|ALL|", "full"), list(range(1, R.SUITE_COUNT + 1)))

    def test_fast_tier_runs_only_the_unit_shards(self):
        fast = sorted(g.label for g in self.groups if R.selected(g, "|x|", "fast"))
        self.assertEqual(fast, ["verify-unit-tests (1)", "verify-unit-tests (2)", "verify-unit-tests (3)"])
        self.assertEqual(R.suites_with_work(self.groups, "|ALL|", "none"), [])

    def test_selection_is_per_former_job(self):
        self.assertTrue(R.selected(next(g for g in self.groups if g.job == "verify-combat-shard"),
                                   "|verify-combat-shard|", "full"))
        self.assertFalse(R.selected(next(g for g in self.groups if g.job == "verify-catching"),
                                    "|verify-combat-shard|", "full"))

    def test_selector_reads_groups_as_their_former_jobs(self):
        jobs = S.ci_jobs(CI)
        for g in self.groups:
            self.assertIn(g.job, jobs)
        self.assertIn("SMOKE: combat", jobs["verify-combat-shard"])

    def test_ci_matrix_comes_from_the_changes_plan(self):
        block = CI[CI.index("  verify-suite:\n"):]
        self.assertIn("suite: ${{ fromJSON(needs.changes.outputs.suites", block)
        self.assertIn("tools/ci/run_suite.py --suite", block)
        self.assertIn("run_suite.py --list", CI)
        gate = CI[CI.index("  ci-gate:\n"):]
        self.assertIn("      - verify-suite\n", gate)


class Parsing(unittest.TestCase):
    def test_header_and_steps(self):
        with tempfile.TemporaryDirectory() as d:
            with open(os.path.join(d, "x.steps"), "w") as f:
                f.write("# c\n### job: verify-x\n### group: a\n### seconds: 5\n### tier: fast\n"
                        "### job-timeout-minutes: 3\n\n### step: One\n### env SMOKE: one\n"
                        "### timeout-minutes: 2\necho one\n### step: Two\n### nightly\necho two\n")
            (g,) = R.load(d)
            self.assertEqual((g.job, g.group, g.seconds, g.tier, g.job_timeout), ("verify-x", "a", 5, "fast", 3))
            self.assertEqual(g.steps[0]["env"], {"SMOKE": "one"})
            self.assertEqual(g.steps[0]["timeout"], 2)
            self.assertTrue(g.steps[1]["nightly"])
            self.assertEqual(g.steps[1]["body"], ["echo two"])

    def test_a_failing_step_fails_the_lane_and_later_steps_still_run(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "x.steps")
            with open(path, "w") as f:
                f.write("### job: verify-x\n### seconds: 1\n### step: Bad\nexit 3\n"
                        "### step: Good\n### env V: ok\necho \"$V\" > \"$RUNNER_TEMP/seen\"\n")
            lane = os.path.join(d, "lane")
            import io
            import contextlib
            buf = io.StringIO()
            with contextlib.redirect_stdout(buf):
                status = R.run_lane([path], lane, False)
            self.assertEqual(status, 1)
            self.assertEqual(open(os.path.join(lane, "runner-temp", "seen")).read().strip(), "ok")
            self.assertTrue(re.search(r"^STEP\tverify-x\tBad\t3\t", buf.getvalue(), re.M))


if __name__ == "__main__":
    unittest.main()
