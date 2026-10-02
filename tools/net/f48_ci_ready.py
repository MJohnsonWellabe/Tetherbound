"""Read-only F48 complete-input integrity gate; never run an engine or earn credit.

Check a packaged or relocated profile before launching any of the original
smokes. Optional producer arguments also verify the terminal native evidence
against the exact reviewed producer profile. Missing/failed evidence is fatal.
"""
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path

import f48_profile_fixture as fixture
import f48_profile_ready as ready
from f48_relocate_profile import tail

SUITES = {"loop", "behind", "boss_four"}
OPERATIONS = set(fixture.OPERATIONS)
CUTS = ("before_input", "after_settlement", "after_host_write_before_delivery",
        "after_owner_write_before_ack")
require = fixture.require


def terminal_producer(root: Path, profile_path: Path, expected_sha: str) -> dict:
    """Read actual terminal artifacts; a partial snapshot is never sufficient."""
    require(fixture.digest(profile_path) == expected_sha, "Reviewed producer profile hash mismatch")
    invocation = fixture.read(root / "invocation.json")
    require(invocation.get("profile_sha256") == expected_sha, "Producer invocation profile mismatch")
    run = fixture.read(root / "net-run/NET_RUN.json")
    require(run.get("failures") == [] and run.get("fatal") == "",
            "Actual producer failed; packaging refused")
    peers = run.get("peers", [])
    require(isinstance(peers, list) and len(peers) == 2 and
            {peer.get("index") for peer in peers} == {0, 1} and
            all(peer.get("exited") is True and peer.get("unexpected_exit") is False for peer in peers),
            "Actual producer peers are not clean terminal returns")
    lines = (root / "coordinator.log").read_text(encoding="utf-8").splitlines()
    lines = [line.strip() for line in lines if line.strip()]
    require(lines and lines[-1] == "ALL CHECKS PASSED" and
            not any(line.startswith(("FAIL:", "SCRIPT ERROR:")) for line in lines),
            "Actual clean terminal coordinator verdict unavailable")
    profile = fixture.read(profile_path)
    expected = [{"file": row["file"], "sha256": row["sha256"]}
                for row in profile["test_configuration"]]
    require(invocation.get("effective_configuration") == expected,
            "Producer effective configuration differs from original profile pins")
    return {str(path.relative_to(root)): fixture.digest(path) for path in
            (root / "invocation.json", root / "net-run/NET_RUN.json", root / "coordinator.log")}


def validate_routes(name: str, start: dict) -> None:
    fixture.validate_pack({key: start[key] for key in ("provenance", "routes", "outcomes")})
    required = set()
    if name in OPERATIONS:
        required |= {name + suffix for suffix in ("_prepare", "_commit", "_reopen")}
    if name in {"loop", "boss_four"}:
        peers = 4 if name == "boss_four" else 2
        required |= {f"boss_prepare_{peer}" for peer in range(peers)}
        required |= {f"boss_join_{peer}" for peer in range(1, peers)} | {"boss_start", "boss_fight"}
    if name == "loop":
        required |= {f"{stage}_{peer}" for stage in
                     ("hub", "craft", "portal", "master", "feast_cook", "feast", "relic") for peer in range(2)}
    if name == "behind":
        required |= {"host_unlock_tidewake", "host_enter_tidewake", "behind_enter_tidewake"}
    require(required <= start["routes"].keys(), f"Missing original routes for {name}: {sorted(required - start['routes'].keys())}")
    outcomes = {"feast_0", "feast_1"} if name == "loop" else (
        {name + "_1"} if name in {"feast", "release", "essence_spend"} else set())
    for key in outcomes:
        row = start["outcomes"].get(key, {})
        require(isinstance(row, dict) and isinstance(row.get("item_delta"), dict) and row["item_delta"],
                f"Missing independent item outcome: {key}")
        if key == "release_1":
            require(isinstance(row.get("released_uid"), str) and row["released_uid"], "Missing original release UID")
        else:
            require(isinstance(row.get("creature"), dict) and
                    {"uid", "level", "breakthroughs"} <= row["creature"].keys(),
                    f"Missing independent owned creature outcome: {key}")


def checked_path(bundle: Path, raw: str, marker: str) -> Path:
    path = bundle / tail(raw, marker)
    require(path.resolve().is_relative_to(bundle), "Pinned path escaped bundle")
    require(not any(parent.is_symlink() or
                    (hasattr(parent, "is_junction") and parent.is_junction())
                    for parent in (path, *path.parents) if parent.is_relative_to(bundle)),
            "Bundle links/junctions cannot replace pinned input bytes")
    return path


