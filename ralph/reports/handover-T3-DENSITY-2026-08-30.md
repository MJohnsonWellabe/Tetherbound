# Handover — T3-DENSITY, 2026-08-30

**Branch:** `ralph/T3-DENSITY`, created off `claude/tetherbound-coordinator-onboard-7pz3ah`
(carrying D70 and the creature-expansion reference boards) and merged forward
with `origin/ralph/T3-PICKUPS` at tip `c1059109` (`T3-PICKUPS: handover report
and corridor probe evidence`) — clean merge, no conflicts, both branches share
`a97f3e84` as their common ancestor.

**Working tree at handover:** clean, pushed.

---

## 0. What I was asked

A corridor census (`tools/_probe_gate_f_corridor.gd`, run 2026-08-30) raised
three possible gaps: gather density halving from bands 1-2 to bands 3-4 (Gap
A), only 3 TMs met on the required path against 74 gather nodes and 495 wild
encounters (Gap B), and 12 of 24 main objectives front-loaded into the
opening/tournament with the rest thin across bands 2-5 (Gap C). The brief was
explicit that two of the three were inference from a census, not established
defects, and that disagreeing with evidence is the most valuable outcome.

Per the standing instruction, this audit (§§1-3 below) was pushed before any
authoring commit.

---

## 1. Gap A — gather density, audited and then fixed

### The audit

The brief's own per-band table (`gather` column: 22/23/11/16/2 for bands
1-5) counts **every harvest node of any kind** within 30m of the spine. Two
refinements were needed before deciding what to fix:

