"""tools/ci/packed.py: the packed solo suites (.github/ci/suites.yml).

    python3 tests/test_ci_packed.py
"""
import os
import re
import sys
import tempfile
import unittest

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "ci"))
import packed as P  # noqa: E402

CI = open(os.path.join(ROOT, ".github", "workflows", "ci.yml"), encoding="utf-8").read()
EVERYTHING = {"CI_CODE": "true", "CI_FULL": "true", "CI_NET": "true", "CI_JOBS": "|ALL|", "CI_EVENT": "workflow_dispatch"}
SEL = P.selection_ctx(EVERYTHING)


class Expressions(unittest.TestCase):
    def test_the_subset_the_suites_use(self):
        ctx = dict(SEL, **{"matrix.group": "bracket-final"})
        self.assertTrue(P.evaluate("${{ startsWith(matrix.group, 'bracket-') && (!cancelled()) }}", ctx))
        self.assertFalse(P.evaluate("${{ matrix.group == 'world' && (!cancelled()) }}", ctx))
        self.assertTrue(P.evaluate("needs.changes.outputs.full == 'true' && (contains(needs.changes.outputs.jobs, "
                                   "'|ALL|') || contains(needs.changes.outputs.jobs, '|x|'))", ctx))
        ctx2 = P.selection_ctx(dict(EVERYTHING, CI_JOBS="|verify-harvest|"))
        self.assertFalse(P.evaluate("contains(needs.changes.outputs.jobs, '|verify-catching|')", ctx2))
        self.assertTrue(P.evaluate("needs.changes.outputs.full == 'true' && (github.event_name == 'schedule' || "
                                   "github.event_name == 'workflow_dispatch')", SEL))

    def test_anything_else_fails_closed(self):
        with self.assertRaises(P.PackError):
            P.evaluate("env.SOMETHING != ''", SEL)
        with self.assertRaises(P.PackError):
            P.evaluate("hashFiles('x') != ''", SEL)


def suites_of(**steps_by_job):
    return {job: {"steps": steps} for job, steps in steps_by_job.items()}


class Units(unittest.TestCase):
    def test_independent_steps_are_units_and_dependent_steps_join_their_prefix(self):
        s = suites_of(j=[{"name": "a", "run": "true", "if": "${{ !cancelled() }}"},
                         {"name": "b", "run": "true", "if": "${{ !cancelled() }}"},
                         {"name": "c", "run": "true"},
                         {"name": "d", "run": "true", "if": "${{ !cancelled() }}"}])
        units = P.units_of(s, SEL)
        self.assertEqual([[st["name"] for st in u["steps"]] for u in units], [["a", "b", "c"], ["d"]])

    def test_a_uses_step_other_than_setup_cannot_be_packed(self):
        s = suites_of(j=[{"uses": "actions/upload-artifact@v4"}])
        with self.assertRaisesRegex(P.PackError, "only run: steps"):
            P.units_of(s, SEL)


class Cover(unittest.TestCase):
    def setUp(self):
        self.units = P.units_of(suites_of(j=[{"name": "a", "run": "true", "if": "${{ !cancelled() }}"},
                                             {"name": "b", "run": "true", "if": "${{ !cancelled() }}"}]), SEL)

    def test_a_unit_planned_twice_fails(self):
        with self.assertRaisesRegex(P.PackError, "units twice"):
            P.check_cover(self.units, [[self.units[0]], [self.units[0], self.units[1]]])

    def test_an_unplanned_unit_fails(self):
        with self.assertRaisesRegex(P.PackError, "units unassigned .*j #2"):
            P.check_cover(self.units, [[self.units[0]], []])

    def test_a_step_in_two_units_fails(self):
        dup = dict(self.units[1], steps=self.units[1]["steps"] + self.units[0]["steps"])
        with self.assertRaisesRegex(P.PackError, "steps twice"):
            P.check_cover([self.units[0], dup], [[self.units[0]], [dup]])


