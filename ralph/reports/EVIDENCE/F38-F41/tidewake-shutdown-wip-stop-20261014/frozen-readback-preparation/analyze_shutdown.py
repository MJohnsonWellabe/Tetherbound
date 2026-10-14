"""Read-only shutdown boundary report. Does not admit, launch or accept a run."""
import argparse
import hashlib
import json
import math
import re
from pathlib import Path

RESOURCE_PREFIX = "TIDEWAKE SHUTDOWN RESOURCES "
PHASE = re.compile(r"^TIDEWAKE SHUTDOWN phase=(\w+) ticks_ms=(\d+)$")
FINAL = "root_deleted_and_delete_queue_flushed"
MAX_LOG_BYTES = 32 * 1024 * 1024


def validate_inventory(obj):
    if not isinstance(obj, dict):
        raise ValueError("resource readback is not an object")
    for name in ("ticks_ms", "terrain_regions", "multimesh_nodes", "multimesh_instances", "msaa_3d"):
        if type(obj.get(name)) is not int or obj[name] < (-1 if name == "terrain_regions" else 0):
            raise ValueError("invalid integer readback: " + name)
    if obj["msaa_3d"] not in (0, 1, 2, 3):
        raise ValueError("invalid MSAA enum")
    if obj.get("renderer") != "forward_plus":
        raise ValueError("unexpected renderer")
    if obj.get("multimesh_scope") != "all world descendants; configured counts, not visible draws":
        raise ValueError("missing count scope")
    size = obj.get("render_size")
    if not isinstance(size, list) or len(size) != 2 or any(type(v) is not int or v <= 0 for v in size):
        raise ValueError("invalid render size")
    if type(obj.get("environment_present")) is not bool:
        raise ValueError("invalid environment presence")
    if "camera_far" in obj and (type(obj["camera_far"]) not in (int, float) or not math.isfinite(obj["camera_far"]) or obj["camera_far"] <= 0):
        raise ValueError("invalid camera far")
    if "environment_source" in obj and obj["environment_source"] not in ("camera", "world", "world_fallback"):
        raise ValueError("invalid environment source")
    if obj["environment_present"]:
        if "camera_far" not in obj or "environment_source" not in obj:
            raise ValueError("environment lacks camera/source provenance")
        if type(obj.get("background_mode")) is not int or obj["background_mode"] not in range(7):
            raise ValueError("invalid background mode")
        for name in ("ssao_enabled", "ssil_enabled", "glow_enabled", "fog_enabled", "volumetric_fog_enabled", "sky_present"):
            if type(obj.get(name)) is not bool:
                raise ValueError("invalid environment boolean: " + name)
        for name in ("volumetric_fog_density", "volumetric_fog_length"):
            if type(obj.get(name)) not in (int, float) or not math.isfinite(obj[name]) or obj[name] < 0:
                raise ValueError("invalid fog readback: " + name)
        if obj["sky_present"]:
            for name, maximum in (("sky_radiance_size", 6), ("sky_process_mode", 3)):
                if type(obj.get(name)) is not int or obj[name] not in range(maximum + 1):
                    raise ValueError("invalid sky enum: " + name)
            if not isinstance(obj.get("sky_material_class"), str):
                raise ValueError("invalid sky material class")


def read_bound(path, digest, limit):
    p = Path(path)
    if p.stat().st_size > limit:
        raise ValueError("input exceeds byte bound: " + str(p))
    data = p.read_bytes()
    if hashlib.sha256(data).hexdigest() != digest:
        raise ValueError("input hash mismatch: " + str(p))
    return data


