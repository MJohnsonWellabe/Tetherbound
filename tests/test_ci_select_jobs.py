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
    # The made-up corpus has none of the real scan sentinels.
    S.REQUIRED_SCAN_CHECK = False
    try:
        return S.select(list(paths), event, CI, corpus)
    finally:
        S.REQUIRED_SCAN_CHECK = True


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

    def test_a_shared_harness_smoke_selects_the_jobs_its_users_run(self):
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

    def test_main_prints_the_all_sentinel_and_net(self):
        import subprocess
        out = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "ci", "select_jobs.py"), "--all",
                              "--event", "schedule", "--ci", os.path.join(ROOT, ".github", "workflows", "ci.yml")],
                             capture_output=True, text=True, check=True).stdout
        self.assertIn("jobs=|ALL|", out)
        self.assertIn("all=true", out)
        self.assertIn("net=true", out)


REAL = None


def real():
    global REAL
    if REAL is None:
        REAL = S.load_corpus(ROOT)
    return REAL


class Walk(unittest.TestCase):
    """Second re-review findings on the walk itself."""

    def test_a_comment_only_referrer_is_still_followed_when_it_really_loads_a_later_node(self):
        corpus = {
            "tests/smoke_alpha.gd": "extends SceneTree\n",
            "tools/beta_tool.gd": 'const A := preload("res://tests/smoke_alpha.gd")\n',
            "scripts/ui/hud.gd": '# see smoke_alpha\nconst B := load("res://tools/beta_tool.gd")\n',
        }
        jobs, every, why = pick("tests/smoke_alpha.gd", corpus=corpus)
        self.assertTrue(every, why)

    def test_a_uid_sidecar_counts_as_its_file(self):
        corpus = {
            "tools/capture_x.gd": "extends SceneTree\n",
            "scripts/world/visual.gd": 'if a in ["res://tools/capture_x.gd"]: pass\n',
        }
        jobs, every, why = pick("tools/capture_x.gd.uid", corpus=corpus)
        self.assertTrue(every, why)

    def test_a_folder_constant_join_counts_as_a_load(self):
        corpus = {
            "tools/capture_x.gd": "extends SceneTree\n",
            "scripts/world/visual.gd": 'const DIR := "res://tools/"\nvar s = load(DIR + "capture_x.gd")\n',
        }
        jobs, every, why = pick("tools/capture_x.gd", corpus=corpus)
        self.assertTrue(every, why)

    def test_deleted_scripts_and_class_name_scripts_select_everything(self):
        corpus = {"scripts/world/cloudreach_bell.gd": "class_name CloudreachBell\nextends Node\n"}
        self.assertTrue(pick("scripts/world/cloudreach_gone.gd", corpus=corpus)[1])
        self.assertTrue(pick("scripts/world/cloudreach_bell.gd", corpus=corpus)[1])

    def test_an_incomplete_corpus_selects_everything(self):
        jobs, every, why = S.select(["tests/smoke_relay.gd"], "pull_request", CI, {"tests/smoke_relay.gd": ""})
        self.assertTrue(every, why)


class RealRepository(unittest.TestCase):
    """Regression cases from the independent selection review (each was a
    silent miss before the transitive walk): every one must select every job,
    or at least the named suite that loads it."""

    def sel(self, path):
        return S.select([path], "pull_request", CI, real())

    def assertEverything(self, path):
        jobs, every, why = self.sel(path)
        self.assertTrue(every, "%s must select everything: %s" % (path, why))

    def assertSelects(self, path, job):
        jobs, every, why = self.sel(path)
        self.assertTrue(every or job in jobs, "%s must select %s: %s" % (path, job, why))

    def test_corpus_covers_data_assets_and_shaders(self):
        files = real().files
        self.assertGreater(len(files), 2000)
        self.assertIn("data/creatures/species.json", files)
        self.assertIn("project.godot", files)

    def test_core(self):
        for path in ["scripts/save/save_game.gd", "scripts/save/water_capture_codec.gd",
                     "scripts/save/water_traversal_save.gd"]:
            self.assertEverything(path)

    def test_transitive_reach_into_shared_code(self):
        # water_roster.json -> water_species_catalog.gd -> creature_species.gd (every lookup).
        self.assertEverything("data/config/water_roster.json")
        # operator_harness.gd -> tools/net/peer_runner.gd -> tests/helpers/net_harness.gd.
        self.assertEverything("tools/gate_f/catch_outcome.gd")
        # cloudreach director <- water director: game code outside the family.
        self.assertEverything("scripts/combat/cloudreach_combat_surface.gd")

    def test_realm_file_reaching_a_meadows_suite(self):
        # water_alpha.gd preloads it; smoke_water_alpha_retirement.gd runs in verify-combat-shard.
        self.assertSelects("scripts/combat/water_alpha_state.gd", "verify-combat-shard")

    def test_ripplet_is_a_starter_not_a_realm(self):
        self.assertEverything("assets/creatures/tetherbound/ripplet/models/creature_ripplet_lod0.glb")
        self.assertEverything("data/config/ripplet_traversal.json")

    def test_unit_tests_follow_their_users(self):
        self.assertSelects("tests/test_harvest.gd", "verify-harvest")  # --skip'd from the unit shards
        self.assertSelects("tests/test_veg_corridor.gd", "verify-veg-corridor")
        self.assertSelects("tests/test_scatter_rules.gd", "verify-scatter-rules")
        self.assertEverything("tests/test_save_format.gd")  # preloaded by tests/helpers/ci_segments.gd
        self.assertSelects("tests/test_meadows_earned_material_segment.gd", "verify-regions-shard")

    def test_game_code_loading_a_tool_by_path_selects_everything(self):
        # scripts/ui/title_screen.gd: load("res://tools/f26_export_bootstrap.gd")
        self.assertEverything("tools/f26_export_bootstrap.gd")

    def test_a_smoke_only_named_in_prose_selects_its_jobs(self):
        jobs, every, why = self.sel("tests/smoke_relay.gd")
        self.assertTrue(every or "verify-regions-relay" in jobs, why)

    def test_uid_sidecars_of_tools_game_code_loads(self):
        # scripts/world/cloudreach_visual_candidate.gd and data/config/lookdev_routes.json.
        for path in ["tools/capture_cloudreach_f40_matrix.gd.uid", "tools/capture_cloudreach_f40_fight.gd.uid",
                     "tools/art_pipeline/capture_tidewake_matrix.gd.uid"]:
            if os.path.exists(os.path.join(ROOT, path[:-4])):
                self.assertEverything(path)

    def test_portraits_and_audio_reach_their_users(self):
        self.assertEverything("assets/ui/portraits/sorrel.png")

    def test_media_follow_their_users(self):
        self.assertSelects("assets/ui/input_prompts/keyboard_r.png", "verify-gate-a-ui-build-shard")

    def test_realm_jobs_include_every_job_running_a_realm_smoke(self):
        self.assertIn("verify-combat-shard", S.realm_jobs("tidewake", S.ci_jobs(CI), real()))


if __name__ == "__main__":
    unittest.main(verbosity=1)
