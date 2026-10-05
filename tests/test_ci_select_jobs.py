#!/usr/bin/env python3
"""Classifies sample paths through tools/ci/select_jobs.py (affected-only CI
selection). Run in ci.yml's `changes` job:  python3 tests/test_ci_select_jobs.py

The selection may only ever cost speed: every case where a path could reach a
suite the rules cannot bound must select EVERYTHING. The sample corpus below
stands in for the repository text the real run scans; the real ci.yml is used
for job names, and one case runs against the real repository.
"""
import os
import sys
import unittest

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "ci"))
import select_jobs as S  # noqa: E402

CI = open(os.path.join(ROOT, ".github", "workflows", "ci.yml")).read()
EVERY = set(S.ci_jobs(CI))

CORPUS = {
    # A Cloudreach script only its own family and its own smoke use.
    "scripts/world/cloudreach_bell.gd": "extends Node\n",
    "scripts/world/cloudreach_world.gd": 'const BELL := preload("res://scripts/world/cloudreach_bell.gd")\n',
    "tests/smoke_cloudreach_persistence_tail.gd": 'const B := preload("res://scripts/world/cloudreach_bell.gd")\n',
    # A water_ script the Meadows ponds use: shared, so everything.
    "scripts/world/water_surface.gd": "extends Node\n",
    "scripts/world/playground_world.gd": 'const W := preload("res://scripts/world/water_surface.gd")\n',
    # A Stormwood script a unit test reads (adds nothing) and a Meadows smoke runs.
    "scripts/world/stormwood_arch.gd": "extends Node\n",
    "tests/test_stormwood_arch.gd": 'preload("res://scripts/world/stormwood_arch.gd")\n',
    "tests/smoke_gate_b_continuous.gd": 'preload("res://scripts/world/stormwood_arch.gd")\n',
    # A smoke extended by another smoke: a harness piece, everything.
    "tests/smoke_net_proof_two_peer.gd": "extends SceneTree\n",
    "tests/smoke_cloudreach_rejoin_closed_gate_proof.gd": 'extends "res://tests/smoke_net_proof_two_peer.gd"\n',
    "tests/smoke_tournament_bracket.gd": "extends SceneTree\n",
    "tests/smoke_relay.gd": "extends SceneTree\n",
    "tools/net/proof_steps_segments.gd": "extends RefCounted\n",
    "tools/net/proof_peer_runner.gd": 'const S := preload("res://tools/net/proof_steps_segments.gd")\n',
}


def pick(*paths, event="pull_request", corpus=CORPUS):
    return S.select(list(paths), event, CI, corpus)