class Lane(unittest.TestCase):
    """The deliberate-failure drill, without Godot: pass, fail, skip-after-fail,
    GITHUB_ENV within a unit, and user:// (XDG) never shared between units."""

    def test_verdicts_isolation_and_env(self):
        # A step without `if:` depended on every step before it in its job, so
        # each suite here is kept small enough to stay separate units.
        s = suites_of(
            failing=[{"name": "fails on purpose", "run": "exit 3"},
                     {"name": "after the failure", "run": "true"}],
            env=[{"name": "writes env", "run": 'echo "FOO=bar" >> "$GITHUB_ENV"; echo "$XDG_DATA_HOME" > "$RUNNER_TEMP/../../xdg-1"'},
                 {"name": "reads env", "run": 'test "$FOO" = bar'}],
            other=[{"name": "own user dir, no env", "if": "${{ !cancelled() }}",
                    "run": 'echo "$XDG_DATA_HOME" > "$RUNNER_TEMP/../../xdg-2"; test -z "${FOO:-}"'}])
        units = P.units_of(s, SEL)
        self.assertEqual(len(units), 3)
        with tempfile.TemporaryDirectory() as out:
            lane = P.Lane("a", units, out, dict(os.environ), live=False)
            lane.run()
            verdicts = [(st["name"], v) for u, st, v, _, _ in lane.results]
            self.assertEqual(verdicts, [("fails on purpose", "FAIL (exit 3)"),
                                        ("after the failure", "SKIPPED (after 'fails on purpose' failed)"),
                                        ("writes env", "PASS"), ("reads env", "PASS"),
                                        ("own user dir, no env", "PASS")])
            a = open(os.path.join(out, "lane-a", "xdg-1")).read()
            b = open(os.path.join(out, "lane-a", "xdg-2")).read()
            self.assertNotEqual(a, b)
            self.assertEqual(P.report([lane]), 1)


class ReviewFindings(unittest.TestCase):
    """Regression cases for the independent review of phase C."""

    def run_lane(self, suites, **kw):
        units = P.units_of(suites, SEL)
        out = tempfile.mkdtemp()
        lane = P.Lane("a", units, out, dict(os.environ), live=False)
        lane.run()
        return units, lane, [(st["name"], v) for _, st, v, _, _ in lane.results]

    def test_1_a_malformed_github_env_fails_its_step_and_the_lane_goes_on(self):
        _, lane, v = self.run_lane(suites_of(
            j=[{"name": "bad env", "run": 'echo "FOO<<EOF" >> "$GITHUB_ENV"'},
               {"name": "next", "if": "${{ !cancelled() }}", "run": "true"}],
            k=[{"name": "other suite", "run": "true"}]))
        self.assertTrue(v[0][1].startswith("FAIL (GITHUB_ENV: no closing"), v)
        self.assertEqual(v[1:], [("next", "PASS"), ("other suite", "PASS")])

    def test_1_a_lost_step_fails_the_job_by_name(self):
        units, lane, _ = self.run_lane(suites_of(j=[{"name": "ran", "run": "true"}]))
        ghost = dict(units[0], id="j #9", steps=[dict(units[0]["steps"][0], index=7, name="never ran")])
        self.assertEqual(P.report([lane], planned=[(units[0], units[0]["steps"][0]), (ghost, ghost["steps"][0])]), 1)

    def test_1_a_crash_inside_a_lane_names_every_remaining_step(self):
        units = P.units_of(suites_of(j=[{"name": "a", "run": "true"}, {"name": "b", "run": "true"}]), SEL)
        lane = P.Lane("a", units, "/proc/no-such-dir", dict(os.environ), live=False)
        lane.run()
        self.assertEqual([v.split(" ")[0] for _, _, v, _, _ in lane.results], ["ERROR", "ERROR"])

    def test_2_an_always_run_step_still_runs_after_a_failure_in_its_unit(self):
        # verify-harvest's shape: two !cancelled() steps, then one without `if:`.
        _, _, v = self.run_lane(suites_of(j=[
            {"name": "spend", "if": "${{ !cancelled() }}", "run": "exit 1"},
            {"name": "release", "if": "${{ !cancelled() }}", "run": "true"},
            {"name": "checks", "run": "true"}]))
        self.assertEqual([x[1].split(" ")[0] for x in v], ["FAIL", "PASS", "SKIPPED"])

    def test_3_no_runner_runs_two_hosting_units_at_once(self):
        suites = P.load_suites()
        for jobs in ("|ALL|", "|verify-gate-evidence-shard|verify-owner-regressions-shard|",
                     "|verify-gate-b-core|verify-cloudreach-persistence|verify-combat-shard|"):
            units = P.units_of(suites, P.selection_ctx(dict(EVERYTHING, CI_JOBS=jobs)))
            bins, _ = P.plan(units, P.load_durations())
            for r in range(P.RUNNERS):
                hosting_lanes = [i for i in (2 * r, 2 * r + 1) if any(u["hosts"] for u in bins[i])]
                self.assertLessEqual(len(hosting_lanes), 1, (jobs, r))
        # Found through helpers too (gate_a_opening_drive.gd drives the title screen).
        ids = {u["id"] for u in P.units_of(suites, SEL) if u["hosts"]}
        self.assertIn("verify-gate-evidence-shard #2", ids)
        self.assertIn("verify-owner-regressions-shard (controls) #1", ids)

    def test_3_a_bind_failure_fails_the_step(self):
        _, _, v = self.run_lane(suites_of(j=[
            {"name": "host", "run": 'echo "WARNING: Session.host: could not bind udp/27015 (err 1); staying offline-solo"'}]))
        self.assertTrue(v[0][1].startswith("FAIL (a udp port"), v)

    def test_4_the_suite_timeout_bounds_the_unit(self):
        s = {"j": {"timeout-minutes": 0.02, "steps": [{"name": "slow", "run": "sleep 5"}]}}
        _, _, v = self.run_lane(s)
        self.assertTrue(v[0][1].startswith("FAIL (timed out"), v)

    def test_6_substitution_and_operands(self):
        with self.assertRaises(P.PackError):
            P.substitute("${{ matrix.group == 'a' }}", {"matrix.group": "a"})
        self.assertEqual(P.substitute("x ${{ matrix.group }}", {"matrix.group": "a"}), "x a")
        self.assertEqual(P.evaluate("'a' && 'b' || 'c'", {}), "b")
        self.assertFalse(P.evaluate("'true' == true", {}))

    def test_7_unknown_suite_keys_are_refused(self):
        with self.assertRaisesRegex(P.PackError, "suite keys"):
            P.units_of({"j": {"env": {"A": "1"}, "steps": [{"name": "x", "run": "true"}]}}, SEL)


