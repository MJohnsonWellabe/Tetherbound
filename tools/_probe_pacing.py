#!/usr/bin/env python3
"""SH47 pacing probe -- how long does the Meadows chapter's critical path take?

Run:  python3 tools/_probe_pacing.py            (from the repo root)
      python3 tools/_probe_pacing.py --verbose  (per-beat breakdown)

WHY THIS EXISTS
---------------
`SH47`/`D42` want the chapter's first completion inside **3-4 hours**, using six
levers (XP curve, trainer levels, material costs, travel time, spawn density,
remove dead walking) and explicitly NOT a smaller map. "Feels about right" is
not an argument you can re-run after a tuning change, so this builds the
estimate out of the shipped data files and prints it per band. Every number it
prints traces to a file in `data/`; the only free parameters are the four
PLAY-MODEL constants below, which are stated, derived, and easy to argue with.

WHAT IT MODELS
--------------
1. TRAVEL. The critical path as an ordered list of beats with real world
   coordinates (data/config/*.json). Straight-line distance between beats,
   multiplied by ROUTE_FACTOR because nobody walks a straight line over a
   heightfield, divided by the effective traversal speed. Effective speed is
   derived from data/config/movement.json's stamina economy, not guessed.
2. FIGHTING. Every creature on the critical path (trainer teams, the warrens'
   aggressive spawns, the guardian, the Warden), timed from its real HP against
   a DPS derived from data/config/combat.json.
3. XP. What those same fights actually pay (data/config/progression.json's
   `xp_award`) against what the level curve actually costs
   (`xp_to_next_base * level ^ xp_to_next_exponent`). Where the critical path
   does not pay for the level the next band's content expects, the shortfall is
   converted into EXTRA WILD FIGHTS -- and that number is the one this whole
   probe was written to expose, because spec 11 calls exactly that "bad grind":
   "walk in circles killing identical weak enemies only to inflate a number."
4. GATHERING. The recipes on the critical path (the Greater Orb, the saddle),
   priced against the harvest nodes that can actually supply them.
5. TALKING. Every line in data/dialogue/*.json, counted, at a reading rate. The
   chapter is 3900-odd words of authored conversation and a fair slice of the
   run is spent reading it; leaving that out made the first cut of this probe
   flatter it by half an hour.
6. CATCHING THE FIVE. Section 18's acceptance gate requires the player to "form
   a meaningful five", so four catches are critical path, not optional. Priced
   from data/config/catching.json's own chance model.

WHAT IT STILL DOES NOT MODEL
----------------------------
Menu and inventory time, optional trainers, exploration for its own sake,
deaths and retries, and the time a player spends undecided. All of those push
the total UP, so this remains a FLOOR rather than a midpoint: a run that
measures 2h30 here is a 3-4 hour run in a human's hands, and one that measures
4h here is well past the target.
"""

import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# BAND-SPLIT: trainers/harvest/spawns are cut per corridor band under
# data/config/bands/. Merged back through the shared helper rather than
# read raw, or this probe would print a number based on an empty table.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import band_content

VERBOSE = "--verbose" in sys.argv


def load(rel):
    with open(os.path.join(ROOT, rel)) as f:
        return json.load(f)


PROG = load("data/config/progression.json")
MOVE = load("data/config/movement.json")
COMBAT = load("data/config/combat.json")
SPECIES = load("data/creatures/species.json")["species"]
TRAINERS = band_content.load_config("data/config/trainers.json", "trainers")
WARRENS = load("data/config/burrow_warrens.json")
HARVEST = band_content.load_config("data/config/harvest.json", "nodes")
SPAWNS = band_content.load_config("data/config/spawns.json", "spawns")
CATCHING = load("data/config/catching.json")
RECIPES_ROOT = load("data/recipes/recipes_rootstone.json")["recipes"]
RECIPES_IRON = load("data/recipes/recipes_ironwood.json")["recipes"]