**First**, narrowing to `kind: resource` items only (`items.json` — wood,
stone, fiber, rootstone, ironwood; excluding `food`/`consumable`/`armor`/
`gear` pickups, which don't feed the crafting loop §9 means by "gather
useful materials") gives a sharper, worse picture:

| band | any-kind on-route | resource-only on-route | per 1000m |
|---|---|---|---|
| 1 | 22 | 20 | 8.3 |
| 2 | 23 | 17 | 6.4 |
| 3 | 11 | 6 | **2.5** |
| 4 | 16 | 13 | **3.8** |
| 5 | 2 | 2 | 3.1 (D70: correct, do not touch) |

Band 3's on-route crafting-material density is under a third of Band 1's;
Band 4's is under half.

**Second**, and more useful than the density number: computing point-to-
spine-segment distance directly (not the probe's stepped-sample
approximation) for every existing node in bands 3 and 4 and sorting by
cumulative distance-along-spine surfaces the actual **on-route resource
gaps**, band-local:

- Band 3: 588m, then 351m, 224m, 453m, 402m, 271m(tail).
- Band 4: 367m(borderline, left alone), then **1380m**, **986m**, 510m(tail).

Band 4's 1380m gap is the single worst finding in this whole census — closer
to a third of the band's own length with no reachable crafting material on
the required path, in the band spec names as Ironwood's own tier.

### Is a taper deliberate? Checked, and partly — but not this much

Two things argue FOR a deliberate taper: (1) `recipes.json`'s own
`_comment_scope` bounds the whole game to a two-tier economy (baseline +
Rootstone + Ironwood, nothing more) — Band 3 introduces no material of its
own, so some taper relative to Band 1/2 (which each own a tier) is honest
region character, not a bug. (2) Band 3 is trainer-dense (5 trainers/2375m
vs. 2/2403m in Band 1) — the Relay's own mission structure, which the brief
itself allows as a legitimate reason to lean on trainers over gathering.

But neither argument explains gaps of 1380m/986m/453m/402m specifically,
because **every material these bands yield has a real, checked-for sink**:
wood/stone/fiber feed Band 3's own saddle recipe (`recipes_rootstone.json`,
8 fiber — "the one baseline material a player has no other Band-3 sink
for"); ironwood feeds `orb_prime` (4), both `ironwood_haft_*` reinforcements
(3 each) and `potion_large` (2) — all real, all named in `recipes_ironwood.
json` as "the top of the ladder" and "the final-stronghold preparation
item". A material with a real sink that the player cannot reach without a
detour on a >1300m stretch is exactly the "noise, not density" case the
brief warned against **avoiding** — the fix is closing the gap, not adding
more nodes broadly.

### The fix: not "match Band 1's 9.2", but "no on-route resource gap wider
than the cadence discipline already applied everywhere else in this file"

Every prior lane's own siting comments (T3-RELAY, T3-BAND4) target 240-360m
sub-gaps when splitting a dead stretch — "both inside the owner's 60-90s/
240-360m cadence band" appears verbatim across a dozen existing comments.
I applied the same target to the **resource-only** gaps specifically (not
the any-kind cadence, which the full probe already confirms is fine
everywhere — worst chapter-wide gap is 165m, unchanged) and inserted:

- **Band 3** (+3 nodes, orders 3020-3022): fiber, wood, stone, splitting the
  588m/453m/402m gaps into six ~200-295m segments.
- **Band 4** (+6 nodes, orders 4025-4030): ironwood, stone, wood, ironwood,
  fiber, ironwood, splitting the 1380m gap into four ~345m segments and the
  986m gap into three ~330m segments, plus one node closing the 510m tail
  before the band4/5 seam. Three of six are ironwood (the region's own
  signature material with real, checked sinks above); the other three are
  material-variety picks against their immediate neighbours.

All nine positioned by point-to-spine-segment geometry (not eyeballed),
15m off the centreline (matching the established "on-route but not
literally on the road" convention every prior on-route node in these files
already uses), and ground-checked with a new scratch probe,
`tools/_probe_density_sites.gd` (same pattern as `_probe_pickups_sites.gd`
before it) — worst slopes 3.5-12.9 degrees over a 2m pad, all inside the
3.5-13.9 degree range T3-PICKUPS' own siting pass already accepted for this
terrain. One candidate (order 3022) measured 16.4 degrees at its first
tested position and was moved ~15m to a flatter spot (7.1 degrees) before
being authored — the probe run is in the tool file's own history, not
silently discarded.

**Confirmed by re-probe** (§4): Band 3 resource-only 6→9 (2.5→**3.8**/1000m),
Band 4 resource-only 13→19 (3.8→**5.5**/1000m) — exact match to the
predicted counts before the fix was ever run. Neither reaches Band 1's
8.3 — deliberately, per the taper argument above — but no on-route
resource gap in either band now exceeds ~350m.

**Left alone on purpose:** Band 4's 367m gap (order 4006→off-route
neighbours), because it already has off-route resource siblings within
49-62m and armor content (`hide_helm`) landing almost exactly at its far
end — a genuine borderline case, not worth a tenth node for 17m of excess.
Band 5 — D70 is explicit and I did not reopen it.

---

## 2. Gap B — TM placement, audited and then fixed

### The split, established first

14 TMs total (`data/moves/tms.json`): 6 Ground, 4 Water, 4 Air.

- **8 placed in the world** (`playground_world.gd`'s `TM_AT`, before this
  branch): `tm_stone_rush`/`tm_burrow_strike` (Band 1 opening field),
  `tm_wind_blade` (Band 1 grove), `tm_leviathan_surge` (Band 3, apex),
  `tm_earthshatter`/`tm_riptide_lance`/`tm_aerial_flash` (Band 4),
  `tm_heavenfall` (Band 5, apex).
- **9 purchasable at Mira's** (`data/config/trade.json`): `tm_rock_throw`,
  `tm_aqua_shot`, `tm_wind_blade`, `tm_stone_spike`, `tm_tidal_burst`,
  `tm_earth_fist`, `tm_aerial_flash`, `tm_riptide_lance`, `tm_cyclone` — four
  of these (`wind_blade`/`aerial_flash`/`riptide_lance`, plus `earth_fist`
  via trainer reward below) already have a second, world-found path; five
  (`rock_throw`, `stone_spike`, `aqua_shot`, `tidal_burst`, `cyclone`) had
  **no path but the shop**.
