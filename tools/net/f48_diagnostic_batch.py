"""Isolated pretend-prerequisite diagnostics; NEVER F48 acceptance inputs.

Each named case launches the unchanged generic proof runner in fresh homes.
Failures remain failures and later cases still execute. Preparation uses real
paid-build/catch inputs; only explicitly disclosed pre-admission prerequisites
are seeded. No original saved source, journal, receipt, UID or namespace changes.
"""
from __future__ import annotations

import argparse
import copy
import json
import os
from pathlib import Path
import shutil
import subprocess

import f48_profile_fixture as fixture
import f48_prepare_profile as routes
import f48_produce_actual as original
from f48_ci_runner import configuration_overlay

ROOT = fixture.ROOT
DISCLOSURE = "DIAGNOSTIC_PRETEND_PREREQUISITES_NO_F48_EARNED_OR_RECORDED_INPUT_CREDIT"
CASES = ("craft", "release", "feast_cook", "feast", "key", "relic", "essence_spend",
         "ordinary_round", "join_recovery", "snapshot_care")
SUBSTANTIVE = {"press", "move_to", "stick", "f48_button", "f48_choice", "f48_build_cell",
               "f48_fixture_approach", "f48_deploy_owned", "f48_fixture_capture",
               "f48_dialogue", "f48_fixture_trainer_fight", "f48_diagnostic"}
ORIGINAL_STAGES = {"craft": "craft", "release": "release", "feast_cook": "feast_cook",
                   "feast": "feast", "key": "key", "relic": "relic", "essence_spend": "hub",
                   "ordinary_round": "boss (one round only)", "join_recovery": "behind/rejoin",
                   "snapshot_care": "craft/snapshot"}


def coverage_manifest(output: Path, original_scenario: Path | None = None):
    """Recipe correspondence is NOT validation of original journey steps."""
    original_steps = fixture.read(original_scenario)["steps"] if original_scenario else []
    total = len(original_steps) if original_scenario else 265
    rows = []
    for name in CASES:
        path = output / "cases" / name / "scenario.json"
        steps = fixture.read(path)["steps"]
        correspondences = []
        for index, step in enumerate(steps, 1):
            matched = [n for n, old in enumerate(original_steps, 1)
                       if all(old.get(key) == step.get(key) for key in ("peer", "action", "args"))]
            if matched:
                correspondences.append({"diagnostic_step": index, "original_steps": matched,
                                        "action": step["action"], "validation_credit": False})
        rows.append({"case": name, "original_stage": ORIGINAL_STAGES[name],
                     "scenario_sha256": fixture.digest(path),
                     "action_recipe_correspondences": correspondences,
                     "original_step_ranges": None, "validated_original_steps": []})
    manifest = {"disclosure": DISCLOSURE, "acceptance_credit": False,
                "mapping_kind": "exact peer/action/args recipe correspondence only; independent seeded scopes",
                "original_scenario": str(original_scenario) if original_scenario else None,
                "original_scenario_sha256": fixture.digest(original_scenario) if original_scenario else None,
                "original_step_count": total,
                "count_source": "exact supplied original scenario" if original_scenario else "controller-reported 265; indices unverified",
                "original_step_execution_claim": False, "validated_original_steps": [],
                "uncovered_original_steps": list(range(1, total + 1)), "uncovered_original_step_count": total,
                "cases": rows}
    fixture.write(output / "original-step-coverage.json", manifest)
    return manifest


def selected_cases(value: str):
    names = tuple(value.split(","))
    fixture.require(bool(names) and len(set(names)) == len(names) and all(name in CASES for name in names),
                    "Diagnostic cases must be unique nonempty names from the ten-case allowlist")
    return names


def entry(peer, action, args=None, **extra):
    return {"peer": peer, "action": action, "args": args or {},
            "continue_on_fail": True, "label": "DIAGNOSTIC ONLY: " + action, **extra}


def diagnostic(peer, phase, **args):
    return entry(peer, "f48_diagnostic", {"disclosure": DISCLOSURE, "phase": phase, **args})


def input_rows(peer, raw):
    return [entry(peer, row["action"], copy.deepcopy(row.get("args", {})),
                  budget_frames=180000 if row["action"] == "f48_fixture_trainer_fight" else 10000)
            for row in raw]


