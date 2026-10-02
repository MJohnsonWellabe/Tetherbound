"""Independently judge returned bytes and scope; no engine/test execution."""
from __future__ import annotations

import gzip
import hashlib
import json
import re
import subprocess
from pathlib import Path
from source_audit import BASE, OUT, PRIMARY, ROOT, data, dump, git, raw, source, stamp, warm

SEALED = ROOT / "ralph/reports/INTEGRATION/branch-closeout/returned-evidence"


def digest(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def audit_sealed() -> None:
    bindings: dict[Path, list[dict]] = {}
    def walk(value, manifest: Path):
        if isinstance(value, dict):
            for key, child in value.items():
                if key.endswith(".gz") and isinstance(child, dict):
                    target = manifest.parent / key
                    if target.is_file(): bindings.setdefault(target, []).append({"manifest": str(manifest.relative_to(ROOT)), **child})
                elif isinstance(child, dict) and str(child.get("copy", "")).endswith(".gz"):
                    target = manifest.parent / child["copy"]
                    if target.is_file(): bindings.setdefault(target, []).append({"manifest": str(manifest.relative_to(ROOT)), **child})
                walk(child, manifest)
        elif isinstance(value, list):
            for child in value:
                if isinstance(child, dict) and str(child.get("copy", "")).endswith(".gz"):
                    target = manifest.parent / child["copy"]
                    if target.is_file(): bindings.setdefault(target, []).append({"manifest": str(manifest.relative_to(ROOT)), **child})
                walk(child, manifest)
    for manifest in sorted(SEALED.rglob("*.json")):
        try: walk(json.loads(manifest.read_text(encoding="utf-8-sig")), manifest)
        except (OSError, ValueError): pass
    rows = []
    failures = []
    for path in sorted(SEALED.rglob("*.gz")):
        compressed = path.read_bytes()
        try: unpacked = gzip.decompress(compressed)
        except (OSError, EOFError) as error:
            failures.append({"path": str(path.relative_to(ROOT)), "error": str(error)})
            continue
        checks = []
        for manifest in bindings.get(path, []):
            expected_raw = manifest.get("raw_sha256") or manifest.get("raw_log_sha256")
            expected_gz = manifest.get("gzip_sha256")
            expected_bytes = manifest.get("raw_bytes")
            results = {"manifest": manifest["manifest"], "raw_sha256_matches": digest(unpacked) == expected_raw if expected_raw else None,
                       "gzip_sha256_matches": digest(compressed) == expected_gz if expected_gz else None,
                       "raw_length_matches": len(unpacked) == expected_bytes if expected_bytes is not None else None}
            if any(results[k] is False for k in ["raw_sha256_matches", "gzip_sha256_matches", "raw_length_matches"]):
                failures.append({"path": str(path.relative_to(ROOT)), **results})
            checks.append(results)
        rows.append({"path": str(path.relative_to(ROOT)), "gzip_sha256": digest(compressed), "raw_sha256": digest(unpacked),
                     "raw_bytes": len(unpacked), "gzip_crc_and_length_valid": True, "manifest_checks": checks})
    report = {**stamp(), "scope": "sealed byte/hash binding only; never converts source/failed/partial artifacts to acceptance",
              "gzip_files": len(rows), "gzip_with_a_matching_raw_manifest": sum(any(c["raw_sha256_matches"] is True for c in r["manifest_checks"]) for r in rows),
              "failures": failures, "files": rows}
    dump("sealed-artifact-integrity-recheck.json", report)
    print(json.dumps({k: report[k] for k in ["gzip_files", "gzip_with_a_matching_raw_manifest", "failures"]}, indent=2))


def seal_copy(path: Path, name: str) -> dict:
    value = path.read_bytes()
    target = OUT / "returned-native" / name
    target.parent.mkdir(exist_ok=True)
    target.write_bytes(gzip.compress(value, mtime=0))
    return {"source": str(path), "copy": str(target.relative_to(OUT)), "raw_bytes": len(value),
            "raw_sha256": digest(value), "gzip_sha256": digest(target.read_bytes())}


def judge_core() -> None:
    result_path = PRIMARY / "returned-smoke-582b2f13cc53-smoke_gate_b_continuous/result.json"
    native = json.loads(result_path.read_text(encoding="utf-8-sig"))
    log_path = Path(native["log"])
    log = log_path.read_bytes()
    text = log.decode("utf-8", errors="replace")
    markers = {
        "mira_dialogue_shop_cancel_owner_and_movement_resume": "Mira cycle 1 exited and movement resumed",
        "mira_actual_interior_exit_gifts_validated": "Mira handed over axe, pickaxe and the Basic Orb pattern through dialogue",
        "axe_equipped_and_real_wood_gather": "axe equipped, swung, gathered +4 Wood",
        "pickaxe_equipped_and_real_stone_gather": "pickaxe equipped, swung, gathered +4 Stone",
        "knife_equipped_and_real_fiber_gather": "knife equipped, swung, gathered +4 Fiber",
        "terminal_core_failed": "gate B continuous FAIL:",
        "oskar_authored_heading_blocker": "missing/malformed bounded authored Oskar approach",
    }
    observations = {}
    for label, marker in markers.items():
        matched = [{"line": i, "text": line} for i, line in enumerate(text.splitlines(), 1) if marker in line]
        observations[label] = {"observed": bool(matched), "matches": matched}
    warm(["tests/helpers/gate_a_npc_gather_segment.gd", "tests/smoke_gate_b_continuous.gd"])
    helper = source("tests/helpers/gate_a_npc_gather_segment.gd")
    guards = ["_wait_dialogue_open(90)", "_close_dialogue(40)", "_wait_open_panel(expected_panel_suffix, 90)",
              "_tap_action(&\"menu_cancel\")", "_wait_world_owned(45)", "_prove_movement_resumed(door, npc.global_position)",
              "_exit_through(door, npc.global_position)"]
    binding = {guard: guard in helper for guard in guards}
    valid = native["head"] == BASE and digest(log) == native["raw_log_sha256"] and all(binding.values()) and all(v["observed"] for v in observations.values())
    report = {**stamp(), "actual_executed_commit": native["head"], "native": native, "platform": "Windows native headless Godot returned by ROOT",
              "input": "actual parsed InputEventJoypadButton and production controller/contact route; instrumented chain",
              "starting_save_and_shortcuts": "Fresh title/opening harness, declared team/level assistance described in smoke_gate_b_continuous.gd; CORE scope, not full chain; no earned campaign inferred.",
              "observations": observations, "production_guard_binding": binding, "raw_hash_matches": digest(log) == native["raw_log_sha256"],
              "independent_verdict": "SCOPED_MIRA_AND_THREE_EQUIPPED_GATHERS_PASS_WHOLE_CORE_FAIL" if valid else "OPEN_INCONSISTENT_RETURN",
              "scope": "Mira cycle1 dialogue→shop handoff→B cancel→world ownership→movement→actual interior exit plus actual Wood/Stone/Fiber gathers; not full16, all modal cycles or M1 chain.",
              "criterion_verdicts": {"F17#4": "OPEN", "M1": "OPEN", "F48": "OPEN", "F49#0": "OPEN"},
              "next_needed": "ROOT's independently reviewed Oskar final duplicate waypoint repair needs the original actual CORE rerun. Full M1 additionally needs --gate-b-full-chain/starter witnesses.",
              "prior_failure_preservation": "Earlier full19 FAIL, full16 terrain FAIL and focused23 PASS remain untouched in sealed mira-verification-16fbddde3930.",
              "members": [seal_copy(result_path, "core582b-result.json.gz"), seal_copy(log_path, "core582b-smoke.log.gz")]}
    dump("core582b-independent-judgment.json", report)
    print(json.dumps({"core": report["independent_verdict"], "hash": digest(log), "observed": {k: v["observed"] for k, v in observations.items()}}, indent=2))


def judge_regression() -> None:
    compile_dir = PRIMARY / "combined-compile-batch-582b2f13cc53"
    compile_path = compile_dir / "receipt.json"
    compile_receipt = json.loads(compile_path.read_text(encoding="utf-8-sig"))
    affected_path = PRIMARY / "combined-affected-582b2f13cc53-85033d0f.json"
    affected = json.loads(affected_path.read_text(encoding="utf-8-sig"))
    unit_path = PRIMARY / "returned-unit-582b2f13cc53-85033d0f/result.json"
    unit = json.loads(unit_path.read_text(encoding="utf-8-sig"))
    compile_log_path = compile_dir / "0.log"
    compile_log = compile_log_path.read_bytes()
    unit_log_path = Path(unit["log"])
    unit_log = unit_log_path.read_bytes()
    compile_text = compile_log.decode("utf-8", errors="replace")
    unit_text = unit_log.decode("utf-8", errors="replace")
    named = compile_receipt["compile_paths"] + ["tests/" + p for p in unit["selection"].split(",")]
    warm(named)
    bindings = []
    for name in sorted(set(named)):
        content = raw(name)
        actual = digest(content)
        checkout_crlf = digest(content.replace(b"\r\n", b"\n").replace(b"\n", b"\r\n"))
        def representation(expected):
            return "exact Git blob" if expected == actual else "Git text checkout CRLF only" if expected == checkout_crlf else None
        bindings.append({"path": name, "pinned_source_sha256": actual,
                         "checkout_CRLF_projection_sha256": checkout_crlf,
                         "compile_before_representation": representation(compile_receipt["source_before"].get(name)),
                         "unit_before_representation": representation(affected["source_before"].get(name))})
    diagnostics = [line for line in unit_text.splitlines() if re.match(r"^(?:SCRIPT ERROR|ERROR|WARNING):", line)]
    expected_warnings = [
        "WARNING: [player] grounded platform velocity 903 m/s exceeded the 120 m/s ceiling at 0.0, 0.0, 0.0; discarded",
        "WARNING: [player] velocity 903 m/s exceeded the 120 m/s ceiling at 0.0, 0.0, 0.0; clamped"]
    checks = {
        "all_executed_heads_pinned": all(d["head"] == BASE for d in [compile_receipt, affected, unit]),
        "compile_before_after_3358_unchanged": len(compile_receipt["source_before"]) == 3358 and compile_receipt["source_before"] == compile_receipt["source_after"],
        "unit_before_after_3358_unchanged": len(affected["source_before"]) == 3358 and affected["source_before"] == affected["source_after"],
        "named_source_blobs_match_both_wrappers": all(b["compile_before_representation"] and b["unit_before_representation"] for b in bindings),
        "compile_raw_hash_matches": digest(compile_log) == compile_receipt["runs"][0]["raw_sha256"],
        "compile_33_exact_cases_and_terminal": [line.removeprefix("COMPILE_CASE|") for line in compile_text.splitlines() if line.startswith("COMPILE_CASE|")] == compile_receipt["compile_paths"] and "COMPILE_BATCH|33 files|0 unavailable" in compile_text,
        "compile_exit0_no_declared_or_strict_errors": compile_receipt["runs"][0]["exit"] == 0 and not compile_receipt["runs"][0]["errors"] and not re.search(r"^(SCRIPT ERROR|ERROR|WARNING):", compile_text, re.M),
        "unit_raw_hash_matches": digest(unit_log) == unit["raw_log_sha256"],
        "unit_44_317_zero_terminal": "44 tests, 317 assertions, 0 failed" in unit_text and unit["summary"] == ["44 tests, 317 assertions, 0 failed"],
        "unit_exit0_not_timed_out": unit["exit"] == 0 and unit["timed_out"] is False and affected["wrapper_exit"] == 0,
        "unit_only_two_expected_runaway_negative_fixture_warnings": diagnostics == expected_warnings and "player._fall_speed = 903.0" in source("tests/test_player_runaway_velocity_guard.gd") and "Vector3(0.0, -903.0, 0.0)" in source("tests/test_player_runaway_velocity_guard.gd"),
        "both_wrappers_report_zero_engine_handles": str(compile_receipt["engine_handles_after"]) == "0" and str(affected["engine_handles_after"]) == "0",
    }
    report = {**stamp(), "actual_executed_commit": BASE, "platform": "ROOT returned Windows headless Godot4.7; no reviewer engine execution",
              "input": "check-only compile and instrumented named unit contracts; no player/controller sequence",
              "scope": "33 listed compile roots and44 tests/317 assertions in ten selected files only; not full-suite, CI, paid producer, M1, F48, F49 or pixels",
              "checks": checks, "named_source_bindings": bindings, "compile_metadata": {k: v for k, v in compile_receipt.items() if k not in {"source_before", "source_after"}},
              "unit_metadata": unit, "source_snapshot_limit": "3358 before/after recorded entries compared;35 named source blobs independently bound to pinned Git, with any exact CRLF checkout projection disclosed per path. Other entries are unchanged wrapper claims, not individually re-read by this reviewer.",
              "unit_strict_diagnostics": diagnostics, "diagnostic_binding": "Both903m/s warning lines are emitted by the explicitly authored grounded/airborne negative fixtures in test_player_runaway_velocity_guard.gd; retained rather than removed from raw proof.",
              "independent_verdict": "BOUNDED_NATIVE_REGRESSION_PASS" if all(checks.values()) else "OPEN_INCONSISTENT_RETURN",
              "members": [seal_copy(compile_path, "compile582b-receipt.json.gz"), seal_copy(compile_log_path, "compile582b-0.log.gz"),
                          seal_copy(affected_path, "unit582b-source-snapshots.json.gz"), seal_copy(unit_path, "unit582b-result.json.gz"), seal_copy(unit_log_path, "unit582b-tests.log.gz")]}
    dump("regression582b-independent-judgment.json", report)
    print(json.dumps({"regression": report["independent_verdict"], "checks": checks, "named_source_bindings": len(bindings), "unit_diagnostics": len(report["unit_strict_diagnostics"])}, indent=2))


def judge_vfx_selected() -> None:
    folder = "ralph/reports/VFX/f25/native-selected-r17"
    manifest = data(folder + "/originals-manifest.json")
    warm([folder + "/" + m["file"] for m in manifest])
    members = [{**m, "actual_git_blob_sha256": digest(raw(folder + "/" + m["file"])),
                "sha256_matches": digest(raw(folder + "/" + m["file"])) == m["sha256"],
                "length_matches": len(raw(folder + "/" + m["file"])) == m["bytes"]} for m in manifest]
    receipt = data(folder + "/native-receipt.json")
    result = data(folder + "/results.json")
    case = result["cases"][0]
    checks = {"13_original_member_hashes_and_lengths": len(members) == 13 and all(m["sha256_matches"] and m["length_matches"] for m in members),
              "single_selected_case_only": len(result["cases"]) == 1 and result["selected_identity"] == "small-stones:r1",
              "native_exit0_without_watchdog_or_declared_errors": receipt["exit_code"] == 0 and receipt["timed_out"] is False and not receipt["errors"] and not result["failures"],
              "actual_lease_zero_before_cleanup": case["end_slots"] == 0 and case["peak_slots"] == 42,
              "same_clock_original_allowance": case["arrival_process_frames"] == [78] and case["independent_schedule_process_frame"] == 78 and case["end_process_frame"] == 101 and case["lifetime_allowance_seconds"] == 2.42 and case["wall_watchdog_expired"] is False,
              "18_actual_node_preflights": result["light_lifecycle"]["check_count"] == 18 and all(result["light_lifecycle"]["checks"].values()),
              "source_unchanged_and_zero_processes_reported": receipt["source_unchanged"] is True and not receipt["godot_processes_remaining"]}
    report = {**stamp(), "actual_executed_commit": receipt["source_commit"], "actual_package_hash": None,
              "platform": {"engine": result["engine"], "renderer": result["renderer"], "adapter": result["adapter"], "resolution": result["resolution"]},
              "input": "synthetic production effect nodes; posed production Mudsnout body; fixed30fps movie with0.7s travel",
              "checks": checks, "members": members, "native": receipt, "selected_case": case,
              "independent_verdict": "ONE_SELECTED_NATIVE_LIFETIME_CASE_PASS" if all(checks.values()) else "OPEN_INCONSISTENT_RETURN",
              "scope": "Original r14 RED preserved; selected r17 ends its lease within original allowance. This is not a code-blind art judgment or a proof of historical failure cause.",
              "honest_gap": "Other identity cases/full craft, real player/contact→HP/audio, active production library, mastery matrix, four-creature Medium timing, peers and Ally remain open. Empty cpu_process_ms/wall_frame_ms arrays are not performance samples;p95/p99 zero does not prove frame time.",
              "criterion_verdicts": {"F25#0": "OPEN", "F25#2": "OPEN", "F25#3": "OPEN", "F25#4": "OPEN", "F25#5": "OPEN"},
              "prior_failure_artifact": "ralph/reports/VFX/f25/native-identities-r14", "visual_verdict_issued": False}
    dump("vfx-r17-independent-scope-judgment.json", report)
    print(json.dumps({"vfx": report["independent_verdict"], "checks": checks}, indent=2))


def blobs_at(commit: str, names: list[str]) -> dict[str, bytes]:
    output = subprocess.check_output(["git", "-C", str(ROOT), "cat-file", "--batch"],
                                     input="".join(f"{commit}:{p}\n" for p in names).encode())
    cursor = 0
    result = {}
    for name in names:
        end = output.index(b"\n", cursor)
        header = output[cursor:end].split()
        if header[-1] == b"missing": raise ValueError(f"Missing executed source {commit}:{name}")
        size = int(header[-1])
        result[name] = output[end+1:end+1+size]
        cursor = end + size + 2
    return result


def judge_data_native() -> None:
    folder = PRIMARY / "criterion-data-native-e2cc41923679"
    receipt_path = folder / "receipt.json"
    native = json.loads(receipt_path.read_text(encoding="utf-8-sig"))
    executed = native["executed_head"]
    log_path = folder / "native.log"
    log = log_path.read_bytes()
    lines = log.decode("utf-8", errors="strict").splitlines()
    markers = [json.loads(line.removeprefix("CRITERION_DATA_NATIVE_RESULT ")) for line in lines if line.startswith("CRITERION_DATA_NATIVE_RESULT ")]
    result = markers[0] if len(markers) == 1 else {}
    probe_name = native["script"]
    members = blobs_at(executed, sorted(set(native["source_before"]) | {probe_name}))
    bindings = []
    for name, expected in native["source_before"].items():
        value = members[name]
        actual = digest(value)
        projected = digest(value.replace(b"\r\n", b"\n").replace(b"\n", b"\r\n"))
        method = "exact Git blob" if actual == expected else "Git text checkout CRLF only" if projected == expected else None
        bindings.append({"path": name, "executed_git_blob_sha256": actual, "recorded_before_sha256": expected,
                         "recorded_after_sha256": native["source_after"].get(name), "CRLF_projection_sha256": projected,
                         "binding_method": method})
    probe = members[probe_name]
    probe_git_sha = digest(probe)
    probe_crlf_sha = digest(probe.replace(b"\r\n", b"\n").replace(b"\n", b"\r\n"))
    source_closure_sha = digest(json.dumps(native["source_before"], sort_keys=True, separators=(",", ":")).encode())
    checks = {
        "actual_executed_head_from_receipt": executed == "e2cc4192367979e44d003038ea915971ac9d8c5b",
        "raw_hash_and_length_match": digest(log) == native["raw_sha256"] and len(log) == native["raw_bytes"],
        "one_complete_result_matches_receipt": len(markers) == 1 and markers == native["results"] and result.get("completed") is True and result.get("failures") == [],
        "original_watchdog_and_exit0": native["watchdog_seconds"] == 240 and 0 < native["elapsed_seconds"] < 240 and native["exit"] == 0,
        "no_declared_or_raw_strict_errors": native["errors"] == [] and not any(re.match(r"^(?:SCRIPT ERROR|ERROR|WARNING):", line) for line in lines),
        "zero_engine_handles_reported": str(native["engine_handles_after"]) == "0",
        "probe_hash_bound_to_executed_git": native["script_sha256"] in {probe_git_sha, probe_crlf_sha},
        "whole3365_source_before_after_identical": len(native["source_before"]) == 3365 and native["source_before"] == native["source_after"],
        "whole3365_source_bound_to_executed_git": len(bindings) == 3365 and all(b["binding_method"] for b in bindings),
        "fixture_constant_not_misused_as_actual_head": result.get("fixture_source_commit") == BASE and executed != BASE,
        "69_live_10_utility_19_shared": [result.get(k) for k in ["live_species", "utility_count", "shared_count"]] == [69, 10, 19],
        "all5_and_unmodified_JSON_saved_carriers": result.get("breakthrough_prefixes_checked") == [1, 2, 3, 4, 5] and result.get("breakthrough_representations") == ["native integers", "unmodified JSON-restored arrays", "unmodified JSON-restored saved character carrier through allowed_saved_moves"],
        "expected_exact_scope_counts": result.get("checks_by_criterion") == {"F23#1": 3140, "F23#2": 350, "F35#0": 307, "F25#1": 95},
        "same_evidence_probe_91b0077b48": probe == git("show", "91b0077b48e90ebc8f3c0802b35b2bc3e65c6bae:" + probe_name),
    }
    verdicts = {
        "F23#1": {"verdict": "PARTIAL_NATIVE_PASS_TM_PRODUCTION_USE_OPEN", "checks": 3140,
                  "passed": "Every live species learnset; L5/L15 gates; all5 native and unmodified JSON completed/preceding prefixes; exact no-future-leak sets; actual saved-carrier allowed_saved_moves; primary-type-only can_learn compatibility for every TM/type.",
                  "gap": "Probe calls can_learn, not actual stage_tm_knowledge/stage_tm_candidate or owned TM debit/use. 'TMs still work' remains unproved by this run. No persisted or earned breakthrough proof."},
        "F23#2": {"verdict": "SUFFICIENT_NATIVE_POLICY_PASS_PENDING_GREEN_MAIN_LANDING", "checks": 350,
                  "passed": "Ten registered utilities; all four authored roles; every one of69 actual live species has at least two L15 choices; each choice accepted by production stage_loadout_edit and refused out of reach.",
                  "gap": "None for this bounded catalogue/equip-policy criterion; fixtures are detached L15 and a synthetic host station context. It does not establish F23#0 active controller combat or F23#3 actual station/save/rejoin."},
        "F35#0": {"verdict": "SUFFICIENT_NATIVE_MAPPING_PASS_PENDING_GREEN_MAIN_LANDING", "checks": 307,
                  "passed": "Nineteen shared signatures within16..20; actual production spawn mapping for all69 live species; each non-unique signature belongs to shared set and exact primary type×learnset role.",
                  "gap": "None for the explicitly named mapping test; presentation/runtime enablement, unique performances, growth, duration and code-blind judgment belong to F35#1..#4."},
        "F25#1": {"verdict": "SUFFICIENT_NATIVE_MAPPING_PASS_PENDING_GREEN_MAIN_LANDING", "checks": 95,
                  "passed": "All94 actual production resolver mappings are nonempty; unknown archetype returns empty. Corroborates independent all-eight-parameter static mapping audit.",
                  "gap": "None for mapping; active effect rendering, visual bar, real contact/HP, mastery appearance and Medium performance remain separate criteria."},
    }
    if not all(checks.values()):
        for item in verdicts.values(): item["verdict"] = "OPEN_INCONSISTENT_RETURN"
    report = {**stamp(), "source_commit": executed, "actual_executed_commit": executed, "fixture_origin_commit": BASE,
              "actual_package_hash": None, "native_probe_sha256": native["script_sha256"], "native_raw_sha256": digest(log),
              "source_closure_canonical_sha256": source_closure_sha, "source_closure_count": len(bindings),
              "source_closure_binding_methods": {method: sum(b["binding_method"] == method for b in bindings) for method in ["exact Git blob", "Git text checkout CRLF only", None]},
              "platform": "ROOT returned Godot4.7.stable.official.5b4e0cb0f, Windows headless; detached production policy calls",
              "input": "Production lookup/spawn/equip-policy calls; native and unmodified JSON fixtures; no controller inputs",
              "shortcuts": "Detached L15 creatures and synthetic owned/reachable/Altar/not-combat context passed only to pure staging. JSON round trips are in memory. No earned progress, paid action, disk save, receipt, write, ACK, network or pixels invented.",
              "checks": checks, "result": result, "native_metadata": {k: v for k, v in native.items() if k not in {"source_before", "source_after"}},
              "production_deltas_from_fixture_origin": git("diff", "--name-only", BASE, executed, "--", "scripts", "autoload", "data").decode().splitlines(),
              "teaching_delta": git("diff", BASE, executed, "--", "scripts/creatures/teaching.gd").decode(),
              "independent_verdict": "BOUNDED_NATIVE_DATA_POLICY_PASS" if all(checks.values()) else "OPEN_INCONSISTENT_RETURN",
              "criterion_verdicts": verdicts, "main_landing_state": "No green main CI/landing returned; no MET/count credit added.",
              "members": [seal_copy(receipt_path, "criterion-e2cc-receipt.json.gz"), seal_copy(log_path, "criterion-e2cc-native.log.gz")]}
    dump("data-native-e2cc-independent-judgment.json", report)
    dump("data-native-e2cc-source-closure.json", {"executed_source_commit": executed, "canonical_snapshot_sha256": source_closure_sha, "bindings": bindings})
    print(json.dumps({"data": report["independent_verdict"], "checks": checks, "source_bindings": report["source_closure_binding_methods"], "verdicts": {k: v["verdict"] for k, v in verdicts.items()}}, indent=2))


def summaries() -> None:
    for name in ["combined-compile-batch-582b2f13cc53/receipt.json", "combined-affected-582b2f13cc53-85033d0f.json"]:
        p = PRIMARY / name
        value = json.loads(p.read_text(encoding="utf-8-sig"))
        print(json.dumps({"artifact": name, "keys": list(value), "runs": value.get("runs"), "results": value.get("results")}, indent=2)[:8000])


if __name__ == "__main__":
    import sys
    if sys.argv[1] == "sealed": audit_sealed()
    elif sys.argv[1] == "core": judge_core()
    elif sys.argv[1] == "regression": judge_regression()
    elif sys.argv[1] == "vfx": judge_vfx_selected()
    elif sys.argv[1] == "data": judge_data_native()
    elif sys.argv[1] == "summaries": summaries()
