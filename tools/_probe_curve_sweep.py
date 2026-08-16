#!/usr/bin/env python3
"""SH47 helper: sweep XP-curve candidates against the real critical path.

Companion to tools/_probe_pacing.py. That probe prints the estimate for the
CURRENT data; this one answers "what would the curve have to be for the
critical path's own fights to carry the player to the level each band expects,
with no forced wild grinding at all?"

Prints, for each candidate (base, exponent, award_base, award_per_level):
  - total XP the critical path pays
  - XP needed to reach L19 from the starter's L3
  - the ratio (>= 1.0 means the main line alone gets there)
  - fights-per-level at L5 / L12 / L19 against a level-matched enemy, which is
    the number that says whether the curve is flat or compounding.
"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(rel):
    with open(os.path.join(ROOT, rel)) as f:
        return json.load(f)


PROG = load("data/config/progression.json")
TR = load("data/config/trainers.json")
WA = load("data/config/burrow_warrens.json")
T = {t["id"]: t for t in TR["trainers"]}

PATH_IDS = [
    "practice_trainer", "trainer_mira", "trainer_tam", "trainer_oskar",
    "relay_picket_hess", "relay_picket_orrin", "relay_officer_dell", "relay_captain",
    "captain_field", "captain_ridge", "captain_riverwatch",
    "stronghold_patrol", "stronghold_courtyard", "stronghold_elite", "warden_aldis",
]

levels = []
bonus = 0
for tid in PATH_IDS:
    for c in T[tid]["team"]:
        levels.append(int(c["level"]))
    bonus += int(T[tid].get("reward", {}).get("xp_bonus", 0))
for s in WA["spawns"]:
    levels += [int(s["level"])] * int(s.get("count", 1))
levels.append(int(WA["guardian"]["level"]))
bonus += int(WA["clear"]["reward"].get("xp_bonus", 0))


def report(base, expo, a, b):
    def cost(L):
        return int(base * L ** expo)

    def cum(x, y):
        return sum(cost(l) for l in range(x, y))

    total = sum(int(a + b * L) for L in levels) + bonus
    need = cum(3, 19)
    fpl = [cost(L) / float(a + b * L) for L in (5, 12, 19)]
    print("base=%-4g e=%-5g award=%2g+%2gL | path %6d xp | need L3->19 %6d | ratio %5.2f"
          " | fights/level @L5/12/19 %4.1f %4.1f %4.1f"
          % (base, expo, a, b, total, need, total / float(need), fpl[0], fpl[1], fpl[2]))


if __name__ == "__main__":
    print("critical path: %d creature fights, %d flat xp_bonus" % (len(levels), bonus))
    print("enemy levels:", sorted(levels))
    print()
    lc, aw = PROG["level"], PROG["xp_award"]
    print("CURRENT:")
    report(lc["xp_to_next_base"], lc["xp_to_next_exponent"], aw["base"], aw["per_enemy_level"])
    print()
    print("CANDIDATES:")
    for cand in [
        (40, 1.15, 18, 6),
        (34, 1.15, 30, 14),
        (30, 1.15, 26, 12),
        (32, 1.15, 24, 12),
        (36, 1.15, 28, 14),
        (40, 1.15, 30, 15),
        (44, 1.15, 30, 15),
        (40, 1.2, 30, 15),
        (48, 1.15, 32, 16),
    ]:
        report(*cand)
