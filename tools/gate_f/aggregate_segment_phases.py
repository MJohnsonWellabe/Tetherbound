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
import struct
import zlib
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


def png_evidence(folder: Path, relative: str, run: Path) -> dict:
    if not isinstance(relative, str) or not relative or "\\" in relative:
        raise ValueError("invalid capture path")
    path = (folder / relative).resolve()
    if not path.is_relative_to(folder.resolve()) or path.suffix.lower() != ".png":
        raise ValueError("capture path escapes phase or is not PNG")
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("capture is not a real PNG")
    offset, types, compressed, dimensions, pixel_format = 8, [], bytearray(), None, None
    while offset < len(data):
        if offset + 12 > len(data):
            raise ValueError("truncated PNG chunk")
        size, kind = struct.unpack_from(">I4s", data, offset)
        end = offset + 12 + size
        if end > len(data):
            raise ValueError("truncated PNG payload")
        payload = data[offset + 8:end - 4]
        checksum = struct.unpack_from(">I", data, end - 4)[0]
        if zlib.crc32(kind + payload) & 0xffffffff != checksum:
            raise ValueError("PNG CRC mismatch")
        types.append(kind)
        if kind == b"IHDR":
            if size != 13:
                raise ValueError("invalid PNG header")
            dimensions = struct.unpack_from(">II", payload)
            pixel_format = struct.unpack_from(">BBBBB", payload, 8)
        elif kind == b"IDAT":
            compressed.extend(payload)
        offset = end
        if kind == b"IEND":
            if size or offset != len(data):
                raise ValueError("invalid PNG end")
            break
    if (not types or types[0] != b"IHDR" or types[-1] != b"IEND" or types.count(b"IHDR") != 1
            or not dimensions or min(dimensions) <= 0 or not compressed):
        raise ValueError("PNG structure is incomplete")
    try:
        decoder = zlib.decompressobj()
        pixels = decoder.decompress(compressed) + decoder.flush()
        if not decoder.eof or decoder.unused_data or decoder.unconsumed_tail:
            raise ValueError("PNG pixel stream contains incomplete or trailing data")
        bits, color, compression, filtering, interlace = pixel_format
        channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(color, 0)
        depths = {0: (1, 2, 4, 8, 16), 2: (8, 16), 3: (1, 2, 4, 8), 4: (8, 16), 6: (8, 16)}
        if bits not in depths.get(color, ()) or compression or filtering or interlace:
            raise ValueError("unsupported or invalid capture PNG format (expected noninterlaced engine PNG)")
        if color == 3 and b"PLTE" not in types:
            raise ValueError("indexed PNG has no palette")
        stride = (dimensions[0] * channels * bits + 7) // 8 + 1
        if len(pixels) != stride * dimensions[1] or any(pixels[i] > 4 for i in range(0, len(pixels), stride)):
            raise ValueError("PNG pixel rows do not match its dimensions")
    except zlib.error as error:
        raise ValueError("PNG pixel stream is corrupt") from error
    return {"file": path.relative_to(run.resolve()).as_posix(), "bytes": len(data),
            "sha256": hashlib.sha256(data).hexdigest(), "width": dimensions[0], "height": dimensions[1]}


