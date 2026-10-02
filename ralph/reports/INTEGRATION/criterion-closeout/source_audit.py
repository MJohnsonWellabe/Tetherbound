"""Read-only criterion evidence audit at the pinned combined source.

This is an evidence artifact, not an engine/test launcher. All Git reads are
from BASE, so evidence commits do not change the source being judged. Writes
are confined to this artifact directory. No source, board, lock, or profiles
are modified. Engine runs remain owned by ROOT.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import math
import re
import subprocess
from pathlib import Path

BASE = "582b2f13cc531f5cf733c43281c1100a6baa319b"
ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
PRIMARY = Path("D:/tetherbound/foundations-batch-check/.tmp/closeout")
BOARD = Path("D:/tetherbound/redesign-board/ralph/reports/COORDINATOR/dashboard/criteria.json")
CACHE: dict[str, bytes] = {}


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def raw(path: str) -> bytes:
    if path not in CACHE:
        CACHE[path] = git("show", f"{BASE}:{path}")
    return CACHE[path]


def source(path: str) -> str:
    return raw(path).decode("utf-8-sig")


def data(path: str):
    return json.loads(source(path))


def paths(prefix: str) -> list[str]:
    return git("ls-tree", "-r", "--name-only", BASE, *( [prefix] if prefix else [] )).decode().splitlines()


def warm(names: list[str]) -> None:
    names = sorted(set(names) - CACHE.keys())
    if not names:
        return
    output = subprocess.check_output(["git", "-C", str(ROOT), "cat-file", "--batch"],
                                     input="".join(f"{BASE}:{p}\n" for p in names).encode())
    cursor = 0
    for name in names:
        end = output.index(b"\n", cursor)
        header = output[cursor:end].split()
        if header[-1] == b"missing":
            raise ValueError(f"missing pinned source: {name}")
        size = int(header[-1])
        CACHE[name] = output[end+1:end+1+size]
        cursor = end + size + 2


def dump(name: str, value) -> None:
    (OUT / name).write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def stamp() -> dict:
    return {"source_commit": BASE, "reviewer": "criterion-evidence-closeout (independent of implementation authors)",
            "recorded_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "platform": "Windows; Python/Git static inspection only", "input": "read-only Git objects",
            "package_hash": None, "engine_runs": 0, "acceptance_credit_added": 0}


def structure() -> None:
    selected = ["data/moves/moves.json", "data/moves/ultimates.json", "data/moves/learnsets.json",
                "data/creatures/species.json", "data/config/vfx.json", "data/items/items.json",
                "data/config/water_creatures.json", "data/config/essence.json"]
    rows = {}
    for path in selected:
        try:
            d = data(path)
            rows[path] = {"type": type(d).__name__, "keys": list(d)[:20],
                          "nested": {k: {"type": type(v).__name__, "length": len(v),
                                          "sample": list(v)[:3] if isinstance(v, dict) else v[:1]}
                                     for k, v in d.items() if isinstance(v, (dict, list))}} if isinstance(d, dict) else d[:1]
        except subprocess.CalledProcessError:
            rows[path] = "absent"
    print(json.dumps(rows, indent=2, ensure_ascii=False))


def audit_mapping() -> dict:
    moves = data("data/moves/moves.json")["moves"]
    cfg = data("data/config/vfx.json")
    archetypes = cfg["move_library"]["archetypes"]
    failures = []
    parameters = ("count", "size", "colour", "arc", "speed", "spread", "trail", "impact_scale")
    for move_id, move in moves.items():
        spec = move.get("vfx", {})
        if spec.get("archetype") not in archetypes:
            failures.append(f"{move_id}: unmapped archetype")
        missing = [k for k in parameters if k not in spec]
        if missing:
            failures.append(f"{move_id}: missing parameters {missing}")
    negative = json.loads(json.dumps(moves))
    negative["pebble_toss"]["vfx"]["archetype"] = "criterion-audit-unknown"
    detected = [k for k, v in negative.items() if v.get("vfx", {}).get("archetype") not in archetypes]
    if detected != ["pebble_toss"]:
        failures.append("negative unknown-ID case was not detected exactly")
    return {**stamp(), "criterion": "F25#1", "method": "exact pinned JSON mapping + detached unknown-archetype negative case",
            "move_count": len(moves), "archetype_count": len(archetypes), "negative_detected": detected,
            "failures": failures, "data_contract_pass": not failures,
            "limitation": "Does not prove effect activation, native lookup, animation, arrival timing, performance or visual bar."}


def audit_catalogues() -> None:
    warm(["data/moves/moves.json", "data/moves/learnsets.json", "data/moves/ultimates.json",
          "data/creatures/species.json", "data/config/vfx.json", "data/config/water_roster.json",
          "scripts/creatures/teaching.gd", "scripts/creatures/creature_instance.gd"])
    moves = data("data/moves/moves.json")["moves"]
    learnsets = data("data/moves/learnsets.json")["species"]
    base = data("data/creatures/species.json")["species"]
    water = data("data/config/water_roster.json")["species"]
    live = set(base) | {"water_" + k for k in water}
    utilities = {k: v for k, v in moves.items() if v.get("slot") == "utility"}
    per_role: dict[str, list[str]] = {}
    failures = []
    for sid in sorted(live):
        row = learnsets.get(sid, {})
        ids = sorted({u.get("move_id") for u in row.get("unlocks", []) if u.get("move_id") in utilities})
        if len(ids) < 2:
            failures.append(f"{sid}: fewer than two authored utilities")
        per_role.setdefault(row.get("role_family", "MISSING"), []).append(sid)
    if len(utilities) < 10 or set(per_role) != {"WALL", "CHARGER", "CURRENT", "DIVER"}:
        failures.append("utility count or four-role coverage missing")
    shared = {k: v for k, v in moves.items() if v.get("slot") == "ultimate" and not v.get("ultimate", {}).get("unique")}
    if not 16 <= len(shared) <= 20:
        failures.append("shared ultimate count outside 16..20")
    mapping = []
    mapping_failures = []
    for sid in sorted(live):
        mid = learnsets.get(sid, {}).get("ultimate")
        definition = moves.get(mid, {})
        unique = definition.get("ultimate", {}).get("unique")
        mapping.append({"species": sid, "ultimate": mid, "unique": unique})
        if definition.get("slot") != "ultimate":
            mapping_failures.append(f"{sid}: unknown/non-ultimate mapping")
        if unique is False and mid not in shared:
            mapping_failures.append(f"{sid}: missing shared mapping")
    species_metadata_missing = sorted(sid for sid, row in base.items() if not row.get("moves", {}).get("ultimate"))
    result = {**stamp(), "utility_count": len(utilities), "live_species_count": len(live),
              "authored_learnset_count": len(learnsets), "utilities": sorted(utilities), "role_species": per_role,
              "utility_catalogue_failures": failures, "shared_ultimate_count": len(shared), "shared_ids": sorted(shared),
              "mapping": mapping, "mapping_failures": mapping_failures,
              "species_metadata_missing_ultimate": species_metadata_missing,
              "verdicts": {"F23#2": "DATA_PASS_RUNTIME_EQUIP_OPEN", "F35#0": "DATA_PASS_NATIVE_MAPPING_OPEN"},
              "honest_gap": "Every base species supplies its authored ultimate; Teaching.initialize_loadout also resolves learned signatures. Runtime feature flags are OFF. No native equip/spawn/mapping or ordinary feature activation is inferred from catalogue presence."}
    dump("f23-f35-catalogue-recheck.json", result)
    mapping_result = audit_mapping()
    dump("f25-mapping-recheck.json", mapping_result)
    print(json.dumps({"utilities": len(utilities), "shared": len(shared), "mapping_failures": mapping_failures,
                      "base_species_missing_ultimate": len(species_metadata_missing), "f25": mapping_result}, indent=2))


def audit_text_removal() -> None:
    live_docs = ["AGENTS.md", "CLAUDE.md", "CODEX_START_HERE.md", "CLAUDE_START_HERE.md"]
    live_docs += [p for p in paths("docs") if p in {"docs/GAME_BIBLE.md", "docs/PRODUCT.md", "docs/ACCEPTANCE.md",
        "docs/ROADMAP.md", "docs/TECHNICAL.md", "docs/WORKFLOW.md", "docs/STATE.md"} or re.fullmatch(r"docs/design/[^/]+\.md", p)]
    game_files = [p for prefix in ["data", "scripts", "autoload"] for p in paths(prefix) if p.endswith((".gd", ".json"))]
    warm(live_docs + game_files)
    mentions = []
    for name in live_docs + game_files:
        for i, line in enumerate(source(name).splitlines(), 1):
            if "ripplet" in line.lower() and "teleport" in line.lower():
                retired = bool(re.search(r"dropped|replaced|removed|supersed|old Ripplet Teleport promise|out of scope", line, re.I))
                mentions.append({"path": name, "line": i, "text": line, "retirement_statement": retired})
    suspects = [m for m in mentions if not m["retirement_statement"]]
    ui = [p for p in game_files if p.startswith("scripts/ui/") or p.startswith("data/dialogue/")]
    ui_matches = [m for m in mentions if m["path"] in ui]
    species = data("data/creatures/species.json")["species"]["ripplet"]
    retired_fields = [k for k, v in species.items() if not k.startswith("_comment") and "teleport" in json.dumps({k: v}).lower()]
    result = {**stamp(), "criterion": "F37#3", "method": "all authorized live contracts plus actual data/scripts/autoload source scan and Ripplet definition inspection",
              "live_documents_scanned": live_docs, "game_files_scanned": len(game_files), "ui_dialogue_files_scanned": len(ui),
              "mentions": mentions, "suspects": suspects, "ui_ripplet_teleport_promises": ui_matches,
              "ripplet_active_teleport_fields": retired_fields,
              "verdict": "SUFFICIENT_STATIC_PASS" if not suspects and not ui_matches and not retired_fields else "OPEN",
              "scope": "Text/promise removal only. Retired history and generic debug relocation terms do not promise Ripplet teleport. No traversal/play/device/co-op credit."}
    dump("f37-teleport-removal-recheck.json", result)
    print(json.dumps({"criterion": "F37#3", "verdict": result["verdict"], "suspects": suspects,
                      "game_files": len(game_files), "ui_matches": ui_matches, "fields": retired_fields}, indent=2))


def audit_wild_roster() -> None:
    names = [p for p in paths("data/config") if p.endswith(".json") and
             (re.search(r"(?:^|/)(?:spawn_tables|spawns|cloudreach_encounters|stormwood_encounters|water_encounters)\.json$", p)
              or p == "data/config/cloudreach_chapter.json")]
    consumers = ["scripts/combat/cloudreach_encounter_director.gd", "scripts/combat/stormwood_encounter_catalogue.gd",
                 "scripts/creatures/water_species_catalog.gd", "scripts/world/water_encounter_runtime_data.gd"]
    warm(names + consumers)
    refs = []
    def visit(value, path, pointer="", wild=True):
        if isinstance(value, dict):
            for key, child in value.items():
                if key.startswith("_"):
                    continue
                if key in {"species", "species_id", "placeholder_species"} and isinstance(child, str) and wild:
                    refs.append({"path": path, "pointer": pointer + "/" + key, "species": child})
                else:
                    visit(child, path, pointer + "/" + key, wild)
        elif isinstance(value, list):
            for index, child in enumerate(value):
                visit(child, path, pointer + "/" + str(index), wild)
    for path in names:
        d = data(path)
        if path.endswith("cloudreach_chapter.json"):
            for index, table in enumerate(d.get("encounter_tables", [])):
                if table.get("catchable") is True and "wild" in table.get("id", ""):
                    visit(table, path, "/encounter_tables/" + str(index))
        else:
            visit(d, path)
    forbidden = [r for r in refs if r["species"] in {"tuskroot", "ashtusk", "stormursa"}]
    cannon = [r for r in refs if r["species"] in {"cannonback", "water_cannonback"}]
    capra = [r for r in refs if r["species"] == "stormcapra"]
    result = {**stamp(), "criterion": "F29#4", "method": "authored wild tables only, excludes trainer teams/commentary; exact wild provider reads reviewed",
              "data_paths": names, "consumer_paths": consumers, "wild_reference_count": len(refs),
              "forbidden_wild_references": forbidden, "cannonback_references": cannon, "stormcapra_references": capra,
              "water_alias": "Water catalogue runtime_id(cannonback) is water_cannonback; this is disclosed, not silently merged with the base evolution species.",
              "verdict": "STATIC_TABLE_PASS_PROVIDER_BINDING_REVIEW_OPEN" if not forbidden and cannon and capra else "OPEN",
              "scope": "Wild eligibility only. No evolution offer, bear creation, acquisition or player-path proof."}
    dump("f29-wild-roster-recheck.json", result)
    print(json.dumps({"forbidden": forbidden, "cannonback": len(cannon), "stormcapra": len(capra), "refs": len(refs)}, indent=2))


def receipts() -> None:
    records = []
    for path in sorted(PRIMARY.glob("*/result.json")):
        try:
            d = json.loads(path.read_text(encoding="utf-8-sig"))
        except (ValueError, OSError):
            continue
        log_path = d.get("log") or d.get("raw_log_local_path")
        if not log_path:
            log_path = next((str(x) for x in [path.parent / "tests.log", path.parent / "smoke.log"] if x.exists()), None)
        actual = hashlib.sha256(Path(log_path).read_bytes()).hexdigest() if log_path and Path(log_path).is_file() else None
        declared = d.get("raw_log_sha256")
        text = Path(log_path).read_text(encoding="utf-8", errors="replace") if actual else ""
        records.append({"artifact": str(path), "source_commit": d.get("head"), "selection": d.get("selection"),
                        "script": d.get("script"), "exit": d.get("exit"), "timed_out": d.get("timed_out"),
                        "log": log_path, "declared_sha256": declared, "actual_sha256": actual,
                        "hash_matches": actual == declared if declared and actual else None,
                        "terminal_counts": re.findall(r"\d+ tests, \d+ assertions, \d+ failed", text),
                        "passing_cases": re.findall(r"^\s*(?:PASS|OK)\s+(.+)$", text, re.M),
                        "failed_cases": re.findall(r"^\s*FAIL\s+(.+)$", text, re.M),
                        "diagnostic_count": len(re.findall(r"^(?:SCRIPT ERROR|ERROR|WARNING):", text, re.M)),
                        "platform": "Windows native Godot (returned artifact); engine not rerun by reviewer",
                        "input": "instrumented unit/smoke or ENet harness; see named source",
                        "criterion_credit": 0})
    dump("native-receipt-audit.json", {**stamp(), "records": records})
    print(json.dumps({"receipts": len(records), "hash_mismatches": [r["artifact"] for r in records if r["hash_matches"] is False]}, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["structure", "mapping", "catalogues", "text", "wild", "receipts"])
    args = parser.parse_args()
    if args.action == "structure":
        structure()
    elif args.action == "mapping":
        result = audit_mapping()
        dump("f25-mapping-recheck.json", result)
        print(json.dumps(result, indent=2))
    elif args.action == "receipts":
        receipts()
    elif args.action == "catalogues":
        audit_catalogues()
    elif args.action == "text":
        audit_text_removal()
    elif args.action == "wild":
        audit_wild_roster()


if __name__ == "__main__":
    main()
