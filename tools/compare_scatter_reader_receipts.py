"""Validate paired reader output receipts. Process-memory acceptance stays separate."""
import argparse
import json
import re
from pathlib import Path


def require(condition, message):
    if not condition:
        raise ValueError(message)


def _validate(receipt, arm):
    require(receipt.get("schema") == 1, f"{arm}: unsupported schema")
    require(receipt.get("status") == "COMPLETE", f"{arm}: incomplete run")
    require(receipt.get("scope") == "SCATTER_READER_ONLY", f"{arm}: wrong scope")
    require(receipt.get("arm") == arm, f"{arm}: arm mismatch")
    require(receipt.get("scene_loaded") is False, f"{arm}: world scene was loaded")
    require(receipt.get("root_children") == 0 and isinstance(receipt.get("isolated_autoloads"), dict),
            f"{arm}: missing reader isolation evidence")
    require(receipt.get("visual_acceptance") is False and receipt.get("memory_acceptance") is False,
            f"{arm}: unsupported acceptance claim")
    require(re.fullmatch(r"[0-9a-f]{40}", receipt.get("source_commit", "")), f"{arm}: missing source pin")
    require(isinstance(receipt.get("pid"), int) and receipt["pid"] > 0, f"{arm}: invalid pid")
    require(bool(receipt.get("godot_version")), f"{arm}: missing engine version")
    for key in ("source_sha256", "region_sha256"):
        values = receipt.get(key)
        require(isinstance(values, dict) and bool(values), f"{arm}: missing {key}")
        require(all(re.fullmatch(r"[0-9a-f]{64}", value) for value in values.values()), f"{arm}: invalid {key}")
    required_sources = {"res://data/scatter/playground/manifest.json", "res://data/config/grass_field.json",
                        "res://data/config/vegetation.json", "res://scripts/world/scatter_bake.gd",
                        "res://scripts/world/terrain_bake.gd", "res://scripts/data/band_content.gd",
                        "res://project.godot", "res://tools/probe_scatter_reader_memory.gd"}
    require(required_sources <= set(receipt["source_sha256"]), f"{arm}: incomplete source binding")
    require(receipt.get("regions") == len(receipt["region_sha256"]), f"{arm}: region count mismatch")
    for key in ("suppressed_layers", "skipped_counts", "identity_bounds"):
        require(isinstance(receipt.get(key), dict), f"{arm}: missing {key}")
    for key in ("raw_orders", "output_hashes"):
        value = receipt.get(key)
        require(isinstance(value, dict) and set(value) == {"kept", "drained"}, f"{arm}: incomplete {key}")
        for group in value.values():
            require(isinstance(group, dict), f"{arm}: invalid layer map")
            for row in group.values():
                require(isinstance(row, dict) and isinstance(row.get("records"), int) and row["records"] >= 0,
                        f"{arm}: invalid record count")
                require(re.fullmatch(r"[0-9a-f]{64}", row.get("sha256", "")), f"{arm}: invalid record digest")
    for kind in ("kept", "drained"):
        raw = receipt["raw_orders"][kind]
        output = receipt["output_hashes"][kind]
        require(set(raw) <= set(output), f"{arm}: output layer lost")
        require(all(output[layer]["records"] == row["records"] for layer, row in raw.items()),
                f"{arm}: output records lost")
        require(all(output[layer]["records"] == 0 and kind == "kept" and layer in receipt["identity_bounds"]
                    for layer in set(output) - set(raw)), f"{arm}: unaccounted output layer")
    records = sum(row["records"] for rows in receipt["raw_orders"].values() for row in rows.values())
    require(records > 0, f"{arm}: empty input")
    stages = receipt.get("stages", [])
    names = [stage.get("name") for stage in stages]
    expected_middle = {"reordered_kept:" + layer for layer in receipt["raw_orders"]["kept"]}
    expected_middle |= {"reordered_drained:" + layer for layer in receipt["raw_orders"]["drained"]}
    # Godot's JSON writer may sort map keys. The stage array retains chronology;
    # do not mistake alphabetically serialized layer maps for traversal order.
    require(names[:2] == ["ready", "decoded"] and names[-1:] == ["retained_output"]
            and len(names) == len(expected_middle) + 3 and set(names[2:-1]) == expected_middle,
            f"{arm}: missing, duplicate or reordered phase markers")
    kinds = [name.startswith("reordered_drained:") for name in names[2:-1]]
    require(kinds == sorted(kinds), f"{arm}: drained phase precedes kept phase")
    times = [stage.get("elapsed_usec") for stage in stages]
    require(all(isinstance(value, int) and value >= 0 for value in times), f"{arm}: invalid phase time")
    require(all(a < b for a, b in zip(times, times[1:])), f"{arm}: nonmonotonic phases")
    require(all(isinstance(stage.get("memory_static_bytes"), int) and stage["memory_static_bytes"] >= 0
                for stage in stages), f"{arm}: invalid static-memory counter")
    return records


def compare(legacy, compact):
    records = _validate(legacy, "legacy")
    require(_validate(compact, "compact") == records, "paired record count mismatch")
    for key in ("source_commit", "godot_version", "source_sha256", "region_sha256", "regions",
                "suppressed_layers", "skipped_counts", "identity_bounds", "raw_orders", "output_hashes",
                "isolated_autoloads", "root_children"):
        require(legacy[key] == compact[key], f"paired {key} mismatch")
    require([s["name"] for s in legacy["stages"]] == [s["name"] for s in compact["stages"]],
            "paired phase traversal mismatch")
    require(legacy.get("started_utc") and compact.get("started_utc"), "missing run start")
    require(legacy.get("ended_utc") and compact.get("ended_utc"), "missing run end")
    # A PID may legitimately be reused, so distinct receipt paths and the
    # supervisor's PID + creation-time identities remain external checks.
    deltas = {}
    before = {s["name"]: s["memory_static_bytes"] for s in legacy["stages"]}
    after = {s["name"]: s["memory_static_bytes"] for s in compact["stages"]}
    for phase in ("decoded", "retained_output"):
        deltas[phase] = ((after[phase] - after["ready"]) - (before[phase] - before["ready"])) \
            if before["ready"] > 0 and after["ready"] > 0 else None
    return {"status": "CONTENT_PARITY_PASS", "records": records, "source_commit": legacy["source_commit"],
            "godot_static_delta_compact_minus_legacy_bytes": deltas,
            "process_memory_acceptance": False, "visual_acceptance": False,
            "required_external_evidence": "Clean supervised exits; exact executable/source bindings; separate process identities; unchanged guards; time-aligned private/working-set and physical/commit samples. Static counters alone do not measure process savings."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--legacy", type=Path, required=True)
    parser.add_argument("--compact", type=Path, required=True)
    args = parser.parse_args()
    require(args.legacy.resolve() != args.compact.resolve(), "receipts must be separate files")
    result = compare(json.loads(args.legacy.read_text(encoding="utf-8-sig")),
                     json.loads(args.compact.read_text(encoding="utf-8-sig")))
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
