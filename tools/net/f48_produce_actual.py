"""Run the existing native F48 producer from hash-pinned original saved sources.

The seed archive is NOT a ready CI bundle. Initial mechanics setup is delegated
to the existing disclosed fixture builder; only the native producer can create
the transaction inputs. Never manufacture a caught card, reward or receipt.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

import f48_profile_fixture as fixture
import f48_prepare_profile as prepare
from f48_ci_runner import configuration_overlay

ROOT = Path(__file__).resolve().parents[2]


def inside(root: Path, relative: str) -> Path:
    path = (root / relative).resolve()
    fixture.require(path.is_relative_to(root.resolve()) and path != root.resolve(),
                    "Seed document must remain inside its declared root")
    return path


def restore_seeds(bundle: Path, output: Path) -> list[Path]:
    manifest = fixture.read(bundle / "manifest.json")
    fixture.require(manifest.get("acceptance_credit") is False and manifest.get("ready_ci_bundle") is False,
                    "Source seeds are not acceptance or complete producer inputs")
    fixture.require(fixture.digest(bundle / "layout.json") == manifest["layout_sha256"], "Seed layout changed")
    peers = manifest["peers"]
    fixture.require(len(peers) == 4 and [p["peer"] for p in peers] == list(range(4)), "Four distinct original peers required")
    fixture.require(len({p["character_id"] for p in peers}) == 4 and len({p["creature_uid"] for p in peers}) == 4,
                    "Never clone an original identity")
    prepared: list[tuple[Path, bytes]] = []
    roots = [output / f"peer-{i}" for i in range(4)]
    seen: set[Path] = set()
    for peer in peers:
        for row in peer["documents"]:
            source = inside(bundle, row["path"])
            destination = inside(roots[peer["peer"]], row["relative"])
            fixture.require(destination not in seen, "Duplicate original document")
            seen.add(destination)
            compressed = source.read_bytes()
            fixture.require(hashlib.sha256(compressed).hexdigest() == row["compressed_sha256"], "Compressed original changed")
            original = gzip.decompress(compressed)
            fixture.require(hashlib.sha256(original).hexdigest() == row["source_sha256"], "Original saved bytes changed")
            prepared.append((destination, original))
    fixture.require(not output.exists(), "Fresh original-source output required")
    # Validate every archive before writing any original carrier.
    for destination, original in prepared:
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(original)
    for index, root in enumerate(roots):
        source = fixture.source_input(root, index == 0)
        fixture.require(source["id"] == peers[index]["character_id"] and source["uids"] == [peers[index]["creature_uid"]],
                        "Manifest and original saved identity differ")
    return roots


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--prepare-only", action="store_true")
    args = parser.parse_args()
    output = args.output.resolve()
    fixture.require(not output.exists(), "Fresh producer output required; preserve prior attempts")
    bundle = ROOT / "tests/fixtures/f48-producer-seeds"
    sources = restore_seeds(bundle, output / "originals")
    manifest = fixture.read(bundle / "manifest.json")
    fixture.generate(sources[:2], bundle / "layout.json", output / "mechanics-start", None,
                     manifest["provenance"], "full", True, True, True)
    profile_path = prepare.produce(output / "mechanics-start/profile.json", output / "producer-profile")
    if args.prepare_only:
        print(json.dumps({"profile": str(profile_path), "acceptance_credit": False, "native_run": False}))
        return 0
    profile = fixture.read(profile_path)
    home = output / "coordinator-home"
    home.mkdir()
    env = dict(os.environ, TB_F48_PROFILE=str(profile_path), TB_PROOF_OUT=str(output / "proof"),
               TB_NET_OUT_DIR=str(output / "net-run"), TB_F48_PROCESS_PYTHON=sys.executable,
               TB_NET_RUN_ID="f48-actual-" + str(os.getpid()),
               APPDATA=str(home), LOCALAPPDATA=str(home), XDG_DATA_HOME=str(home))
    command = [args.godot, "--headless", "--path", str(ROOT), "--script", "tools/net/f48_prepare.gd"]
    with configuration_overlay(ROOT, profile) as pins:
        fixture.write(output / "invocation.json", {"command": command, "profile_sha256": fixture.digest(profile_path),
                      "source_manifest_sha256": fixture.digest(bundle / "manifest.json"), "effective_configuration": pins,
                      "acceptance_credit": False, "ready_ci_bundle": False})
        with (output / "coordinator.log").open("wb") as log:
            result = subprocess.run(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT, check=False)
    print(json.dumps({"exit_code": result.returncode, "output": str(output), "acceptance_credit": False}))
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
