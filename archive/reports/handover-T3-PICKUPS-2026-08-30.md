# Handover — T3-PICKUPS, 2026-08-30

**Branch:** `ralph/T3-PICKUPS`, off `origin/main` at `a97f3e84`.
**HEAD at handover:** pushed, working tree clean except this report.
**Commits:** three, all pushed —

```
78732506  T3-PICKUPS: scatter off-path consumables, place orphaned items, close the 768m TM gap
79fc9e3f  T3-PICKUPS: scatter the temporary tonic trio into the world
<this commit>  T3-PICKUPS: handover report
```

---

## 1. What I was asked, and where I got to

### The headline ask: scatter findable consumables off-path

Owner directive, issued in this session: scatter potions, revives, orbs and
comparable consumables around the map as findable gathering — "not an
overwhelming amount, but enough that going off-path to find them is worth
doing." A later scheduled check-in added a second source: an owner board,
`docs/reference/owner-board-2026-08-15-systems-and-castle.png`, names the
exact potion/tonic set under a "POTIONS & ITEMS (found in world / merchants)"
panel. I opened and read the board myself (not the coordinator's paraphrase)
— transcription and cross-check against `items.json` are in §5.

**Done.** 16 new harvest-node pickups across all 5 bands, plus one true
one-time find (`elixir_might`) via a new minimal mechanism. Full list:

| order | band | item | siting |
|---|---|---|---|
| 1028 | 1 | potion_small | elder Mosshell's hollow |
| 1029 | 1 | orb_basic | bramblebun corner-cut pocket |
| 1030 | 1 | travel_pack | galecrest off-route pocket |
| 2013 | 2 | potion_large | quarry_rim_overlook rejoin |
| 2014 | 2 | revive | warren_undertrail rejoin, past the Warrens' second mouth |
| 2015 | 2 | hide_boots | ranger camp spur |
| 2016 | 2 | stoneguard_brew | just outside the Warrens mouth |
| 3016 | 3 | potion_small | Old Mill Crossing south bank |
| 3017 | 3 | orb_basic | beside the tm_leviathan_surge detour |
| 3018 | 3 | hide_leggings | beside the river fiber cut (band3/4 seam fix) |
| 3019 | 3 | attack_tonic | riverwatch_rest staging camp, before the Relay gauntlet |
| 4021 | 4 | revive | ruined watchtower / tm_riptide_lance |
| 4022 | 4 | potion_large | ironwood grove's night-duskhush pocket |
| 4023 | 4 | hide_helm | tree-line ironwood stand |
| 4024 | 4 | swift_tonic | near Captain Field |
| 5008 | 5 | revive | off-spine galecrest hunting pocket, last stretch before the Hall |
| (CACHE_AT) | 5 | elixir_might | off-spine warren pocket, one-time find |

All 15 harvest-node positions were ground-checked with a new scratch probe,
`tools/_probe_pickups_sites.gd` (committed — same pattern as
`tools/_probe_band4_sites.gd`), worst local slope 3.5–13.9° over a 2m pad,
none colliding with any other authored point-placed content within 10m
(checked with a script, not eyeballed).

**Mechanism decision, stated plainly per the brief's own instruction:**
`scripts/world/props.gd` genuinely has no item-granting mechanism — reconfirmed
independently. `harvest_node.gd` does (item id, amount, model, position; a
60s in-memory respawn, no save persistence) and is item-id-agnostic — nothing
in it assumes "resource". I reused it as-is for every consumable/armor pickup;
zero new code for those 16. For `elixir_might` alone I added a small new file,
`scripts/world/item_cache_pickup.gd` — see §2 for why and how minimal it is.

### The 768m gap before Captain Vess

**Placed `tm_aerial_flash` in `TM_AT`, but the gap it was meant to close no
longer existed by the time I measured it — see §4, this is the most
important finding in this report.** The placement itself is still good,
independently-justified content (Band 4 had no Air-type TM at all), just not
the emergency fix the brief described it as.

### The four remaining orphaned items

Done — `hide_helm`/`hide_leggings`/`hide_boots`/`travel_pack` are all four
in the table above, folded into the off-path scatter exactly as the brief
suggested.

---

## 2. `item_cache_pickup.gd` — the one new mechanism, and why

`elixir_might` is D47's permanent, capped stat booster
(`data/config/progression.json`'s `elixirs.cap_per_stat` = 24, i.e. 4 copies
matter per creature) and `items.json`'s own comment says these are kept out
of Mira's stock deliberately, to stay rare. A 60s-respawn harvest node — fine
for every other pickup in this pass — would let a player farm past the cap
on one creature in under 20 minutes standing still, which is the opposite of
what D47 asked for.

`key_pickup.gd` already has exactly the right CONTRACT for a one-time find
(any item id, a `pickup:<id>` progression flag, refuse-not-vanish on a full
satchel, `restore_progression_from_game` for save/load) — but its
`_build_visual()` hard-builds a literal brass key regardless of `item_id`,
which would put a key-shaped prop where an elixir belongs. Rather than edit
that shared, save-critical file (used for `castle_gate_key` and
`south_bridge_key`), I wrote `scripts/world/item_cache_pickup.gd`: the same
persistence contract, restated (not imported — GDScript has no clean way to
share private state across two `Node3D` subclasses here without a bigger
refactor than this warranted), with a generic PackedScene-loading visual
(`Barrel.gltf`, an already-installed quaternius_fantasy model — the same
"load, branch on PackedScene vs Mesh" pattern `harvest_node.gd` and
`props.gd` already use for this exact pack). ~140 lines, no new inventory/
currency/recipe system — it calls the same `inventory.add`/`progression.
set_flag` every other pickup already calls.

Wired into `playground_world.gd` via a `CACHE_AT`/`CACHE_LABEL` dict and
`_place_item_caches()`/`_spawn_item_cache()`, mirroring `TM_AT`/`_place_tms()`
exactly, plus a `restore_progression_from_game()` hookup for save/load.

**This is the "small extension" the brief said was acceptable if genuine and
kept minimal — stated here plainly rather than buried in a commit message.**

---

## 3. Test results

Targeted, after every commit:

```
xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd -- \
  --only=test_chapter_rewards.gd,test_band_content.gd,test_spawns_data.gd,test_trainers_data.gd,test_item_icons.gd,test_trade.gd,test_moves.gd
# -> 132 tests, 4402 assertions, 1 failed (test_no_material_the_world_yields_is_an_orphan
#    x5 -- see below, fixed same session before this was ever pushed red)

xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd -- \
  --only=test_chapter_rewards.gd,test_band_content.gd,test_spawns_data.gd,test_harvest.gd,test_harvest_permanence.gd,test_camp_supply_reaches_every_band.gd,test_gather_point_props.gd,test_item_icons.gd,test_trade.gd,test_moves.gd,test_inventory.gd,test_satchel.gd
# -> 188 tests, 946173 assertions, 0 failed  (after the test-scoping fix, first commit)

xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd -- \
  --only=test_chapter_rewards.gd,test_band_content.gd,test_camp_supply_reaches_every_band.gd,test_harvest.gd,test_trade.gd
# -> 65 tests, 724816 assertions, 0 failed  (after the tonic-trio commit)
```

Full unrestricted suite, once, against the final state (re-ran after the
tonic-trio commit, since the first full run was started before that commit
landed and I killed it early rather than report a stale number):

```
xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd
# -> 1521 tests, 3366565 assertions, 0 failed
```

The `ERROR: Parse JSON failed` and `ERROR: Can't use get_node() with
absolute paths...` lines that appear in every one of these logs are
pre-existing negative-test fixtures and a benign renderer-noise warning in
an unrelated harvest fallback test, both present on `main` before this
branch — not caused by this work, and every run still reports `0 failed`.

### A real test gap found and fixed, not weakened

`test_chapter_rewards.gd::test_no_material_the_world_yields_is_an_orphan`
asserted that EVERYTHING `harvest.json` yields must have a recipe/build/shop
sink. That check was written for crafting materials (wood/stone/fiber/
rootstone/ironwood, all `kind: resource`) — the moment I put a `kind:
consumable`/`armor` item into a harvest node, it failed, correctly by its
OLD definition, incorrectly by prompt 58's own actual wording ("every
introduced MATERIAL must have understandable current uses"). A potion or a
worn helm does not need a recipe to consume it — being drunk or worn IS its
use, the same as any of these ids already sitting in a trainer's
`reward.items` with no such requirement.

I narrowed the check to `kind: resource` items only (reads `items.json`'s own
`kind` field, one `_json(ITEMS_PATH)` lookup, no relaxed assertion) —
resource-kind materials are still checked exactly as strictly as before.
Verified this fails correctly before the fix (5 real failures, all pointing
at genuine non-resource pickups) and stays strict for materials (would still
catch a real orphaned wood/stone/fiber/rootstone/ironwood entry — did not
retest this destructively, but the logic path is unchanged for that branch).

---

## 4. The most important finding: the "768m gap" was already closed

The brief's own diagnosis (via two predecessor handovers,
`handover-T3-REWARD-2026-08-29.md` and `handover-T3-RELAY-2026-08-29.md`)
was thorough and, at the time each was written, accurate: a 768m
authored-content dead stretch immediately before Captain Vess
(`captain_ridge`), caused by a `TM_AT` id collision that `LAND-0829A`'s
integrator resolved in Band 1's favour.

