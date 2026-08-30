# T5-CADENCE handover — the camps, the dead travel, and the resource ladder

**Lane:** T5-CADENCE. **Date:** 2026-08-30. **Branch:** `ralph/T5-CADENCE`.
**Base:** `origin/main` @ `1d7fc8e7`, plus `origin/ralph/T4-REGIONS` merged in for
its audit and its probe (that branch is two files: the report and
`tools/region_cadence_probe.py`).

This lane acts on `ralph/reports/REGION_AUDIT_2026-08-30.md` and on the
coordinator correction appended to it. It fixes the four findings the correction
names as measurements against real placement data, in the priority order the
brief gave them, and one extension of the first.

---

## 1. Headline: the probe, before and after

`tools/region_cadence_probe.py` is T4-REGIONS' own committed acceptance test.
Run unchanged, with no edits to the probe, the thresholds or the notice radii.

### Longest tier-A dead run per band, in metres

| band | spine | **before** | **after** | change |
|---|---:|---:|---:|---|
| band1 lower meadows | 2403 m | 397 PASS | 397 PASS | untouched |
| band2 stone & root | 2653 m | 396 PASS | 396 PASS | untouched |
| **band3 the river lock** | 2375 m | **668 FAIL** | **218 PASS** | **−450 m** |
| **band4 upper meadows / ironwood** | 3436 m | **1161 FAIL** | **342 PASS** | **−819 m** |
| band5 stronghold approach | 651 m | 0 PASS | 0 PASS | untouched |

Every band now passes at every tier. The chapter has no FAIL left on this
measurement.

The two named runs specifically:

- **band 3's 668 m opening run** (arc 0–668, world `(0,3180)` → `(145,3628)`) is
  gone. The band's longest run is now the 218 m at arc 1158–1375 — which is
  where `ralph/T3-ACTIVITIES` sites the River Nest giver (Doss at `(66,3988)`,
  arc ≈ 1230). That lane's content closes it; this lane did not double-author
  over it.
- **band 3's 519 m exit run** (arc 1855–2375) is gone; its remnants are 85 m,
  109 m and a 46 m.
- **band 4's 1161 m run** (arc 1386–2547) is gone. The band's longest is now the
  342 m at arc 945–1286, which is a **pre-existing PASS this lane did not
  create and did not fix** — see §6.

### Sensitivity — the fix is not a threshold artifact either

The audit's own check: longest tier-A dead run with every notice radius scaled.

| band | ×0.75 | ×1.0 | ×1.5 | ×2.0 | ×3.0 |
|---|---:|---:|---:|---:|---:|
| band1 | 487 | 397 | 220 | 43 | 0 |
| band2 | 484 | 396 | 221 | 46 | 0 |
| **band3** (was 718 / **668** / 568 / 468 / 268) | **293** | **218** | 81 | 51 | 0 |
| **band4** (was 1211 / **1161** / 846 / 798 / **709**) | **368** | **342** | 290 | 239 | **138** |
| band5 | 123 | 0 | 0 | 0 | 0 |

Band 4 failed at ×3 before. It now passes at ×0.75 — i.e. even assuming the
player notices a camp only at 45 m and a trainer only at 37 m.

Reproduce:

```
python3 tools/region_cadence_probe.py
```

---

## 2. Finding 1 — the camps do not work. Fixed, and played.

`props.gd` had no interaction path of any kind, so every authored camp in the
Meadows was scenery. The audit ranked this third across the chapter and was
right about why it is worse than having no camps: five named, well-dressed
sites, one of them a map landmark with a lit fire and a bed, teaching the player
to walk over and be refused.

**What shipped**

- **`scripts/world/night_rest.gd`** — the body of `camp.gd::_on_rest()` /
  `_pass_the_night()`, moved out and unchanged. Same fade, same `advance_day`,
  same `player_slept_at_home`, same `complete_creature_bed_rests`, same trainer
  heal, same morning reset, same autosave. `camp.gd` now calls it (its
  `_pass_the_night` stays as a thin forward, because tests and
  `tools/gate_f/probe_bed_rest_sequence.gd` call it directly to pass a night
  without a tween). **There is one definition of what a night costs and pays,
  and both kinds of camp use it** — the alternative was a second implementation
  and the standing lesson of this audit is what happens when the world has two
  half-answers to one question.