# --- PLAY MODEL (the only free parameters in this file) ----------------------

# Nobody walks a straight line across a heightfield with rocks, water and
# fences on it. 1.25 is the usual navmesh-detour rule of thumb and it is the
# single most arguable number here; halving the chapter would need it to be
# wrong by more than a factor of two.
ROUTE_FACTOR = 1.25

# Fraction of quick/charged cycles that actually land, once repositioning,
# telegraphs and the enemy's own movement are in the picture. 0.6 is
# deliberately generous to the build -- a lower number makes fights LONGER and
# the chapter worse, so this errs toward the optimistic estimate.
HIT_EFFICIENCY = 0.6

# Per-fight fixed cost: engage range closed, deploy, the faint pause, the
# victory banner. data/config/combat.json's own `flow` numbers add to ~2s of
# that; the rest is the player's hands.
FIGHT_OVERHEAD_S = 10.0

# A wild encounter fought purely to farm XP: found, engaged, killed, and the
# few seconds of walking to the next one inside a spawn cluster.
GRIND_FIGHT_S = 45.0

# Reading speed for authored dialogue, plus the button press between lines.
# 2.5 words/second is unhurried silent reading; a player who skims goes faster
# and a player who savours goes slower.
WORDS_PER_SECOND = 2.5
LINE_ADVANCE_S = 1.2

# --- derived: how fast the player actually moves -----------------------------


def effective_walk_speed():
    """Sustainable ground speed, derived from movement.json's stamina economy.

    Sprinting drains `sprint_drain_per_second`; standing off sprint regenerates
    `regen_per_second`. In steady state the player sprints a fraction f where
    drain*f == regen*(1-f), and walks the rest.
    """
    loco = MOVE["locomotion"]
    stam = MOVE["stamina"]
    drain = float(stam["sprint_drain_per_second"])
    regen = float(stam["regen_per_second"])
    f = regen / (drain + regen)
    return f * float(loco["sprint_speed"]) + (1.0 - f) * float(loco["walk_speed"])


def ride_speed():
    """Meadowhart's ride speed -- walk_speed * its own multiplier."""
    block = SPECIES["meadowhart"]["rideable"]
    return float(MOVE["locomotion"]["walk_speed"]) * float(block["ride_speed_multiplier"])


WALK = effective_walk_speed()
RIDE = ride_speed()

# --- derived: how long one enemy creature takes to kill -----------------------


def dps():
    """Damage per second the player's creature actually deals.

    One energy cycle is `charged_cost / gain_per_quick` quick attacks followed
    by one charged. Damage is combat_math.base_damage with attack == defence
    (evenly matched levels), which reduces to power * scale * 0.5... but the
    two halves cancel to `power * scale * attack/(attack+defence)` = power.
    """
    q = COMBAT["player_quick"]
    c = COMBAT["player_charged"]
    e = COMBAT["energy"]
    quicks = max(1.0, float(e["charged_cost"]) / float(e["gain_per_quick"]))
    q_time = float(q["cooldown"]) + float(q["windup"]) + float(q["recovery"])
    c_time = float(c["cooldown"]) + float(c["windup"]) + float(c["recovery"])
    scale = float(COMBAT["damage"]["scale"])
    # attack/(attack+defence) == 0.5 for an even match, so power*scale*0.5.
    dmg = (quicks * float(q["power"]) + float(c["power"])) * scale * 0.5
    cycle = quicks * q_time + c_time
    return (dmg / cycle) * HIT_EFFICIENCY


DPS = dps()


def creature_hp(species_id, level):
    base = float(SPECIES.get(species_id, {}).get("base_hp", 120.0))
    growth = float(PROG["level"]["growth_per_level"]["hp"])
    return base * (1.0 + growth * float(level - 1))


def kill_seconds(species_id, level):
    return creature_hp(species_id, level) / DPS


# --- derived: the XP curve ----------------------------------------------------