def validate(profile_path: Path, bundle: Path | None = None) -> dict:
    profile_path = profile_path.resolve()
    profile = fixture.read(profile_path)
    require(set(profile.get("suite_profiles", {})) == SUITES and
            set(profile.get("transaction_profiles", {})) == OPERATIONS,
            "Require all nine original starts, including four-peer boss and every transaction")
    starts = {**profile["suite_profiles"], **profile["transaction_profiles"]}
    if bundle is None:
        # Native profiles use absolute local roots. A moved Windows profile
        # must first pass through the existing paths-only relocation tool.
        bundle = Path(starts["loop"]["saves"][0]).parents[2]
    bundle = bundle.resolve()
    manifest = fixture.read(bundle / "producer-manifest.json")
    original_path = bundle / "profile.json"
    require(fixture.digest(original_path) == manifest.get("profile_sha256"), "Packaged profile hash mismatch")
    require(manifest.get("acceptance_credit") is False and manifest.get("earned_checkpoint") is False and
            manifest.get("mutations") == [] and set(manifest["starts"]) == SUITES | OPERATIONS,
            "Require immutable nine-start actual-input manifest without acceptance credit")
    original = fixture.read(original_path)
    expected = copy.deepcopy(original)
    pinned_files = set()
    for group in ("suite_profiles", "transaction_profiles"):
        for name, start in expected[group].items():
            require(len(start["saves"]) == (4 if name == "boss_four" else 2), "Original peer count missing")
            roots = []
            for index, raw in enumerate(start["saves"]):
                path = checked_path(bundle, raw, "starts")
                require(path == bundle / "starts" / name / f"peer-{index}", "Cross-start or cross-peer save path")
                roots.append(path)
            closure = set()
            for row in manifest["starts"][name]["documents"]:
                path = checked_path(bundle, row["path"], "starts")
                require(any(path.is_relative_to(root) for root in roots) and path not in closure,
                        "Duplicate/cross-start document pin")
                require(path.is_file() and fixture.digest(path) == row["sha256"], "Pinned saved document byte mismatch")
                closure.add(path)
            actual = set()
            for root in roots:
                require(root.is_dir(), "Actual prepared save directory missing")
                for path in root.rglob("*"):
                    checked_path(bundle, str(path), "starts")
                    if path.is_file(): actual.add(path)
            require(actual == closure, "Unlisted or missing actual saved input bytes")
            inputs = [fixture.source_input(root, index == 0) for index, root in enumerate(roots)]
            require(len({source["id"] for source in inputs}) == len(inputs), "Cloned character identities")
            uids = [uid for source in inputs for uid in source["uids"]]
            require(len(set(uids)) == len(uids), "Cloned owned creature identities")
            ready.prerequisite(name, inputs)
            validate_routes(name, start)
            start["saves"] = [str(root) for root in roots]
            pinned_files |= closure
    defaults = [start for group in ("suite_profiles", "transaction_profiles")
                for start in original[group].values() if start["saves"] == original["saves"]]
    require(len(defaults) == 1, "Default roots must match one original named start")
    expected["saves"] = [str(checked_path(bundle, raw, "starts")) for raw in original["saves"]]
    configurations = expected.get("test_configuration", [])
    require(expected.get("configuration_scope") == "full" and isinstance(configurations, list) and
            len(configurations) == len(ready.CONFIGURATION_FILES) and
            {row["file"] for row in configurations} ==
            {"res://data/config/" + name for name in ready.CONFIGURATION_FILES},
            "Require exact original full configuration pin set")
    for row in expected["test_configuration"]:
        path = checked_path(bundle, row["overlay_file"], "test-configuration")
        require(path == bundle / "test-configuration/data/config" / Path(row["file"]).name,
                "Overlay pin names a different configuration")
        require(path.is_file() and fixture.digest(path) == row["sha256"], "Pinned overlay byte mismatch")
        require(fixture.digest(fixture.ROOT / "data/config" / path.name) == row["source_sha256"],
                "Production configuration differs from original source pins")
        row["overlay_file"] = str(path)
    require(profile == expected, "Profile differs from original pins beyond verified local path relocation")
    return {"ok": True, "starts": sorted(starts), "transaction_cases": len(OPERATIONS) * len(CUTS),
            "saved_documents": len(pinned_files), "profile_sha256": fixture.digest(profile_path),
            "acceptance_credit": False, "status": "INPUT_INTEGRITY_ONLY_NATIVE_ORACLES_REQUIRED"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", type=Path)
    parser.add_argument("--bundle", type=Path)
    parser.add_argument("--producer-root", type=Path)
    parser.add_argument("--producer-profile", type=Path)
    parser.add_argument("--producer-profile-sha256")
    args = parser.parse_args()
    try:
        require(args.profile is not None or args.producer_root is not None, "Require profile or terminal producer")
        result = {"ok": True, "acceptance_credit": False}
        if args.producer_root:
            require(args.producer_profile is not None and args.producer_profile_sha256,
                    "Producer needs exact reviewed profile and SHA256")
            result["terminal_artifacts"] = terminal_producer(args.producer_root, args.producer_profile,
                                                            args.producer_profile_sha256)
        if args.profile: result.update(validate(args.profile, args.bundle))
        print(json.dumps(result))
        return 0
    except (OSError, ValueError, KeyError, TypeError, IndexError, AttributeError) as error:
        print(json.dumps({"ok": False, "error": str(error), "acceptance_credit": False}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
