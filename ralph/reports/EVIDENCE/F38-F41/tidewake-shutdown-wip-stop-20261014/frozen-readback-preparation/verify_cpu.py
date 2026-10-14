"""CPU-only malformed evidence checks; no engine, process, stage or lease access."""
import copy
import hashlib
import json
from pathlib import Path
import analyze_shutdown as analyzer

ROOT = Path(__file__).resolve().parent
OLD = Path("D:/tetherbound/.artifacts/s/run-twdiag-e006-r1/receipt.json")
checks = []


def reject(name, function):
    try:
        function()
    except (ValueError, KeyError):
        checks.append({"case": name, "result": "PASS_REJECTED"})
        return
    raise AssertionError(name)


digest = hashlib.sha256(OLD.read_bytes()).hexdigest()
report = analyzer.analyze(str(OLD), digest)
assert report["recorded_run_status"] == "FAILED"
assert report["resource_readback"] is None
assert report["lifecycle_markers"][-1]["ticks_ms"] == 73016
assert not report["root_delete_and_queue_flush_observed"]
reject("old trace lacks new readbacks", lambda: analyzer.analyze(str(OLD), digest, True))
reject("wrong receipt hash", lambda: analyzer.analyze(str(OLD), "0" * 64))
fixture = {
    "ticks_ms": 10, "terrain_regions": 24, "multimesh_nodes": 900,
    "multimesh_instances": 50000, "msaa_3d": 1, "renderer": "forward_plus",
    "multimesh_scope": "all world descendants; configured counts, not visible draws",
    "render_size": [1920, 1080], "environment_present": True, "camera_far": 6500,
    "environment_source": "world", "background_mode": 2, "ssao_enabled": True,
    "ssil_enabled": False, "glow_enabled": True, "fog_enabled": True,
    "volumetric_fog_enabled": True, "volumetric_fog_density": .0005,
    "volumetric_fog_length": 96, "sky_present": True, "sky_radiance_size": 3,
    "sky_process_mode": 0, "sky_material_class": "ShaderMaterial",
}


def log(obj):
    lines = [analyzer.RESOURCE_PREFIX + json.dumps(obj)]
    for phase, ticks in [("quit_requested", 11), ("quit_returned", 11),
                         ("root_tree_exiting", 12), ("root_tree_exited_before_delete", 13),
                         (analyzer.FINAL, 15)]:
        lines.append(f"TIDEWAKE SHUTDOWN phase={phase} ticks_ms={ticks}")
    return "\n".join(lines) + "\n"


analyzer.parse_stdout(log(fixture))
checks.append({"case": "complete synthetic typed readback", "result": "PASS"})
for key in fixture:
    changed = copy.deepcopy(fixture)
    del changed[key]
    reject("missing " + key, lambda changed=changed: analyzer.parse_stdout(log(changed)))
for key, value in [("terrain_regions", True), ("environment_present", "true"),
                   ("sky_present", 1), ("sky_process_mode", False),
                   ("volumetric_fog_density", float("nan")), ("camera_far", float("inf")),
                   ("render_size", [True, 1080]), ("ticks_ms", 20)]:
    changed = copy.deepcopy(fixture)
    changed[key] = value
    reject("invalid " + key, lambda changed=changed: analyzer.parse_stdout(log(changed)))
reject("duplicate readback", lambda: analyzer.parse_stdout(log(fixture) + analyzer.RESOURCE_PREFIX + json.dumps(fixture)))
reject("duplicate phase", lambda: analyzer.parse_stdout(log(fixture) + "TIDEWAKE SHUTDOWN phase=quit_requested ticks_ms=16"))
reject("reversed boundary", lambda: analyzer.parse_stdout("TIDEWAKE SHUTDOWN phase=" + analyzer.FINAL + " ticks_ms=1\nTIDEWAKE SHUTDOWN phase=quit_requested ticks_ms=2"))
changed = copy.deepcopy(fixture)
changed["terrain_regions"] = -1
analyzer.parse_stdout(log(changed))
checks.append({"case": "unknown residency retained as sentinel", "result": "PASS_UNAVAILABLE"})
result = {"status": "PASS_CPU_ONLY", "checks": checks, "engine_launched": False,
          "real_lease_or_stage_accessed": False, "synthetic_populations_are_not_runtime_evidence": True}
print(json.dumps(result, indent=2))