- **1 locked behind a trainer reward**: `tm_earth_fist` (`captain_field`,
  Band 4) — also shop-purchasable, so not a single-point-of-failure.

`test_every_tm_in_the_game_can_actually_be_obtained` already pins that every
TM has *a* path — confirmed still true before touching anything. The real
question, as the brief framed it, is whether enough are found in the world.

### The finding the brief didn't name: Band 2 has zero TMs, on-route or off

Reading `TM_AT`'s own siting comments for WHICH region each of the 8
world-placed TMs actually sits in: Band 1 owns 3, Band 3 owns 1 (the apex
`leviathan_surge`, a deliberate off-route detour), Band 4 owns 3, Band 5
owns 1 (apex `heavenfall`, also a deliberate detour). **Band 2 — Stone &
Root, home of the Old Quarry and the Burrow Warrens, the region owner-
direction §6 names as the roster-improvement test — has none at all.** Not
"thin on-route like Band 3's genuine detours" — literally zero, on-route or
off.

This is a cleaner, more concrete finding than "only 3 TMs are met within
30m", because that number is explained by established, intentional design
(every world TM past the opening tutorial pair is sited as a >30m curiosity
detour by explicit comment — "a real detour a player chooses to make", not
a roadside beat — confirmed directly against the committed after-probe
log: the only on-route TMs anywhere in the chapter are the two Band-1
starting ones plus `tm_riptide_lance`). A player who never leaves the road
was never going to meet most of these TMs regardless of band; that's the
architecture working as designed, not Gap B. Band 2 having *no* detour TM
at all, when every other band has at least one, is the actual gap.

### The fix

Added `tm_stone_spike` to `TM_AT` at `(230.0, 1870.0)` — a genuinely
unplaced-anywhere-but-the-shop Ground TM, sited on the `quarry_rim_overlook`
loop (`docs/MEADOWS_MACRO_LAYOUT.md` row 2), further into the loop than the
existing rejoin's `potion_large` pickup so the two don't crowd one spot.
Ground-checked (worst slope 3.8 degrees, the flattest of four candidates
tested). This is a straight second-acquisition-path addition, the identical
shape every prior `TM_AT` entry already establishes — no new TM/move data,
no touch to typing or the per-type multiplier ladder T3-CREATURES/
T3-TYPECHART own.

**Not done, and why**: I did not place the other four unplaced-in-world TMs
(`rock_throw`, `aqua_shot`, `tidal_burst`, `cyclone`). Ground already has
world coverage at both the start (stone_rush/burrow_strike) and the apex
(earthshatter) plus now the quarry (stone_spike) — a real ladder shape, not
a gap. Water has `riptide_lance` (Band 4) and the apex `leviathan_surge`
(Band 3) — two of four, matching the same "early + apex" shape. Air has
`wind_blade` (Band 1), `aerial_flash` (Band 4) and the apex `heavenfall` —
three of four. Placing every remaining shop-only TM in the world would
erase the shop as an economic sink entirely, which is not what the ladder
the owner's board describes (per-type multiplier tiers) implies — some TMs
being coin-bought is the intended shape, not an oversight. **Flagging this
reasoning for the coordinator rather than asserting it's certainly
correct**: if a later pass wants Water or Air to also get a "regional
detour" TM the way Ground now has one per major region, `tm_aqua_shot`/
`tm_tidal_burst` (Water) and `tm_cyclone` (Air) are the pre-vetted,
zero-new-system candidates.

---

## 3. Gap C — objectives, audited, NOT authored against

### The count, confirmed against the live tree

25 total objective entries (24 `main` + 1 `local`), matching the brief
exactly. 12 are opening/tournament (`opening_first_catch` through
`tournament_win`). The other 12 main + 1 local span everything from South
Bridge to the post-Warden epilogue.

### Why I did not add objectives

