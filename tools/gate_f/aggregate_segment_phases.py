#!/usr/bin/env python3
"""Publish an explicitly labelled parent view only after proving every phase.

Raw phase telemetry stays in its own directories. This does not stitch route
or event timelines and is not a fresh unsplit execution of the parent segment.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import re
from pathlib import Path

_SPEC = importlib.util.spec_from_file_location("segment_phase_generator", Path(__file__).with_name("derive_segment_phases.py"))
GEN = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(GEN)
METRICS = ("distance_m", "dead_travel_m", "dead_travel_peak", "since_interaction_s", "trace_rows")
DELEGABLE = {"capture", "capture_seq", "capture_seq_complete", "record_start", "record_stop"}


def read(path: Path) -> dict:
    result = json.loads(path.read_text(encoding="utf-8-sig"))
    if not isinstance(result, dict):
        raise ValueError(f"not an object: {path}")
    return result


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def safe_name(value: str) -> bool:
    return isinstance(value, str) and bool(value) and value not in (".", "..") and not any(c in value for c in "/\\:")


def number(value) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and value >= 0


def clean(inv: dict) -> bool:
    steps = inv.get("steps", {})
    counts = [steps.get(key) for key in ("total", "ran", "fail", "skipped", "refused")]
    return (inv.get("complete") is True and all(number(n) and int(n) == n for n in counts)
            and steps["total"] > 0 and steps["ran"] == steps["total"]
            and all(steps[key] == 0 for key in ("fail", "skipped", "refused"))
            and not any(inv.get(key) for key in ("blocked", "derailed", "derails", "harness_errors")))


def validate_metrics(metrics: dict, previous: dict) -> None:
    if any(not number(metrics.get(key)) for key in METRICS):
        raise ValueError("missing, nonfinite or negative aggregate metrics")
    if int(metrics["trace_rows"]) != metrics["trace_rows"] or metrics["dead_travel_peak"] < metrics["dead_travel_m"]:
        raise ValueError("inconsistent aggregate metrics")
    if any(metrics[key] < previous.get(key, 0) for key in ("distance_m", "trace_rows", "dead_travel_peak")):
        raise ValueError("aggregate metrics moved backwards")


def metric_predicates(source: dict, metrics: dict) -> None:
    for step in source["steps"]:
        if step["action"] != "assert":
            continue
        args = step.get("args", {})
        check = args.get("check")
        passed = True
        if check == "distance_above":
            passed = metrics["distance_m"] >= args["metres"]
        elif check == "route_rows_at_least":
            passed = metrics["trace_rows"] >= args["rows"]
        elif check == "dead_travel_below":
            passed = metrics["dead_travel_m"] <= args["metres"]
        elif check == "dead_travel_peak_above":
            passed = metrics["dead_travel_peak"] >= args["metres"]
        if not passed:
            raise ValueError(f"aggregate metric predicate failed: {step['id']} {check}")


def external_input(run: Path, filename: str, expected_hash: str, excluded: list[str]) -> dict:
    if not safe_name(filename) or not re.fullmatch(r"[0-9a-f]{64}", expected_hash):
        raise ValueError("invalid initial input save declaration/hash")
    candidates = [p for p in run.rglob(filename) if p.is_file() and p.parent.name == "saves"
                  and p.relative_to(run).parts[0] not in excluded]
    if not candidates or any(sha(path) != expected_hash for path in candidates):
        raise ValueError("initial external input save is missing, ambiguous or has a different hash")
    origins = []
    for path in sorted(candidates):
        inv_path = path.parent.parent / "INVENTORY.json"
        inv = read(inv_path) if inv_path.exists() else {}
        origins.append({"save_path": str(path.relative_to(run)), "save_sha256": expected_hash,
                        "source_revision": inv.get("sha"),
                        "source_inventory_path": str(inv_path.relative_to(run)) if inv_path.exists() else None,
                        "source_inventory_sha256": sha(inv_path) if inv_path.exists() else None})
    return {"origins": origins, "revision_policy": "Inherited prefix revision is recorded explicitly; only the generated phases must share one frozen revision."}


def collect(run: Path, definitions: Path, parent: str) -> dict:
    if not safe_name(parent):
        raise ValueError("unsafe parent ID")
    source_path = definitions / "segments" / f"{parent}.json"
    source_text = source_path.read_text(encoding="utf-8")
    source = json.loads(source_text)
    plan = read(definitions / "phase_plans" / f"{parent}.json")
    if source.get("id") != parent or plan.get("parent") != parent:
        raise ValueError("source/plan parent differs from requested aggregate")
    expected_phases, expected_manifest = GEN.derive(source, plan, source_text)
    manifest = read(definitions / "phase_plans" / f"{parent}.manifest.json")
    if manifest != expected_manifest:
        raise ValueError("phase manifest differs from canonical generated source contract")
    order = manifest["order"]
    source_hash = GEN.normalized_sha256(source_text)
    coverage, receipts, delegated = [], [], []
    revision = previous_output_hash = ""
    previous_metrics = {}
    final_save = None
    input_provenance = {}
    for index, expected_phase in enumerate(expected_phases):
        name = expected_phase["id"]
        if not safe_name(name):
            raise ValueError("unsafe phase ID")
        phase = read(definitions / "segments" / f"{name}.json")
        if phase != expected_phase:
            raise ValueError(f"{name}: generated phase differs from canonical source/templates")
        declaration = phase["phase"]
        if not safe_name(declaration["input_save"]) or not safe_name(declaration["output_save"]):
            raise ValueError("unsafe save filename")
        coverage.extend(declaration["original_step_ids"])
        folder = run / name
        inv_path = folder / "INVENTORY.json"
        inv = read(inv_path)
        if not clean(inv) or inv.get("segment") != name or inv["steps"]["total"] != len(phase["steps"]):
            raise ValueError(f"{name}: incomplete, failed or mismatched phase step count")
        if not revision:
            revision = inv.get("sha", "")
        if not revision or inv.get("sha") != revision:
            raise ValueError(f"{name}: mixed source revisions")
        receipt = inv.get("phase", {})
        if any(receipt.get(key) != value for key, value in declaration.items()):
            raise ValueError(f"{name}: inventory declaration differs from canonical phase")
        input_hash = receipt.get("input_sha256", "")
        if index == 0:
            input_provenance = external_input(run, declaration["input_save"], input_hash, order + [parent])
        elif input_hash != previous_output_hash or declaration["input_save"] != expected_phases[index - 1]["phase"]["output_save"]:
            raise ValueError(f"{name}: input save breaks continuity")
        final_save = folder / "saves" / declaration["output_save"]
        previous_output_hash = sha(final_save)
        if receipt.get("output_sha256") != previous_output_hash:
            raise ValueError(f"{name}: output save hash mismatch")
        metrics = receipt.get("metrics", {})
        validate_metrics(metrics, previous_metrics)
        previous_metrics = metrics
        captures = inv.get("captures", {})
        if (captures.get("delegated") != declaration["capture_ids"]
                or captures.get("delegated_to") != source.get("capture_lane")
                or inv.get("evidence_lane") != "logic"):
            raise ValueError(f"{name}: missing or altered delegated capture debt")
        delegated.extend(captures["delegated"])
        events_path = folder / "telemetry/events.jsonl"
        events = [json.loads(line) for line in events_path.read_text(encoding="utf-8").splitlines() if line.strip()]
        notes_path = folder / "notes" / f"{name}.md"
        blocks = re.findall(r"^### (\S+) — .*?\n(.*?)(?=^### |\Z)", notes_path.read_text(encoding="utf-8"), re.M | re.S)
        if [row[0] for row in blocks] != [s["id"] for s in phase["steps"]]:
            raise ValueError(f"{name}: notes do not prove every phase step in order")
        verdicts = []
        for (step_id, body), step in zip(blocks, phase["steps"]):
            found = re.findall(r"^- verdict: (\S+)\s*$", body, re.M)
            wanted = "DELEGATED" if step["action"] in DELEGABLE else "PASS"
            if found != [wanted]:
                raise ValueError(f"{name}: invalid step verdict for {step_id}; expected {wanted}")
            verdicts.append((step_id, found[0]))
        receipts.append({"segment": name, "inventory_path": str(inv_path.relative_to(run)),
                         "inventory_sha256": sha(inv_path), "events_path": str(events_path.relative_to(run)),
                         "events_sha256": sha(events_path), "event_count": len(events),
                         "notes_path": str(notes_path.relative_to(run)), "notes_sha256": sha(notes_path),
                         "step_verdicts": verdicts, "input_sha256": input_hash,
                         "output_save_path": str(final_save.relative_to(run)),
                         "output_sha256": previous_output_hash, "metrics": metrics})
    if coverage != [s["id"] for s in source["steps"]] or delegated != GEN.planned_captures(source["steps"]):
        raise ValueError("phase union does not exactly cover original steps and capture debts")
    if manifest["canonical_output_save"] != f"{parent}-exit.json":
        raise ValueError("final phase does not export the canonical parent exit filename")
    metric_predicates(source, previous_metrics)
    return {"parent": parent, "execution": "save_linked_phases", "sha": revision,
            "source_sha256": source_hash, "manifest": manifest, "order": order,
            "input_provenance": input_provenance, "receipts": receipts,
            "original_step_ids": coverage, "delegated_captures": delegated,
            "metrics": previous_metrics, "exit_save_source": str(final_save.relative_to(run)),
            "exit_save_sha256": previous_output_hash,
            "analytics": {"stitched_telemetry": False,
                          "note": "Raw phase paths are authoritative. No parent route.csv, stitched events or unsplit-execution claim is created."}}


def publish(run: Path, definitions: Path, parent: str) -> dict:
    target = run / parent
    if target.exists():
        raise ValueError(f"refusing to overwrite existing evidence: {target}")
    result = collect(run, definitions, parent)
    # Capture immutable bytes and recheck before publishing. Do not claim the
    # earlier hash if the final save changed while evidence was being verified.
    final_bytes = (run / result["exit_save_source"]).read_bytes()
    if hashlib.sha256(final_bytes).hexdigest() != result["exit_save_sha256"]:
        raise ValueError("canonical exit save changed during verification")
    target.mkdir(parents=True, exist_ok=False)
    (target / "saves").mkdir()
    with (target / "saves" / f"{parent}-exit.json").open("xb") as handle:
        handle.write(final_bytes)
    (target / "PHASE_AGGREGATE.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    count = len(result["original_step_ids"])
    inventory = {"segment": parent, "execution": result["execution"], "sha": result["sha"],
                 "complete": True, "evidence_lane": "logic", "aggregate": result,
                 "blocked": "", "derailed": "", "derails": [], "harness_errors": [],
                 "steps": {"total": count, "ran": count, "fail": 0, "refused": 0, "skipped": 0},
                 "captures": {"planned": 0, "present": 0, "absent": 0, "rows": [],
                              "delegated": result["delegated_captures"],
                              "delegated_to": result["manifest"]["capture_lane"]}}
    # Publish the completion marker last; partial output is never a complete run.
    (target / "INVENTORY.json").write_text(json.dumps(inventory, indent=2) + "\n", encoding="utf-8")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run", type=Path)
    parser.add_argument("--parent", default="S03")
    parser.add_argument("--definitions", type=Path, default=Path(__file__).resolve().parent)
    args = parser.parse_args()
    result = publish(args.run, args.definitions, args.parent)
    print(f"Verified {len(result['order'])} phases; {len(result['original_step_ids'])} original steps; capture debts remain delegated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
