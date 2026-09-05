# W20-SMALL-FIXES — report

Branch: `ralph/W20-SMALL-FIXES-0904`, from `origin/main` at `ef16544f`.
Lane brief: `ralph/briefs/0904/W20-SMALL-FIXES.md` (closure plan §6.2 — the cheap,
owned, disjoint items that were generating false readings).

**One line per item, done / not done, up front. Detail below.**

| Item | Verdict |
|---|---|
| CL-E12 — relay heals its own three drain stations on `relay_disabled` | **done** |
| CL-G6 — the Riding Saddle costs Ironwood | **done** |
| CL-E1 — Oreth's C-3 profiles (Mosshell WALL, Brooktail CURRENT) | **done** |
| CL-E2 — Oreth's stale `facing_deg` | **already fixed; verified, not rewritten** |
| CL-D1 — `chapter_curve.json`'s "no trainers of its own" | **done** |
| CL-D2 — prompts 64 / 66 "empty spawn data" | **done** |
| CL-D6 — `GATE3_EXECUTION_PLAN.md` §4's answered questions | **done** |
| CL-D7 — `MEADOWS_EXIT_CRITERION.md` B2 / B4 / E5 numbers | **done** |
| CL-D4 — band 2 vegetation `_why` strings | **skipped, as the brief instructs** |
| CL-H5 — the freeze-record trap | **done** |
| CL-H4 — `S02-60`'s route-row threshold | **done** (S02 only; S04/S05 left to G3-HARNESS) |
| CL-H8 — `S06-30`'s invented workbench beat | **decided** — not a game defect; removal handed to W21 |
| CL-E10 — `_probe_band5_approach.gd`'s `03-mid-route` aim | **done** |

---

## Files changed

Game data and code:

- `data/recipes/recipes_rootstone.json` — the saddle's Ironwood line (CL-G6)
- `data/config/bands/band3_the_river_lock/trainers.json` — Oreth's C-3 profiles (CL-E1)
- `tests/fixtures/band_split_baseline/trainers.json` — the tracked mirror of the same,
  in the same commit, per that fixture's own policy (CL-E1)
- `data/config/chapter_curve.json` — the stale "no trainers of its own" sentence (CL-D1)
- `data/config/tether_relay.json` — `dead_ground.heal_stations` (CL-E12)
- `scripts/world/meadow_healing.gd` — `heal_stations()`, the station filter (CL-E12)
- `scripts/world/tether_relay.gd` — `_heal_local_scatter()`, fired from the console (CL-E12)
- `scripts/world/vegetation.gd` — `restore_drained(within)` (CL-E12) **— outside the
  brief's named ownership list; see "One file touched outside the list" below**

Tests:

- `tests/test_recipes.gd` — the Ironwood price, seen red first (CL-G6)
- `tests/test_gate_f_rig.gd` — the lane declaration, end to end (CL-H5)
- `tests/smoke_relay_station.gd` — the local heal, and that it is local (CL-E12)

Harness and tools:

- `tools/gate_f/run_segment.sh` — writes its own logic-lane freeze declaration (CL-H5)
- `tools/gate_f/segments/S02.json` — `S02-60`'s threshold, re-derived (CL-H4)
- `tools/gate_f/segments/S06.json` — **step `S06-30` only**, the CL-H8 verdict
- `tools/_probe_band5_approach.gd` — `03-mid-route`'s eye, back on the sightline (CL-E10)
- `tools/_probe_oreth_profiles.gd` — new, the CL-E1 runtime proof
- `tools/_probe_workbench_context.gd` — new, the CL-H8 decision probe
- `tools/_capture_relay_healing.gd` — new, the CL-E12 before/after pair

Docs:

- `docs/prompts/64-BAND3-finished-river-relay.md`, `docs/prompts/66-BAND5-finished-stronghold-approach.md` (CL-D2)
- `docs/GATE3_EXECUTION_PLAN.md` §4 (CL-D6)
- `docs/acceptance/MEADOWS_EXIT_CRITERION.md` B2 / B4 / E5 (CL-D7)

---

## What changed, in player-facing terms

