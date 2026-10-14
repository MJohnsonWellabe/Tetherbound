"""Read-only receipt/log validation. Never starts an engine or accesses the lease."""
import argparse
import hashlib
import json
import math
import pathlib
import re
import shlex

HERE = pathlib.Path(__file__).resolve().parent
PHASES = ["rendered_live_component", "quit_requested", "cover_tree_exited_before_delete",
          "terrain_tree_exited_before_delete", "root_tree_exited_before_delete", "root_deleted_and_queue_flushed"]
PREFIX = "TERRAIN DELETE ISOLATION "
BAD_LOG = re.compile(r"SCRIPT ERROR|Parse Error:|^(WARNING|ERROR):|missing asset|velocity.{0,100}exceeded.{0,40}ceiling|falling trainer", re.I | re.M)

def read(path):
    return json.loads(pathlib.Path(path).read_text(encoding="utf-8-sig"))

def sha(path):
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()

def require(condition, message):
    if not condition:
        raise ValueError(message)

def number(value):
    return type(value) in (int, float) and math.isfinite(value)

def validate(receipt_path, job):
    receipt_path = pathlib.Path(receipt_path)
    out = pathlib.Path(job["output_directory"])
    require(receipt_path.resolve() == (out / "receipt.json").resolve(), "Receipt path differs from job")
    require(sha(HERE / "supervisor/run_isolation.ps1") == job["supervisor_sha256"], "Supervisor hash mismatch")
    template = pathlib.Path(job["project_template"]).resolve()
    for binding in job["project_bindings"]:
        file = (template / binding["path"]).resolve()
        require(file.is_relative_to(template), "Payload path escapes template")
        require(sha(file) == binding["sha256"] and file.stat().st_size == binding["bytes"], "Payload hash/size mismatch")
    for binding in job["packet_bindings"]:
        require(sha(binding["path"]) == binding["sha256"], "Source binding mismatch")
    receipt = read(receipt_path)
    require(receipt["status"] == "EXITED_ZERO_AWAITING_REVIEW", "Run did not finish successfully")
    require(receipt["job_id"] == job["job_id"] and receipt["source_commit"] == job["source_commit"], "Receipt identity mismatch")
    require(receipt["engine_sha256"] == job["engine"]["sha256"], "Engine identity mismatch")
    require(receipt.get("isolated_source") == job["source_commit"], "Isolated source missing or mismatched")
    require(isinstance(receipt.get("incoming_owner_source"), str) and receipt["incoming_owner_source"].strip(), "Incoming lease source not recorded")
    for key in ("failed_step", "stop_reason", "failure", "cleanup_blocked", "lease_retained_for_live_or_unverified_child"):
        require(not receipt.get(key), "Failure or incomplete cleanup recorded: " + key)
    require(len(receipt["steps"]) == len(job["steps"]) == 2, "Two steps required")
    total_log_bytes = 0
    raw_phases = None
    for step, expected in zip(receipt["steps"], job["steps"]):
        require(step["id"] == expected["id"] and step["kind"] == expected["kind"], "Step identity mismatch")
        require(step["status"] == "PASSED" and step["exit_code"] == 0, "Step did not naturally exit zero")
        require(not step.get("stop_reason") and not step.get("identity_failure"), "Step stop/identity failure")
        require(number(step["wall_seconds"]) and 0 <= step["wall_seconds"] <= expected["wall_seconds"] == 60, "Terminal elapsed overrun")
        require(step["expected_arguments"] == expected["args"], "Step argument mismatch")
        require(isinstance(step.get("observed_command_line"), str) and step["observed_command_line"], "Observed identity missing")
        # This job has only fixed arguments without embedded quotes. Preserve
        # Windows backslashes while accepting normal whole-token quoting.
        observed = [token[1:-1] if token.startswith('"') and token.endswith('"') else token
                    for token in shlex.split(step["observed_command_line"], posix=False)]
        require(observed == [job["engine"]["path"], *expected["args"]], "Observed command line differs from pinned engine/arguments")
        require(type(step.get("pid")) is int and step["pid"] > 0 and step.get("created_utc"), "Process identity missing")
        require(number(step["supervisor_elapsed_with_drain_seconds"]) and step["supervisor_elapsed_with_drain_seconds"] >= step["wall_seconds"], "Invalid drain-inclusive elapsed")
        for field, cap in (("minimum_C_free_bytes", "C_stop_bytes"), ("minimum_D_free_bytes", "D_stop_bytes"),
                           ("minimum_physical_free_bytes", "physical_and_commit_bytes"), ("minimum_commit_headroom_bytes", "physical_and_commit_bytes")):
            require(number(step[field]) and step[field] >= job["caps"][cap], "Resource floor violated")
        logs = {}
        for stream in ("stdout", "stderr"):
            path = pathlib.Path(step[stream])
            require(path.resolve() == (out / (step["id"] + "." + stream + ".log")).resolve(), "Log path mismatch")
            require(sha(path) == step[stream + "_sha256"], "Raw log hash mismatch")
            logs[stream] = path.read_text(encoding="utf-8-sig")
            total_log_bytes += path.stat().st_size
        require(pathlib.Path(step["stderr"]).stat().st_size == 0, "Nonempty stderr")
        require(not BAD_LOG.search(logs["stdout"]), "Warning/error in stdout")
        if expected["kind"] == "diagnostic":
            raw_phases = [json.loads(line[len(PREFIX):]) for line in logs["stdout"].splitlines() if line.startswith(PREFIX)]
            require(raw_phases == step["capture"], "Receipt phases differ from raw stdout")
            require([r["phase"] for r in raw_phases] == PHASES, "Incomplete/duplicate/out-of-order phases")
            times = [r.get("ticks_usec") for r in raw_phases]
            require(all(type(t) is int and t >= 0 for t in times) and times == sorted(times), "Invalid lifecycle timestamps")
            live, quit_state = raw_phases[:2]
            require(live["regions"] == 1 and live["collision_shapes"] > 0 and live["map_rids_valid"] is True and live["renderer"] == "forward_plus", "Terrain prerequisites failed")
            cover = live["cover"]
            required = {"ready": True, "bound": True, "materials": 4, "map_bindings_match": True,
                        "tile_nodes": 148, "grass_instances": 32748, "instances": 47612}
            require(all(type(cover.get(k)) is type(v) and cover[k] == v for k, v in required.items()), "Cover prerequisites/population failed")
            require(quit_state.get("explicit_free") is False and all(quit_state.get(k) is True for k in
                    ("cover_alive_in_tree", "terrain_alive_in_tree", "rig_alive_in_tree")), "Components not alive at normal quit")
            require(raw_phases[-1].get("setup_failed") is False, "Setup failed")
    require(total_log_bytes <= job["caps"]["combined_stdout_stderr_bytes"], "Combined log cap exceeded")
    require(number(receipt["total_output_bytes"]) and total_log_bytes <= receipt["total_output_bytes"] <= job["caps"]["run_output_and_isolated_homes_bytes"], "Output cap/size invalid")
    for path in out.rglob("godot.log"):
        require(not BAD_LOG.search(path.read_text(encoding="utf-8-sig")), "Warning/error in retained Godot log")
    require(raw_phases is not None, "Missing diagnostic step")
    return {"status": "RECEIPT_CHECKS_PASS_ROOT_REVIEW_PENDING", "receipt_sha256": sha(receipt_path),
            "phases": len(raw_phases), "quit_to_root_finalized_usec": raw_phases[-1]["ticks_usec"] - raw_phases[1]["ticks_usec"],
            "limits": "Receipt and raw-log verification only; external process absence and final live lease observation remain root review responsibilities."}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipt", type=pathlib.Path)
    args = parser.parse_args()
    print(json.dumps(validate(args.receipt, read(HERE / "supervisor/native-job.json")), indent=2))
