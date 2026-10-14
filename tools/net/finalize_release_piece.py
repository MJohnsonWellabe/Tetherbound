#!/usr/bin/env python3
"""Turn a completed four-peer proof into a saved successor; never runs the engine.

Usage: python tools/net/finalize_release_piece.py PROOF_DIRECTORY PIECE OUTPUT_DIRECTORY
The output must not exist. This is checkpoint packaging, not export/build acceptance.
"""
import argparse
import base64
import copy
import hashlib
import json
from pathlib import Path
import re
import shutil


def require(condition, message):
    if not condition:
        raise ValueError(message)


def inherited_lineage(previous: dict, provenance: dict, current=()) -> dict:
    """checkpoint_lineage.gd::derive, with no authority to verify a fresh prefix."""
    inherited = previous.get("lineage", {})
    origins, status = [], "unproven"
    if isinstance(inherited, dict):
        if inherited.get("status") == "generated":
            status = "generated"
        elif (type(inherited.get("version")) is int and inherited["version"] == 1
              and inherited.get("status") == "earned" and inherited.get("continuous_fresh_save") is True
              and inherited.get("origins") == []):
            status = "earned"
        if isinstance(inherited.get("origins"), list):
            origins = copy.deepcopy(inherited["origins"])
    mode = str(previous.get("input_mode", ""))
    if mode.startswith("generated"):
        origins.append("predecessor input_mode=" + mode)
    if "generated_origin" in previous:
        origins.append("predecessor generated_origin=" + json.dumps(previous["generated_origin"]))
    if provenance.get("prior_earned_play") is False or "generated" in json.dumps(provenance).lower():
        origins.append("legacy PROVENANCE declares generated ancestry")
    if "generated" in json.dumps(previous.get("disclosures", [])).lower():
        origins.append("legacy receipt discloses generated input")
    origins.extend(current)
    unique = []
    for origin in origins:
        if origin not in unique:
            unique.append(origin)
    if unique or status == "generated":
        status = "generated"
    return {"version": 1, "status": status, "origins": unique, "continuous_fresh_save": status == "earned"}


def loaded_predecessor(rows: list, piece_index: int, current=()) -> tuple:
    loads = [row for row in rows if row.get("what") == "load_save" and row.get("peer") == 0]
    require(len(loads) == 1 and 0 < loads[0].get("index", 0) < piece_index,
            "one actual host predecessor load before the piece is required")
    data = loads[0].get("data", {})
    require(isinstance(data, dict), "host load has no predecessor witness")
    parent = data.get("predecessor")
    require(isinstance(parent, dict) and isinstance(data.get("loaded_from"), str)
            and data["loaded_from"] and parent.get("save_directory") == data["loaded_from"],
            "predecessor must be the host's actual loaded save directory")
    hashes = parent.get("save_sha256")
    require(isinstance(hashes, dict) and hashes and all(isinstance(path, str) and path
            and isinstance(digest, str) and re.fullmatch(r"[0-9a-f]{64}", digest)
            for path, digest in hashes.items()), "loaded predecessor save hashes missing")
    binding = {"save_directory": parent["save_directory"], "save_sha256": hashes,
               "load_step_index": loads[0]["index"]}
    documents, payloads = {}, {}
    for key, name in [("receipt", "receipt.json"), ("provenance", "PROVENANCE.json")]:
        witness = parent.get(key)
        require(isinstance(witness, dict) and type(witness.get("present")) is bool,
                "predecessor metadata presence was not witnessed: " + key)
        if not witness["present"]:
            binding[key], documents[key] = {"present": False}, {}
            continue
        require(isinstance(witness.get("bytes_base64"), str), "predecessor metadata bytes missing: " + key)
        raw = base64.b64decode(witness["bytes_base64"], validate=True)
        digest = hashlib.sha256(raw).hexdigest()
        require(digest == witness.get("sha256"), "predecessor metadata hash mismatch: " + key)
        document = json.loads(raw)
        require(isinstance(document, dict), "predecessor metadata must be an object: " + key)
        documents[key], payloads[name] = document, raw
        binding[key] = {"present": True, "sha256": digest, "path": "predecessor/" + name}
    return binding, payloads, inherited_lineage(documents["receipt"], documents["provenance"], current)


def generated_setup_origins(scenario: dict) -> list:
    """Retain the current replay generator's grants and disclosed portal setup."""
    origins = []
    for index, step in enumerate(scenario.get("steps", []), 1):
        if not isinstance(step, dict):
            continue
        action, args = step.get("action"), step.get("args", {})
        fixture = args.get("actual_portal_fixture") if isinstance(args, dict) else None
        if action in ("party_grant", "story_flag") or fixture:
            origins.append("current scenario generated setup: step %d peer %s action %s%s" % (
                index, step.get("peer"), action, " fixture=" + str(fixture) if fixture else ""))
    return origins