def verify_captures(run: Path, folder: Path, phase: dict, inv: dict) -> tuple[list[dict], list[dict]]:
    ids = phase["phase"]["capture_ids"]
    caps = inv.get("captures", {})
    rows = caps.get("rows", [])
    if (inv.get("evidence_lane") != "capture" or caps.get("delegated")
            or caps.get("owes") != ids or caps.get("planned") != len(ids)
            or caps.get("present") != len(ids) or caps.get("absent") != 0
            or [r.get("id") for r in rows] != ids or len(ids) != len(set(ids))):
        raise ValueError("capture inventory does not exactly pay its original capture IDs")
    if inv.get("uncommittable") or inv.get("preflight", {}).get("degraded_why"):
        raise ValueError("capture evidence is degraded or uncommittable")
    shots = read(folder / "shots/manifest.json").get("shots", [])
    if [r.get("id") for r in shots] != ids:
        raise ValueError("shot manifest does not match exact capture IDs")
    planned = {}
    for step in phase["steps"]:
        for shot_id in GEN.planned_captures([step]):
            planned[shot_id] = step
    verified, seen = [], set()
    for row, shot in zip(rows, shots):
        step = planned[row["id"]]
        if (row.get("exists") is not True or row.get("reason") or row.get("degenerate")
                or shot.get("reason") or shot.get("degenerate") or row.get("git_ignored_by")
                or row.get("file") != shot.get("file") or row.get("step") != step["id"]
                or row.get("action") != step["action"]):
            raise ValueError("capture row is missing, degraded or attributed to the wrong step")
        proof = png_evidence(folder, row["file"], run)
        if row.get("bytes") != proof["bytes"] or proof["file"] in seen:
            raise ValueError("capture bytes mismatch or duplicate file reuse")
        seen.add(proof["file"])
        verified.append(dict(row, **proof, raw_phase=phase["id"]))
    for step in phase["steps"]:
        if step["action"] == "capture_seq" and step.get("args", {}).get("background"):
            sequence = inv.get("capture_sequences", {}).get(step["args"].get("id", step["id"]), {})
            if sequence.get("verified") is not True:
                raise ValueError("background capture sequence lacks completed verification")
    ledger = read(folder / "frames/manifest.json")
    frames = ledger.get("frames", [])
    stats = inv.get("frames", {})
    if (stats.get("absent") != 0 or ledger.get("absent") != 0 or stats.get("delegated_windows")
            or stats.get("written") != len(frames) or ledger.get("written") != len(frames)):
        raise ValueError("continuous frame ledger is incomplete")
    if (float(phase.get("record_hz", 0)) > 0 or any(s["action"] == "record_start" for s in phase["steps"])) and not frames:
        raise ValueError("required recording window has no real frames")
    frame_proofs = []
    for frame in frames:
        if frame.get("reason") or frame.get("segment") != phase["id"]:
            raise ValueError("invalid continuous frame attribution")
        proof = png_evidence(folder, frame.get("file"), run)
        if proof["file"] in seen:
            raise ValueError("continuous frame reuses another capture file")
        seen.add(proof["file"])
        frame_proofs.append(dict(frame, **proof, raw_phase=phase["id"]))
    return verified, frame_proofs


def collect(run: Path, definitions: Path, parent: str) -> dict:
    if not safe_name(parent):
        raise ValueError("unsafe parent ID")
    source_path = definitions / "segments" / f"{parent}.json"
    source_text = source_path.read_text(encoding="utf-8")
    source = json.loads(source_text)
    plan = read(definitions / "phase_plans" / f"{parent}.json")
    if source.get("id") != parent or plan.get("parent") != parent:
        raise ValueError("source/plan parent differs from requested aggregate")
    template_text = None
    if plan.get("template_source_path"):
        prefix = "res://tools/gate_f/segments/"
        filename = plan["template_source_path"].removeprefix(prefix)
        if not plan["template_source_path"].startswith(prefix) or not safe_name(filename):
            raise ValueError("unsupported external template source path")
        template_text = (definitions / "segments" / filename).read_text(encoding="utf-8")
    expected_phases, expected_manifest = GEN.derive(source, plan, source_text, template_text)
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
    capture_lane = source.get("evidence_lane") == "capture"
    capture_rows, frame_rows = [], []
    for index, expected_phase in enumerate(expected_phases):
        name = expected_phase["id"]
        if not safe_name(name):
            raise ValueError("unsafe phase ID")
        phase = read(definitions / "segments" / f"{name}.json")
        if phase != expected_phase:
            raise ValueError(f"{name}: generated phase differs from canonical source/templates")
        declaration = phase["phase"]
        terminal = declaration.get("terminal_capture") is True
        if not safe_name(declaration["input_save"]) or (not terminal and not safe_name(declaration["output_save"])):
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
        if terminal:
            final_save = None
            if receipt.get("output_sha256", ""):
                raise ValueError("terminal capture must not claim an output save hash")
        else:
            final_save = folder / "saves" / declaration["output_save"]
            previous_output_hash = sha(final_save)
            if receipt.get("output_sha256") != previous_output_hash:
                raise ValueError(f"{name}: output save hash mismatch")
        metrics = receipt.get("metrics", {})
        validate_metrics(metrics, previous_metrics)
        previous_metrics = metrics
        captures = inv.get("captures", {})
        if capture_lane:
            shots, frames = verify_captures(run, folder, phase, inv)
            capture_rows.extend(shots)
            frame_rows.extend(frames)
        elif (captures.get("delegated") != declaration["capture_ids"]
                or captures.get("delegated_to") != source.get("capture_lane")
                or inv.get("evidence_lane") != "logic"):
            raise ValueError(f"{name}: missing or altered delegated capture debt")
        if not capture_lane:
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
            wanted = "DELEGATED" if not capture_lane and step["action"] in DELEGABLE else "PASS"
            if found != [wanted]:
                raise ValueError(f"{name}: invalid step verdict for {step_id}; expected {wanted}")
            verdicts.append((step_id, found[0]))
        receipts.append({"segment": name, "inventory_path": str(inv_path.relative_to(run)),
                         "inventory_sha256": sha(inv_path), "events_path": str(events_path.relative_to(run)),
                         "events_sha256": sha(events_path), "event_count": len(events),
                         "notes_path": str(notes_path.relative_to(run)), "notes_sha256": sha(notes_path),
                         "step_verdicts": verdicts, "input_sha256": input_hash,
                         "output_save_path": str(final_save.relative_to(run)) if final_save else None,
                         "output_sha256": previous_output_hash if final_save else "", "metrics": metrics})
    paid = [row["id"] for row in capture_rows] if capture_lane else delegated
    if coverage != [s["id"] for s in source["steps"]] or paid != GEN.planned_captures(source["steps"]):
        raise ValueError("phase union does not exactly cover original steps and capture debts")
    if not manifest.get("terminal_capture") and manifest["canonical_output_save"] != f"{parent}-exit.json":
        raise ValueError("final phase does not export the canonical parent exit filename")
    metric_predicates(source, previous_metrics)
    return {"parent": parent, "execution": "save_linked_phases", "sha": revision,
            "source_sha256": source_hash, "manifest": manifest, "order": order,
            "input_provenance": input_provenance, "receipts": receipts,
            "original_step_ids": coverage, "delegated_captures": delegated,
            "metrics": previous_metrics, "exit_save_source": str(final_save.relative_to(run)) if final_save else None,
            "exit_save_sha256": previous_output_hash if final_save else "",
            "evidence_lane": source.get("evidence_lane", "logic"),
            "capture_rows": capture_rows, "frame_rows": frame_rows,
            "analytics": {"stitched_telemetry": False,
                          "note": "Raw phase paths are authoritative. No parent route.csv, stitched events or unsplit-execution claim is created."}}