def parse_stdout(text):
    phases, inventories = [], []
    for line_number, line in enumerate(text.splitlines(), 1):
        match = PHASE.fullmatch(line)
        if match:
            phases.append({"phase": match[1], "ticks_ms": int(match[2]), "line": line_number})
        elif line.startswith("TIDEWAKE SHUTDOWN phase="):
            raise ValueError("malformed lifecycle marker")
        elif line.startswith(RESOURCE_PREFIX):
            obj = json.loads(line[len(RESOURCE_PREFIX):])
            validate_inventory(obj)
            inventories.append({"line": line_number, "values": obj})
    if len(inventories) > 1:
        raise ValueError("duplicate resource readback")
    names = [p["phase"] for p in phases]
    if len(names) != len(set(names)):
        raise ValueError("duplicate lifecycle marker")
    if any(b["ticks_ms"] < a["ticks_ms"] for a, b in zip(phases, phases[1:])):
        raise ValueError("nonmonotonic lifecycle marker")
    if inventories:
        quits = [p for p in phases if p["phase"] == "quit_requested"]
        if len(quits) != 1 or inventories[0]["line"] >= quits[0]["line"] or inventories[0]["values"]["ticks_ms"] > quits[0]["ticks_ms"]:
            raise ValueError("resource readback is not before normal quit request")
    expected = ["quit_requested", "quit_returned", "root_tree_exiting", "root_tree_exited_before_delete", FINAL]
    observed = [name for name in names if name in expected]
    if observed != sorted(observed, key=expected.index):
        raise ValueError("shutdown boundary order reversed")
    return phases, inventories


def analyze(receipt_path, receipt_sha256, require_readback=False):
    receipt = json.loads(read_bound(receipt_path, receipt_sha256, 2 * 1024 * 1024).decode("utf-8-sig"))
    steps = [s for s in receipt["steps"] if s.get("kind") == "capture"]
    if len(steps) != 1:
        raise ValueError("expected exactly one full-scene capture step")
    step = steps[0]
    stdout = read_bound(step["stdout"], step["stdout_sha256"], MAX_LOG_BYTES)
    stderr = read_bound(step["stderr"], step["stderr_sha256"], MAX_LOG_BYTES)
    if len(stdout) + len(stderr) > MAX_LOG_BYTES:
        raise ValueError("combined logs exceed bound")
    phases, inventories = parse_stdout(stdout.decode("utf-8-sig"))
    if require_readback:
        if not inventories:
            raise ValueError("reviewed source requires resource readback; missing")
        obj = inventories[0]["values"]
        if obj["terrain_regions"] < 1 or not obj["environment_present"] or not obj.get("sky_present") or not obj.get("sky_material_class"):
            raise ValueError("required resource scope unavailable")
        if obj["render_size"] != [1920, 1080] or obj["multimesh_nodes"] < 1 or obj["multimesh_instances"] < 1:
            raise ValueError("expected full-scene resource scope unavailable")
    finalized = any(p["phase"] == FINAL for p in phases)
    return {
        "status": "OBSERVATION_ONLY_NOT_RUN_ACCEPTANCE",
        "receipt_sha256": receipt_sha256,
        "source_commit": receipt.get("source_commit"),
        "recorded_run_status": receipt.get("status"),
        "recorded_exit_code": step.get("exit_code"),
        "recorded_stop_reason": step.get("stop_reason"),
        "recorded_wall_seconds": step.get("wall_seconds"),
        "stderr_bytes": len(stderr),
        "lifecycle_markers": phases,
        "resource_readback": inventories[0]["values"] if inventories else None,
        "resource_scope_available": bool(inventories and inventories[0]["values"]["terrain_regions"] >= 0 and inventories[0]["values"]["environment_present"]),
        "root_delete_and_queue_flush_observed": finalized,
        "boundary": "Root deletion and queue flush marker reached; later cleanup may remain" if finalized else "No root-deleted marker; absence cannot localize a stall when that source lacked instrumentation",
        "limits": "No native launch, PID/lease verification, GPU allocation inference, warning exemption, full-world pass or visual acceptance. Requested presets are never substituted for absent readbacks. Receipt fields are recorded observations, not independently certified process outcome.",
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipt")
    parser.add_argument("--receipt-sha256", required=True)
    parser.add_argument("--require-readback", action="store_true")
    args = parser.parse_args()
    print(json.dumps(analyze(args.receipt, args.receipt_sha256, args.require_readback), indent=2, allow_nan=False))
