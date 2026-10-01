#!/usr/bin/env python3
"""Read-only F49 package/device/journey checks; never launch, publish or certify hardware.

ROOT supplies downloaded artifact bytes, GitHub API run/jobs/artifact JSON and
the exact expected digest/commit. Local JSON is evidence input, not an API trust
anchor. This checker makes the binding reviewable; it cannot attest who played.
"""
import argparse
import hashlib
import json
import math
import re
import struct
import sys
import zipfile
from pathlib import Path, PurePosixPath

SHA = re.compile(r"[0-9a-f]{40}\Z")
DIGEST = re.compile(r"[0-9a-f]{64}\Z")
ORDER = ["meadows", "tidewake", "cloudreach", "stormwood", "homecoming_credits"]
DEVICE_PHASES = {"band1_travel_combat", "hall", "cloudreach_flight", "stormwood_storm",
                 "water_traversal_veilfall", "ally_host_client", "four_peer_worst_case"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def digest(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def package_check(package, commit, expected_digest, run, jobs, artifact, repository):
    require(SHA.fullmatch(commit), "expected commit must be the full reviewed SHA")
    require(DIGEST.fullmatch(expected_digest), "expected package digest must be SHA256")
    require(digest(package) == expected_digest, "download bytes differ from expected artifact digest")
    require(run.get("head_sha") == commit and run.get("conclusion") == "success"
            and run.get("status") == "completed", "workflow did not pass on the exact commit")
    require(str(run.get("repository", {}).get("full_name", "")).casefold() == repository.casefold(),
            "run belongs to another repository")
    require(artifact.get("name") == "Tetherbound-windows-debug" and artifact.get("expired") is False,
            "missing, expired or wrong Windows export artifact")
    require(artifact.get("workflow_run", {}).get("id") == run.get("id")
            and artifact.get("workflow_run", {}).get("head_sha") == commit,
            "artifact does not belong to the exact passing run/head")
    require(artifact.get("digest") == "sha256:" + expected_digest,
            "GitHub artifact digest is absent or differs from downloaded ZIP")
    job_rows = jobs.get("jobs", [])
    require(job_rows and jobs.get("total_count") == len(job_rows),
            "jobs response is incomplete; collect all paginated jobs")
    for name in ("export", "ci-gate"):
        matches = [job for job in job_rows if job.get("name") == name]
        require(len(matches) == 1 and matches[0].get("conclusion") == "success"
                and matches[0].get("run_id") == run.get("id"),
                f"actual {name} job did not pass in this run")
    export = next(job for job in job_rows if job.get("name") == "export")
    for name in ("Export Windows build", "Verify the export is a real Windows binary",
                 "Verify the exported build runs and has ground under the player"):
        matches = [step for step in export.get("steps", []) if step.get("name") == name]
        require(len(matches) == 1 and matches[0].get("conclusion") == "success",
                f"actual export proof step missing/skipped/failed: {name}")
    files = {}
    with zipfile.ZipFile(package) as archive:
        names = set()
        total = 0
        for entry in archive.infolist():
            path = PurePosixPath(entry.filename)
            require(not path.is_absolute() and ".." not in path.parts and "\\" not in entry.filename
                    and not any(":" in part for part in path.parts), "unsafe ZIP member path")
            require(entry.filename.casefold() not in names, "duplicate/case-colliding ZIP member")
            names.add(entry.filename.casefold())
            require((entry.external_attr >> 16) & 0o170000 != 0o120000, "ZIP contains a symlink")
            require(not entry.flag_bits & 1, "encrypted ZIP cannot be inspected")
            if entry.is_dir():
                continue
            total += entry.file_size
            require(total <= 8 * 1024**3 and entry.file_size <= 4 * 1024**3,
                    "package exceeds bounded inspection size")
            require(not set(part.casefold() for part in path.parts) &
                    {".git", ".github", "tests", "tools", "archive", "assets_raw", "ralph"},
                    "package includes development-only files")
            require(path.suffix.casefold() not in {".pem", ".key"} and path.name.casefold() != ".env",
                    "package contains a credential-like file")
            with archive.open(entry) as stream:
                head = stream.read(4096)
                hasher = hashlib.sha256(head)
                for block in iter(lambda: stream.read(1024 * 1024), b""):
                    hasher.update(block)
            files[entry.filename] = {"sha256": hasher.hexdigest(), "bytes": entry.file_size}
            if path.name.casefold() == "tetherbound.exe":
                require(head[:2] == b"MZ" and entry.file_size > 10_000_000, "Windows executable is a stub")
                offset = struct.unpack_from("<I", head, 0x3C)[0]
                require(offset + 6 <= len(head) and head[offset:offset+4] == b"PE\0\0"
                        and struct.unpack_from("<H", head, offset+4)[0] == 0x8664,
                        "Windows executable is not a valid x64 PE")
        exe = [name for name in files if PurePosixPath(name).name.casefold() == "tetherbound.exe"]
        pck = [name for name in files if PurePosixPath(name).name.casefold() == "tetherbound.pck"]
        require(len(exe) == len(pck) == 1, "package requires exactly one executable and external PCK")
        require(PurePosixPath(exe[0]).parent == PurePosixPath(pck[0]).parent,
                "external PCK must be alongside the executable")
        with archive.open(pck[0]) as stream:
            require(stream.read(4) == b"GDPC", "external PCK has no Godot pack header")
    return {"kind": "f49_package_byte_verification", "commit": commit,
            "run_id": run["id"], "artifact_id": artifact.get("id"), "package_sha256": expected_digest,
            "files": files, "scope": "artifact provenance and ZIP/binary structure only",
            "pending": ["PCK resource exclusions and licence/credits audit", "actual Windows install/launch/update",
                        "exported fresh campaign clears", "controller and invitation internet co-op",
                        "owner human play", "ROG Ally hardware provenance", "publication"]}


def percentile(samples, percent):
    ordered = sorted(samples)
    return ordered[max(0, math.ceil(len(ordered) * percent / 100) - 1)]


def device_check(data, commit):
    require(SHA.fullmatch(commit) and data.get("commit") == commit, "device data commit differs from candidate")
    profile = data.get("profile", {})
    for field in ("hardware_variant", "driver", "os", "storage", "renderer", "settings", "capture_source"):
        require(isinstance(profile.get(field), str) and profile[field].strip(), "missing recorded device field: " + field)
    require("rog ally" in profile["hardware_variant"].casefold() and "windows" in profile["os"].casefold(),
            "release profile requires recorded Windows ROG Ally hardware")
    require(profile.get("power_watts") == 15 and profile.get("fps_cap") == 30,
            "release capture requires 15W and 30fps cap")
    require(profile.get("resolution") in ([1920, 1080], [1280, 720]), "unsupported device resolution")
    phases = data.get("phases", [])
    require(len(phases) == len(DEVICE_PHASES) and {phase.get("id") for phase in phases} == DEVICE_PHASES,
            "missing or duplicate representative device phase")
    metrics = {}
    for phase in phases:
        samples = phase.get("gameplay_frame_ms", [])
        require(samples and all(type(value) in (int, float) and math.isfinite(value) and value > 0
                                for value in samples), "invalid gameplay frame samples")
        require(sum(samples) >= 1_800_000, "each phase needs 30 minutes of actual gameplay samples")
        require(isinstance(phase.get("loading_frame_ms"), list), "loading timings must be separately reported")
        require(type(phase.get("peak_private_memory_bytes")) is int and phase["peak_private_memory_bytes"] > 0,
                "peak private memory was not captured")
        require(type(phase.get("peak_process_memory_bytes")) is int and phase["peak_process_memory_bytes"] > 0,
                "peak process memory was not captured")
        p95, p99 = percentile(samples, 95), percentile(samples, 99)
        require(p95 <= 33.3 and p99 <= 50, "release frame-time target failed: " + phase["id"])
        require(sum(value > 1000 for value in samples) < 2, "repeated gameplay stalls exceed one second")
        metrics[phase["id"]] = {"median_ms": percentile(samples, 50), "p95_ms": p95, "p99_ms": p99,
                                  "hitches_over_100ms": sum(value > 100 for value in samples),
                                  "peak_private_memory_bytes": phase["peak_private_memory_bytes"],
                                  "peak_process_memory_bytes": phase["peak_process_memory_bytes"],
                                  "gpu_usage": phase.get("gpu_usage", "unavailable"),
                                  "loading_frame_ms": phase["loading_frame_ms"]}
    cycle = data.get("warmed_scene_memory", {})
    require(type(cycle.get("elapsed_seconds")) in (int, float) and cycle["elapsed_seconds"] >= 10800,
            "retained-memory cycle needs three hours")
    memory = cycle.get("same_scene_private_bytes", [])
    require(len(memory) >= 3 and all(type(value) is int and value > 0 for value in memory),
            "missing warmed same-scene memory samples")
    require(not (all(a <= b for a, b in zip(memory, memory[1:])) and memory[-1] > memory[0] * 1.10),
            "monotonic retained-memory growth exceeds ten percent")
    for field, limit in (("ordinary_save_max_ms", 250), ("warm_transition_max_ms", 15000), ("cold_load_max_ms", 45000)):
        value = data.get(field)
        require(type(value) in (int, float) and math.isfinite(value) and 0 <= value <= limit,
                "missing or failed timing: " + field)
    require(type(data.get("first_import_ms")) in (int, float) and data["first_import_ms"] >= 0,
            "first import timing must be separately reported")
    return {"kind": "f49_device_sample_analysis", "commit": commit, "profile": profile, "metrics": metrics,
            "sample_resolution_is_1080p": profile["resolution"] == [1920, 1080],
            "scope": "supplied samples meet numerical targets; operator/device authenticity requires owner evidence",
            "pending": ["owner hardware attestation", "second resolution capture", "controller/UI readability",
                        "Forward+ Medium owner gate before changing Compatibility default"]}


def journey_check(log, commit):
    # Local log identity remains subordinate to ROOT's identified source/package.
    require(SHA.fullmatch(commit), "journey expected commit must be a full reviewed SHA")
    text = Path(log).read_text(encoding="utf-8-sig")
    def rows(prefix):
        return [json.loads(line[len(prefix):]) for line in text.splitlines() if line.startswith(prefix)]
    results = rows("FRESH CAMPAIGN RESULT ")
    journeys = rows("F49 JOURNEY ")
    require(len(results) == len(journeys) == 1, "missing/ambiguous final journey evidence")
    result, journey = results[0], journeys[0]
    require(result.get("campaign_complete") is True and result.get("counts_as_proof") is True
            and result.get("failures") == [] and result.get("reached") == "completed_world_continuation",
            "run did not complete the earned campaign and disk-loaded continuation")
    require(journey.get("order") == ORDER and result.get("dry_run") is False
            and result.get("resumed_from") == "", "wrong order or isolated setup/resume")
    require(isinstance(journey.get("shortcuts"), list) and journey["shortcuts"], "shortcuts are not disclosed")
    require(set(journey.get("legacy_cards", {})) == {"M2", "M3", "S2", "T2"}, "legacy chapter obligations omitted")
    require("LEGACY ORDER DIAGNOSTIC" not in text, "legacy diagnostic cannot earn F49 completion")
    handoffs = rows("F49 DISK HANDOFF ")
    require([row.get("boundary") for row in handoffs] ==
            ["meadows_settled", "tidewake_settled", "cloudreach_settled", "stormwood_settled", "completed_world"],
            "missing or out-of-order immutable disk handoffs")
    require(all(row.get("commit") == commit and row.get("files_sha256")
                and all(DIGEST.fullmatch(value) for value in row["files_sha256"].values()) for row in handoffs),
            "disk handoff identities/digests do not bind the exact candidate")
    return {"kind": "f49_journey_log_verification", "commit": commit, "sha256": digest(log), "order": ORDER,
            "scope": "one source smoke log only; exported clear cohorts and card proofs remain separate"}


def owner_check(data, commit, package_digest):
    require(SHA.fullmatch(commit) and data.get("commit") == commit, "owner notes use a different commit")
    require(DIGEST.fullmatch(package_digest) and data.get("package_sha256") == package_digest,
            "owner notes use a different download")
    require(data.get("participant") == "owner" and data.get("human_play_attestation") is True,
            "owner human play attestation is missing")
    require(data.get("controls") == "controller" and data.get("journey") == ORDER,
            "owner notes omit the ordinary controller campaign path")
    require(data.get("completed_world_continuation") is True, "owner did not record completed-world continuation")
    for field in ("started_at", "finished_at", "findings"):
        require(data.get(field), "owner notes need " + field)
    require(isinstance(data["findings"], list)
            and all(isinstance(row, dict) and row.get("observation")
                    and row.get("severity") in {"none", "minor", "major", "blocker"}
                    for row in data["findings"]), "invalid owner findings")
    require(not any(row["severity"] == "blocker" for row in data["findings"]),
            "owner play has an unresolved blocker")
    return {"kind": "f49_owner_notes_binding", "commit": commit, "package_sha256": package_digest,
            "findings": data["findings"], "scope": "validates supplied owner notes; never manufactures human play"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    package = commands.add_parser("package")
    for name in ("package", "commit", "sha256", "run", "jobs", "artifact"):
        package.add_argument("--" + name, required=True)
    package.add_argument("--repository", default="MJohnsonWellabe/Tetherbound")
    device = commands.add_parser("device")
    device.add_argument("--samples", required=True)
    device.add_argument("--commit", required=True)
    journey = commands.add_parser("journey")
    journey.add_argument("--log", required=True)
    journey.add_argument("--commit", required=True)
    owner = commands.add_parser("owner")
    owner.add_argument("--notes", required=True)
    owner.add_argument("--commit", required=True)
    owner.add_argument("--sha256", required=True)
    args = parser.parse_args()
    try:
        if args.command == "package":
            result = package_check(args.package, args.commit, args.sha256, read_json(args.run),
                                   read_json(args.jobs), read_json(args.artifact), args.repository)
        elif args.command == "device":
            result = device_check(read_json(args.samples), args.commit)
        elif args.command == "journey":
            result = journey_check(args.log, args.commit)
        else:
            result = owner_check(read_json(args.notes), args.commit, args.sha256)
        print(json.dumps(result, indent=2))
        return 0
    except (ValueError, OSError, KeyError, struct.error, zipfile.BadZipFile) as error:
        print(json.dumps({"verified": False, "error": str(error)}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