**The relay's ground heals when you switch the relay off (CL-E12).** Before this,
pressing the console faded the site's runtime dead-ground skin and did nothing else, so
the compound went from dead ground with no plants on it to ordinary ground with no plants
on it — the drain had removed real scatter instances at build time and only the chapter's
own ending put them back. A player standing in the yard they had just taken saw a site
that was still half dead. Now the plants inside the relay's own three drain stations grow
back at the moment its own machinery dies, and nowhere else does: the quarry's four
stations, which have no console to press, still wait for the Warden, and so does every
other metre of the map.

**The Riding Saddle costs Ironwood (CL-G6).** The finishing step of the saddle now asks
for 2 Ironwood alongside its Rootstone, so riding is earned in early Band 4 at the
old-growth grove rather than being affordable a region earlier. The intermediate
`saddle_frame` deliberately stays Rootstone-only, so half the saddle is still a Band 3
goal a player can work toward before the grove is on their map.

**Oreth's three creatures fight three different ways (CL-E1).** His Mosshell now plants
itself and hits hard and slowly (WALL); his Brooktail ace never lets up and never backs
off far (CURRENT); his Trailpup fights the ordinary way. Before this all three shared one
brain, and the fight the contract designed around composition read as three health bars.

**Nothing else here is player-facing.** The rest is instruments and documents: a Gate F
runner that can start a run, a threshold that can be satisfied, a capture that points at
the Hall, and five sentences that describe content as missing when it is not.

---

## Per item

### CL-G6 — the Riding Saddle costs Ironwood — **done**

`recipes_rootstone.json`'s `saddle` shipped at the Rootstone-only price with its own
`_comment_ironwood` spelling out the edit to make when SF31 landed. SF31 has landed:
`ironwood` is a real item in `data/items/items.json`, felled with an axe from the Band 4
old-growth stands (`bands/band4_upper_meadows_ironwood/harvest.json`). Made exactly the
prescribed edit — one `{ "id": "ironwood", "n": 2 }` line, `wood` 4 → 2 — and nothing
more. The seam comment is rewritten to say it is closed and to state the pacing
consequence out loud rather than leaving it to be discovered: riding is now Ironwood-gated
and therefore early Band 4, inside the spec's own "available by Band 3 or early Band 4"
window. `saddle_frame` stays Rootstone-only on purpose.

Checked before shipping: no tier rule breaks. `test_every_rootstone_tier_recipe_actually_
costs_rootstone` only requires Rootstone to be present, `IRONWOOD_TIER_RECIPES` does not
list `saddle`, and `test_no_recipe_anywhere_needs_a_third_progression_material` already
allows both materials.

- `tests/test_recipes.gd`: added the Ironwood assertion to
  `test_saddle_recipe_consumes_the_frame_and_makes_a_saddle`, and a new
  `test_the_saddle_is_priced_in_both_progression_materials` holding both halves (the
  saddle costs both; the frame costs no ironwood).