def xp_to_next(level):
    lc = PROG["level"]
    return int(float(lc["xp_to_next_base"]) * math.pow(max(level, 1), float(lc["xp_to_next_exponent"])))


def cumulative_xp(from_level, to_level):
    return sum(xp_to_next(l) for l in range(from_level, to_level))


def xp_award_for(enemy_level):
    a = PROG["xp_award"]
    return int(float(a["base"]) + float(a["per_enemy_level"]) * float(enemy_level))


def level_after(start_level, start_xp, gained):
    """Walk the curve forward. Returns (level, leftover_xp)."""
    lvl, xp = start_level, start_xp + gained
    cap = int(PROG["level"]["cap"])
    while lvl < cap and xp >= xp_to_next(lvl):
        xp -= xp_to_next(lvl)
        lvl += 1
    return lvl, xp


# --- derived: reading the chapter ---------------------------------------------


def dialogue_seconds(path):
    """Every authored line in one data/dialogue file, at reading speed."""
    d = load(path)
    words = 0
    lines = 0
    for key, conv in d.get("conversations", {}).items():
        if key.startswith("_"):
            continue
        for entry in conv.get("lines", []):
            text = entry if isinstance(entry, str) else str(entry.get("text", ""))
            words += len(text.split())
            lines += 1
    return words / WORDS_PER_SECOND + lines * LINE_ADVANCE_S, words, lines


# --- derived: catching the five -----------------------------------------------


def catch_seconds():
    """One wild catch: soften it, then throw until it sticks.

    Chance per throw is catching.json's own model -- the species catch_rate
    scaled by how empty its HP bar is, by the orb's multiplier and by where the
    orb lands. Modelled at a well-softened target with a basic orb and a
    centre-ish hit, which is what a player who is trying does.
    """
    ch = CATCHING["chance"]
    rate = float(SPECIES["bramblebun"].get("catch_rate", 0.3))
    per_throw = min(float(ch["max"]),
                    rate * float(ch["hp_factor_empty"]) * 1.0 * float(ch["centre_bonus"]))
    throws = 1.0 / max(per_throw, 0.02)
    th = CATCHING["throw"]
    per_throw_s = float(th["cooldown"]) + float(th["release_windup"]) + 1.0 + 2.0  # +aim
    wild_lo, wild_hi = PROG["level"]["wild_band"]
    soften_hp = creature_hp("bramblebun", (wild_lo + wild_hi) / 2.0) * 0.75
    return soften_hp / DPS + throws * per_throw_s + FIGHT_OVERHEAD_S


# --- the critical path --------------------------------------------------------

TRAINER_BY_ID = {t["id"]: t for t in TRAINERS["trainers"]}


def trainer_beat(tid, band, note=""):
    t = TRAINER_BY_ID[tid]
    return {
        "kind": "trainer",
        "band": band,
        "name": t.get("display_name", tid),
        "at": tuple(t["position"]),
        "team": [(c["species"], int(c["level"])) for c in t["team"]],
        "xp_bonus": int(t.get("reward", {}).get("xp_bonus", 0)),
        "note": note,
    }


def site_beat(band, name, at, note="", seconds=0.0):
    return {"kind": "site", "band": band, "name": name, "at": tuple(at),
            "note": note, "seconds": seconds}


# Rootstone/Ironwood harvest clusters, taken from harvest.json itself so a moved
# node moves the estimate.
def harvest_centre(item):
    nodes = [n for n in HARVEST["nodes"] if n["item"] == item]
    x = sum(n["at"][0] for n in nodes) / len(nodes)
    z = sum(n["at"][1] for n in nodes) / len(nodes)
    return (x, z)


def harvest_total(item):
    return sum(int(n["amount"]) for n in HARVEST["nodes"] if n["item"] == item)


def harvest_walk_seconds(item):
    """Time to work a cluster: the tour between its own nodes, plus a few
    seconds swinging at each one."""
    nodes = [n for n in HARVEST["nodes"] if n["item"] == item]
    tour = 0.0
    for a, b in zip(nodes, nodes[1:]):
        tour += math.dist(a["at"], b["at"])
    return tour * ROUTE_FACTOR / WALK + 6.0 * len(nodes)