`data/progression/objectives.json`'s own top-of-file comments (`_comment`,
`_comment_count_flags`, `_comment_chain`) are explicit and load-bearing:

1. **The architecture is capped by design.** "spec sec19 and CLAUDE.md both
   ban a quest engine — an entry is only ever DONE or not-yet." No
   prerequisites, no branching, no per-entry visibility conditions. Every
   entry must be built from a flag the game **already sets** —
   `_comment_chain`'s own words: "no new boolean was invented for any of
   them... avoid redundant booleans where real game state can answer
   completion." Inventing new objectives to fill out bands 2-5 would mean
   inventing new flags with nothing real behind them, which is precisely
   what this file's own history (the eleven-entry CHAPTER-OBJECTIVES pass)
   says not to do.

2. **Multi-part milestones already carry sub-progress.** `defeat_the_
   captains` (Band 4, the "Captain Hunt") is not one monolithic flag — it
   carries `count_flags: [defeated_captain_field, defeated_captain_ridge,
   defeated_captain_riverwatch]` and renders as "Defeat the Upper Meadows
   captains. 2/3" per `_comment_count_flags`'s own worked example.
   `fight_through_the_hall` does the same for the Hall gauntlet's three
   fights. So the "one objective for three captains" reading the brief's
   band-mapping suggests is not what a player actually sees in the log —
   they see live progress across all three.