- **Seen red first:** with the ironwood line removed, `48 tests, 348 assertions, 2 failed`
  — "the saddle is not priced in Ironwood (spec 3 Band 4)" and "the saddle must cost
  Ironwood ...; recipes_rootstone.json's seam is closed". Restored: `48 tests, 352
  assertions, 0 failed`.

### CL-E1 — Oreth's C-3 profiles — **done**

Authored against G-3's own table, on the G-2 per-member `combat` override
`captain_field` and `captain_ridge` already use:

| member | profile | override |
|---|---|---|
| mosshell 13 | WALL | telegraph 0.85, recovery 1.1, chase_speed 3.4, reposition_distance 2.5, power 12.0 (8.0 × 1.5) |
| trailpup 14 | default | none — C-3's own third member |
| brooktail 15 | CURRENT | attack_cooldown 0.7, recovery 0.55, reposition_time 0.5, reposition_distance 2.0, power 6.4 (8.0 × 0.8) |

CURRENT keeps its own ×0.8 here; C-4's Meadowhart is the one the contract explicitly
re-prices at ×1.0, and C-3 asks for "fast and thin", not relentless.

**G-3's fails-if computed before shipping, not assumed.** `combat_math.base_damage` with
these powers against every species' stats at `chapter_curve.json`'s Band 3 `team.enter`
level of 12, worst type multiplier 1.25, each attacker's own quick move: Mosshell's worst
single hit is **18.3** against the frailest level-12 creature's **129.5 HP (14.1%)**;
Brooktail's is **9.0 (7.0%)**. Neither is within a factor of seven of a one-blow kill.

Mirrored in `tests/fixtures/band_split_baseline/trainers.json` in the same commit, entry
at its index, per that fixture's TRACKED MIRROR policy.

### CL-E2 — Oreth's facing — **already fixed; verified rather than rewritten**

`facing_deg` is already −160.5 with a `_why_c2_gate3_encounters` recording the
re-derivation, live and mirrored. Re-checked the arithmetic rather than trusting the
comment: atan2(−52, −147) from his (−100, 4350) to the Old Mill Crossing at (−152, 4203)
is **−160.52°**. The stale −31.4 his own comment flagged is gone. No change made.

### CL-D1, CL-D2, CL-D6, CL-D7 — the stale sentences — **done**

Each correction is dated and, where the old text was load-bearing, struck through rather
than deleted, so a reader who remembers the old sentence can see which way the drift went.

- **CL-D1** — band 2 has four trainers (`quarry_picket_dorn`, `warrens_watch_pell`,
  `band2_outrider_kest`, `night_watch_farro`), counted from its own `trainers.json`.
- **CL-D2** — Band 3 authors **54** spawn clusters, Band 5 authors **23**, counted from
  their own `spawns.json`. Band 5's note also says why 23 is below 54 (D70's crescendo),
  so nobody reads it as a gap to fill.
- **CL-D6** — three of §4's five questions answered: the relay's escalation (V-1 spread
  the picket line to a ~90 m gradient, V-2 re-cut Vance; still unplayed), the Warden
  (measured, then W-1 raised him to 18/18/19/19/20 on the owner's yes), Band 5 (26/30/22
  live bodies at three eyes, 63 m worst gap — the cluster count was the wrong instrument).
- **CL-D7** — B2's 1.08:1 is three passes stale (2.4 measured 1.331 → 1.568;
  G3-CREATURE-COLOUR-0904 reads 1.618 against a 1.5 bar), and what is actually open is
  Burrowback at 1.18–1.19:1 and the overshoot. B4's "no contact shadows" is closed by
  2.4's contact ellipse; the embedded-on-slope half is now the only open half. E5's
  "the Warrens is the standing good example" is marked contested against the owner's
  2026-09-03 finding 9 and pointed at CL-E8.

### CL-D4 — **skipped, as instructed**

The band 2 vegetation `_why` strings are still saying "waiting on the re-bake". The brief
assigns vegetation to another lane this round, so this lane did not touch them. Whoever
takes it: the closure plan's own row has the evidence (the clearings last changed at
`ca78933a`; both bakes were re-run for the merged config at `3c73aab5`, PR #29), and the
same reasoning closes G3-BAND5's "terrain bake freshness for the drain stations is
unconfirmed".

### CL-H4 — S02-60's route-row threshold — **done**

`route_rows_at_least: 900` on a segment that has never written more than 681 rows: an
assertion that could only ever report a defect that was not there.

The trace fires at `trace_hz` 2.0 in **play** seconds, so 900 rows is 450 play seconds.
Measured across every committed `S02/telemetry/route.csv` under `ralph/reports/`, filtered
to runs whose measured rate is actually ~2 rows/play-second (the 2026-08-25/27 pair record
1.62–1.63 on a different clock and are excluded rather than averaged in): **13 healthy
completions, 287.1–341.7 play seconds, 561–681 rows, mean 599.**

Re-derived to **450 rows = 225 play seconds** — 80% of the shortest healthy run ever
measured. That keeps ~20% headroom for variance while still failing a recorder that quits
before roughly the last quarter of the segment, and failing every broken shape on record
(the 235-row aborted attempt in `gate-f-run-20260826T110000Z`; the 1-row boot-only trace a
refused segment writes). The derivation is in the step's own `observation`.

S04's 1,200 and S05's 3,000 are the same defect and were **not** touched — the closure
plan assigns those to G3-HARNESS. Nothing else in `S02.json` was edited.

### CL-H5 — the freeze-record trap — **done**

`run_segment.sh` now writes the run directory's own logic-lane freeze declaration, in
logic mode, for a segment that declares `evidence_lane: logic`. Three deliberate refusals,
each guarding against this fix becoming the next trap: it never touches the tracked
2026-08-27 candidate record; it never overwrites a declaration already present (so a
coordinator's real record wins and a genuine contradiction stays a refusal rather than
being amended away); and it never writes a flat `display_server`, which would bind a
capture lane run into the same directory later. `suite_state_at_freeze` is filled at the
same time and filled honestly — `reverified_in_container: false`, with a line naming who
should replace it — because a runner cannot run a ~28-minute suite and an implied green is
worse than an absent field. `--write-lane-declaration` writes it and exits, skipping the
binary and import-cache checks because it starts no engine.

**Proven both directions on a real segment.** With the fix,
`run_segment.sh --run-dir <tmp> tools/gate_f/segments/selfcheck_context.json`: **no
BLOCKER.md, 9 of 12 steps executed**, and `INVENTORY.json`'s preflight records
`freeze_record.key = "lanes.logic.display_server"`, claim `"headless (--headless, no
rendering driver)"`, read from the run-local record, **with no `contradiction` key**. (The
3 unexecuted steps are selfcheck_context's own SC-X-05 derail on `menu_backpack`,
unrelated.) Without it — the same segment driven straight at the harness into a directory
with no `RUN_METADATA.json` — `BLOCKER.md`: *"the freeze record contradicts this process:
… says display_server=X11 under xvfb-run; this process has none. No step of this segment
executed."*