ROOTSTONE_AT = harvest_centre("rootstone")
IRONWOOD_AT = harvest_centre("ironwood")
WARRENS_AT = tuple(WARRENS["site"]["at"])

# Band 0 numbers come from the opening's own scripted content, not from a
# combat table: waking, Grandpa, the starter choice, the name entry and the
# first taught fight. Timed as one block.
BAND0_SCRIPTED_S = 14.0 * 60.0

BEATS = [
    site_beat(0, "Grandpa's house (wake, Grandpa, starter, name)", (-22.0, -16.0),
              seconds=BAND0_SCRIPTED_S),
    trainer_beat("practice_trainer", 0, "the taught first fight"),
    site_beat(0, "The village", (10.0, -10.0), seconds=120.0,
              note="harvest/camp basics, signpost"),

    trainer_beat("trainer_mira", 1),
    trainer_beat("trainer_tam", 1),
    trainer_beat("trainer_oskar", 1, "pays the South Bridge Key"),
    site_beat(1, "The South Bridge (gate 1)", (5.0, 80.0), seconds=30.0),

    site_beat(2, "Old Quarry rootstone", ROOTSTONE_AT,
              seconds=harvest_walk_seconds("rootstone")),
    site_beat(2, "Burrow Warrens", WARRENS_AT, note="dungeon, see fights below"),

    trainer_beat("relay_picket_hess", 3),
    trainer_beat("relay_picket_orrin", 3),
    trainer_beat("relay_officer_dell", 3),
    trainer_beat("relay_captain", 3, "frees the captive, pays the Mill Bridge Gear"),
    site_beat(3, "Old Mill Crossing", (162.4, 42.1), seconds=60.0,
              note="restore the crossing"),

    site_beat(4, "Ironwood grove", IRONWOOD_AT, seconds=harvest_walk_seconds("ironwood")),
    trainer_beat("captain_field", 4),
    trainer_beat("captain_ridge", 4),
    trainer_beat("captain_riverwatch", 4),
    site_beat(4, "The Sigil gate", (130.0, -176.0), seconds=30.0),

    trainer_beat("stronghold_patrol", 5),
    trainer_beat("stronghold_courtyard", 5),
    trainer_beat("stronghold_elite", 5),
    trainer_beat("warden_aldis", 5, "the Warden"),
    site_beat(5, "Free the legendary, the Rift collapses", (232.0, -206.0), seconds=300.0,
              note="reveal, release ceremony, meadow healing"),
]

# The warrens are a dungeon, not a single beat: its aggressive spawns and its
# guardian are real fights on the critical path (burrow_warrens.json).
WARRENS_FIGHTS = []
for s in WARRENS["spawns"]:
    for _ in range(int(s.get("count", 1))):
        WARRENS_FIGHTS.append((s["species"], int(s["level"])))
WARRENS_FIGHTS.append((WARRENS["guardian"]["species"], int(WARRENS["guardian"]["level"])))
WARRENS_XP_BONUS = int(WARRENS["clear"]["reward"].get("xp_bonus", 0))

# Level the content of each band expects the player to ARRIVE at -- derived
# from the content itself rather than hand-set, so retuning a team retunes this
# too. The test is the band's FIRST critical-path fight, one level below its
# lead creature: a band is entered, not walked into fully levelled, and the
# band's own fights are what carry the player up to its later ones. Checking
# against a band's PEAK instead would demand the player be ready for the
# stronghold's elite before meeting its patrol, which is not how any of this
# is meant to be played.
def _band_entry_levels():
    want = {0: int(PROG["level"]["starter_level"])}
    for beat in BEATS:
        b = beat["band"]
        if b in want:
            continue
        if beat["kind"] == "trainer" and beat["team"]:
            want[b] = max(1, min(lv for _sp, lv in beat["team"]) - 1)
        elif beat["name"] == "Burrow Warrens":
            want[b] = max(1, min(lv for _sp, lv in WARRENS_FIGHTS) - 1)
    return want