def scenario(name, saves, profile, actions, seed="none", outcome=None):
    fixture.require(name == "preparation" or name in CASES, "Unknown diagnostic case")
    steps = [entry("all", "f48_require_configuration", {"files": profile["test_configuration"], "scope": "full"})]
    for peer, source in enumerate(saves):
        steps += [entry(peer, "load_save", {"from": str(source), "portable_only": peer > 0}),
                  diagnostic(peer, "initial_save", seed=seed, case=name)]
    steps += [entry(0, "host"), entry(1, "production_join", {"returning_route": True,
              "character": {"character_id": "$character1"}}, budget_frames=10000),
              entry("all", "expect_peers", {"count": 2}),
              entry("all", "f48_watch_owner_saves"), entry("all", "f48_witness", {"remember": "before"})]
    steps += actions
    if outcome is not None:
        steps.append(entry(1, "f48_assert", {"since": "before", **outcome}))
    steps += [entry("all", "f48_witness", {"remember": "after"}),
              entry("all", "capture_saves", {"label": "diagnostic-files"})]
    count = sum(row.get("action") in SUBSTANTIVE and
                not (row.get("action") == "f48_diagnostic" and row.get("args", {}).get("phase") == "initial_save")
                for row in steps)
    fixture.require(count <= 10, f"Diagnostic {name} has {count} substantive actions; maximum10")
    fixture.require(all(row.get("continue_on_fail") is True for row in steps), "Diagnostic must retain later observations")
    fixture.require(not any(row.get("action") in {"f48_capture_durable", "f48_arm_boundary", "f48_boundary_transaction"}
                            for row in steps), "Diagnostics cannot create recorded acceptance cuts")
    return {"name": "DIAGNOSTIC ONLY F48 " + name,
            "claim": DISCLOSURE + "; pretend initial prerequisites, actual results never suppressed; no acceptance credit",
            "peers": 2, "scene": "title", "budget_s": 900, "build_allowance_s": 300,
            "steps": steps, "_comment_substantive_actions": count}


def case_actions(name, profile):
    peer = 1
    r = profile["routes"]
    seed = "none"
    outcome = None
    if name == "craft":
        actions = input_rows(peer, routes.contact("forge") + [routes.button("Refine Rootiron Ingot"), routes.wait(180)])
        outcome = {"item_delta": {"rootstone": -2, "ironwood": -1, "rootiron_ingot": 1},
                   "append_count": {"redesign_character/transaction_receipts": 1}}
    elif name == "release":
        actions = input_rows(peer, routes.contact("altar") + [routes.button("Traits / Release")])
        actions += [diagnostic(peer, "choose_caught"), entry(peer, "f48_button", {"text": "Release companion and distil chosen trait"}),
                    diagnostic(peer, "confirm_release"), entry(peer, "wait", {"frames": 180})]
        outcome = {"append_count": {"redesign_character/release_receipts": 1}}
    elif name in {"feast_cook", "feast"}:
        seed = "feast_ready"
        actions = input_rows(peer, routes.contact("kitchen") + [routes.button("Cook learned Ascension Feasts"), routes.wait()])
        if name == "feast_cook":
            actions += [entry(peer, "f48_button", {"feast_recipe": "feast_t1_ground"}), entry(peer, "wait", {"frames": 180})]
            outcome = {"item_delta": {"berries": -4, "rootstone": -2, "attuned_ground": -1, "feast_t1_ground": 1}}
        else:
            nickname = fixture.source_input(Path(profile["saves"][peer]), False)["character"]["party"][0]["nickname"]
            actions += [entry(peer, "f48_button", {"text": "Feed creatures"}),
                        entry(peer, "f48_button", {"text": f"{nickname} · Breakthrough needed · Ascension Feast 1 (ground)"}),
                        entry(peer, "wait", {"frames": 180})]
            outcome = {"item_delta": {"feast_t1_ground": -1}}
    elif name == "key":
        seed = "key_ready"
        actions = input_rows(peer, routes.contact("tidewake_arch") + [routes.wait(180)])
        outcome = {"item_delta": {"tidewake_portal_key": -1}, "contains": {"redesign_character/portal_unlocks": "tidewake"}}
    elif name == "relic":
        seed = "relic_ready"
        actions = input_rows(peer, routes.contact("meadows_pedestal") + [routes.wait(180)])
        outcome = {"contains": {"redesign_character/relics_hung": "meadows"}}
    elif name == "essence_spend":
        actions = input_rows(peer, r["hub_1"][:-4]) + [entry(peer, "wait", {"frames": 180})]
        outcome = profile["outcomes"]["essence_spend_1"]
    elif name == "ordinary_round":
        seed = "round_ready"
        actions = input_rows(0, routes.contact("warden_aldis") + [routes.step("f48_dialogue", conversation="stronghold_warden_challenge"), routes.wait(90)])
        round_step = diagnostic(0, "ordinary_round", budget_frames=9000)
        round_step["budget_frames"] = 10000  # Carry the existing driver's 9000-frame bound through the coordinator.
        actions += [round_step, entry("all", "wait", {"frames": 240})]
    elif name == "join_recovery":
        actions = [entry(1, "leave"), entry(1, "production_join", {"returning_route": True,
                   "character": {"character_id": "$character1"}}, budget_frames=10000), entry("all", "expect_peers", {"count": 2})]
    else:
        actions = input_rows(peer, routes.contact("forge") + [routes.button("Refine Rootiron Ingot"), routes.wait(180), routes.press("menu_cancel")])
        # Observe real care/retained canonical save source; do not advance or
        # fabricate the 180-second natural fallback clock for diagnostics.
        actions += [entry("all", "wait", {"frames": 240}), entry("all", "f48_assert_snapshot")]
    return actions, seed, outcome