- **`scripts/world/rest_point.gd`** — the authored-camp node. Offers
  **Rest until morning**, **Craft**, and where the camp already authored a bed,
  a **working creature bed** (`creature_bed.gd::build_real(false)` plus a
  reserved negative index, the same pattern `stronghold.gd` already uses for the
  Hall's recovery point).
- **`props.gd`** reads an optional cluster-level `rest` block and builds one.
  It also reports `rest_points()`, so a silently skipped camp is visible.

**The five camps**

| camp | band | what it now offers |
|---|---|---|
| `trail_camp` | 1 | rest · craft · a creature bed added beside the fire (the existing `camp_bed` stays as the trainer's own) |
| `ranger_camp` | 2 | rest · craft at the anvil · the toppled cot **righted** into a working bed · **a fire ring and fire** |
| `riverwatch_rest` | 3 | rest · craft · its bedroll made real · **a fire ring and fire** |
| `highfield_stockcamp` | 4 | **new camp** — see §4. Band 4's first usable stop in 3436 m |
| `the_waystop` | 5 | rest · craft · a creature bed · **a fire ring and fire** (extension, see §5) |

The creature bed is the half that makes "recovery" mean anything away from home:
`game_state.gd::_tick_creature_bed_recovery()` heals an occupant over real time
whether or not the player is standing there, so an injured creature left at the
ranger camp is genuinely unavailable and genuinely recovering — exit criterion
H3's expedition decision, which cannot land while every bed in the wild is a
mesh. `Bed_Twin1` (the furniture pack's human twin bed, which
`creature_bed.gd`'s own header records two blind critics calling "a human bed
labelled creature bed") is retired from bands 2 and 3 in favour of the camp
set's `camp_bed.glb`. One fewer stand-in, no new asset.

**Prose this overturns, named rather than quietly overwritten.** Both reversals
are recorded in the `_why` of the block that reverses them:

- `riverwatch_rest`: *"Deliberately NOT a healer or a second camp mechanic — the
  game has exactly one rest structure (scripts/build/camp.gd) and this is not a
  second one."* It still is not a second one: `rest_point.gd` calls
  `night_rest.gd`, which is the same single mechanic `camp.gd` calls. What
  changed is that the promise the site's name makes is now kept.
- `ranger_camp`: *"Salvage, not shelter."* The collapse still reads — the
  toppled cabinet, the emptied crate, the dropped bag, the tipped bucket are all
  untouched. The cot is what a traveller using the site would right first, and
  now has.
- `ranger_camp`, `the_waystop`: both recorded the fire ring as **unbuildable**
  ("the shipped prop family has no stone or tent/frame mesh"). That substitution
  note is spent — `campfire_stone_ring.glb` shipped from the owner-referenced
  camp set afterwards and bands 1, 3 and 4 all use it. Nothing generated,
  nothing sourced.

**Played-path evidence.** `tests/smoke_authored_camps.gd` (new, wired into
`ci.yml` as `smoke: authored_camps`) boots the real world, walks the player to
each camp and presses the button:

```
authored camps carrying a rest block: 5
  trail_camp             rest + craft + bed at 346, 935
  ranger_camp            rest + craft + bed at -256, 2260
  riverwatch_rest        rest + craft + bed at 215, 3697
  highfield_stockcamp    rest + craft + bed at 277, 5652
  the_waystop            rest + craft + bed at -21, 7457
  trail_camp             offers 'Rest until morning'
  ranger_camp            offers 'Rest until morning'
  riverwatch_rest        offers 'Rest until morning'
  highfield_stockcamp    offers 'Rest until morning'
  the_waystop            offers 'Rest until morning'
  rested at trail_camp: day 1 -> 2
  the bedded creature woke at full HP
authored camps smoke test passed
```

The middle block is the point. A prompt that exists but never wins the
arbitration is the same refusal in a different costume, so the test asks the
live `interaction_arbiter` what it is offering where the player is standing.

---

## 3. Finding 2 — band 3's dead travel. 668 m → 218 m.

Five authored sites, from fun-rebuild §12's own activity vocabulary, fitted to
the region rather than scattered uniformly. Every site was ground-probed before
it went into data (`tools/_probe_cadence_sites.gd`,
`tools/_probe_cadence_flat.gd`, both committed) — band 1's trail camp took three
relocations to learn that a camp on a 1.2 m drop reads as a slope with objects
on it.

**The opening run (arc 0–668)**

1. **`tether_haulage_wreck`** (props 3005, arc 100) — a Team Tether hauling sled
   that shed its load coming down out of Stone & Root. Environmental
   storytelling + Team Tether presence + a resource formation, and the first
   thing in the River Lock that says whose road this is. It carries band 3's
   rootstone (see §6 below — one site fixes two findings).
2. **`lockwater_overlook`** (props 3006, arc 339) — the shelf at the spine's
   western bend where the ground opens north. §12 names "overlook" and
   "anticipate something clearly visible ahead", and this band needs it more
   than any: the audit's tenth finding is that a 12 m gorge is a negative-space
   feature with no silhouette. It **pays** (exit criterion G9) — a Greater Orb,
   harvest 3026.
3. **`the_springhead`** (props 3007, arc 515) + **a brooktail alpha**
   (spawns 3102) — a spring pool ringed with stone and fern, held by a 1.3×,
   +4-level individual. This answers the audit's team-building PARTIAL directly:
   band 3's two new species are *"conditional singletons ... a player who
   crosses this band in clear weather by day sees ZERO new species."* This one
   is unconditional, on the route, in any weather at any hour.
4. **The Stonewater Reach** — a named region (`map_landmarks.json`) over the
   whole opening stretch, which had no name and no landmark at all. Separation
   checked, not assumed: 492 m to The Tether Relay, 780 m to The Long Water,
   996 m to The Burrow Warrens.

**The exit run (arc 1855–2375)**

5. **`northbank_ironwood_cut`** (props 3008, arc 2006) — a cutting stopped
   mid-job on the climb out of the river country, carrying band 3's ironwood.
6. **A galecrest alpha pair** (spawns 3103, arc 2097) on the north-bank bluff —
   the ecological handover into band 4, said in creatures rather than in a sign.
7. **`crossing_watchpost`** (props 3009, arc 2200) — Team Tether's own
   observation post above the Old Mill Crossing, **empty**. The player reaches
   it having just taken the Relay and restored the crossing; exit criterion G6
   asks a major victory to change world state, and an abandoned post 450 m past
   the fight is that, told without a line of dialogue.

---

## 4. Finding 3 — band 4's dead travel. 1161 m → 342 m.

The audit's own verdict on this stretch was *"A player who is going to put the
Meadows down will put it down here"*, and it survived the ×3 sensitivity test.
Five beats:

1. **`highfield_stockcamp`** (props 4001, arc 1459) — **a working camp**, and
   band 4's first: until this the band had exactly one prop cluster in 3436 m,
   and that one is Team Tether's own posting at the far end. This is the other
   end of `pasture_drover_juno`'s road, the summer stock camp the drovers keep
   while the herd is up — still in use, unlike the ranger camp and the quarry,
   which is the point, because the chapter's back half needed one place that is
   not abandoned. Sited on the flattest 7 m pad within 26 m of the spine
   (0.70 m relief, 9.0° worst slope, swept by `tools/_probe_cadence_flat.gd`).
2. **A meadowhart herd bull** (spawns 4101, arc 1703) — 1.35×, +4. §12's own
   worked example of a beat that needs no fight: *"a visible herd on a ridge"*.
   Meadowhart is spec §3's riding creature, and all four of band 4's existing
   alphas sat in the western third; the whole eastern half of the longest band
   in the chapter had no exceptional individual at all.
3. **`severed_conduit_post`** (props 4002, arc 1950) — Team Tether cable
   hardware on the high ground, cut and abandoned. Exit criterion E3 asks for
   *"pylons, hardware, drained ground escalating toward the stronghold"* and the
   band had none of it anywhere in the dead stretch.
4. **`the_wind_overlook`** (props 4003, arc 2131) — the crest where the road
   leaves the Highfield: bedrock, two drovers' waymarker stones, somebody's
   pack. It pays a Greater Orb (harvest 4031), which band 4 had none of.
5. **`ridge_road_picket`** (props 4004, arc 2395) — a Team Tether roadblock
   300 m below `captain_ridge`. Exit criterion F2's hierarchy closing in.
6. **The Highfield** — a named region over the eastern sweep. The name is the
   chapter's own, not new world-building: `items.json`'s `field_sigil` calls the
   Field Captain's posting *"the high pasture posting"*. Separation is the most
   comfortable on the map (902 m / 968 m / 1160 m), because the whole finding is
   that nothing was here.

---

## 5. Finding 4 — band 3's resource regression. Fixed.

`MEADOWS_PROGRESSION_SPEC` §10 and `items.json`'s own `rootstone` comment agree
there are exactly two tier materials in the whole biome: Rootstone, then
Ironwood. Band 2 introduced both; band 3 shipped wood/fiber/stone/berries and
nothing else.

- **Rootstone ×3** (harvest 3023–3025), **in the haulage spill**, not in open
  meadow. That siting is the reason this is content rather than a number
  correction: `items.json` says Rootstone *"comes only from deep seams —
  warrens, old quarry faces"*, and there is no seam in the river country. What
  there is, is Team Tether's haul road out of Stone & Root. It is their load,
  off the sled.
- **Ironwood ×4** (harvest 3027–3030), in the north-bank cutting — on the climb
  *into* the band the Ironwood Grove is named for, which is where
  `items.json`'s "old-growth stands" actually are.

The ladder still rises: band 2 keeps five rootstone deposits, band 4 keeps ten
ironwood. Band 3 is back on it rather than ahead of it.

**Band 5's resource FAIL (8 nodes, all band-1 tier) is NOT fixed** — see §6.

---

## 6. What this lane did NOT do, and why

Written so the next lane can pick these up without re-deriving them.

### Held by another lane — worked around, per the brief

- **`data/config/bands/*/trainers.json`.** `ralph/T3-ACTIVITIES` and
  `ralph/T1-CREATURE-RIG` both hold band trainer files. The audit's eighth
  finding — band 1 puts 7 of 9 trainers in the village square, band 3 puts 4 of
  5 in an 84 m span, band 4 runs one per 859 m — is **still open**, and trainers
  are the cheapest fix for the remaining gaps because they are people the world
  already has. Two rows this lane would have written, both sited and
  ground-probed:
  - **band 4, on the `ridge_road_picket` barricade** at `(-6.7, 6299.7)`. A
    grunt or officer standing on the block, 300 m below `captain_ridge`. This is
    the single highest-value trainer row available in the chapter: it mans an
    already-built site, closes band 4's 870 m trainer gap, and turns a piece of
    scenery into the escalation F2 asks for.
  - **band 3, at the `crossing_watchpost`** at `(127, 4649)`. Optional; the post
    reads better empty, given the player has just taken the relay.
- **`scripts/build/creature_bed.gd`** (T3-ACTIVITIES). Not touched. The reserved
  index range for authored camp beds is declared in `rest_point.gd`
  (`AUTHORED_BED_INDEX_CEILING`, −10) rather than added to `creature_bed.gd`'s
  own `UNASSIGNED`/`AUTHORED_STRONGHOLD_REST` constants, specifically to avoid
  racing that file. **Worth folding in later**: those three constants belong
  together.
- **`scripts/build/camp.gd`** is touched, but only at the bottom (`_on_rest`,
  `_pass_the_night`). T3-ACTIVITIES' 90-line change to that file is entirely in
  the constants / `build_real` / `_spawn_meshes` region, so the two should merge
  cleanly. Flagging it because that branch also conflicts with `main`'s own
  T1-LIGHT change to the same file.
- **`species.json` / `spawn_tables.json`** (creature-rig lane). Untouched. The
  audit's second-ranked gap — zero new species in bands 4 and 5 — is a roster
  question, and the three alphas added here are deliberately extra individuals
  of species those bands already hold, not an answer to it. Note also that the
  audit's `ashtusk` line is partly stale: `band5/spawns.json` carries a
  `_comment_ashtusk_removed`, so a wild Ashtusk was placed and deliberately
  removed by T3-CREATURES. Do not re-place it without reading that comment.

### Deliberately not built

- **A pylon line in band 4.** `severed_spokes.gd::_build_pylons` is a shared
  builder already borrowed twice (`old_quarry.gd`, `stronghold.gd`), and
  fun-rebuild §12 names "Team Tether pylon" outright — a 12 m pylon run marching
  across the Highfield is the **better** version of `severed_conduit_post` and
  probably the strongest single beat available in band 4. It was not built
  because it needs a new script, a new config and a cable-sag/ground-clearance
  sweep that this lane could not verify visually, and a half-built pylon run is
  worse than a well-built cable post. Recommended as a small, well-scoped
  follow-up for whoever has frames.
- **Band 5's resource FAIL.** 8 nodes of band-1 material in the region whose
  purpose is final preparation. Out of this lane's four priorities; cheap, and
  the pattern is now established (rootstone/ironwood sited in fiction).
- **Zero night-gated spawns in bands 0/1.** Listed in the brief as "if time
  remains" and not reached. Band 2 is the working template (12 night clusters
  plus `nightburrow`); the opening still has no evidence at all that night
  changes the world.
- **Band 4's remaining 342 m run** (arc 945–1286, world `(-175,5407)` →
  `(127,5565)`). A **pre-existing PASS**, not created here, but it is now the
  band's binding constraint. It is the crest out of the ironwood into the high
  pasture; one small beat there (a drovers' waystone, or the band-4 picket
  trainer relocated) would give the band real margin.

### Visual verification — not done, and honestly flagged

Every site here was placed from **measured terrain** (two committed ground
probes) and from the measured layout of the props already at each camp. **No
frames were captured.** Specifically worth a look when these areas are next
rendered:

- `trail_camp`'s new creature bed at `(347, 934)` — 0.49 m relief but 12° worst
  local slope, the roughest of anything this lane placed on a pad.
- `the_wind_overlook`'s two waymarker stones use `scale_xyz` to narrow and raise
  a boulder mesh into standing-stone proportions. It works geometrically and it
  **stretches the normal maps**; that cost is real and is written into the
  cluster's own `_why` rather than hidden.
- Whether the Lockwater Overlook's view actually opens is the one claim in this
  report a capture has to settle.

### One pre-existing defect noticed and left alone

`map_landmarks.json`'s `band1_trail_camp` landmark sits at `(348, 919.5)`. The
camp itself moved to `(344, 935)` in BAND1-D1-v3 and the landmark did not follow
— it is 15.6 m out. Harmless today (the discover radius is 25 m) and outside
this lane's scope, but it will read wrong on the map the moment anyone looks.

---

## 7. Verification run

| check | result |
|---|---|
| `tools/region_cadence_probe.py` | all five bands PASS at all three tiers; band 3 668→218, band 4 1161→342 |
| sensitivity sweep ×0.75 … ×3.0 | band 3 and band 4 PASS at every scale |
| unit suite (`run_tests.gd`, CI's own skip list) | **1545 tests, 278174 assertions, 0 failed** |
| `tests/smoke_authored_camps.gd` (new) | passed — 5 camps, all offering rest, night passed, bedded creature woke at full HP |
| `tests/smoke_playground.gd` | passed |
| `tests/smoke_gate_a_rest_torch.gd` | passed |
| `tests/smoke_relay_station.gd` | passed |
| `tests/smoke_warrens.gd` | passed |
| `tests/smoke_wild_streaming.gd` | passed |

`origin/main` had not moved from `1d7fc8e7` at push time; nothing to merge
forward. Merged forward from `origin/ralph/T4-REGIONS` only, for the audit and
the probe.

---

## 8. Files

**New**

```
scripts/world/night_rest.gd          one definition of what a night costs and pays
scripts/world/rest_point.gd          the authored-camp rest/craft/bed offer
tests/smoke_authored_camps.gd        played-path evidence for the camps
tools/_probe_cadence_sites.gd        ground/relief/slope at every new site
tools/_probe_cadence_flat.gd         flattest-pad sweep for the two camp sites
ralph/reports/handover-T5-CADENCE-2026-08-30.md
```

**Changed**

```
scripts/world/props.gd               reads a cluster `rest` block; reports rest_points()
scripts/build/camp.gd                _on_rest/_pass_the_night now call night_rest.gd
data/config/bands/band1_lower_meadows/props.json      trail_camp rest block
data/config/bands/band2_stone_and_root/props.json     ranger_camp rest block, fire, righted cot
data/config/bands/band3_the_river_lock/props.json     riverwatch_rest rest block + fire; 5 new clusters
data/config/bands/band3_the_river_lock/harvest.json   rootstone x3, ironwood x4, orb_greater
data/config/bands/band3_the_river_lock/spawns.json    brooktail alpha, galecrest alpha pair
data/config/bands/band4_upper_meadows_ironwood/props.json    4 new clusters, one of them a camp
data/config/bands/band4_upper_meadows_ironwood/harvest.json  orb_greater
data/config/bands/band4_upper_meadows_ironwood/spawns.json   meadowhart herd bull
data/config/bands/band5_stronghold_approach/props.json       the_waystop rest block + fire
data/config/map_landmarks.json       The Stonewater Reach, The Highfield
.github/workflows/ci.yml             smoke: authored_camps
```

No asset was generated, sourced or added. Every mesh placed here was already
installed and already used elsewhere in the chapter, and
`docs/ASSET_LEDGER.md` needs no new row.