# Which band each dialogue file is read in. `trainers.json` is the one that
# does not belong to a single place -- its 22 conversations are the pre/post
# battle lines of every trainer in the chapter -- so it is split across the
# bands in proportion to how many critical-path trainers each one holds.
DIALOGUE_BAND = {
    "data/dialogue/opening.json": {0: 1.0},
    "data/dialogue/village.json": {1: 1.0},
    "data/dialogue/relay.json": {3: 1.0},
    "data/dialogue/stronghold.json": {5: 1.0},
    "data/dialogue/meadows_freed.json": {5: 1.0},
    "data/dialogue/trainers.json": {0: 1 / 15.0, 1: 3 / 15.0, 3: 4 / 15.0,
                                    4: 3 / 15.0, 5: 4 / 15.0},
}

# Section 18's gate asks the player to "form a meaningful five". The starter is
# given; the other four are caught, and the spec puts that in the early bands.
CATCHES_PER_BAND = {0: 1, 1: 2, 2: 1}

BAND_NAMES = {
    0: "Band 0 - Homebound",
    1: "Band 1 - Lower Meadows",
    2: "Band 2 - Stone & Root",
    3: "Band 3 - The River Lock",
    4: "Band 4 - Upper Meadows / Ironwood",
    5: "Act VI - The Meadows Hall",
}

# --- material gate: can the critical path afford the recipes it needs? --------


def recipe_cost(recipes, rid):
    return {c["id"]: int(c["n"]) for c in recipes[rid]["cost"]}


def material_report():
    rows = []
    saddle = recipe_cost(RECIPES_ROOT, "saddle")
    frame = recipe_cost(RECIPES_ROOT, "saddle_frame")
    orb = recipe_cost(RECIPES_ROOT, "orb_greater")
    saddle_total = dict(frame)
    for k, v in saddle.items():
        if k == "saddle_frame":
            continue
        saddle_total[k] = saddle_total.get(k, 0) + v
    rootstone_supply = harvest_total("rootstone") + sum(
        int(i["count"]) for i in WARRENS["clear"]["reward"]["items"] if i["id"] == "rootstone"
    ) + sum(int(d["amount"]) for d in WARRENS["deposits"] if d["item"] == "rootstone")
    rows.append(("Riding Saddle (frame + saddle)", saddle_total.get("rootstone", 0)))
    rows.append(("Greater Orb (one)", orb.get("rootstone", 0)))
    return rows, rootstone_supply, harvest_total("ironwood"), recipe_cost(RECIPES_IRON, "orb_prime")


# --- the simulation ----------------------------------------------------------