def prepare(output: Path, original_scenario: Path | None = None):
    fixture.require(not output.exists(), "Fresh diagnostic output required")
    sources = original.restore_seeds(ROOT / "tests/fixtures/f48-producer-seeds", output / "originals")
    manifest = fixture.read(ROOT / "tests/fixtures/f48-producer-seeds/manifest.json")
    fixture.generate(sources[:2], ROOT / "tests/fixtures/f48-producer-seeds/layout.json", output / "mechanics-start",
                     None, manifest["provenance"], "full", True, True, True)
    profile_path = routes.produce(output / "mechanics-start/profile.json", output / "routes")
    profile = fixture.read(profile_path)
    actions = input_rows(0, profile["routes"]["bootstrap_altar"])
    capture = {"fixture_disclosure": "actual_shared_alpha_rng_and_actor_placement_no_earned_credit"}
    actions += [entry(0, "f48_fixture_capture", {**capture, "role": "host"}, budget_frames=10000),
                entry(1, "f48_fixture_capture", {**capture, "role": "guest"}, budget_frames=10000)]
    fixture.write(output / "preparation/scenario.json", scenario("preparation", profile["saves"], profile, actions))
    fixture.write(output / "diagnostic-manifest.json", {"disclosure": DISCLOSURE, "acceptance_credit": False,
                  "earned_checkpoint": False, "ready_ci_bundle": False, "cases": list(CASES),
                  "source_profile": str(profile_path), "source_profile_sha256": fixture.digest(profile_path),
                  "protected": "Every original journal, receipt, character/creature identity, namespace and capture provenance",
                  "source_seed_manifest": manifest, "initial_fixture_manifest": fixture.read(output / "mechanics-start/fixture-manifest.json")})
    prepare_cases(output, profile, [Path(p) for p in profile["saves"]], "Canonical generated initial mechanics fixtures; preparation has not executed")
    coverage_manifest(output, original_scenario)
    return profile


def prepare_cases(output: Path, profile: dict, sources: list[Path], origin: str):
    for name in CASES:
        root = output / "cases" / name
        fixture.require(not (root / "sources").exists(), "Never overwrite a diagnostic source")
        saves = []
        source_rows = []
        for peer, source in enumerate(sources):
            destination = root / "sources" / f"peer-{peer}"
            shutil.copytree(source, destination)
            actual = fixture.source_input(destination, peer == 0)
            saves.append(destination)
            source_rows.append({"peer": peer, "source": str(source), "character_id": actual["id"],
                                "documents": [{"relative": str(path.relative_to(destination)), "sha256": fixture.digest(path)}
                                              for path in sorted(destination.rglob("*.json"))]})
        actions, seed, outcome = case_actions(name, profile)
        fixture.write(root / "scenario.json", scenario(name, saves, profile, actions, seed, outcome))
        fixture.write(root / "fixture-source.json", {"disclosure": DISCLOSURE, "acceptance_credit": False,
                      "earned_checkpoint": False, "ready_ci_bundle": False, "origin": origin,
                      "seed": seed, "sources": source_rows})


