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
            lane = P.Lane("a", units, out, dict(os.environ))
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
