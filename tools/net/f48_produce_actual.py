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
from f48_ci_runner import FIELDS, configuration_overlay
from f48_configuration import shipping_configuration

ROOT = Path(__file__).resolve().parents[2]


def pin_shipping_profile(profile: dict, project: Path) -> None:
    """Bind the native guard to seven original config files, without overlays."""
    pins = [{"file": "res://data/config/" + name,
             "sha256": fixture.digest(project / "data/config" / name)}
            for name in sorted(set(FIELDS) | {"combat.json"})]
    profile["test_configuration"] = [row.copy() for row in pins
                                     if not row["file"].endswith("/combat.json")]
    profile["configuration_scope"] = "full"
    profile["production_configuration_pins"] = pins
    profile["provenance"] += " Shipping configuration bytes preserved; no mechanics overlay or flag overrides."


def loop_profile(source: Path, output: Path, shipping_config: bool = False) -> Path:
    path = prepare.produce(source, output)
    if shipping_config:
        profile = fixture.read(path)
        pin_shipping_profile(profile, ROOT)
        fixture.write(path, profile)
        source_record = fixture.read(output / "source.json")
        source_record["profile_sha256"] = fixture.digest(path)
        fixture.write(output / "source.json", source_record)
    return path


def boss_profile(source: Path, output: Path, shipping_config: bool = False) -> Path:
    """Declare the same real boss input actions for four original participants."""
    profile = fixture.read(source)
    fixture.require(len(profile["saves"]) == 4, "Four original boss participants required")
    fixture.require(not output.exists(), "Fresh boss profile required")
    routes = {}
    for peer in range(4):
        routes[f"boss_prepare_{peer}"] = prepare.approach("warden_aldis")
        if peer > 0:
            routes[f"boss_join_{peer}"] = [prepare.step("f48_fixture_join_boss",
                fixture_disclosure="named_mechanics_actual_announced_boss_join_no_earned_credit")]
    routes["boss_start"] = [prepare.press("interact"), prepare.wait(),
                            prepare.step("f48_dialogue", conversation="stronghold_warden_challenge"), prepare.wait(90)]
    routes["boss_fight"] = [prepare.fight("warden_aldis")]
    profile["routes"] = routes
    profile["outcomes"] = {}
    profile["provenance"] += (" Four original distinct participants. Disclosed named actor/ally placement,"
        " actual announced boss joins and self-HP aid. No enemy HP ceiling, authored outcome or earned campaign credit.")
    if shipping_config:
        pin_shipping_profile(profile, ROOT)
    output.mkdir(parents=True)
    path = output / "profile.json"
    fixture.write(path, profile)
    fixture.write(output / "source.json", {"source": str(source), "source_sha256": fixture.digest(source),
        "profile_sha256": fixture.digest(path), "acceptance_credit": False, "ready_ci_bundle": False})
    return path


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
    parser.add_argument("--producer", choices=("loop", "boss_four", "behind"), default="loop")
    parser.add_argument("--shipping-config", action="store_true",
                        help="Pin shipping configuration without overlays; behind requires a matching shipping loop")
    parser.add_argument("--loop-output", type=Path)
    parser.add_argument("--loop-profile", type=Path)
    parser.add_argument("--loop-profile-sha256")
    parser.add_argument("--behind-guest-peer", type=int, choices=(2, 3), default=2)
    args = parser.parse_args()
    output = args.output.resolve()
    fixture.require(not output.exists(), "Fresh producer output required; preserve prior attempts")
    bundle = ROOT / "tests/fixtures/f48-producer-seeds"
    if args.producer == "behind":
        fixture.require(args.loop_output is not None and args.loop_profile is not None and args.loop_profile_sha256,
                        "Behind requires the completed original loop artifact, reviewed profile and SHA256")
        import f48_behind_profile
        profile_path = f48_behind_profile.generate(args.loop_output, args.loop_profile,
            args.loop_profile_sha256, output, args.behind_guest_peer, shipping_config=args.shipping_config)
    else:
        fixture.require(args.loop_output is None and args.loop_profile is None and args.loop_profile_sha256 is None,
                        "Loop source arguments apply only to behind producer")
        sources = restore_seeds(bundle, output / "originals")
        manifest = fixture.read(bundle / "manifest.json")
        fixture.generate(sources if args.producer == "boss_four" else sources[:2], bundle / "layout.json", output / "mechanics-start", None,
                         manifest["provenance"], "full", True, True, True)
        source_profile = output / "mechanics-start/profile.json"
        profile_path = boss_profile(source_profile, output / "producer-profile", args.shipping_config) \
            if args.producer == "boss_four" else loop_profile(source_profile, output / "producer-profile", args.shipping_config)
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
    if args.producer == "boss_four":
        # Attribute a repeated liveness failure without extending any deadline.
        # This existing observer measures real heartbeat snapshots/encoding.
        env["TB_PEER_PHASE_TRACE"] = "1"
        env["TB_BACKGROUND_WORK_TRACE"] = "1"
    script = {"loop": "tools/net/f48_prepare.gd", "boss_four": "tools/net/f48_prepare_boss_four.gd",
              "behind": "tools/net/f48_prepare_behind.gd"}[args.producer]
    command = [args.godot, "--headless", "--path", str(ROOT), "--script", script]
    configuration = shipping_configuration(ROOT, profile) if args.shipping_config else configuration_overlay(ROOT, profile)
    with configuration as pins:
        fixture.write(output / "invocation.json", {"command": command, "profile_sha256": fixture.digest(profile_path),
                      "source_manifest_sha256": fixture.digest(bundle / "manifest.json"), "effective_configuration": pins,
                      "shipping_configuration": args.shipping_config,
                      "peer_phase_trace": env.get("TB_PEER_PHASE_TRACE") == "1",
                      "background_work_trace": env.get("TB_BACKGROUND_WORK_TRACE") == "1",
                      "acceptance_credit": False, "ready_ci_bundle": False})
        with (output / "coordinator.log").open("wb") as log:
            result = subprocess.run(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT, check=False)
    # Keep the final native failure visible even when a runner fails before its
    # ordinary log-summary step. The complete log remains in the visible bundle.
    with (output / "coordinator.log").open("rb") as log:
        log.seek(max(0, (output / "coordinator.log").stat().st_size - 20000))
        print(log.read().decode("utf-8", errors="replace"), flush=True)
    print(json.dumps({"exit_code": result.returncode, "output": str(output), "acceptance_credit": False}))
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