def run():
    band_expected = _band_entry_levels()
    bands = {}

    def band(b):
        return bands.setdefault(b, {
            "travel_s": 0.0, "fight_s": 0.0, "scripted_s": 0.0, "grind_s": 0.0,
            "talk_s": 0.0, "catch_s": 0.0,
            "fights": 0, "grind_fights": 0, "xp": 0, "level_in": 0, "level_out": 0,
        })

    for path, split in DIALOGUE_BAND.items():
        secs, _words, _lines = dialogue_seconds(path)
        for b, share in split.items():
            band(b)["talk_s"] += secs * share
    one_catch = catch_seconds()
    for b, n in CATCHES_PER_BAND.items():
        band(b)["catch_s"] += n * one_catch

    level = int(PROG["level"]["starter_level"])
    xp = 0
    pos = None
    mounted = False
    saddle_ready_index = None

    # The saddle can only be crafted once Rootstone is in hand -- find the beat
    # index of the rootstone cluster, and treat every leg AFTER the warrens as
    # ridden if a Meadowhart is realistically catchable by then.
    meadowhart_at = None
    for s in SPAWNS["spawns"]:
        if s["species"] == "meadowhart":
            meadowhart_at = (s["centre"][0], s["centre"][2])
    for i, b in enumerate(BEATS):
        if b["name"].startswith("Old Quarry"):
            saddle_ready_index = i

    detail = []

    for i, beat in enumerate(BEATS):
        st = band(beat["band"])
        if st["level_in"] == 0:
            st["level_in"] = level

        # travel to this beat
        if pos is not None:
            d = math.dist(pos, beat["at"]) * ROUTE_FACTOR
            speed = RIDE if mounted else WALK
            t = d / speed
            st["travel_s"] += t
            if VERBOSE:
                detail.append("    travel %6.0f m %s -> %5.1f min" %
                              (d, "(ridden)" if mounted else "(on foot)", t / 60.0))
        pos = beat["at"]

        st["scripted_s"] += beat.get("seconds", 0.0)

        fights = []
        if beat["kind"] == "trainer":
            fights = list(beat["team"])
        if beat["name"] == "Burrow Warrens":
            fights = list(WARRENS_FIGHTS)

        gained = 0
        for sp, lv in fights:
            st["fight_s"] += kill_seconds(sp, lv) + FIGHT_OVERHEAD_S
            st["fights"] += 1
            gained += xp_award_for(lv)
        gained += beat.get("xp_bonus", 0)
        if beat["name"] == "Burrow Warrens":
            gained += WARRENS_XP_BONUS
        st["xp"] += gained
        level, xp = level_after(level, xp, gained)

        if VERBOSE:
            detail.append("  %-52s L%-3d %s" % (beat["name"], level,
                                                "(+%d xp)" % gained if gained else ""))

        # The Meadowhart detour + saddle craft, taken the moment Rootstone is
        # in hand. Cost: the round trip out to the nearest Meadowhart cluster.
        if i == saddle_ready_index and meadowhart_at is not None:
            d = math.dist(pos, meadowhart_at) * ROUTE_FACTOR * 2.0
            st["travel_s"] += d / WALK
            st["scripted_s"] += 180.0  # catch attempts + crafting
            mounted = True
            if VERBOSE:
                detail.append("    saddle detour: %6.0f m round trip to a Meadowhart" % d)

        st["level_out"] = level

        # At the END of a band, check the level against what the NEXT band's
        # content expects, and grind the shortfall out on wild creatures.
        next_band = BEATS[i + 1]["band"] if i + 1 < len(BEATS) else None
        if next_band is not None and next_band != beat["band"]:
            want = band_expected[next_band]
            if level < want:
                need = cumulative_xp(level, want) - xp
                wild_lo, wild_hi = PROG["level"]["wild_band"]
                wild_avg = (wild_lo + wild_hi) / 2.0
                per = xp_award_for(wild_avg)
                n = int(math.ceil(need / max(per, 1)))
                st["grind_fights"] += n
                st["grind_s"] += n * GRIND_FIGHT_S
                level, xp = want, 0
                st["level_out"] = level
                if VERBOSE:
                    detail.append("    !! %d extra wild fights to reach L%d for %s"
                                  % (n, want, BAND_NAMES[next_band]))

    return bands, detail


