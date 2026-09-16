#!/usr/bin/env python3
"""Generate explicit, separately budgeted segments linked by production saves.

python tools/gate_f/derive_segment_phases.py [--check] [--plan PATH]

Original step dictionaries are never edited, renamed, deleted or duplicated.
Added Save/Load steps have their own IDs and provenance. This generator does
not declare a parent PASS: runtime and inventory must validate the ordered
phase verdicts, physical save hashes, cumulative telemetry and capture debts.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
METRIC_CHECKS = {"distance_above", "route_rows_at_least", "dead_travel_below", "dead_travel_peak_above"}


def normalized_sha256(text: str) -> str:
    return hashlib.sha256(text.replace("\r\n", "\n").encode("utf-8")).hexdigest()


def planned_captures(steps: list[dict]) -> list[str]:
    ids = []
    for step in steps:
        args = step.get("args", {})
        base = args.get("id", step["id"])
        if step["action"] == "capture":
            ids.append(base)
        elif step["action"] == "capture_seq":
            count = int(max(1.0, float(args.get("hz", 5.0))) * max(0.2, float(args.get("seconds", 2.0))))
            ids.extend(f"{base}-{index:03d}" for index in range(count))
    return ids


def derive(source: dict, plan: dict, source_text: str, template_text: str | None = None) -> tuple[list[dict], dict]:
    parent = str(plan["parent"])
    if source["id"] != parent:
        raise ValueError("plan parent does not match source segment")
    steps = source["steps"]
    if source.get("evidence_lane") == "capture" and source.get("owes") != planned_captures(steps):
        raise ValueError("capture source owes must exactly match its prescribed capture IDs")
    by_id = {step["id"]: step for step in steps}
    if len(by_id) != len(steps):
        raise ValueError("original step IDs must be unique")
    phase_specs = plan["phases"]
    order = [entry["id"] for entry in phase_specs]
    folded = [name.casefold() for name in order]
    reserved = {parent.casefold(), str(source.get("capture_lane", "")).casefold()}
    if not order or len(set(folded)) != len(order) or reserved.intersection(folded):
        raise ValueError("phase IDs must be unique and distinct from parent")
    outputs = [entry["output_save"] for entry in phase_specs]
    terminal_capture = bool(plan.get("terminal_capture", False))
    if terminal_capture and (source.get("evidence_lane") != "capture" or outputs[-1] != ""):
        raise ValueError("terminal capture without output is restricted to the final capture phase")
    for index, name in enumerate(outputs):
        if not name and not (terminal_capture and index == len(outputs) - 1):
            raise ValueError("every nonterminal phase requires an output save")
    template_path = plan.get("template_source_path", "")
    if bool(template_path) != (template_text is not None):
        raise ValueError("external template text and source path must both be supplied")
    template_hash = normalized_sha256(template_text) if template_text is not None else ""
    template_steps = json.loads(template_text)["steps"] if template_text is not None else steps
    template_by_id = {step["id"]: step for step in template_steps}
    if len(template_by_id) != len(template_steps):
        raise ValueError("template step IDs must be unique")
    if len({name.casefold() for name in outputs}) != len(outputs):
        raise ValueError("phase save artifact names must be unique")
    boundaries = []
    previous = -1
    original_ids = list(by_id)
    for index, entry in enumerate(phase_specs):
        cut = entry.get("through")
        if index == len(phase_specs) - 1:
            if cut is not None:
                raise ValueError("final phase must preserve the complete remaining suffix")
            end = len(steps) - 1
        else:
            if cut not in by_id:
                raise ValueError(f"missing boundary step {cut}")
            boundary = by_id[cut]
            if boundary["action"] != "assert" or boundary.get("args") != {"check": "input_context", "equals": "world"}:
                raise ValueError(f"boundary {cut} must explicitly assert world input")
            end = original_ids.index(cut)
        if end <= previous:
            raise ValueError("phase boundaries must be increasing and nonempty")
        boundaries.append((previous + 1, end + 1))
        previous = end
    final_exports = [s["args"].get("name") for s in steps[boundaries[-1][0]:]
                     if s["action"] == "save_out"]
    if terminal_capture and final_exports:
        raise ValueError("terminal capture must not contain an undeclared exit save")
    if not terminal_capture and final_exports.count(outputs[-1]) != 1:
        raise ValueError("final phase must retain the canonical original exit save exactly once")
    # A world-context assertion does not prove that a recording window stopped.
    cuts = {end for _, end in boundaries[:-1]}
    recording = float(source.get("record_hz", 0)) > 0
    background = set()
    for position, step in enumerate(steps, 1):
        action, args = step["action"], step.get("args", {})
        if action == "record_start":
            recording = True
        elif action == "record_stop":
            recording = bool(args.get("baseline", True)) and float(source.get("record_hz", 0)) > 0
        elif action == "capture_seq" and args.get("background"):
            background.add(args.get("id", step["id"]))
        elif action == "capture_seq_complete":
            background.discard(args.get("id", ""))
        if position in cuts and (recording or background):
            raise ValueError("phase cut crosses an active recording/background capture window")
    metrics = [{"id": s["id"], "args": copy.deepcopy(s["args"])} for s in steps
               if s["action"] == "assert" and s.get("args", {}).get("check") in METRIC_CHECKS]
    signature = normalized_sha256(source_text)
    manifest_path = f"res://tools/gate_f/phase_plans/{parent}.manifest.json"
    generated = []
    all_ids = set(original_ids)

    def template(phase_id: str, kind: str, names: list[str], save_name: str) -> list[dict]:
        result = []
        for number, name in enumerate(names):
            item = copy.deepcopy(template_by_id[name])
            item["id"] = f"{phase_id}-phase-{kind}-{number:02d}"
            if item["id"] in all_ids:
                raise ValueError("phase-added ID collision")
            all_ids.add(item["id"])
            item["_phase_added"] = {"kind": kind, "template_step": name}
            if template_path:
                item["_phase_added"].update(template_source_path=template_path, template_source_sha256=template_hash)
            if item["action"] == "seed_save":
                item["args"]["from"] = f"run://{save_name}"
            elif item["action"] == "save_out":
                item["args"]["name"] = save_name
            item["expected"] = f"Explicit phase-added production {kind} seam, derived from {name}; handoff artifact {save_name}."
            result.append(item)
        required = {"seed_save", "boot", "press"} if kind == "load" else {"open_menu", "select_menu_tab", "press", "save_out"}
        if not required.issubset({item["action"] for item in result}):
            raise ValueError(f"{kind} template lacks the production handoff actions")
        return result

    for index, (entry, span) in enumerate(zip(phase_specs, boundaries)):
        phase_id = entry["id"]
        source_steps = copy.deepcopy(steps[span[0]:span[1]])
        input_save = plan["input_save"] if index == 0 else outputs[index - 1]
        prefix = template(phase_id, "load", plan["load_template_ids"], input_save) if index else []
        suffix = template(phase_id, "save", plan["save_template_ids"], outputs[index]) if index < len(order) - 1 else []
        phase = copy.deepcopy(source)
        phase["id"] = phase_id
        phase["title"] = f"{parent} phase {index + 1}/{len(order)}: {source['title']}"
        phase["steps"] = prefix + source_steps + suffix
        if source.get("evidence_lane") == "capture":
            phase["owes"] = planned_captures(source_steps)
        phase["phase"] = {
            "parent": parent, "index": index, "order": order,
            "source_path": plan["source_path"], "source_sha256": signature,
            "manifest_path": manifest_path,
            "previous_segment": order[index - 1] if index else "",
            "input_save": input_save, "output_save": outputs[index],
            "original_step_ids": [s["id"] for s in source_steps],
            "added_step_ids": [s["id"] for s in prefix + suffix],
            "aggregate_metric_checks": copy.deepcopy(metrics),
            "capture_ids": planned_captures(source_steps),
        }
        if template_path:
            phase["phase"].update(template_source_path=template_path, template_source_sha256=template_hash)
        if terminal_capture:
            phase["phase"]["terminal_capture"] = index == len(order) - 1
        generated.append(phase)
    union = [s for p in generated for s in p["steps"] if "_phase_added" not in s]
    if union != steps:
        raise ValueError("generated phases do not preserve every original step dictionary in order")
    captures = [capture for phase in generated for capture in phase["phase"]["capture_ids"]]
    if captures != planned_captures(steps):
        raise ValueError("generated phase capture debts differ from parent")
    manifest = {
        "schema_version": 1, "parent": parent, "order": order,
        "source_path": plan["source_path"], "source_sha256": signature,
        "hash_algorithm": "sha256 of UTF-8 source text with CRLF normalized to LF",
        "capture_lane": source.get("capture_lane", ""), "capture_ids": captures,
        "canonical_output_save": outputs[-1], "original_step_ids": original_ids,
        "aggregate_metric_checks": metrics,
        "phases": [copy.deepcopy(p["phase"]) for p in generated],
        "acceptance": "All ordered phase verdicts, source signatures, actual saved/loaded artifact hashes and aggregate metrics must verify; capture debts remain with the named capture lane. This manifest is not a parent PASS.",
    }
    if template_path:
        manifest.update(template_source_path=template_path, template_source_sha256=template_hash)
    if terminal_capture:
        manifest["terminal_capture"] = True
        manifest["acceptance"] = "All ordered capture phases, original steps, template/source hashes, input save chain and actual capture files must verify. Terminal capture exports no save. Raw phase evidence remains authoritative."
    return generated, manifest


def outputs_for_plan(plan_path: Path, root: Path = ROOT) -> dict[Path, str]:
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    source_path = root / plan["source_path"].removeprefix("res://")
    text = source_path.read_text(encoding="utf-8")
    template_text = (root / plan["template_source_path"].removeprefix("res://")).read_text(encoding="utf-8") if plan.get("template_source_path") else None
    phases, manifest = derive(json.loads(text), plan, text, template_text)
    outputs = {root / "tools/gate_f/segments" / f"{p['id']}.json": p for p in phases}
    outputs[root / "tools/gate_f/phase_plans" / f"{plan['parent']}.manifest.json"] = manifest
    return {path: json.dumps(doc, indent=2, ensure_ascii=False) + "\n" for path, doc in outputs.items()}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plan", type=Path, default=ROOT / "tools/gate_f/phase_plans/S03.json")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    drift = []
    for path, text in outputs_for_plan(args.plan).items():
        if args.check:
            if not path.exists() or path.read_text(encoding="utf-8") != text:
                drift.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8", newline="\n")
            print(path.relative_to(ROOT))
    if drift:
        print("phase generation drift: " + ", ".join(drift))
        return 1
    if args.check:
        print("phase definitions and manifest match their canonical source")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
