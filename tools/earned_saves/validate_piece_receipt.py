#!/usr/bin/env python3
"""Fail-closed launcher check; the game runner still verifies loaded state."""
import argparse
import json
from pathlib import Path


def validate(checkpoint: Path, segment: str) -> dict:
    receipt = json.loads((checkpoint / "receipt.json").read_text(encoding="utf-8"))
    if not isinstance(receipt, dict) or receipt.get("passed") is not True:
        raise ValueError("checkpoint receipt must contain boolean PASS")
    if receipt.get("segment") != segment:
        raise ValueError("checkpoint receipt must name " + segment)
    if not isinstance(receipt.get("after"), dict) or not receipt["after"]:
        raise ValueError("checkpoint receipt must contain its after-state")
    if not (checkpoint / "save").is_dir():
        raise ValueError("checkpoint has no save directory")
    return receipt


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkpoint", type=Path)
    parser.add_argument("segment")
    args = parser.parse_args()
    try:
        validate(args.checkpoint, args.segment)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Invalid checkpoint {args.checkpoint}: {error}\n")


if __name__ == "__main__":
    main()