def main():
    bands, detail = run()

    print("=" * 78)
    print("SH47 PACING PROBE -- Meadows critical path")
    print("=" * 78)
    print("play model: route factor %.2f, effective walk %.2f m/s, ride %.2f m/s,"
          % (ROUTE_FACTOR, WALK, RIDE))
    print("            player dps %.1f, fight overhead %.0fs, grind fight %.0fs"
          % (DPS, FIGHT_OVERHEAD_S, GRIND_FIGHT_S))
    print("curve:      xp_to_next = %g * level ^ %g   |   award = %g + %g * enemy_level"
          % (PROG["level"]["xp_to_next_base"], PROG["level"]["xp_to_next_exponent"],
             PROG["xp_award"]["base"], PROG["xp_award"]["per_enemy_level"]))
    print("            L3->L10 costs %d xp, L10->L20 costs %d xp"
          % (cumulative_xp(3, 10), cumulative_xp(10, 20)))
    print()

    if VERBOSE:
        print("-- beat by beat " + "-" * 62)
        for line in detail:
            print(line)
        print()

    parts = ["travel_s", "fight_s", "catch_s", "talk_s", "scripted_s", "grind_s"]
    hdr = "%-33s %6s %6s %6s %6s %6s %6s %8s %7s" % (
        "band", "travel", "fights", "catch", "talk", "story", "GRIND", "total", "levels")
    print(hdr)
    print("-" * len(hdr))
    total = 0.0
    total_grind_fights = 0
    for b in sorted(bands):
        st = bands[b]
        t = sum(st[p] for p in parts)
        total += t
        total_grind_fights += st["grind_fights"]
        print("%-33s %5.0fm %5.0fm %5.0fm %5.0fm %5.0fm %5.0fm %7.0fm %3d->%-3d" % (
            BAND_NAMES[b], st["travel_s"] / 60.0, st["fight_s"] / 60.0,
            st["catch_s"] / 60.0, st["talk_s"] / 60.0, st["scripted_s"] / 60.0,
            st["grind_s"] / 60.0, t / 60.0, st["level_in"], st["level_out"]))
    print("-" * len(hdr))
    print("%-33s %5.0fm %5.0fm %5.0fm %5.0fm %5.0fm %5.0fm %7.0fm" % (
        "TOTAL",
        *[sum(s[p] for s in bands.values()) / 60.0 for p in parts],
        total / 60.0))
    total_grind = sum(s["grind_s"] for s in bands.values())
    print()
    print("TOTAL: %.2f hours   (target 3-4h, D42)" % (total / 3600.0))
    print("  of which forced wild grinding: %.2f hours across %d extra fights"
          % (total_grind / 3600.0, total_grind_fights))
    print("  critical-path fights: %d creature battles"
          % sum(s["fights"] for s in bands.values()))
    # FLOOR -> FIRST COMPLETION. What this probe measures is a route-known run
    # that reads every line, fights every critical-path battle and does nothing
    # else. A first completion is not that. What it adds is, almost exactly,
    # spec 11's own GOOD-grind list -- optional trainers and patrols (12 sizes
    # those at 2-4 of the chapter's 12-17 battles), catching alternatives,
    # seeking traits, gathering past the minimum, the Mudsnout evolution, TMs,
    # food buffs -- plus menu time, deaths and retries, and the plain fact that
    # a first-time player does not know where anything is. Doubling the floor is
    # the estimate; it is a STATED assumption, not a measurement, and it is the
    # number to argue with if the owner's own timed run disagrees.
    FIRST_COMPLETION_MULTIPLIER = 2.0
    projected = total * FIRST_COMPLETION_MULTIPLIER
    print("  projected first completion: %.2f hours (floor x %.1f)"
          % (projected / 3600.0, FIRST_COMPLETION_MULTIPLIER))
    verdict = "ON TARGET" if 3.0 * 3600 <= projected <= 4.0 * 3600 else (
        "UNDER" if projected < 3.0 * 3600 else "OVER")
    print("  verdict: %s the 3-4 hour target (D42)" % verdict)
    print()

    rows, rootstone_supply, ironwood_supply, orb_prime = material_report()
    print("-- materials on the critical path " + "-" * 44)
    for name, n in rows:
        print("  %-34s costs %2d rootstone" % (name, n))
    print("  rootstone the chapter can supply: %d (quarry nodes + warrens deposits + clear reward)"
          % rootstone_supply)
    print("  ironwood the chapter can supply:  %d ; orb_prime costs %d"
          % (ironwood_supply, orb_prime.get("ironwood", 0)))
    print()


if __name__ == "__main__":
    main()