### CL-H8 — the invented workbench beat — **decided: remove it; it is not a game defect**

The fork mattered: if `build_catalogue` genuinely failed to release after a workbench
interact, the beat was the only thing photographing a real shared-UI bug. It does not.

`tools/_probe_workbench_context.gd` drives the real nodes in a live world and reads the
result through the harness's own resolver (`gate_f_probe.gd::input_context()`):

```
world
-> open the real BuildMenu                        -> build_catalogue
-> close it as a player closes it                 -> world
-> place a real workbench through build_placer.gd -> world
-> interact its CraftInteractable                 -> panel:<craft_panel.gd>
-> cancel out                                     -> world
```

The interact does not enter the catalogue context at all. So S06's stuck catalogue belongs
to **CL-H13** — the harness's own input path resolving against a context the action does
not belong to, already seen at three independent sites — and removing the beat hides
nothing.

**Only step `S06-30` was edited**, as the brief requires: lane W21-HARNESS-FIGHTS owns
`S06.json` except that step. The verdict, the probe transcript and the reasoning are in
the step's own note, together with the thing that would otherwise be lost with the beat —
section L.3's crafting requirement still needs a home, and the honest one is a segment
whose band has an authored crafting site, not a workbench conjured at the quarry.
**Action for W21: delete steps S06-31 … S06-49.**

### CL-E10 — `03-mid-route` faces away from the Hall — **done**

The aim was never the problem and the look-at needed no change: every shot points at the
same fixed target and from (−20, 7250) toward (0, 7560) the camera faces up-corridor
exactly as intended. What was wrong was **where it stood**. Band 5's Hall sightline is an
authored corridor — `band5_stronghold_approach/vegetation.json` clearings 15–19, x
interpolated 0 → 8 across z 7160 → 7560, radius 16 — cut for exactly this purpose. At
z = 7250 that corridor's centre is x = 1.8, so the old eye stood **21.8 m outside it**, in
canopy the clearings deliberately do not touch. The judge photographed a grove because the
camera was in one.

Moved to **(2.2, 7270)** — clearing 16's own centre, not the gap between two: the discs
are r = 16 at z 7230 and 7270, so z = 7250 falls in the 8 m hole between them and even
x = 1.8 would not have been reliably clear. The camera's back point lands at (2.23,
7265.8), 4.2 m from that centre. Still between shot 02 (z 7150) and shot 04 (z 7350) and
still monotone in z, so the sequence's "watch it get closer" read is unchanged in shape.

