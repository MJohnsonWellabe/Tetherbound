"""Prepare real behind-Tidewake inputs from a successful pinned loop producer.

Copies the native pre-key host capture and one unmodified original nonparticipant
guest. No stock, flags, poses, cards, rewards or receipts are written. The new
profile drives the shipping arch twice for its host and once for its guest;
f48_prepare_behind.gd must still pass the original behind oracle in native play.
"""
from __future__ import annotations

import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re

import f48_ci_ready as gate
import f48_prepare_profile as actions
import f48_profile_fixture as fixture
import f48_profile_ready as ready
from f48_relocate_profile import tail

ROOT = Path(__file__).resolve().parents[2]
SEEDS = ROOT / "tests/fixtures/f48-producer-seeds"
CAPTURE = "f48-before-key"
require = fixture.require


def inside(root: Path, relative: str | Path) -> Path:
    relative = Path(relative)
    require(not relative.is_absolute() and relative.parts and ".." not in relative.parts,
            "Unsafe original source path")
    path = root / relative
    require(path.resolve().is_relative_to(root), "Original source escaped root")
    for item in (path, *path.parents):
        if not item.is_relative_to(root): break
        require(not item.is_symlink() and not (hasattr(item, "is_junction") and item.is_junction()),
                "Original source links refused")
    return path