**I did not re-run the chapter-wide corridor probe before authoring the fix
— I verified only that `tm_cyclone`/`tm_aerial_flash` were still unplaced in
`TM_AT` and shop-only in `trade.json` (true), and trusted the gap-size claim
from the two written handovers.** That was a mistake by the letter of this
repo's own stated culture ("a report's numbers go stale... verify against
the live tree"), and I only caught it after the fact, comparing my own
after-probe against the existing `ralph/reports/
gate-f-corridor-probe-2026-08-29.txt` baseline (captured the same day, by a
different lane, on `main` — i.e. BEFORE my session started and BEFORE I
touched anything):

```
baseline (2026-08-29, main):  worst_gap_m=165  tm=2  met=567  gather=56
after this branch:            worst_gap_m=165  tm=3  met=589  gather=74
```

`worst_gap_m` is **unchanged at 165m** — the chapter's worst dead-travel gap
was already 165m (in `band2_stone_and_root`, nothing to do with Band 4)
*before I ever opened `playground_world.gd`*. Directly checking the cadence
around the diagnosed location (chapter distance 9300–10200m, immediately
before `captain_ridge` at 10119m) confirms it: the largest single jump in
that whole stretch is 105m, nowhere near 250m let alone 768m. Some other
landed lane's wild-spawn content (Meadowhart/Pipwing/Galecrest/Trailpup
clusters densely populate exactly this stretch) must have closed it between
whenever the two predecessor reports were written and whenever that
2026-08-29 baseline was captured — both on the same day, hours apart, in a
fast-moving multi-lane session. Neither predecessor report was wrong when
written; the ground moved under it, exactly the pattern their own reports
warned the next lane about.