def publish(run: Path, definitions: Path, parent: str) -> dict:
    target = run / parent
    if target.exists():
        raise ValueError(f"refusing to overwrite existing evidence: {target}")
    result = collect(run, definitions, parent)
    # Capture immutable bytes and recheck before publishing. Do not claim the
    # earlier hash if the final save changed while evidence was being verified.
    final_bytes = (run / result["exit_save_source"]).read_bytes() if result["exit_save_source"] else None
    if final_bytes is not None and hashlib.sha256(final_bytes).hexdigest() != result["exit_save_sha256"]:
        raise ValueError("canonical exit save changed during verification")
    target.mkdir(parents=True, exist_ok=False)
    if final_bytes is not None:
        (target / "saves").mkdir()
        with (target / "saves" / f"{parent}-exit.json").open("xb") as handle:
            handle.write(final_bytes)
    (target / "PHASE_AGGREGATE.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    count = len(result["original_step_ids"])
    # Recheck raw capture bytes before publishing the completion marker. A file
    # changed since collect must not acquire an aggregate PASS under its old hash.
    for proof in result["capture_rows"] + result["frame_rows"]:
        if sha(run / proof["file"]) != proof["sha256"]:
            raise ValueError("capture changed during aggregate publication")
    inventory = {"segment": parent, "execution": result["execution"], "sha": result["sha"],
                 "complete": True, "evidence_lane": "logic", "aggregate": result,
                 "blocked": "", "derailed": "", "derails": [], "harness_errors": [],
                 "steps": {"total": count, "ran": count, "fail": 0, "refused": 0, "skipped": 0},
                 "captures": {"planned": 0, "present": 0, "absent": 0, "rows": [],
                              "delegated": result["delegated_captures"],
                              "delegated_to": result["manifest"]["capture_lane"]}}
    if result["evidence_lane"] == "capture":
        inventory["evidence_lane"] = "capture"
        # Paths are explicitly run-relative raw-phase references, not files
        # invented beneath this parent directory. Consumers must honor scope.
        rows = result["capture_rows"]
        inventory["captures"] = {"planned": len(rows), "present": len(rows), "absent": 0,
            "delegated": [], "owes": [row["id"] for row in rows], "rows": rows,
            "path_scope": "run_root", "raw_phase_references": True}
        inventory["frames"] = {"written": len(result["frame_rows"]), "absent": 0,
            "rows": result["frame_rows"], "path_scope": "run_root", "continuous_across_phases": False}
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
    print(f"Verified {len(result['order'])} {result['evidence_lane']} phases; {len(result['original_step_ids'])} original steps; raw phase evidence remains authoritative")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
