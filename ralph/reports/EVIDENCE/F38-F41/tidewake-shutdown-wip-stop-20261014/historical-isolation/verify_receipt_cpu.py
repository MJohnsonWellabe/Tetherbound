"""Synthetic local receipt fixtures only; never starts/inspects an OS process."""
import copy
import json
import pathlib
import subprocess
import validate_receipt as validator

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "cpu-evidence/receipt-fixture"
OUT.mkdir(parents=True, exist_ok=True)
JOB = validator.read(HERE / "supervisor/native-job.json")
JOB["output_directory"] = str(OUT)
BASE = validator.read(HERE.parent.parent / "s/run-twcover-isolation-bf81-r2/receipt.json")
BASE.update(job_id=JOB["job_id"], cpu_fixture_only=True)
LIVE = copy.deepcopy(BASE["steps"][1]["capture"][0])
RECORDS = [LIVE] + [{"phase": phase, "ticks_usec": LIVE["ticks_usec"] + (i + 1) * 100}
                    for i, phase in enumerate(validator.PHASES[1:])]
RECORDS[1].update(explicit_free=False, cover_alive_in_tree=True, terrain_alive_in_tree=True, rig_alive_in_tree=True)
RECORDS[-1]["setup_failed"] = False
CHECKS = []

def write_case(mutation=None, log_mutation=None, seal=True):
    receipt = copy.deepcopy(BASE)
    for i, (step, job_step) in enumerate(zip(receipt["steps"], JOB["steps"])):
        step.update(id=job_step["id"], kind=job_step["kind"], pid=9000 + i,
                    expected_arguments=job_step["args"],
                    observed_command_line='"' + JOB["engine"]["path"] + '" ' + subprocess.list2cmdline(job_step["args"]))
        step["capture"] = copy.deepcopy(RECORDS) if i == 1 else None
        for stream in ("stdout", "stderr"):
            step[stream] = str(OUT / (step["id"] + "." + stream + ".log"))
    if mutation:
        mutation(receipt)
    for i, step in enumerate(receipt["steps"]):
        stdout = "Godot CPU FIXTURE ONLY\n"
        if i == 1:
            stdout += "\n".join(validator.PREFIX + json.dumps(r, separators=(",", ":")) for r in step["capture"]) + "\n"
        pathlib.Path(step["stdout"]).write_text(stdout, encoding="utf-8")
        pathlib.Path(step["stderr"]).write_bytes(b"")
    if log_mutation and seal:
        log_mutation(receipt)
    for step in receipt["steps"]:
        for stream in ("stdout", "stderr"):
            step[stream + "_sha256"] = validator.sha(step[stream])
    if log_mutation and not seal:
        log_mutation(receipt)
    path = OUT / "receipt.json"
    path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    return path

def passes():
    result = validator.validate(write_case(), JOB)
    assert result["phases"] == 6
    CHECKS.append("Valid six-phase receipt accepted")

def fails(name, pattern, mutation=None, log_mutation=None, seal=True):
    try:
        validator.validate(write_case(mutation, log_mutation, seal), JOB)
    except ValueError as error:
        assert pattern in str(error), (name, str(error))
    else:
        raise AssertionError("Accepted invalid fixture: " + name)
    CHECKS.append(name)

passes()
fails("Exit1 rejected", "naturally exit zero", lambda r: r["steps"][1].update(exit_code=1))
fails("Overrun rejected", "elapsed overrun", lambda r: r["steps"][1].update(wall_seconds=60.001))
fails("Missing finalizer rejected", "out-of-order phases", lambda r: r["steps"][1]["capture"].pop())
fails("Wrong source rejected", "identity mismatch", lambda r: r.update(source_commit="foreign"))
fails("Missing lease source rejected", "Incoming lease", lambda r: r.pop("incoming_owner_source"))
fails("Nonempty stderr rejected", "Nonempty stderr", log_mutation=lambda r: pathlib.Path(r["steps"][1]["stderr"]).write_text("error"))
fails("Hash tamper rejected", "Raw log hash", log_mutation=lambda r: pathlib.Path(r["steps"][1]["stdout"]).write_text("tampered"), seal=False)
fails("Duplicate phase rejected", "out-of-order phases", lambda r: r["steps"][1]["capture"].append(r["steps"][1]["capture"][-1]))
fails("Early cover deletion rejected", "not alive", lambda r: r["steps"][1]["capture"][1].update(cover_alive_in_tree=False))
fails("Changed population rejected", "population failed", lambda r: r["steps"][1]["capture"][0]["cover"].update(instances=47611))
fails("Wrong observed command rejected", "command line differs", lambda r: r["steps"][1].update(observed_command_line="foreign.exe"))
fails("Cleanup blocker rejected", "incomplete cleanup", lambda r: r.update(cleanup_blocked="retained lease"))
fails("Identity mismatch rejected", "identity failure", lambda r: r["steps"][1].update(identity_failure={"actual": "foreign"}))
fails("Missing timestamp rejected", "lifecycle timestamps", lambda r: r["steps"][1]["capture"][2].pop("ticks_usec"))
fails("Resource floor breach rejected", "Resource floor", lambda r: r["steps"][1].update(minimum_commit_headroom_bytes=1))
fails("Warning stdout rejected", "Warning/error", log_mutation=lambda r: pathlib.Path(r["steps"][1]["stdout"]).write_text("WARNING: fixture\n"))
# Leave the fixture valid and clearly labeled synthetic; it is outside the declared native run path.
write_case()
report = {"status": "CPU_RECEIPT_CHECKS_PASS", "checks": len(CHECKS), "cases": CHECKS,
          "engine_launched": False, "real_lease_accessed": False, "fixture_only": True}
(HERE / "cpu-evidence/receipt-verification.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report))