def finalize(proof_dir: Path, segment: str, output: Path) -> dict:
    proof_dir = proof_dir.resolve()
    output = output.resolve()
    require(not output.exists(), "output already exists; preserve the previous attempt")
    require(not output.is_relative_to(proof_dir), "checkpoint output must be outside the proof directory")
    proof_path = proof_dir / "PROOF.json"
    raw = proof_path.read_bytes()
    proof = json.loads(raw)
    require(isinstance(proof, dict) and proof.get("passed") is True
            and type(proof.get("exit_code")) is int and proof["exit_code"] == 0
            and proof.get("failures") == [], "proof did not complete successfully")
    commit = proof.get("source_commit", "")
    require(isinstance(commit, str) and re.fullmatch(r"[0-9a-f]{40}", commit), "exact source commit missing")
    scenario = proof.get("scenario", {})
    require(isinstance(scenario, dict) and scenario.get("peers") == 4
            and scenario.get("host_peer", 0) == 0, "proof must have host 0 and four peers")
    rows = proof.get("rows")
    require(isinstance(rows, list) and rows and all(isinstance(row, dict) and row.get("ok") is True
            and row.get("verdict") == "PASS" for row in rows), "proof contains missing or failed steps")
    pieces = [row for row in rows if row.get("what") == "piece_wait"]
    require(len(pieces) == 1 and pieces[0].get("peer") == 0, "one host piece completion required")
    piece = pieces[0].get("data", {})
    require(isinstance(piece, dict) and piece.get("segment") == segment
            and piece.get("passed") is True and piece.get("done") is True
            and piece.get("failures") == [], "named piece did not pass")
    predecessor, metadata, lineage = loaded_predecessor(rows, pieces[0].get("index", 0),
                                                       generated_setup_origins(scenario))
    captures = [row for row in rows if row.get("what") == "capture_saves"]
    require(len(captures) == 4 and sorted(row.get("peer", -1) for row in captures) == [0, 1, 2, 3],
            "one saved owner capture per peer required")
    require(all(row.get("index", 0) > pieces[0].get("index", 0) for row in captures),
            "captures must follow the completed piece")
    require(any(row.get("what") == "hashes_agree" and row.get("index", 0) > pieces[0].get("index", 0)
                for row in rows), "post-piece peer hash agreement missing")
    for row in captures:
        data = row.get("data", {})
        require(isinstance(data, dict) and data.get("owner_readback") is True
                and data.get("owner_error") == "" and data.get("copy_errors") == []
                and data.get("files", 0) > 0, "peer capture lacks matching persisted owner")
    host = next(row["data"] for row in captures if row["peer"] == 0)
    require(host.get("world_written") is True and host.get("owns_world") is True, "host world was not saved")
    after = host.get("handoff")
    require(isinstance(after, dict) and all(key in after for key in ("uids", "flags", "items", "realm", "training")),
            "captured host lacks handoff state")
    require(isinstance(after["training"], dict) and after["training"], "training handoff missing")
    captured = Path(host.get("dir", "")).resolve()
    require(captured.is_relative_to(proof_dir) and captured != proof_dir and captured.is_dir(),
            "host capture must be inside this proof directory")
    files = list(captured.rglob("*"))
    require(files and not any(path.is_symlink() or not path.resolve().is_relative_to(captured) for path in files),
            "capture contains a link or escapes its directory")
    slots = list((captured / "saves").rglob("slot_*.json"))
    require(len(slots) == 1, "captured host needs one uncompressed slot")
    hashes = {path.relative_to(captured).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
              for path in files if path.is_file()}
    require(hashes == host.get("file_sha256"), "capture bytes changed since the owner readback")
    require(any(path.startswith("worlds/") for path in hashes)
            and any(path.startswith("characters/") for path in hashes), "captured split saves missing")
    # Retain a partial output on failure, but never publish a PASS receipt until
    # every copied byte matches. Callers must choose a fresh directory to retry.
    output.mkdir(parents=True)
    shutil.copytree(captured, output / "save")
    for path, digest in hashes.items():
        require(hashlib.sha256((output / "save" / path).read_bytes()).hexdigest() == digest,
                "copied save differs: " + path)
    (output / "predecessor").mkdir()
    for name, payload in metadata.items():
        (output / "predecessor" / name).write_bytes(payload)
    provenance = {"kind": "four_peer_piece_checkpoint", "proof": str(proof_path),
                  "proof_sha256": hashlib.sha256(raw).hexdigest(), "commit": commit,
                  "run_id": proof.get("run_id"), "save_sha256": hashes,
                  "predecessor": predecessor, "lineage": lineage,
                  "scope": "Saved four-peer piece only; exported build identity and full chapter acceptance remain separate",
                  "claim": scenario.get("claim", "")}
    receipt = {"passed": True, "segment": segment, "commit": commit, "after": after,
               "input_mode": {"earned": "earned", "generated": "generated_ancestry",
                              "unproven": "unproven_ancestry"}[lineage["status"]],
               "lineage": lineage, "from": predecessor["save_directory"], "provenance": provenance}
    (output / "PROVENANCE.json").write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
    (output / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("proof", type=Path)
    parser.add_argument("segment")
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    try:
        finalize(args.proof, args.segment, args.output)
    except (OSError, ValueError, TypeError) as error:
        parser.exit(1, f"Checkpoint refused: {error}\n")
    print(args.output.resolve())


if __name__ == "__main__":
    main()