class RealSuites(unittest.TestCase):
    def setUp(self):
        self.suites = P.load_suites()

    def test_every_step_is_run_by_some_instance_and_nothing_is_unresolved(self):
        P.check_every_step_is_reachable(self.suites)
        for u in P.units_of(self.suites, SEL):
            for st in u["steps"]:
                self.assertNotIn("${{", st["run"] + st["name"] + "".join(st["env"].values()))

    def test_full_plan_is_an_exact_cover_and_every_step_is_measured(self):
        units = P.units_of(self.suites, SEL)
        durations = P.load_durations()
        P.plan(units, durations)
        self.assertEqual([P.step_key(u["instance"], s["name"]) for u in units for s in u["steps"]
                          if P.step_key(u["instance"], s["name"]) not in durations], [])

    def test_selection_is_each_suites_own_if(self):
        self.assertEqual(P.units_of(self.suites, P.selection_ctx(dict(EVERYTHING, CI_FULL="false"))), [])
        some = P.units_of(self.suites, P.selection_ctx(dict(EVERYTHING, CI_JOBS="|verify-harvest|")))
        self.assertEqual({u["job"] for u in some}, {"verify-harvest", "verify-segment-handoffs"})

    def test_packed_suites_are_not_also_ci_jobs(self):
        jobs = set(re.findall(r"^  ([a-z0-9][a-z0-9-]*):\s*$", CI.split("\njobs:\n", 1)[1], re.M))
        self.assertEqual((set(self.suites) & jobs) - {"verify-regions-shard"}, set())

    def test_ci_matrix_matches_runners(self):
        block = CI[CI.index("  verify-packed:\n"):]
        matrix = re.search(r"runner: \[([0-9, ]+)\]", block).group(1)
        self.assertEqual([int(x) for x in matrix.split(",")], list(range(1, P.RUNNERS + 1)))


if __name__ == "__main__":
    unittest.main()
