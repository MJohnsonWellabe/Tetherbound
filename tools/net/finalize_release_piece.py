#!/usr/bin/env python3
"""Turn a completed four-peer proof into a saved successor; never runs the engine.

Usage: python tools/net/finalize_release_piece.py PROOF_DIRECTORY PIECE OUTPUT_DIRECTORY
The output must not exist. This is checkpoint packaging, not export/build acceptance.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil


def require(condition, message):
    if not condition:
        raise ValueError(message)


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
    provenance = {"kind": "four_peer_piece_checkpoint", "proof": str(proof_path),
                  "proof_sha256": hashlib.sha256(raw).hexdigest(), "commit": commit,
                  "run_id": proof.get("run_id"), "save_sha256": hashes,
                  "scope": "Saved four-peer piece only; exported build identity and full chapter acceptance remain separate",
                  "claim": scenario.get("claim", "")}
    receipt = {"passed": True, "segment": segment, "commit": commit, "after": after,
               "provenance": provenance}
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