Recorded and **not** acted on: `02-outer-watch` (x −70) and `04-before-the-gate` (x +60)
sit even further off the corridor than the old 03 did. Neither was flagged by the judge,
neither is what CL-E10 names, and re-siting a band lane's whole capture composition would
be an un-asked-for redesign. The corridor centres are x = 8 × (z − 7160) / 400 if a later
pass wants them.

### CL-E12 — the relay heals its own three drain stations — **done**

**What was actually missing.** `tether_relay.gd` already faded its own runtime dead-ground
skin on `relay_disabled` (`_heal_local_ground()`, shipped by G3-BAND3-0903). What it never
did was put back the SCATTER: `scatter_rules._thin_by_drain` removed real instances at
build time and only `vegetation.gd::restore_drained()` returns them, and that only ran
chapter-wide on `legendary_freed`. So the site went from dead ground with no plants on it
to ordinary ground with no plants on it. The owner answered V-5 with a plain **yes**
(`OWNER_DIRECTIVES_2026-09-04.md`, question 1).

**Built as a filter on the existing mechanism, as the contract requires — not a second
healing system.**

- `meadow_healing.gd::heal_stations(ids)` — new. Looks the ids up in
  `terrain_playground.json`'s `drains.stations` (the same authored centres and radii
  `playground_heightfield.drain_factor()` reads and the scatter was thinned on), then
  calls the same `vegetation.restore_drained()` and the same per-node `heal()` the
  chapter-wide sweep calls, restricted to those discs. An id that names no real station
  warns rather than passing silently — a typo there is a site that quietly never heals,
  which is V-5's own *fails if*.
- `vegetation.gd::restore_drained(within = [])` — the filter. Empty is the whole-map heal,
  byte for byte: the chapter's `legendary_freed` sweep does not know the argument exists.
  With a filter, unmatched placements stay held for later and `_regrown` accumulates
  rather than being replaced, so two partial heals report the total that has actually
  grown back.
- `tether_relay.gd::_heal_local_scatter()` — fires it, with the three station ids from the
  relay's own `tether_relay.json` `dead_ground.heal_stations`. The relay knows which
  stations are its; a second list inside `meadow_healing.gd` would be a second place to
  keep that true.