3. **A separate, already-landed system carries the "shape" the brief is
   asking objectives to provide.** `ralph/reports/finding-ladder-readiness-
   2026-08-29.md` confirms §10's readiness signals shipped across **all
   ten rungs** of spec §3's challenge ladder (South Bridge, Warrens
   Guardian, Captain Vance, all three captains, the Hall gauntlet, the
   Warden) as dialogue lines a player reads immediately before each major
   fight — team-size expectations, rest cues, endurance-sequence framing.
   That is the qualitative "what's coming and how to prepare" guidance §9/
   §10 ask for; the objectives file was never meant to carry it, and
   `_comment_no_spoilers`/the guided-view mechanism (`quest_log.gd::
   guided_entries()`) confirm the log is deliberately minimal ("what is
   done plus the ONE current rung") by design, not by neglect.

4. **The band-by-band spread is lopsided in a way that matches region
   character, not an oversight.** Mapping the 12 non-opening main entries
   by which region's content they name: Band 2 = 1 (Warrens), Band 3 = 4
   (Relay Captain, rescue, disable relay, restore the crossing — one
   continuous mission arc), Band 4 = 1 (captains, but count-tracked at
   3 sub-goals), Band 5/Hall = 4 (gauntlet, Warden, machine, roster) + 1
   epilogue. Band 3's mission structure earns four discrete beats because
   it IS four discrete story beats (arrive, fight the captain, find the
   captive, disable the machine, reopen the crossing) — Band 2 and Band 4
   are the self-directed "roam, gather, catch, prepare" regions the design
   explicitly wants to NOT be a checklist, per §12's own "the world does
   not need constant combat, it does need constant potential" framing
   (which this same lane's Gap A/B work already reinforces with world
   content, not quest-log lines).

**Conclusion: no objectives.json change.** This is the "already fine, say
so with the evidence" outcome the brief explicitly said was legitimate and
more valuable than authored padding. I looked for a genuine missing beat
(a real flag the game already sets that isn't tracked) and did not find
one — every real milestone flag I could find already has an entry or is
folded into an existing entry's `count_flags`.

---

## 4. Test results

Environment: Godot 4.7-stable fetched fresh
(`tools/art_pipeline/setup.sh godot`), `--import` run once (~clean, no
manual re-run needed), and a second short `--import` pass to mint the
`.uid` for the new scratch probe tool.

Baseline (before any authoring, confirming the merged tree was green):
```
--only=test_chapter_rewards.gd,test_band_content.gd,test_spawns_data.gd,test_trainers_data.gd,test_item_icons.gd,test_trade.gd,test_moves.gd,test_harvest.gd
-> 154 tests, 727090 assertions, 0 failed
```

After Gap A + Gap B (band3/4 harvest.json, playground_world.gd TM_AT):
```
--only=test_chapter_rewards.gd,test_band_content.gd,test_spawns_data.gd,test_trainers_data.gd,test_item_icons.gd,test_trade.gd,test_moves.gd,test_harvest.gd,test_harvest_permanence.gd,test_camp_supply_reaches_every_band.gd,test_gather_point_props.gd,test_inventory.gd,test_satchel.gd,test_recipes.gd
-> 285 tests, 949254 assertions, 0 failed
```
(the trailing `PagedAllocator`/`ObjectDB leak`/`RID allocation leaked` lines
at process exit are normal Godot shutdown noise, matching every predecessor
handover's own note — not test failures.)

Corridor probe, before/after (raw logs:
`ralph/reports/gate-f-corridor-probe-t3-pickups-after-2026-08-30.txt` was
the "before" state for this branch, and
`ralph/reports/gate-f-corridor-probe-t3-density-after-2026-08-30.txt` is
the "after"):

| metric | before | after |
|---|---|---|
| chapter `gather` (any kind, on-route) | 74 | **83** |
| band3 `gather` | 11 | **14** |
| band4 `gather` | 16 | **22** |
| band3 resource-only on-route (computed, not a raw probe field) | 6 (2.5/1000m) | **9 (3.8/1000m)** |
| band4 resource-only on-route | 13 (3.8/1000m) | **19 (5.5/1000m)** |
| chapter `met` (total things) | 589 | **598** |
| chapter `tm` | 3 | **3** (unchanged — `tm_stone_spike` is a deliberate >30m detour, see §2) |
| chapter `worst_gap_m` | 165 (band2) | **165 (band2, unchanged)** |
| dead-walk intervals ≥250m | 0 | **0** |

Every number moved exactly as predicted before the fix was run, and nothing
outside bands 3/4 shifted at all — confirming the additions didn't disturb
cadence anywhere else in the chapter, including Band 2 (where the TM
placement is a pure detour addition, invisible to the `met`/`gather`
count) and Band 5 (untouched, per D70).

---

## 5. Done-verified vs. still-open

**Done and verified:**
- Gap A: 9 new harvest nodes (3 band3, 6 band4), all ground-checked,
  all collision-checked (23m+ clearance from nearest existing content,
  well over the 4.5m `MIN_SPOT_SEPARATION` test), all using existing
  item ids with existing models (no new asset, no Meshy spend).
- Gap B: 1 new `TM_AT` entry, ground-checked, no code change beyond the
  dict literal (the placement/restore mechanism already iterates `TM_AT`
  generically).
- Gap C: audited, evidence recorded, no change — see §3.

**Still open / flagged, not mine to act on further:**
- Water/Air "one detour TM per major region" parity (§2) — a judgement
  call I made NOT to extend to `tm_aqua_shot`/`tm_tidal_burst`/`tm_cyclone`
  this pass, flagged for a coordinator call.
- Band 4's borderline 367m resource gap (§1) — left alone, arguably still
  slightly over the 350m target; a tenth node would close it if a future
  pass wants zero exceptions rather than one small one.
- `docs/reference/owner-board-2026-08-15-systems-and-castle.png`'s "Clarity
  Draught" orphan and "Defense Elixir" duplicate (T3-PICKUPS's own flags,
  §5 of that handover) — untouched, not this lane's scope, still open for
  whoever owns new item design.

---

## 6. What I learned that is NOT visible in the diff

- **The corridor probe's `gather` metric conflates two very different
  things** (crafting materials and consumable/gear pickups) and measuring
  only the conflated total would have led to a wrong fix — narrowing to
  `kind: resource` via `items.json` before drawing conclusions was the
  single most load-bearing analytical step in this pass. Any future
  density audit should do the same narrowing before trusting the raw
  `gather` column.
- **Point-to-segment distance against the live spine (`terrain_playground.
  json`) is more useful than the probe's own stepped-sample "met/not met"
  classification** for finding WHERE to place a fix, because it gives an
  exact cumulative-distance-along-spine for every existing node, which
  turns "the density is low" into "here are the six specific gaps and
  their exact sizes" — this is what let me target insertions precisely
  rather than scattering by feel.
- **`_comment_red_leak_d4b` in band4's harvest.json is a real trap** for
  anyone adding ironwood content: three prior blind visual passes fought a
  crimson-canopy/"blight ground" misread down to "TwistedTree_4, pale
  variant, ONLY" — any of the other three TwistedTree numbers reintroduces
  a bug two rounds of visual-judge time already spent fixing. All three new
  ironwood nodes in this pass use TwistedTree_4 exclusively for this reason.
- **TM_AT's own comments already document, in full, WHY every existing
  entry sits where it does** — reading them end to end before touching the
  dict answered "which region owns which TM" faster and more reliably than
  re-deriving it from world coordinates, and is why I could state the
  "Band 2 has zero" finding with confidence rather than guessing from raw
  Vector2 values.
- **The frozen `band_split_baseline` fixture mirror only covers orders
  0-21** (the pre-band-split legacy content) — band3/4's own 3000+/4000+
  ranges are NOT in it, so none of this pass's new entries needed a mirror
  edit. Confirmed by reading the fixture directly rather than assuming the
  trap applied here too.

---

## 7. Disagreements

None of substance beyond what's flagged inline above (§2's Water/Air parity
question, §1's one borderline gap left alone). The two "is this actually a
gap" questions the brief posed came back genuinely mixed: Gap A was real
and worth fixing (with a different target than the brief's own naive
"match Band 1" framing); Gap B was real but not the number the brief named
(Band 2's total absence, not the on-route-count); Gap C was not real and I
did not manufacture content to make its table look even.

---

## 8. File footprint

**Data:**
- `data/config/bands/band3_the_river_lock/harvest.json` — +3 nodes
  (orders 3020-3022).
- `data/config/bands/band4_upper_meadows_ironwood/harvest.json` — +6 nodes
  (orders 4025-4030).

**Code:**
- `scripts/world/playground_world.gd` — +1 `TM_AT` entry (`tm_stone_spike`).

**Tools (committed per this repo's own scratch-probe convention):**
- `tools/_probe_density_sites.gd` (+ `.uid`) — ground-check probe for every
  candidate position in this pass, including the one rejected/relocated
  candidate (order 3022) left in the file's own history.

**Reports:**
- `ralph/reports/gate-f-corridor-probe-t3-density-after-2026-08-30.txt` —
  after-probe raw output.
- This file.

**Not touched:** `data/creatures/species.json`, typing/rarity/spawn tables,
move/TM *data* (`data/moves/*.json`), `data/config/bands/*/trainers.json`,
terrain/grass/scatter/sky, `scripts/world/stronghold*.gd`, `landmark.gd`,
`building_prefabs.json`, `scripts/ui/**`, `objectives.json` — all per this
lane's stated ownership boundaries, and `objectives.json` specifically left
alone per §3's own conclusion.

---

## 9. What I would do next

1. Re-probe after a full unrestricted test run to confirm no other lane's
   concurrent work (LAND-0830 is mid-merge of fourteen branches) shifted
   the chapter-wide numbers between this audit and integration.
2. If the coordinator wants Water/Air region parity on TM detours to match
   Ground's now-three-region coverage, `tm_aqua_shot`/`tm_tidal_burst`
   (Water) and `tm_cyclone` (Air) are pre-vetted candidates — no new
   TM/move data needed, just `TM_AT` placement, which is this lane's own
   file.
3. A played walkthrough of at least the three worst-gap fixes (Band 4's
   1380m and 986m gaps especially) to confirm the ~330-345m sub-segments
   read as "worth stopping for" in practice, not just on paper — I could
   only verify this at the config/geometry/test level, same limitation
   T3-PICKUPS flagged for its own pass.