class SelectJobs(unittest.TestCase):
    def assertEverything(self, *paths, **kw):
        jobs, every, why = pick(*paths, **kw)
        self.assertTrue(every, "%s should select everything: %s" % (paths, why))
        self.assertEqual(jobs, EVERY)

    def test_schedule_dispatch_empty_and_large_select_everything(self):
        self.assertEverything("scripts/world/cloudreach_bell.gd", event="schedule")
        self.assertEverything("scripts/world/cloudreach_bell.gd", event="workflow_dispatch")
        self.assertEverything()
        self.assertEverything(*["scripts/world/cloudreach_x%d.gd" % i for i in range(S.MAX_PATHS + 1)])

    def test_core_paths_select_everything(self):
        for path in ["autoload/game_state.gd", "scripts/save/save_game.gd", "scripts/net/session.gd",
                     "scripts/net/ledger_rpc.gd", "scripts/combat/encounter_director.gd",
                     "scripts/combat/combat_manager.gd", "project.godot", ".github/workflows/ci.yml",
                     "tests/helpers/net_harness.gd", "tools/ci/select_jobs.py", "tests/fixtures/x.json.gz",
                     "addons/terrain_3d/x.gd", "scripts/player/player.gd"]:
            self.assertEverything(path)

    def test_cross_cutting_gameplay_selects_everything(self):
        # Every world-booting smoke (net ones too) fights, boots Meadows, opens the HUD.
        for path in ["scripts/combat/aim_assist.gd", "data/config/combat.json", "scripts/creatures/x.gd",
                     "scripts/ui/hud.gd", "scripts/build/station_forge.gd", "scripts/masters/x.gd",
                     "scripts/world/village.gd", "data/config/bands/b1/vegetation.json", "scenes/ui/hud.tscn",
                     "assets/creatures/tetherbound/terrapup/terrapup.glb"]:
            self.assertEverything(path)

    def test_unmapped_paths_select_everything(self):
        for path in ["weird/new_tree/file.xyz", "icon.svg.unknown", "Makefile", "scripts/newdir/thing.gd",
                     "data/whatever.bin"]:
            self.assertEverything(path)

    def test_a_realm_file_used_only_by_its_family_selects_that_realm(self):
        jobs, every, why = pick("scripts/world/cloudreach_bell.gd")
        self.assertFalse(every, why)
        self.assertTrue({"verify-cloudreach-persistence", "verify-regions-shard",
                         "verify-cloudreach-midride-rejoin", "verify-multiplayer-shard"} <= jobs, why)
        for skipped in ["verify-combat-shard", "verify-gate-b-core", "verify-gate-evidence-shard"]:
            self.assertNotIn(skipped, jobs)

    def test_a_realm_file_used_outside_its_family_selects_everything(self):
        self.assertEverything("scripts/world/water_surface.gd")

    def test_a_realm_file_a_meadows_smoke_uses_adds_that_smokes_job(self):
        jobs, every, why = pick("scripts/world/stormwood_arch.gd")
        self.assertFalse(every, why)
        self.assertIn("verify-gate-b-core", jobs, why)  # runs smoke_gate_b_continuous
        self.assertIn("verify-regions-shard", jobs, why)

    def test_a_smoke_selects_the_jobs_that_run_it(self):
        jobs, every, why = pick("tests/smoke_tournament_bracket.gd")
        self.assertFalse(every, why)
        self.assertIn("verify-gate-evidence-finale", jobs, why)
        jobs, _every, why = pick("tests/smoke_relay.gd")  # named only as `SMOKE: relay`
        self.assertIn("verify-regions-relay", jobs, why)

    def test_a_shared_harness_smoke_selects_everything_its_users_run(self):
        jobs, every, why = pick("tests/smoke_net_proof_two_peer.gd")
        self.assertIn("verify-cloudreach-midride-rejoin", jobs, why)
        self.assertIn("verify-multiplayer-shard", jobs, why)

    def test_net_tools_select_the_net_group(self):
        jobs, every, why = pick("tools/net/proof_steps_segments.gd")
        self.assertFalse(every, why)
        self.assertTrue(S.NET_JOBS <= jobs, why)

    def test_unit_tests_and_docs_add_nothing_but_the_always_jobs(self):
        jobs, every, why = pick("tests/test_stormwood_arch.gd", "docs/STATE.md", "ralph/reports/X/y.txt")
        self.assertFalse(every, why)
        self.assertEqual(jobs, S.ALWAYS_JOBS & EVERY, why)

    def test_media_selects_presentation_jobs_only(self):
        jobs, every, why = pick("assets/ui/icons/items/berry.png", "shaders/grass.gdshader")
        self.assertFalse(every, why)
        self.assertEqual(jobs, (S.ALWAYS_JOBS | S.PRESENTATION_JOBS) & EVERY, why)

    def test_always_jobs_are_never_removed(self):
        jobs, _every, _why = pick("tests/test_stormwood_arch.gd")
        self.assertTrue({"verify-unit-tests", "verify-bake-freshness", "export", "verify-segment-handoffs"} <= jobs)

    def test_every_named_job_exists_in_ci_yml(self):
        for name in S.ALWAYS_JOBS | S.NET_JOBS | S.PRESENTATION_JOBS | set().union(*S.REALM_JOBS.values()):
            self.assertIn(name, EVERY, "%s is not a ci.yml job" % name)

    def test_against_the_real_repository(self):
        corpus = S.load_corpus(ROOT)
        self.assertGreater(len(corpus), 500)
        # The real save code is core.
        jobs, every, _ = S.select(["scripts/save/save_game.gd"], "pull_request", CI, corpus)
        self.assertTrue(every)


if __name__ == "__main__":
    unittest.main(verbosity=1)
