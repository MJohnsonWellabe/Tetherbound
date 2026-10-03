"""Bind ordinary F48 release inputs to a hash-pinned actual caught owner save.

Writes only a fresh route pack and provenance manifest. This is unverified input
packaging, never a release result, saved receipt, or native acceptance claim.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
from pathlib import Path

import f48_profile_fixture as fixture
import f48_prepare_profile as inputs

ROOT = Path(__file__).resolve().parents[2]
STARTERS = {"terrapup", "ripplet", "galewisp"}


def integer(value, minimum, maximum):
    return (type(value) in (int, float) and math.isfinite(value)
            and minimum <= value <= maximum and int(value) == value)


def generate(profile_path: Path, guest_root: Path, output: Path, *,
             profile_sha256: str, character_sha256: str, uid: str | None = None) -> Path:
    """Caller supplies independently retained source hashes, not computed outcomes."""
    fixture.require(not output.exists(), "Fresh release-route output required")
    pinned: dict[Path, str] = {}

    def read(path: Path, expected: str | None = None):
        path = path.resolve()
        actual = fixture.digest(path)
        fixture.require(expected is None or actual == expected, f"Source bytes changed: {path}")
        fixture.require(path not in pinned or pinned[path] == actual, f"Source bytes changed: {path}")
        pinned[path] = actual
        return fixture.read(path)

    fixture.require(isinstance(profile_sha256, str) and len(profile_sha256) == 64
                    and isinstance(character_sha256, str) and len(character_sha256) == 64,
                    "Retained profile and actual character SHA256 pins required")
    profile = read(profile_path, profile_sha256)
    fixture.require(profile.get("configuration_scope") == "full"
                    and isinstance(profile.get("saves"), list) and len(profile["saves"]) == 2,
                    "Require generated full two-peer profile")
    pack = {key: copy.deepcopy(profile.get(key)) for key in ("provenance", "routes", "outcomes")}
    fixture.validate_pack(pack)
    fixture.require(isinstance(pack["routes"].get("essence_spend_prepare"), list)
                    and pack["routes"]["essence_spend_prepare"], "Reviewed ordinary Altar opening route required")

    character_path = fixture.one_document(guest_root / "characters/redesign-v28", "character")
    character = read(character_path, character_sha256)
    captured = fixture.source_input(guest_root, False)
    fixture.require(character == captured["character"], "Source bytes changed while reading actual character")
    original_root = Path(profile["saves"][1])
    original_path = fixture.one_document(original_root / "characters/redesign-v28", "character")
    original = read(original_path)
    fixture.require(character.get("character_id") == original.get("character_id")
                    and original.get("version") == 28, "Actual captured owner must be the profile's original guest")
    fixture.require(len(character["party"]) > 1, "Never release the last companion")

    configurations = profile.get("test_configuration")
    fixture.require(isinstance(configurations, list), "Pinned generated configuration required")
    effective = {}
    for row in configurations:
        fixture.require(isinstance(row, dict) and isinstance(row.get("file"), str)
                        and row["file"].startswith("res://data/config/")
                        and Path(row["file"].removeprefix("res://")).parts[:2] == ("data", "config")
                        and ".." not in row["file"].split("/")
                        and row["file"] not in effective, "Invalid or duplicate configuration resource")
        original_config = ROOT / row["file"].removeprefix("res://")
        read(original_config, row.get("source_sha256", ""))
        effective[row["file"]] = read(Path(row["overlay_file"]), row.get("sha256", ""))
    cfg = effective.get("res://data/config/essence.json", {})
    traits = effective.get("res://data/config/traits.json", {})
    fixture.require(cfg.get("release_rounding") == "floor"
                    and cfg.get("dual_type_payout") == "split_remainder_to_primary"
                    and traits.get("runtime_enabled") is True,
                    "Reviewed release configuration unavailable")
    species = read(ROOT / "data/creatures/species.json")["species"]
    # Unlike the payout catalogue, shipping Traits eligibility uses this exact
    # base catalogue. Do not broaden release eligibility to other species here.
    essence_path = ROOT / "data/schema/essences.json"
    pinned[essence_path] = fixture.digest(essence_path)
    essences = json.loads(essence_path.read_bytes())
    essence_items = {row["type"]: row["id"] for row in essences}
    personal = character["redesign_character"]
    candidates = []
    for card in character["party"]:
        record = personal["creatures"][card["uid"]]
        source = record.get("captured_from", {})
        definition = species.get(card.get("species_id"), {})
        eligible = (isinstance(source, dict) and source.get("kind") == "wild"
                    and isinstance(source.get("world_namespace"), str) and bool(source["world_namespace"])
                    and isinstance(source.get("spawn_id"), str) and bool(source["spawn_id"])
                    and integer(source.get("spawn_generation"), 1, 2147483647)
                    and bool(definition) and not definition.get("starter", False)
                    and not definition.get("legendary", False) and card.get("species_id") not in STARTERS)
        if eligible:
            candidates.append(card)
    if uid is not None:
        candidates = [card for card in candidates if card["uid"] == uid]
    fixture.require(len(candidates) == 1, "Require one unambiguous eligible actual caught UID; specify --uid if needed")
    card = candidates[0]
    uid = card["uid"]
    fixture.require("release:" + uid not in personal.get("release_receipts", [])
                    and "release:" + uid not in personal.get("transaction_receipts", []),
                    "Selected creature already has a release receipt")
    definition = species[card["species_id"]]
    fixture.require(card.get("creature_type") == definition.get("type")
                    and card.get("secondary_type", "") == definition.get("type_secondary", "")
                    and integer(card.get("level"), 1, 100), "Actual card species/type/level mismatch")
    fixture.require(isinstance(card.get("nickname"), str) and isinstance(card.get("display_name"), str),
                    "Actual shipping companion label missing")
    label = card["nickname"] if card["nickname"].strip() else card["display_name"]
    fixture.require(bool(label), "Actual shipping companion label empty")
    for field in ("release_essence_base", "release_essence_per_level"):
        value = cfg.get(field)
        fixture.require(type(value) in (int, float) and math.isfinite(value) and value >= 0,
                        "Invalid pinned release pricing")
    total = cfg["release_essence_base"] + cfg["release_essence_per_level"] * card["level"]
    fixture.require(math.isfinite(total) and 1 <= total <= 2147483647, "Invalid independent release yield")
    total = math.floor(total)
    types = [kind for kind in (definition["type"], definition.get("type_secondary", "")) if kind]
    fixture.require(len(set(types)) == len(types) and all(kind in essence_items for kind in types),
                    "Canonical release essence types unavailable")
    amounts = [total] if len(types) == 1 else [total - total // 2, total // 2]
    payout = {essence_items[kind]: amount for kind, amount in zip(types, amounts) if amount > 0}

    # _refresh resets the distillation choice to Essence only. f48_choice uses
    # real popup input and UID metadata, so duplicate display names are safe.
    prepare = copy.deepcopy(pack["routes"]["essence_spend_prepare"]) + [
        inputs.button("Traits / Release"), inputs.wait(), inputs.step("f48_choice", uid=uid), inputs.wait()]
    commit = [inputs.button("Release companion and distil chosen trait"), inputs.wait(15),
              inputs.button(f"Release {label}? This can't be undone. A confirms; B leaves."), inputs.wait(120)]
    updates = {"release_prepare": prepare, "release_reopen": copy.deepcopy(prepare),
               "release_commit": commit, "release_1": prepare + commit + inputs.close()}
    outcome = {"released_uid": uid, "item_delta": payout}
    for name, route in updates.items():
        fixture.require(name not in pack["routes"] or pack["routes"][name] == route,
                        f"Refuse replacing an existing different release route: {name}")
        pack["routes"][name] = route
    fixture.require("release_1" not in pack["outcomes"] or pack["outcomes"]["release_1"] == outcome,
                    "Refuse replacing an existing different release outcome")
    pack["outcomes"]["release_1"] = outcome
    pack["provenance"] += " Release input bound to actual caught guest carrier; ordinary UID popup and two confirmations, Essence only. Independent source-derived yield; no release/native acceptance credit."
    fixture.validate_pack(pack)
    # Pin routing/payout implementation for subsequent source review as well.
    for relative in ("scripts/ui/altar_traits_panel.gd", "scripts/ui/altar_traits_service.gd",
                     "scripts/creatures/traits.gd", "scripts/creatures/essence.gd",
                     "tools/net/proof_steps_f48.gd"):
        path = ROOT / relative
        pinned[path] = fixture.digest(path)
    for path, expected in pinned.items():
        fixture.require(fixture.digest(path) == expected, f"Source bytes changed before output: {path}")
    output.mkdir(parents=True, exist_ok=False)
    route_path = output / "route-pack.json"
    fixture.write(route_path, pack)
    fixture.write(output / "source.json", {"acceptance_credit": False, "ready_ci_bundle": False,
        "character_id": character["character_id"], "released_uid": uid, "species_id": card["species_id"],
        "nickname": card["nickname"], "display_label": label, "captured_from": personal["creatures"][uid]["captured_from"],
        "independent_item_delta": payout, "sources": [{"path": str(path), "sha256": digest} for path, digest in pinned.items()],
        "route_pack_sha256": fixture.digest(route_path)})
    return route_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", type=Path, required=True)
    parser.add_argument("--guest", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--profile-sha256", required=True)
    parser.add_argument("--character-sha256", required=True)
    parser.add_argument("--uid")
    args = parser.parse_args()
    path = generate(args.profile, args.guest, args.output, profile_sha256=args.profile_sha256,
                    character_sha256=args.character_sha256, uid=args.uid)
    print(json.dumps({"route_pack": str(path), "sha256": fixture.digest(path), "acceptance_credit": False}))
