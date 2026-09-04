# G3-BAND3-0903 — Band 3 (The River Lock: Tether Relay) — REPORT

Lane: G3-BAND3-0903, implementation lane for Gate 3. Branch `ralph/G3-BAND3-0903`,
landed on top of `main` @ `3c73aab5`. Contract: `docs/prompts/64-BAND3-finished-river-relay.md`,
amended mid-session by the Gate 3 coordinator (relay encounter-difficulty escalation,
then a request to play Gate F segment S07 for real evidence, then
`docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` from the `ralph/G3-ENCOUNTERS-0903` lane).
No pull request opened, per instruction.

Environment: Godot 4.7-stable installed fresh in this container (none was present),
full `--headless --path . --import` run to completion before any test. Every test
result below was run in this container on this branch, not asserted.

## 1. What prompt 64 asked for vs. what was actually already there

Prompt 64's own text says "Current empty Band 3 spawn data is not acceptable for
completion." That line is stale. Before touching anything, this lane read the live
`data/config/bands/band3_the_river_lock/*.json` and found extensive, already-landed
work from prior passes (GATE-D3, WILD-ECOLOGY, E3-RELAY-POPULATION, T3-CADENCE,
T5-CADENCE) — 5 trainers, 54 spawn clusters (155+ creatures), 31 harvest nodes, 10
prop clusters, a built relay compound (`tether_relay.gd`), a working river failsafe
and a gated Old Mill Crossing. This report verifies each acceptance bullet against
that real state rather than re-authoring content that already exists.

### Acceptance bullets, verified with evidence