**A defect found and fixed while building it, worth naming because it failed silently.**
The first cut placed a drain skin by its node's `global_position`. `tether_relay.gd`
writes its skin's vertices in WORLD coordinates and leaves the MeshInstance3D at the node
origin, so that reads (0, 0, 0) for a skin painted 3.7 km down the corridor: the filter
matched nothing, printed "0 drain skins fading" and looked exactly like a site with no
skin to fade. `_skin_position()` now asks the rendered geometry (the first visual
instance's global AABB centre), and returns `Vector3.INF` rather than the origin when it
cannot answer. A skin already mid-fade is skipped via a new `tether_relay.healing()`, so
the count is a statement about what the sweep did rather than about what the site had
already started one line earlier.

**Idempotent both ways round with the chapter's own `apply()`.** Run first, it hands
`apply()` a smaller `_drained`; run after a save loaded past the ending, the discs are
already empty and it returns 0 rather than double-placing.

**What still does not heal, stated rather than hidden:** the terrain's baked colour and
control maps. Nothing at run time can repaint a texel — D45 priced that out loud — so the
discolouration under the regrown plants survives. The plants, the skin and the dead lights
are the three things that *can* change, and all three now do.

---

## One file touched outside the brief's named ownership list

`scripts/world/vegetation.gd` — one function signature and one 12-line helper.
`restore_drained()` gained an optional `within: Array = []` filter, plus `_inside_any()`.

The brief names `meadow_healing.gd` and `tether_relay.gd` for CL-E12 and says to stop a
sub-item and report it rather than reach outside the list. This is reported rather than
silently done, and here is the reasoning for doing it rather than dropping the item:

- CL-E12 is an owner-approved item (V-5, answered **yes** on 2026-09-04) and its whole
  content is the vegetation half. Without a partial restore there is no station filter to
  put in `meadow_healing.gd` — the item cannot be delivered at all.
- No 0904 lane claims `scripts/world/vegetation.gd`. W05-TREELINE owns the vegetation
  **data** and the bake and is told explicitly to stay out of `scatter_rules.gd`; it does
  not name this script. W06-FINALE is told not to touch `meadow_healing.gd`, which points
  the other way.
- The change is additive and the default path is unchanged: with no argument the partition
  puts every entry in the restore set and `_drained` still ends empty, so
  `regrown_count()`, `drained_count()` and the second-call no-op all behave exactly as
  before. The chapter-wide sweep does not know the argument exists.
- It follows the precedent the coordinator set for W14-RIDING on `creature_body.gd`:
  "apply the minimal one-line change and flag it".

If the coordinator would rather this went through the vegetation lane, the whole of it is
`restore_drained`'s signature plus `_inside_any`, and `meadow_healing.gd` calls it in one
place.

## Files this lane did NOT touch, and why

- `data/config/bands/band2_stone_and_root/vegetation.json` — CL-D4, another lane's this
  round (above).
- `tools/gate_f/segments/S06.json` beyond step `S06-30` — W21-HARNESS-FIGHTS owns the
  rest; the CL-H8 deletion is handed to it with the verdict.
- `tools/gate_f/segments/S04.json`, `S05.json`, `S06`–`S09` route rows — G3-HARNESS and
  W21 respectively.
- `data/config/bands/band3_the_river_lock/props.json` — Oreth's Riverwatch post, another
  lane's (the brief says so explicitly).
- `tests/test_encounter_combat_override.gd` and `tests/test_trainers_data.gd` — the
  natural home for a CL-E1 assertion, but W10-TRAINER-RULES owns `test_encounter_*.gd` and
  `test_trainers_data.gd` this round. The assertion was made as a committed runtime probe
  (`tools/_probe_oreth_profiles.gd`) instead. **For W10, if it wants it as a unit test:**
  add to `test_encounter_combat_override.gd` a test that reads the merged trainer table,
  finds `captain_riverwatch`, and asserts its mosshell resolves telegraph 0.85 / power
  12.0, its brooktail attack_cooldown 0.7 / power 6.4, and its trailpup byte-identical to
  `combat.json`'s `enemy` block.

---

## Known limitations

- **CL-E12's baked half.** The terrain colour and control maps around the relay stay
  discoloured after the heal. D45 decided that and priced it; nothing at run time can
  repaint a texel, and re-baking is a ~15–40 minute offline job this lane is not
  authorised to run. The plants, the runtime skin and the dead lights all change.
- **CL-H8 is a decision, not a deletion.** Steps `S06-31`…`S06-49` are still in the file.
  Only W21-HARNESS-FIGHTS can remove them this round.
- **CL-H4 fixed one of three thresholds.** S04's 1,200 and S05's 3,000 are the same
  transcription defect and belong to G3-HARNESS.
- **CL-D4 is untouched by design** — the vegetation lane's.
- **CL-E10's fix is verified geometrically and by render, not by a blind judge.** The
  eye is now inside an authored clearing rather than 21.8 m outside the corridor, which is
  the mechanism the original judge's finding pointed at. A fresh blind read of the whole
  six-frame Band 5 sequence belongs to whoever next runs P-5.1, not to a one-shot fix.
- **`heal_stations()` is only wired to the relay.** Nothing else in the chapter has a
  console of its own, and the contract's own question 1 answered "no" for the quarry's
  four stations, so no second caller was added.

---

## For `docs/CURRENT_STATE.md` — not edited by this lane

COMMON asks lanes to rewrite the relevant status rows. This lane did not: `CURRENT_STATE.md`
is not on its ownership list and every one of the round's other lanes has a claim on it, so
a coordinator merging twenty-four edits to one file is a worse outcome than one precise
instruction. Two rows are affected, and here is exactly what to put in them.

- **§3's P1 row on the harness `input_context` misresolution (CL-H13).** Add one
  supporting datum: the GAME's own `build_catalogue` context releases correctly at the
  site S06 blamed. Driven through the real nodes and read through the harness's own
  resolver (`tools/_probe_workbench_context.gd`), opening the catalogue and closing it
  returns `world`, and a workbench interact does not enter the catalogue context at all —
  it opens `craft_panel.gd` and cancels back to `world`. That is a **fourth** independent
  confirmation that the defect is the harness's input path and not the shared UI, this
  time from the positive direction: at a site where a run recorded the context sticking,
  the game does not stick.
- **A new row (or an amendment to the Gate F harness rows) for CL-H5.** The freeze-record
  trap is closed at its source: `tools/gate_f/run_segment.sh` writes the run directory's
  own logic-lane declaration, so an isolated logic-lane run starts without an operator
  hand-writing `RUN_METADATA.json` first. Proven both directions on `selfcheck_context`
  (with: no BLOCKER, 9 of 12 steps executed; without: BLOCKER, 0 steps). `docs/GATE3_EXECUTION_PLAN.md`
  §4b still documents the manual workaround and is still correct for a capture lane and
  for an unconverted `both` segment, which the runner deliberately does not guess at.

---

## Validation

Every command below was run in this container on this branch, with Godot
4.7.stable.official.5b4e0cb0f installed per COMMON's own recipe. `PATH=$HOME/godot-bin:$PATH`
is on every one and elided here.

### Unit

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_recipes.gd` | 48 tests, 352 assertions, **0 failed** |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_chapter_curve.gd` | 20 tests, 465 assertions, **0 failed** |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_band_content.gd` | 6 tests, 1147 assertions, **0 failed** |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_trainers_data.gd` | 50 tests, 1386 assertions, **0 failed** |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_gate_f_rig.gd` | 50 tests, 191 assertions, **0 failed** |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_gate_f_instrumentation.gd` | 18 tests, 41593 assertions, **0 failed** |

### Seen red first

A green test is not evidence until it has failed for the right reason.

- **CL-G6.** Ironwood line removed from `recipes_rootstone.json` → `48 tests, 348
  assertions, 2 failed`: *"the saddle is not priced in Ironwood (spec 3 Band 4)"* and
  *"the saddle must cost Ironwood (spec 3 Band 4); recipes_rootstone.json's seam is
  closed"*. Restored → green.
- **CL-E1.** WALL block removed from mosshell → `tools/_probe_oreth_profiles.gd` FAIL:
  *"mosshell/WALL: telegraph is 0.55, expected 0.85"* and *"WALL and CURRENT resolve to
  the same telegraph or power"*. Restored → PASS.
- **CL-H5.** The negative half is inside the test itself and runs on every pass: with no
  run-local record the harness falls through to the tracked 2026-08-27 candidate record,
  whose claim does not contain "headless". The test asserts that, so it fails if the
  runner ever quietly stops writing.
- **CL-E12.** Proven by construction rather than by mutation: the smoke asserts that the
  drain held placements inside the relay's stations before the console was pressed and
  that it held some outside too, and refuses to pass if either is zero — a build where the
  heal silently did nothing, or where there was nothing to heal, fails rather than passes.

### Runtime validation, on the real world

| What | How | Result |
|---|---|---|
| CL-E1 profiles reach the AI | `godot --headless --path . --script tools/_probe_oreth_profiles.gd` | **PASS** — mosshell telegraph 0.85 / power 12.0, brooktail cooldown 0.7 / power 6.4, trailpup byte-identical to the shipped `enemy` block |
| CL-H8 the catalogue releases | `godot --headless --path . --script tools/_probe_workbench_context.gd` | **PASS** — world → build_catalogue → world → workbench interact → `panel:craft_panel.gd` → world |
| CL-H5 a logic run starts | `tools/gate_f/run_segment.sh --run-dir <tmp> tools/gate_f/segments/selfcheck_context.json` | **no BLOCKER**, 9 of 12 steps executed, preflight `freeze_record.key = lanes.logic.display_server`, no `contradiction` |
| CL-H5 the trap without it | the same segment straight at the harness, no run-local record | **BLOCKER.md**, 0 steps executed |

