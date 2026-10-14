#!/usr/bin/env python3
"""Fail-closed launcher check; the game runner still verifies loaded state."""
import argparse
import json
from pathlib import Path


def validate(checkpoint: Path, segment: str, *, require_route_state: bool = False,
             expected_realm: str | None = None) -> dict:
    receipt = json.loads((checkpoint / "receipt.json").read_text(encoding="utf-8"))
    if not isinstance(receipt, dict) or receipt.get("passed") is not True:
        raise ValueError("checkpoint receipt must contain boolean PASS")
    if receipt.get("segment") != segment:
        raise ValueError("checkpoint receipt must name " + segment)
    if not isinstance(receipt.get("after"), dict) or not receipt["after"]:
        raise ValueError("checkpoint receipt must contain its after-state")
    if not (checkpoint / "save").is_dir():
        raise ValueError("checkpoint has no save directory")
    slot = checkpoint / "save" / "slot_0.json"
    if not slot.is_file() or slot.stat().st_size == 0:
        raise ValueError("checkpoint has no nonempty slot_0.json save carrier")
    if require_route_state:
        # Mirror the release handoff's required witness fields, without claiming
        # that receipt contents prove what production Load will actually read.
        after = receipt["after"]
        uids = after.get("uids")
        if not isinstance(uids, list) or len(uids) != 5 or any(
                not isinstance(uid, str) or not uid.strip() for uid in uids) or len(set(uids)) != 5:
            raise ValueError("route checkpoint must name five distinct ordered UIDs")
        flags = after.get("flags")
        if not isinstance(flags, list) or any(not isinstance(flag, str) for flag in flags):
            raise ValueError("route checkpoint must contain its flag list")
        items = after.get("items")
        if not isinstance(items, dict) or any(
                not isinstance(key, str) or type(value) not in (int, float) or not value >= 0
                or (isinstance(value, float) and not value.is_integer())
                for key, value in items.items()):
            raise ValueError("route checkpoint must contain its item counts")
        realm = after.get("realm")
        if not isinstance(realm, str) or not realm or (
                expected_realm is not None and realm != expected_realm):
            raise ValueError("route checkpoint realm differs from the requested route")
        if not isinstance(after.get("training"), dict) or not after["training"]:
            raise ValueError("route checkpoint requires its actual training snapshot")
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
