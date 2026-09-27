#!/usr/bin/env python3
"""C2 (cadence, rewards) read from one C1 full-chapter run's events.json.

  python3 analyze_c1_events.py <run dir containing events.json and c1.json> [out.json]

Reports, from the run's own log only (no re-derivation of game rules):
  * A7: every activity interval (the harness's activity_intervals) and the
    longest; any interval over 120 s is a failure.
  * Fights: every battle_resolved row (live or mechanics), rounds, coins gained,
    and the retained five's level/XP before and after.
  * Ledger: the five's level/XP at start and end, coins at start and end, the
    final inventory, and whether the party stayed the same five (no new catch).
  * Legendary offers: any meaningful_offer naming a legendary species.
"""
import json
import sys

LEGENDARY = {"solmane", "veridian", "abyssal_guardian", "water_abyssal_guardian", "fulgocobra"}


def main() -> int:
    run = sys.argv[1].rstrip("/")
    events = json.load(open(run + "/events.json"))
    rows = events["events"]
    intervals = events.get("activity_intervals", [])
    # An interval that starts and ends inside one named fight (challenge press ->
    # victory) is fight time, not an empty travel interval; A7 measures travel.
    def in_fight(i: dict) -> bool:
        return str(i.get("from_stage", "")).startswith("battle_") and i.get("from_stage") == i.get("to_stage") \
            and i.get("to") in ("battle_victory", "battle_started")
    for i in intervals:
        i["in_fight"] = in_fight(i)
    over = [i for i in intervals if float(i.get("gap_seconds", 0)) > 120.0 and not i["in_fight"]]
    travel = [i for i in intervals if not i["in_fight"]]
    longest = max(travel, key=lambda i: float(i.get("gap_seconds", 0))) if travel else {}
    fights = []
    for r in rows:
        if r.get("kind") != "battle_resolved":
            continue
        fights.append({
            "id": r.get("id"), "stage": r.get("stage"), "t": r.get("simulated_seconds"),
            "mode": r.get("mode", r.get("evidence_scope")), "rounds": len(r["rounds"]) if isinstance(r.get("rounds"), list) else r.get("rounds"),
            "victory": r.get("victory_callback"), "coins": r.get("coins_gained"),
            "team_before": [(m.get("species_id"), m.get("level"), m.get("xp")) for m in r.get("team_before", [])],
            "team_after": [(m.get("species_id"), m.get("level"), m.get("xp")) for m in r.get("team_after", [])],
        })
    pre = next((r for r in rows if r.get("kind") == "precondition"), {})
    snap = [r for r in rows if r.get("kind") == "persistence_snapshot"]
    end_team = snap[-1].get("team") if snap else (fights[-1]["team_after"] if fights else [])
    end_inventory = snap[-1].get("inventory") if snap else []
    legendary_offers = [
        {"t": r.get("simulated_seconds"), "label": r.get("label"), "path": r.get("path")}
        for r in rows if r.get("kind") == "meaningful_offer"
        and any(s in str(r.get("label", "")).lower() for s in LEGENDARY)
    ]
    start_team = pre.get("team", [])
    same_five = sorted(m.get("species_id") for m in start_team) == sorted(
        (m.get("species_id") if isinstance(m, dict) else m[0]) for m in end_team) if start_team and end_team else None
    out = {
        "run": run,
        "a7": {"intervals": len(intervals), "longest_s": float(longest.get("gap_seconds", 0)) if longest else 0.0,
               "longest": longest, "over_120": over, "pass": not over},
        "fights": fights,
        "fights_won": sum(1 for f in fights if f["victory"] or f["mode"] == "mechanics_only"),
        "ledger": {"start_team": start_team, "end_team": end_team, "start_inventory": pre.get("inventory"),
                   "end_inventory": end_inventory, "same_five_no_new_catch": same_five},
        "legendary_offers": legendary_offers,
        "distance_m": events.get("distance_m"),
    }
    text = json.dumps(out, indent=2)
    if len(sys.argv) > 2:
        open(sys.argv[2], "w").write(text)
    print(json.dumps({"a7_pass": out["a7"]["pass"], "longest_s": out["a7"]["longest_s"], "fights": len(fights),
                      "same_five": same_five, "legendary_offers": len(legendary_offers)}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
