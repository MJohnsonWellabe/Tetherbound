"""Run one original F48 smoke with a pinned disclosed mechanics overlay.

The CI caller supplies an immutable full prepared profile generated with
f48_profile_ready.py --require-complete. No route, oracle, cut, or test is
removed. This explicit runner requires the caller's serialized engine lease;
its lock refuses another F48 overlay writer in the same checkout. Native
output and exit status pass through unchanged. All configuration bytes are
restored in finally; production defaults are never committed or promoted.
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

import f48_ci_ready

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = {"tests/smoke_net_f48_loop.gd", "tests/smoke_net_f48_behind.gd",
           "tests/smoke_net_f48_transactions.gd", "tests/smoke_net_f48_boss_four.gd"}
FIELDS = {"stations.json": {"runtime_enabled", "craft_runtime_enabled", "forge.runtime_enabled"},
          "essence.json": {"altar_runtime_enabled", "altar_building_runtime_enabled", "altar_remote_spend_enabled"},
          "traits.json": {"runtime_enabled"},
          "multiplayer.json": {"session.redesign_portal_runtime_enabled", "session.redesign_boss_handoff_runtime_enabled"},
          "hud.json": {"new_system_screens.enabled"},
          "alpha_respawns.json": {"runtime_enabled"}}
OPERATIONS = {"craft", "release", "feast", "key", "relic", "essence_spend"}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def altered_fields(original: object, effective: object, prefix: str = "") -> set[str]:
    require(type(original) is type(effective), "Overlay changed configuration value type")
    if isinstance(original, dict):
        require(original.keys() == effective.keys(), "Overlay changed configuration keys")
        result: set[str] = set()
        for key in original:
            result |= altered_fields(original[key], effective[key], f"{prefix}.{key}" if prefix else key)
        return result
    # Lists/strings/numbers must remain exactly equal. Only typed booleans at
    # the explicitly named paths may change, and only to enabled for this run.
    if original != effective:
        require(type(original) is bool and effective is True, "Overlay changed a non-boolean field or disabled a gate")
        return {prefix}
    return set()


@contextmanager
def configuration_overlay(project: Path, profile: dict):
    require(profile.get("configuration_scope") == "full", "Require the reviewed full named-mechanics overlay")
    rows = profile.get("test_configuration")
    require(isinstance(rows, list) and len(rows) == len(FIELDS), "Full overlay configuration file set missing")
    prepared = []
    names = set()
    for row in rows:
        require(isinstance(row, dict), "Malformed configuration pin")
        name = Path(row["file"]).name
        require(name in FIELDS and name not in names and row["file"] == "res://data/config/" + name,
                "Unknown, duplicated, or mismatched configuration path")
        names.add(name)
        original_path = project / "data/config" / name
        overlay_path = Path(row["overlay_file"])
        require(original_path.resolve() != overlay_path.resolve(), "Overlay must be separate from production configuration")
        original = original_path.read_bytes()
        effective = overlay_path.read_bytes()
        require(digest(original) == row["source_sha256"] and digest(effective) == row["sha256"],
                "Original/effective configuration differs from the reviewed pins")
        changed = altered_fields(json.loads(original), json.loads(effective))
        require(changed <= FIELDS[name] and set(row["enabled_fields"]) == FIELDS[name],
                "Overlay changes fields outside its exact named-mechanics scope")
        parsed = json.loads(effective)
        for field in FIELDS[name]:
            value = parsed
            for part in field.split("."):
                value = value[part]
            require(value is True, "Effective named-mechanics gate is not enabled")
        prepared.append((original_path, original, effective))
    require(names == set(FIELDS), "Full effective configuration set missing")
    lock_path = project / ".tmp/f48-native-overlay.lock"
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    # An existing lock is a failure, never silently cleared as stale.
    with lock_path.open("x", encoding="utf-8") as lock:
        lock.write(json.dumps({"pid": os.getpid(), "scope": "explicit F48 mechanics overlay"}))
        lock.flush()
    mutated = []
    try:
        # Recheck after owning the overlay lock, before any mutation.
        for path, original, _ in prepared:
            require(path.read_bytes() == original, "Production configuration changed while acquiring the overlay lease")
        for path, original, effective in prepared:
            mutated.append((path, original, effective))
            path.write_bytes(effective)
        yield [{"file": "res://data/config/" + path.name, "sha256": digest(effective)}
               for path, _, effective in prepared]
    finally:
        # Keep the lock if restoration fails. A later run must not proceed on
        # ambiguous effective bytes. There is no recursive workspace cleanup.
        for path, original, _ in mutated:
            path.write_bytes(original)
            require(path.read_bytes() == original, "Production configuration restoration failed")
        lock_path.unlink()


def validate_ready_profile(profile: dict, script: str) -> None:
    suites = profile.get("suite_profiles", {})
    starts = profile.get("transaction_profiles", {})
    require(isinstance(suites, dict) and {"loop", "behind", "boss_four"} == suites.keys() and
            isinstance(starts, dict) and OPERATIONS == starts.keys(),
            "Complete required F48 input bundle missing; no default suite or cut is skipped")
    if script.endswith("boss_four.gd"):
        require("boss_four" in suites, "Original four-peer boss input absent")
    for name, row in {**suites, **starts}.items():
        require(isinstance(row, dict) and isinstance(row.get("saves"), list) and
                len(row["saves"]) == (4 if name == "boss_four" else 2), "Original input peer count missing")
        require(all(isinstance(path, str) and Path(path).is_dir() for path in row["saves"]),
                "Actual prepared save directory missing")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--profile", type=Path, required=True)
    parser.add_argument("--script", choices=sorted(SCRIPTS), required=True)
    parser.add_argument("--proof-out", type=Path, required=True)
    args = parser.parse_args()
    try:
        profile_path = args.profile.resolve()
        profile = json.loads(profile_path.read_bytes())
        validate_ready_profile(profile, args.script)
        readiness = f48_ci_ready.validate(profile_path)
        output = args.proof_out.resolve()
        require(not output.exists(), "Fresh detached native output required")
        output.mkdir(parents=True)
        environment = dict(os.environ, TB_F48_PROFILE=str(profile_path), TB_PROOF_OUT=str(output),
                           TB_F48_PROCESS_PYTHON=sys.executable)
        # Keep the actual coordinator home and scenario together with native
        # logs/receipts, even on failure. No temporary home is recursively
        # deleted while original peer-process evidence may still be needed.
        coordinator = tempfile.mkdtemp(prefix="f48-coordinator-", dir=output)
        require(Path(coordinator).resolve().is_relative_to(output), "Coordinator home escaped named native output")
        environment.update(XDG_DATA_HOME=coordinator, APPDATA=coordinator, LOCALAPPDATA=coordinator)
        environment.setdefault("TB_NET_OUT_DIR", str(output / "net-run"))
        with configuration_overlay(ROOT, profile) as pins:
            print(json.dumps({"disclosed_mechanics_overlay": pins, "profile_sha256": digest(profile_path.read_bytes()),
                              "script": args.script, "readiness": readiness, "acceptance_credit": False}), flush=True)
            result = subprocess.run([args.godot, "--headless", "--path", str(ROOT), "--script", "res://" + args.script],
                                    cwd=ROOT, env=environment, check=False)
        return result.returncode
    except (OSError, ValueError, KeyError, TypeError, IndexError, AttributeError) as error:
        print(json.dumps({"ok": False, "error": str(error)}), flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
