"""Validate evidence references and produce a bounded closure forecast.

Offline artifact QA only; never launches engine/tests or changes the board.
"""
from __future__ import annotations

import gzip
import hashlib
import json
from source_audit import BASE, OUT, dump, git, stamp
from judge_returned import blobs_at


def read(name: str):
    return json.loads((OUT / name).read_text(encoding="utf-8"))


def main() -> None:
    mapped = read("criteria-evidence-map.json")
    board = read("board-snapshot.json")
    expected = {f'{f["id"]}#{i}': c["text"] for f in board["rows"] for i, c in enumerate(f["criteria"])}
    actual = {c["id"]: c["requirement"] for c in mapped["criteria"]}
    requests = read("run-requests.json")
    request_ids = {r["id"] for r in requests["requests"]}
    anchors = {(a["source_commit"], a["path"]): a for c in mapped["criteria"] for a in c["source_anchors"] if a["present"]}
    source_by_head = {}
    for head in sorted({h for h, _ in anchors}):
        source_by_head[head] = blobs_at(head, sorted(p for h, p in anchors if h == head))
    bad_anchors = [{"head": h, "path": p} for (h, p), a in anchors.items()
                   if hashlib.sha256(source_by_head[h][p]).hexdigest() != a["sha256_git_blob_content"]]
    missing_artifacts = []
    unknown_requests = []
    for c in mapped["criteria"]:
        for proof in c["independent_evidence"]:
            for key in ["artifact", "source_closure_artifact"]:
                if key in proof and not (OUT / proof[key]).is_file(): missing_artifacts.append({"id": c["id"], "path": proof[key]})
        unknown_requests += [{"id": c["id"], "request": r} for r in c["needed_proof"]["named_run_request_ids"] if r not in request_ids]
    sealed = []
    for judgment in ["core582b-independent-judgment.json", "regression582b-independent-judgment.json", "data-native-e2cc-independent-judgment.json"]:
        for member in read(judgment)["members"]:
            compressed = (OUT / member["copy"]).read_bytes()
            unpacked = gzip.decompress(compressed)
            sealed.append({"judgment": judgment, "path": member["copy"],
                           "raw_sha256_matches": hashlib.sha256(unpacked).hexdigest() == member["raw_sha256"],
                           "gzip_sha256_matches": hashlib.sha256(compressed).hexdigest() == member["gzip_sha256"],
                           "raw_length_matches": len(unpacked) == member["raw_bytes"]})
    changed = set(git("diff", "--name-only", BASE).decode().splitlines())
    changed.update(git("ls-files", "--others", "--exclude-standard").decode().splitlines())
    prefix = "ralph/reports/INTEGRATION/criterion-closeout/"
    data = read("data-native-e2cc-independent-judgment.json")
    quality_checks = {
        "all280_exact_ids_and_requirements": len(actual) == len(mapped["criteria"]) == 280 and actual == expected,
        "original101_redesign179": sum(int(c["id"].split("#")[0][1:]) <= 15 for c in mapped["criteria"]) == 101,
        "all_source_anchors_present_and_hash_bound": not bad_anchors and all(a["present"] for c in mapped["criteria"] for a in c["source_anchors"]),
        "all_artifact_links_exist": not missing_artifacts,
        "all_run_request_references_resolve": not unknown_requests,
        "all9_new_lossless_return_copies_match": len(sealed) == 9 and all(all(m[k] for k in ["raw_sha256_matches", "gzip_sha256_matches", "raw_length_matches"]) for m in sealed),
        "data_native_complete_independent_source_binding": data["independent_verdict"] == "BOUNDED_NATIVE_DATA_POLICY_PASS" and all(data["checks"].values()),
        "no_new_acceptance_credit": all(c["acceptance_credit_added"] == 0 for c in mapped["criteria"]),
        "all_lane_changes_evidence_only": bool(changed) and all(p.startswith(prefix) for p in changed),
    }
    report = {**stamp(), "artifact_kind": "offline evidence QA", "checks": quality_checks,
              "source_anchor_pairs_rehashed": len(anchors), "bad_source_anchors": bad_anchors,
              "missing_artifacts": missing_artifacts, "unknown_run_requests": unknown_requests,
              "lossless_return_members": sealed, "changed_paths": sorted(changed),
              "verdict": "PASS" if all(quality_checks.values()) else "OPEN_EVIDENCE_INCONSISTENCY"}
    dump("evidence-quality-recheck.json", report)
    sufficient = [{"id": c["id"], "verdict": c["independent_verdict"],
                   "proofs": [p["artifact"] for p in c["independent_evidence"]], "honest_gap": c["honest_gap"]}
                  for c in mapped["criteria"] if c["independent_verdict"].startswith("SUFFICIENT_")]
    forecast = {**stamp(), "artifact_kind": "criterion closure forecast with bounded independent verdicts",
                "quality_recheck": report["verdict"], "latest_reviewed_native_source": data["actual_executed_commit"],
                "board_historical": {"accepted": 110, "total": 280, "original": "95/101", "redesign": "15/179", "fresh_rechecks_of_prior110": 0},
                "independently_sufficient_new_rows_pending_green_main": sufficient, "sufficient_new_row_count": len(sufficient),
                "added_MET_now": 0, "current_confirmed_main_landing": "No green main build/landing returned to this lane.",
                "conditional_count_arithmetic": {"if_existing110_remain_relevant_and_all4_independent_rows_land_green": "114/280 (95/101 original;19/179 redesign)",
                                                 "limit": "Arithmetic only; neither existing110 relevance nor main green is newly certified by this evidence lane."},
                "partial_rows": [
                    {"id": "F23#1", "passed": "All69 learnsets, L5/L15, all5 native+unmodified JSON prefix/carrier cases and primary compatibility.",
                     "remaining": "New knowledge-only TM consumer binding and successful owned teaching/debit/use. Existing test_moves exercises retired Teaching.teach auto-equip and cannot substitute. No new planner microtest alone establishes actual paid use."},
                    {"id": "F29#4", "passed": "No forbidden572 wild references; six positive-weight Cannonback Water-alias pools and three Stormcapra pools bound to live provider source; prior-main weights/unlocks/site IDs retained.",
                     "remaining": "Live provider/unlock/physical site resolution not exercised. Namespace is water_cannonback in Water; base evolution Cannonback is distinct and not silently merged."},
                    {"id": "F17#4", "passed": "Actual Mira cycle1 and all three equipped Wood/Stone/Fiber gathers at582b.",
                     "remaining": "Whole CORE failed at Oskar; reviewed route repair still needs original actual rerun. M1 additionally needs full camp/three-bed/three played tournament rounds and all three starter witnesses."}],
                "larger_remaining_gates": [
                    "F48 authentic saved inputs, paid Forge/Altar/feed, guest Master and actual host/owner write/ACK/disconnect/restart boundaries are still open; first paid Altar return failed.",
                    "F49 has no passing continuous four-biome save-to-credits witness. Source helpers and inactive flags cannot replace it.",
                    "Current combat bands/named fights require new timing distributions and C2/C3 proof; pre448/450 results are stale.",
                    "Full High/Medium BarsA/B biome, creature, VFX, ultimate and UI pixel/motion judgments remain open. Selected VFX r17 lifetime PASS leaves original r14 RED and all omitted scopes retained.",
                    "Owner human play, owner ROG Ally/renderer authorization and a current passing published download remain distinct unclaimed gates."],
                "forecast": "Four additional rows have reviewable sufficient evidence. This is not a forecast that all170 historical open criteria can close in this batch.",
                "integrity_counts": {"historical_native_inventory": 95, "paired_declared_raw_hashes_matched": 79, "unpaired_not_called_hash_verified": 16,
                                     "prior_sealed_gzips_CRC_valid": 296, "prior_sealed_gzips_matching_raw_manifest": 75,
                                     "new_lossless_return_copies_hash_verified": 9, "VFXr17_original_members_hash_verified": 13,
                                     "latest_native_source_entries_bound": 3365},
                "execution_limit": "No engine/import/GPU/network/test execution launched by this lane; ROOT owns serialized execution under RENDER_LOCK. No production/board/STATE/workflow modifications or main push."}
    dump("closure-forecast.json", forecast)
    print(json.dumps({"quality": report["verdict"], "checks": quality_checks, "source_anchor_pairs": len(anchors),
                      "sufficient": [c["id"] for c in sufficient], "added_MET": 0}, indent=2))
    if not all(quality_checks.values()): raise SystemExit(1)


if __name__ == "__main__":
    main()