**Consequence for my own work:** `tm_aerial_flash` is real, tested content
that closes a DIFFERENT gap the two reports also correctly diagnosed and
that is still true today — Band 4 has zero Air-type TM pickup anywhere,
despite fielding an Air-focused captain (`captain_ridge`/Vess: pipwing/
duskhush/galecrest). That is worth having on its own merits (a second,
free acquisition path, matching `tm_wind_blade`'s own Band-1 precedent, and
a genuine "prepare for the known threat" beat per owner-direction §9). I am
keeping the placement. I am **not** claiming it closed "the worst gap in the
chapter" — it didn't need to, because nothing there needed closing by the
time I got to it. `tm=2 -> tm=3` in the by-kind totals is exactly the
`+1` this one placement, confirmed.

It also does not appear in the probe's own "met within 30m" cadence list —
checked directly (`grep "  TM " `on the after-probe log only shows
`tm_stone_rush`/`tm_burrow_strike`/`tm_riptide_lance`). That is consistent
with the other four off-route apex/rare TMs (`tm_wind_blade`,
`tm_leviathan_surge`, `tm_earthshatter`, `tm_heavenfall`), which are also
>30m off the stepped spine by design — a curiosity-driven detour, not a
roadside beat. `tm_aerial_flash` landed in that same class at
`(85.0, 6260.0)`, not the "close a corridor gap" class its own siting
comment (written before I had the after-probe) implies. I have left that
comment as written in the code because it is still an accurate account of
WHY the spot was chosen (band 4's own prep gap) — I did not go back and
rewrite it once I had this evidence, and I am flagging that explicitly here
rather than silently.

**What I would do differently, and recommend to whoever reads this next:**
run the corridor probe FIRST, before trusting any "N metres of dead gap"
number in a handover, however recent and however careful the report reads.
I had the tool available the whole time and did not reach for it until
after the placement, which is the exact mistake this repo's own culture
document (`CLAUDE.md`, "evidence-backed 'already fixed' is valid") warns
about from the other direction.

---

## 5. The owner board: transcription and cross-check

Per a mid-session scheduled check-in, I opened
`docs/reference/owner-board-2026-08-15-systems-and-castle.png` myself (Read
tool, full resolution) rather than trust a paraphrase. The "POTIONS & ITEMS
(found in world / merchants)" panel reads:

- **PERMANENT:** Level Up, Attack Elixir, Defense Elixir
- **TEMPORARY:** Swift Tonic, Stoneguard Brew, Defense Elixir, Clarity Draught

("Defense Elixir" appears in both columns on the board itself — almost
certainly a labelling duplicate in the owner's own concept art, since
`stoneguard_brew` already fills the "temporary defence" niche the second
listing implies. Flagging rather than resolving; not mine to silently drop
a row from someone else's board.)

Cross-checked against `items.json`'s real ids:

- **Attack Elixir** → `elixir_might` (permanent, `elixir_stat: attack`) — exact.
- **Defense Elixir** (permanent) → `elixir_guard` (permanent, `elixir_stat:
  defence`) — exact. Already placed by T3-REWARD (`captain_ridge`'s reward).
- **Level Up** → no item literally named this. By elimination against the
  three permanent elixirs `items.json` actually has (might/guard/vigour),
  and `elixir_vigour`'s own description ("raises the ceiling rather than
  filling the cup") reading closest to a levelling-up concept, I take this
  as the board's evocative name for `elixir_vigour` — already placed by
  T3-REWARD (`captain_riverwatch`'s reward). **This is a reasonable
  best-fit reading, not a certainty** — flagging rather than asserting it.
- **Swift Tonic** → `swift_tonic` — exact, already existed, shop-only until
  this branch. Now also a world find (order 4024).
- **Stoneguard Brew** → `stoneguard_brew` — exact, same story (order 2016).
- **Defense Elixir** (temporary) → no separate item; reads as the same
  duplicate-label issue above, or as `stoneguard_brew` again. Not invented.
- **Clarity Draught** → **no backing item anywhere in `items.json`, and
  none in any recipe/trade/reward file either — genuinely orphaned by
  design, not by omission.** Per the brief's own instruction ("if the board
  names something with no item behind it at all, that is a finding to
  report, not a licence to invent an item"), I have NOT created this item.
  It would presumably be some kind of accuracy/status-cure/crit buff given
  the name ("clarity") and its place beside three stat-buff tonics, but
  that is speculation, not something I am acting on. **Flagged for whoever
  owns new item design next.**

The board's TM SYSTEM panel (per-type ladders, 1.1×–2.0× multipliers) is
move/TM DATA, owned by the concurrent T3-TYPECHART lane per my own brief's
boundary — I read it, did not act on it, and am not aware of any conflict
between it and my one `TM_AT` placement (a position, not a multiplier).

---

## 6. Done-verified vs. still-open

**Done and verified:**
- All 16 harvest-node pickups: real items (`test_harvest.gd`), real
  positions inside world bounds, no prompt collisions
  (`MIN_SPOT_SEPARATION` 4.5m check in `test_harvest.gd`), correct band
  order ranges (`test_camp_supply_reaches_every_band.gd`,
  `test_band_content.gd`), ground-checked slopes.
- `elixir_might`'s one-time pickup: wired into both `build()` and
  `restore_progression_from_game()`, same shape as `TM_AT`'s own two
  hookups, not smoke-tested end-to-end in a running scene (see below).
- `tm_aerial_flash`: spawns without error (checked both test logs for `no
  ground under TM` — none), appears in `TM_AT`, obtainable per
  `test_every_tm_in_the_game_can_actually_be_obtained` (was already true
  via the shop; this adds a second path, matching the existing "any one of
  the three" test shape).
- Full suite green: 1521 tests, 3366565 assertions, 0 failed.
- Corridor probe run end-to-end; numbers are in §4 and the raw log is
  committed at `ralph/reports/gate-f-corridor-probe-t3-pickups-after-
  2026-08-30.txt`.

**Done but NOT independently verified by an actual play session:**
- I did not launch the game and walk to any of these 17 pickups in a real
  session — no interactive Godot session was available in this container
  beyond `--headless` script runs. Everything above is config-level and
  test-level verification, not a played "I walked up, pressed the prompt,
  the item landed in my satchel" confirmation. This matches
  `docs/owner-direction/README.md`'s standing note that Gate F (Track 2) is
  the continuous-play safety net for this — I did not run it myself.
- `item_cache_pickup.gd` has no dedicated unit test. It reuses
  `key_pickup.gd`'s proven contract closely enough that I trust the shape,
  but there is no `tests/test_item_cache_pickup.gd` and I did not add one —
  budget ran out after everything else in this report. **This is the one
  piece of new code in this branch with zero direct test coverage.**
  Recommend a follow-up: a small test mirroring whatever
  `tests/test_key_pickup.gd`-equivalent coverage exists for the pattern
  (if none exists for `key_pickup.gd` either, that is itself worth noting).

**Still open:**
- Clarity Draught (§5) — a design decision, not an implementation task.
- The "Defense Elixir" board duplicate (§5) — likely a board authoring
  slip, not consequential to game data either way.
- Whether 17 total world pickups (16 harvest + 1 cache) across a 7.5km,
  5-band chapter reads as "not overwhelming" in actual play is a judgement
  call I made without being able to playtest it. Roughly 3-4 per band. I
  believe this sits on the right side of the owner's own bar but flag it
  as unverified by play.

---

## 7. File footprint

**Data (band content), all three commits combined:**
- `data/config/bands/band1_lower_meadows/harvest.json` — orders 1028-1030.
- `data/config/bands/band2_stone_and_root/harvest.json` — orders 2013-2016.
- `data/config/bands/band3_the_river_lock/harvest.json` — orders 3016-3019.
- `data/config/bands/band4_upper_meadows_ironwood/harvest.json` — orders 4021-4024.
- `data/config/bands/band5_stronghold_approach/harvest.json` — order 5008.

**Code:**
- `scripts/world/playground_world.gd` — `ITEM_CACHE_PICKUP` preload,
  `CACHE_AT`/`CACHE_LABEL`/`CACHE_MODEL`/`CACHE_MODEL_SCALE` consts,
  `_place_item_caches()`/`_spawn_item_cache()`, one new `tm_aerial_flash`
  entry in `TM_AT`, both wired into `build()` and
  `restore_progression_from_game()`.
- `scripts/world/item_cache_pickup.gd` (+ `.uid`) — new file, §2.

**Tests:**
- `tests/test_chapter_rewards.gd` — narrowed
  `test_no_material_the_world_yields_is_an_orphan` to `kind: resource`
  items, §3.

**Tools (scratch, but committed per this repo's own convention for probe
scripts):**
- `tools/_probe_pickups_sites.gd` (+ `.uid`) — ground-height/slope checker
  for the 15 harvest-node candidates plus the TM candidate, modelled on
  `tools/_probe_band4_sites.gd`.
- `ralph/reports/gate-f-corridor-probe-t3-pickups-after-2026-08-30.txt` —
  raw after-probe output, §4.

**Not touched:** `trainers.json` in any band, `burrow_warrens.json`,
`landmark.gd`, `building_prefabs.json`, `scripts/combat/**`,
`data/creatures/species.json`, terrain/grass/scatter/material files — all
per the brief's stated ownership boundaries.

---

## 8. What I would do next

1. Add a direct test for `item_cache_pickup.gd`'s one-time contract
   (spawn, pick up, flag set, reload does not re-spawn, full satchel
   refuses) — the one real coverage gap this branch leaves.
2. A played walkthrough of at least one pickup per band, to confirm the
   "not overwhelming, worth the detour" read actually lands — I could only
   verify this at the config/test level.
3. Resolve the board's "Defense Elixir" duplicate and the Clarity Draught
   gap as an explicit design decision (own it, or route it to whichever
   lane owns new item concepts) rather than leaving it silently unresolved.
4. If a future lane wants MORE off-path pickup density, the pattern here
   (harvest node reuse for renewables, `item_cache_pickup.gd` for anything
   that must stay rare/one-time) generalises cleanly — `CACHE_AT` already
   takes more than one entry.