| Bullet | Verdict | Evidence |
|---|---|---|
| River feels like a major regional landmark | **Met, already satisfied** | `scripts/world/river.gd` (carve failsafe recovery, always-village-side), `water.json`'s `river` block (dedicated shader tuning, EV5's own multi-round history), `terrain_playground.json`'s 340m course. Not touched — nothing here needed a fix. |
| Wild ecology is real and findable | **Met, already satisfied** | `spawns.json`: 54 clusters / ~155 creatures across the band, habitat-matched (air owns the gorge, water sits at the reachable crossing, ground works the relay's spoil), two conditional-rare singletons (Stormtrail, Riftfrill) plus two unconditional alphas (springhead Brooktail, bluff Galecrest pair) so a player sees something worth catching regardless of weather/time. `tests/test_spawns_data.gd::test_band3_clears_the_roster_temptation_floor` pins both mechanically. |
| Team Tether presence builds before the captain | **Met, already satisfied** | `props.json`: `tether_haulage_wreck` (band opening), `relay_approach_checkpoint` (barricade + camp, well short of Hess), `relay_station`/`crossing_watchpost` dressing; `relay_site.json`'s four decorative grunts (Patrol/Sentry/Watch/Deckhand) read the compound as staffed, not just fought. |
| Relay is a compact assault, not four NPCs standing together | **Was partly true, fixed this session** — see §2 | Blind visual-judge pass on this branch's own render (§2); GATE3_ENCOUNTER_CONTRACTS.md V-1. |
| Vance is a real milestone | **Partly met; judged and left as-is on evidence, not fixed** — see §2 | `docs/specs/MEADOWS_PROGRESSION_CURVE.md` §4 (the economy lane's own audit already reviewed and deliberately left Vance's levels unchanged); V-2 fixed the one part that was actually wrong (send order contradicted his own dialogue). |
| Rescue/crossing restoration visibly changes what the player can do | **Met, already satisfied** | `smoke_relay.gd` real interact-driven run (§4): captain beaten → captive freed → Gear granted → Sela relocates to the village with a new greeting → `mill_crossing.gd`'s gate permanently opens on `mill_crossing_restored`. |
| Player understands Team Tether through experience, not exposition | **Met, already satisfied** | `data/dialogue/trainers.json`'s four-line escalation (Hess apologetic → Orrin weary → Dell impressed-but-firm, naming the captain → Vance explicit doctrine, "I don't send the weakest out first," "fix it now" telling the player to prepare); objectives.json's `how` lines name Team Tether directly at every rung. |
| Resources/rewards fit the tier, survival loop intact | **Met, already satisfied** | `harvest.json`: 31 nodes — wood/fiber/stone/berries baseline, rootstone (D24's spilled-haulage narrative tie), ironwood (foreshadowing Band 4), plus reward caches (orb_greater at the overlook, potions, hide_leggings, attack_tonic). |
| Camp/rest before the gauntlet | **Met, already satisfied** | `props.json`'s `riverwatch_rest` cluster: bench/barrel/bag/campfire/creature bed 60m short of Hess, explicitly NOT inside the gauntlet (T5-CADENCE's own note answers the "free-heal in the gauntlet" worry directly). |
| One optional detour tied to river ecology/occupation | **Met, already satisfied (multiple)** | `near_bank_river_walk` Brooktail pocket (spawns order 3008), `lockwater_overlook` (Greater Orb cache), `the_springhead` (unconditional Brooktail alpha) — three, not one. |

**No `vegetation.json` change was needed or proposed.** Nothing in scope required
touching mid-layer/ground-cover density; the hard constraint (never touch any
`vegetation.json`) was honoured by not needing to.

## 2. The relay's own escalation — judged, then fixed

The coordinator's brief asked this lane to judge honestly whether the relay reads
as a staged assault. Measured from the live coordinates (before any edit):

- Hess (241.3, 3680.0) → Orrin (284.0, 3710.5): 52.5 m
- Orrin → Officer Dell (347.5, 3763.5): 82.7 m
- Dell → Captain Vance (352.0, 3757.0): **7.9 m** — same yard, same backdrop, thirty
  seconds apart

So the outer picket line (already fixed by an earlier GATE-D3 pass, moving Hess and
Orrin onto the spine road) was **not** the huddle prompt 64 describes any more — the
huddle was Dell and Vance, on the site itself.

**Verified rather than assumed.** A fresh capture of the site
(`tools/_capture_locations.gd --only=06-relay`, this branch, real render) was sent to
a fresh, blind, code-blind agent running `.claude/skills/visual-judge/SKILL.md` with
no prior context. Verbatim verdict: *"reads as clump, not escalation... the
picket/officer/captain roles collapse into one loose crowd... no frame shows a
picket close to camera with the officer small and distant beyond the gate."* This
independently confirmed the diagnosis before any change was made.

Separately, `docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` (Fable's Gate 3 encounter
contract, `ralph/G3-ENCOUNTERS-0903`, docs-only) landed the same diagnosis with named
contracts (V-1..V-6). This lane implemented the three that are inside its own file
ownership:

- **V-1** — Officer Dell moves from the yard interior (4 m from centre) to the gate
  opening itself (local `s=-13,t=0.6`, world (343.2, 3771.1)), so the ladder reads
  road → road → **gate** → yard instead of two fights on the same floor, framed by the
  compound's own piers and lintel. `relay_site.json`'s Relay Sentry (a decorative
  body, not a fight) moves three metres further into the yard so the two no longer
  overlap.
- **V-2** — Captain Vance's team reorders from tuskroot(11)/galecrest(11)/duskhush(12)
  to galecrest(11)/duskhush(11)/tuskroot(12). Same three creatures, same levels, same
  total (34) — only send order moved, so his own challenge line ("I don't send the
  weakest out first") stops being false: Tuskroot is the first Tuskroot the player has
  ever seen (D20/D17: never spawns wild, no earlier trainer fields one) and it used to
  be sent out *first* and fall *first*. It is now the ace, and it carries a `combat`
  block giving it a CHARGER profile (G-3) for when the per-body combat override (G-2,
  landing separately from the encounters lane in `wild_creature.gd`, which this lane
  was explicitly told not to touch) is read. Absent that code, this body fights
  exactly as it did before — verified: `smoke_relay.gd` still beats the captain in
  2181 action frames after this change, statistically identical to before.
- **C-1** — Captain Oreth's Brooktail ace drops 16 → 15, so the road-order captain
  ladder climbs 15 → 15 → 16 (Oreth → Halder → Vess) instead of dipping after the
  first captain — the same backwards-step fix GATEC-CURVE already made for
  `captain_field`/`captain_ridge`, left undone for Oreth.

All three edits are mirrored in `tests/fixtures/band_split_baseline/trainers.json`
in the same commit, with matching `_why_*` rationale on both sides, per
`test_band_content.gd`'s tracked-mirror policy — verified: `test_band_content.gd`
6/6 after the edit.

**What was *not* changed, and why.** V-3 through V-6 (console/Sela framing, dialogue
readiness line, local ground-healing on `relay_disabled`) either verified as already
true (V-3, V-4) or require a code change in a file this lane does not own and the
contract itself flags as an open owner question (V-5, `terrain_playground.json`
`meadow_healing` filtering — out of scope, not attempted). C-2 through C-7 (Oreth's
prop dressing, the other two captains' combat profiles) belong to the world/props
lane and the encounters lane respectively per the contract's own text, not this
one's file ownership.

**Vance's raw levels were left unchanged, on evidence, not by default.**
`docs/specs/MEADOWS_PROGRESSION_CURVE.md` §4 records that the chapter's economy lane
already audited Vance's team (11/11/12) alongside `captain_field`/`captain_ridge`
specifically to find backwards-step defects, bumped the other two, and *left Vance
alone* as "already correct." Overriding that considered, documented, cross-band
decision unilaterally — especially from a lane explicitly told to treat
`chapter_curve.json`/`progression.json` as another lane's authority — would have
been presumptuous. What prompt 64 actually asks for (team composition, arena/site
context, rank, pacing distinguishing the captain) is now better served by V-1/V-2 than
a level bump would have been on its own.

## 3. The Oreth placement question — answered from evidence, not moved

`captain_riverwatch` (Captain Oreth) sits at (-100, 4350), inside Band 3's z-range,
while spec/prompt 65 group him with Halder and Vess as one of "the three Sigil
captains" conceptually associated with Band 4. **Verdict: this is deliberate, not
drift, and Oreth stays exactly where he is.**

Evidence, highest authority first:
- `docs/specs/MEADOWS_MACRO_LAYOUT.md` §10.2 (OW5D, an owner-directed macro-layout
  pass) explicitly places "captain_riverwatch" at (-100, 4350) in its own moved-content
  table, and its own §3.1 text states outright: *"Riverwatch Captain sits off-spine on
  the Band 3/4 seam."* This document outranks `docs/prompts/65` in CLAUDE.md's own
  precedence order.
- `GATE3_ENCOUNTER_CONTRACTS.md` §4.1 (Fable, the lane that owns encounter identity
  per `docs/ROADMAP.md`'s own Gate 3 assignment) independently reaches the same
  verdict and gives the design reason: a Riverwatch captain's whole site fiction only
  works at the water, moving him to the Highfield/ridge would make him a third field
  captain, and the road delivers the three captains in a deliberate
  plan → power → endurance order (Oreth's own dialogue: *"not all one type — you'll
  want a plan"*) that the coordinator's own message asked this lane to check against
  the walked route.
- Numerically, `test_every_trainer_fights_at_their_own_regions_strength` resolves
  Oreth's region by his world z (4350 < Band 3's 4760 bound) and checks his team
  against Band 3's `[8,16]` trainer_levels window — his team (13/14/15 after C-1)
  fits comfortably, so there is no mechanical drift either.

**Do not move him.** Flagging this to the coordinator as confirmed, not as an open
question.

## 4. Real interact-driven playthrough evidence

Two smoke tests were run to completion on this branch, unmodified from `main` except
by this lane's own edits, verifying the scripted relay path end to end:

- `tests/smoke_relay.gd`: captain beaten after 2181 action frames (3 of 3 creatures
  felled) → `relay_captain_defeated` set → `captive_rescued` set →
  `mill_bridge_gear` in the satchel → Sela removed from the relay and standing in the
  village with a new greeting (`village_rescued_ranger` → `village_rescued_ranger_home`).
  **PASS.**
- `tests/smoke_relay_station.gd`: station stands (4 walls, 2 decks, 1 ramp, 10
  pylons), the gantry/pad/ramp traversal is walkable and lands at the authored deck
  height, the console refuses while `relay_captain_defeated` is unset and opens once
  it is set, 14 lit surfaces before the console and 0 after, drain reads 1.0 at the
  relay pad and 0.0 elsewhere. **PASS.**

Both re-run after V-1/V-2/C-1 landed, both still green — the geometry and team
changes did not break the scripted path.

### 4b. Gate F segment S07 — played end to end (STRANDED, not a Band 3 verdict)

The coordinator's addendum asked for more than config inspection: a played run of
Gate F segment S07 (`tools/gate_f/segments/S07.json`, the river-arrival →
pickets → officer → captain → captive → crossing-restored path), because CLAUDE.md's
binding rule is that a region is done when the complete player path produces the
intended experience.

**What was built, following `tools/gate_f/seed_s09_exit.gd`'s own pattern (its header
explains the reasoning; this section only states where this one differs).** No
completed Gate F run has ever produced a real `S06-exit.json` either — the four
archived ones this session checked
(`ralph/reports/gate-f-run-*/S06/saves/S06-exit.json`) all hold the identical
two-creature, level 2-3, fainted party at the South Bridge (z≈1325), 1855 m short of
Band 3's own entry. `tools/gate_f/build_s07_entry_synthetic.gd` (committed) constructs
a clean one instead: five creatures at `chapter_curve.json`'s band-3 `team.enter=10`
(levels 9-10), full HP/energy/satiety, every main-chain flag through
`warrens_cleared`, player at `burrow_warrens.gd`'s own `marker("entrance")`. Every
claim below takes the form "S07, given this clean entry, does X" — never "the chapter
does X".

**Harness pre-flight defect found and worked around, not silently.** The first run
attempt refused before step 1: `operator_harness.gd`'s CD-8b check compared this
process's real (headless) display capability against the checked-in
`ralph/reports/gate-f-candidate/RUN_METADATA.json` — a frozen record for an unrelated
whole-chapter run at a different SHA claiming X11 under xvfb-run for every lane. The
harness's own documented mechanism for this (`_freeze_display_claim`, checks the run
directory's own `RUN_METADATA.json` first) was used as intended: a lane-scoped
`ralph/reports/G3-BAND3-0903/gate-f-s07/RUN_METADATA.json` declaring
`lanes.logic.display_server = headless` was written (a true statement about this
process), matching the exact shape other completed Gate F runs in this repo already
use for their own logic lanes. The re-run then passed pre-flight cleanly.

**Result: 90 pass / 20 fail / 9 delegated (captures, correctly deferred to `S07C`) of
119 steps. `INVENTORY.json` says COMPLETE (ran to completion; that field means "not
blocked before starting", not "all steps passed").** The 20 failures are **not 20
independent defects** — read from the raw telemetry (`S07/telemetry/events.jsonl`),
they cluster to two root causes, both **harness/step-script defects, not Band 3
content defects**:

1. **The dominant cause (17 of 20 failures).** Hess's own fight step (`S07-32`, a
   fixed `combat_quick × 34` press block with no swap-recovery, unlike the later
   fights in this same file) ran out of scripted input while Hess's second creature
   (Mudsnout) was still alive at roughly 11 HP. Combat never formally ended, so
   `input_context` never returned to `world`, and every subsequent step in the
   segment — walking to Orrin (`S07-34`), fighting Orrin/Dell/Vance, rescuing the
   captive, disabling the relay, restoring the crossing, opening the pause menu,
   saving — executed against a player still frozen in that same stuck combat, at the
   same fixed position `(343.18, 5.52, 3758.56)`, for the rest of the run. Traced hit
   by hit in the telemetry: the player's own creatures kept taking damage with no
   further attacks landing after the press budget ran out, and the whole five-creature
   party was ground down to 0 HP (confirmed directly in the telemetry) without ever
   reaching Orrin, Officer Dell, or Captain Vance for real. **This means S07, on this
   run, produced no real evidence about whether V-1/V-2's relay changes read correctly
   in play** — the fight that would prove or disprove that never started. It is the
   identical *class* of defect this same file's own `GATE-D3-SWAP`/`GATE-D3-DIALOGUE`
   comments already document and fixed for Dell's and Vance's own steps (splitting a
   long press block with `party_cycle` recovery between segments) — Hess's step was
   simply never given the same treatment. `tools/gate_f/segments/S07.json` is not in
   this lane's file ownership (it belongs to the Gate F protocol/coordinator), so per
   the coordinator's own instruction ("a harness defect is a finding to report
   honestly, not something to paper over") it was not patched by this lane.
2. **A separate, independent, minor defect (1 of 20 failures, `S07-26`).** The step
   asserts `region_is == the_long_water` at the walk target `(150, 3500)` — but
   `map_landmarks.json`'s own `the_long_water` region is a 52 m-radius circle
   centred near `(-150, 4200)`, roughly 700 m from that point. This is a
   miscalibrated waypoint/assertion pairing inside `S07.json` itself, unrelated to
   Hess's fight and unrelated to anything in this lane's file ownership.
3. The remaining 2 of 20 (`S07-29w`, an `input_context` assert) are direct
   restatements of cause 1 at an earlier point in the cascade.

**Honest bottom line for the acceptance question this segment was meant to answer:**
S07 could not, on this run, produce played-path evidence of whether the relay reads
as an escalating assault, because the harness never got the player past Hess. The
scripted `smoke_relay.gd`/`smoke_relay_station.gd` runs (§4 above, which do exercise
real interact-driven combat through the whole ladder including the captain) and the
blind visual-judge pass (§2) are the real evidence this lane has for that question,
and both predate and independently corroborate the V-1/V-2 fix. **S07 itself: FAIL
by the letter of its own 20 failed assertions, but the honest verdict is
"stranded by a harness scripting gap before reaching Band 3's own content" rather
than "Band 3 fails S07."** Recommend the coordinator or the Gate F protocol lane
extend Hess's and Orrin's fight steps with the same swap-and-continue pattern already
used for Dell/Vance, then re-run — this lane's synthetic seed
(`tools/gate_f/build_s07_entry_synthetic.gd`) is reusable as-is for that re-run.

Evidence template (from what the run did produce before stranding):

- **Player purpose:** clear, and it survived the whole cascade — the tracked
  objective stayed correctly pinned to "Defeat the Relay Captain" throughout, never
  drifting to a wrong rung.
- **Team progression:** entered at 5/5, levels 9-10, full HP; left at 5/5, all
  fainted (0 HP) — a genuine full-party wipe, but caused by the harness never
  attacking after its press budget ran out, not by Band 3's own difficulty (the
  player's creatures kept taking undefended hits with zero return input for over
  1100 simulated seconds).
- **World interaction:** the outrider Kest fight and the walk to Hess both completed
  normally before the strand; nothing past Hess was reachable.
- **Empty travel:** N/A — the segment never covered real distance after the strand
  (`S07-81`: 1499 m walked against a 2200 m minimum, entirely from before the strand).
- **Reliability:** one real harness defect found (§ above), reported, not
  silently patched; one pre-existing minor region-assertion mismatch, reported.
- **Presentation:** not assessable from this run; see §2's blind-judge evidence
  instead.
- **Decision:** **FAIL (harness-stranded)**, replay after the Hess/Orrin fight-step
  fix above is applied.

## 5. Tests actually run on this branch (Godot 4.7-stable, fresh `--import`)

- `test_chapter_curve.gd`: 18/18, 451 assertions.
- `test_band_content.gd`: 6/6, 1145 assertions (run again after the V-1/V-2/C-1
  edit, still 6/6 — the tracked-mirror fixture agrees).
- `test_trainers_data.gd`, `test_spawn_tables.gd`, `test_spawns_data.gd` together:
  108 tests, 11845 assertions, 0 failed (before the edit); `test_band_content.gd` +
  `test_chapter_curve.gd` + `test_trainers_data.gd` together again after the edit:
  74 tests, 2982 assertions, 0 failed.
- `test_chapter_content_map.gd`: 4/4, 37 assertions.
- `smoke_relay.gd`, `smoke_relay_station.gd`: both PASS, before and after the edit.
- Gate F `S07` (logic mode, synthetic entry): 90 pass / 20 fail / 9 delegated of 119
  — see §4b for why the failures are a harness defect, not a content one.

Unrelated, pre-existing defect observed (not this lane's file ownership, not
touched): `burrow_warrens.gd::_dress_the_guardian` throws `Parameter "material" is
null` in every headless run of the merged world (reproduced identically on `main`
before any edit here, in `smoke_relay.gd`, `smoke_relay_station.gd`, and the S07
synthetic-seed builder). Does not stop any of those runs from completing. Flagging
for whichever lane owns Band 2's Warrens guardian.

## 6. Vegetation

No `vegetation.json` change was needed anywhere in this pass. Nothing proposed, per
the hard constraint — this is not a case of a withheld diff, there is no diff.

## 7. Summary of changes shipped

- `data/config/bands/band3_the_river_lock/trainers.json` — V-1 (Dell to the gate),
  V-2 (Vance's send order + Tuskroot combat profile), C-1 (Oreth's ace level).
- `data/config/relay_site.json` — Relay Sentry repositioned to clear Dell's new spot.
- `tests/fixtures/band_split_baseline/trainers.json` — mirrors all three, same commit.
- `tools/gate_f/build_s07_entry_synthetic.gd` — new, reusable synthetic Band 3 entry
  seed for Gate F S07 (and any future re-run of it).
- `ralph/reports/G3-BAND3-0903/gate-f-s07/` — the S07 run artefacts (including the
  first, pre-flight-blocked attempt, kept per the harness's own restart-protection
  convention rather than deleted) and this run's own `RUN_METADATA.json`.

Commits: `fdd2d47b` (stray `.uid` sidecars from the fresh import), `eb6f7192`
(V-1/V-2/C-1), `ceffa168` (the S07 synthetic seed builder), plus this report.

## 8. What is still open

- The Gate F S07 harness fix (Hess/Orrin fight-step swap-recovery) — not this lane's
  file ownership; recommend to the Gate F protocol/coordinator, cited in §4b.
- V-5 (local `meadow_healing` filtering on `relay_disabled`) — the contract itself
  lists this as an open owner question; not attempted.
- C-2 (Oreth's own prop dressing / stale `facing_deg`) — belongs to the world/props
  lane per the contract's own text.
- The pre-existing `burrow_warrens.gd` guardian material-null error (§5) — not this
  lane's file ownership, flagged for whoever owns Band 2's Warrens.