def generate(loop_root: Path, profile_path: Path, profile_sha256: str, output: Path,
             guest_peer: int = 2) -> Path:
    """Generate the standard producer layout; the native launcher is separate."""
    loop_root, output = loop_root.resolve(), output.resolve()
    require(not output.exists(), "Fresh behind output required")
    require(not output.is_relative_to(loop_root) and not loop_root.is_relative_to(output),
            "Output must be disjoint from original loop evidence")
    require(type(guest_peer) is int and guest_peer in (2, 3), "Choose original nonparticipant peer 2 or 3")
    require(isinstance(profile_sha256, str) and re.fullmatch(r"[0-9a-f]{64}", profile_sha256),
            "Retained reviewed loop profile SHA256 required")
    profile_path = profile_path.resolve()
    require(profile_path.is_relative_to(loop_root), "Reviewed loop profile must be inside original producer")
    inside(loop_root, profile_path.relative_to(loop_root))
    pins: dict[Path, str] = {}
    copies: dict[Path, bytes] = {}

    def pin(path: Path, expected: str | None = None) -> bytes:
        raw = path.read_bytes()
        actual = hashlib.sha256(raw).hexdigest()
        require(expected is None or actual == expected, f"Original source hash mismatch: {path}")
        require(path not in pins or pins[path] == actual, f"Original source changed: {path}")
        pins[path] = actual
        return raw

    pin(profile_path, profile_sha256)
    profile = fixture.read(profile_path)
    terminal = gate.terminal_producer(loop_root, profile_path, profile_sha256)
    for relative, digest in terminal.items(): pin(inside(loop_root, relative), digest)
    require("tools/net/f48_prepare.gd" in fixture.read(loop_root / "invocation.json").get("command", []),
            "Original successful loop producer required")
    require(len(profile["saves"]) == 2 and profile.get("configuration_scope") == "full",
            "Original full two-peer loop profile required")
    report = pin(inside(loop_root, "proof/PROOF.md")).decode("utf-8")
    require("**Verdict: PASS**" in report and "**Verdict: FAIL**" not in report, "Original loop proof must pass")
    capture = inside(loop_root, Path("proof/peer-0") / CAPTURE)
    host = fixture.source_input(capture, True)
    for item in capture.rglob("*"): inside(loop_root, item.relative_to(loop_root))
    native_documents = [host["character_path"], host["world_path"], host["slot_path"]]
    for path in native_documents:
        raw = pin(path)
        require(f"`{path.relative_to(loop_root / 'proof').as_posix()}`" in report,
                "Actual host capture missing from native proof report")
        copies[Path("mechanics-start/peer-0") / path.relative_to(capture)] = raw
    matched = False
    for observation in inside(loop_root, "proof/f48-observations").glob("f48_assert_snapshot-*.json"):
        inside(loop_root, observation.relative_to(loop_root))
        row = fixture.read(observation)
        result = row.get("result", {})
        data = result.get("data", {})
        if (row.get("action") == "f48_assert_snapshot" and result.get("verdict") == "PASS"
                and data.get("character_id") == host["id"]
                and data.get("character_sha256") == pins[host["character_path"]]
                and data.get("world_sha256") == pins[host["world_path"]]
                and data.get("snapshot_source") == "actual_owner_BOOL_edge_full_canonical_after_and_accepted_ACK"):
            pin(observation)
            matched = True
    require(matched, "Actual pre-key host bytes lack the sealed native owner-save/ACK snapshot")
    personal = host["character"]["redesign_character"]
    require(host["character"].get("realm") == "meadows"
            and ready.counts(host["character"]).get("tidewake_portal_key", 0) >= 1
            and "meadows" in personal.get("relics_held", [])
            and "tidewake" not in personal.get("portal_unlocks", [])
            and "tidewake" not in host["world"].get("redesign_world", {}).get("portal_unlocks", []),
            "Actual host must retain its original unspent key/relic and unopened Tidewake world")

    # Archive peer 2/3 never participated in this two-peer loop. Restoring the
    # old loop guest would expose its actual pending/accepted boss rewards.
    pin(SEEDS / "manifest.json")
    manifest = fixture.read(SEEDS / "manifest.json")
    require(manifest.get("acceptance_credit") is False and manifest.get("ready_ci_bundle") is False,
            "Original archive must remain disclosed nonacceptance input")
    candidates = [row for row in manifest["peers"] if row.get("peer") == guest_peer]
    require(len(candidates) == 1 and len(candidates[0]["documents"]) == 1,
            "Require one original portable nonparticipant carrier")
    seed = candidates[0]
    row = seed["documents"][0]
    compressed = pin(inside(SEEDS.resolve(), row["path"]), row["compressed_sha256"])
    raw = gzip.decompress(compressed)
    require(hashlib.sha256(raw).hexdigest() == row["source_sha256"], "Original guest archive bytes changed")
    import save_document
    guest = save_document.decode(json.loads(raw))
    expected = Path("characters/redesign-v28") / seed["character_id"] / "character.json"
    require(Path(row["relative"]) == expected and guest.get("version") == 28
            and guest.get("character_id") == seed["character_id"]
            and [card.get("uid") for card in guest.get("party", [])] == [seed["creature_uid"]]
            and set(guest.get("redesign_character", {}).get("creatures", {})) == {seed["creature_uid"]},
            "Original guest identity or party differs from archive provenance")
    require(guest["character_id"] != host["id"] and seed["creature_uid"] not in host["uids"],
            "Never clone original character or companion identities")
    ready.prerequisite("behind", [host, {"character": guest}])
    copies[Path("mechanics-start/peer-1") / expected] = raw

    configurations = copy.deepcopy(profile.get("test_configuration", []))
    require(len(configurations) == len(ready.CONFIGURATION_FILES)
            and {row["file"] for row in configurations} ==
                {"res://data/config/" + name for name in ready.CONFIGURATION_FILES},
            "All six reviewed configuration pins required")
    for row in configurations:
        suffix = Path("mechanics-start") / tail(row["overlay_file"], "test-configuration")
        require(suffix == Path("mechanics-start/test-configuration/data/config") / Path(row["file"]).name,
                "Configuration path differs from original resource")
        copies[suffix] = pin(inside(loop_root, suffix), row["sha256"])
        pin(ROOT / row["file"].removeprefix("res://"), row["source_sha256"])
        row["overlay_file"] = str(output / suffix)
    routes = {
        "host_unlock_tidewake": actions.contact("tidewake_arch") + [actions.wait(180)],
        "host_enter_tidewake": [actions.press("interact"), actions.wait(240)],
        "behind_enter_tidewake": actions.contact("tidewake_arch") + [actions.wait(240)],
    }
    provenance = ("Actual pinned successful loop pre-key host plus unchanged original nonparticipant archive guest. "
                  "Disclosed named actor/owned-ally approach only; original key spent by ordinary interact, "
                  "actual shared world unlock and guest barrier. No saved-state mutation or earned campaign credit.")
    pack = {"provenance": provenance, "routes": routes, "outcomes": {}}
    gate.validate_routes("behind", pack)
    generated = {**pack, "configuration_scope": "full", "test_configuration": configurations,
                 "saves": [str(output / "mechanics-start" / f"peer-{peer}") for peer in range(2)]}
    for path, digest in pins.items(): require(fixture.digest(path) == digest, f"Original source changed before copy: {path}")
    output.mkdir(parents=True)
    for relative, data in copies.items():
        destination = output / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
    for peer in range(2): fixture.source_input(Path(generated["saves"][peer]), peer == 0)
    profile_out = output / "producer-profile/profile.json"
    fixture.write(profile_out, generated)
    fixture.write(output / "producer-profile/route-pack.json", pack)
    fixture.write(output / "producer-profile/source.json", {
        "loop_root": str(loop_root), "loop_profile_sha256": profile_sha256, "host_capture": CAPTURE,
        "guest_archive_peer": guest_peer, "profile_sha256": fixture.digest(profile_out),
        "acceptance_credit": False, "ready_ci_bundle": False, "saved_mutations": [],
        "sources": [{"path": str(path), "sha256": digest} for path, digest in pins.items()]})
    return profile_out


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--loop-output", type=Path, required=True)
    parser.add_argument("--loop-profile", type=Path, required=True)
    parser.add_argument("--loop-profile-sha256", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--behind-guest-peer", type=int, choices=(2, 3), default=2)
    args = parser.parse_args()
    path = generate(args.loop_output, args.loop_profile, args.loop_profile_sha256,
                    args.output, args.behind_guest_peer)
    print(json.dumps({"profile": str(path), "sha256": fixture.digest(path), "acceptance_credit": False}))