def run_case(output: Path, name: str, profile: dict, godot: str, render=False):
    root = output / name if name == "preparation" else output / "cases" / name
    env = os.environ.copy()
    home = root / "coordinator-home"
    home.mkdir(parents=True, exist_ok=False)
    env.update(XDG_DATA_HOME=str(home), APPDATA=str(home), TB_NET_OUT_DIR=str(root / "net"),
               TB_PROOF_OUT=str(root / "proof"), TB_PROOF_SCENARIO=str(root / "scenario.json"),
               TB_NET_PROOF_RENDER="1" if render else "0", TB_F48_DIAGNOSTIC_ONLY=DISCLOSURE,
               GODOT_BIN=godot)
    # Preserve the existing shell's run-ID/process cleanup and peer isolation.
    command = ["timeout", "--signal=TERM", "--kill-after=15s", "1200s", "bash",
               str(ROOT / "tools/net/run_two_peer_proof.sh"), str(root / "scenario.json"),
               "--out=" + str(root / "proof")]
    if render:
        command.append("--render")
    with (root / "run.log").open("wb") as log:
        with configuration_overlay(ROOT, profile):
            completed = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT)
    return {"case": name, "exit_code": completed.returncode, "run_log": str(root / "run.log"),
            "run_log_sha256": fixture.digest(root / "run.log"), "scenario_sha256": fixture.digest(root / "scenario.json"),
            "acceptance_credit": False}


def run_all(output: Path, profile: dict, godot="godot", render=False, runner=run_case,
            original_scenario=None, cases=CASES):
    cases = selected_cases(",".join(cases))
    results = []
    for name in ("preparation", *cases):
        try:
            row = runner(output, name, profile, godot, render)
        except (OSError, subprocess.SubprocessError, ValueError) as error:
            row = {"case": name, "exit_code": None, "error": str(error), "acceptance_credit": False}
        results.append(row)
        if name == "preparation":
            captures = [output / "preparation/proof" / f"peer-{peer}" / "diagnostic-files" for peer in range(2)]
            try:
                # Schema/identity existence is a diagnostic input check, never
                # an acceptance decision for this preparation's raw verdict.
                for peer, captured in enumerate(captures):
                    fixture.source_input(captured, peer == 0)
                (output / "cases").rename(output / "planned-starter-cases")
                prepare_cases(output, profile, captures,
                              "Actual isolated diagnostic paid-build/catch preparation; raw exit=" + str(row.get("exit_code")))
                row["downstream_source"] = "actual_diagnostic_preparation_files"
            except (OSError, ValueError, KeyError, TypeError) as error:
                backup = output / "planned-starter-cases"
                if backup.exists():
                    if (output / "cases").exists():
                        (output / "cases").rename(output / "failed-preparation-case-plan")
                    backup.rename(output / "cases")
                row["downstream_source"] = "canonical_generated_starter_fixture"
                row["preparation_source_error"] = str(error)
            coverage_manifest(output, original_scenario)
        fixture.write(output / "diagnostic-results.json", {"disclosure": DISCLOSURE,
                      "acceptance_credit": False, "earned_checkpoint": False, "ready_ci_bundle": False,
                      "selected_cases": list(cases), "unattempted_cases": [case for case in CASES if case not in cases],
                      "completed_cases": len(results), "results": results})
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--run", action="store_true", help="Requires the caller's existing serialized native engine lease")
    parser.add_argument("--render", action="store_true")
    parser.add_argument("--original-scenario", type=Path, help="Optional hash-pinned original scenario for exact recipe-index correspondence; never validation credit")
    parser.add_argument("--cases", default=",".join(CASES), help="Optional diagnostic-only unique comma-separated allowlist; default all ten")
    args = parser.parse_args()
    cases = selected_cases(args.cases)
    profile = prepare(args.output.resolve(), args.original_scenario)
    results = run_all(args.output.resolve(), profile, args.godot, args.render,
                      original_scenario=args.original_scenario, cases=cases) if args.run else []
    print(json.dumps({"disclosure": DISCLOSURE, "acceptance_credit": False, "cases": len(CASES),
                      "selected_cases": list(cases), "unattempted_cases": [case for case in CASES if case not in cases],
                      "results": results, "output": str(args.output.resolve())}))
    return 1 if results and any(row.get("exit_code") != 0 for row in results) else 0


if __name__ == "__main__":
    raise SystemExit(main())
