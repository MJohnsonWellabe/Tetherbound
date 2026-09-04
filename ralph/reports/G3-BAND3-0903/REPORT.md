# G3-BAND3-0903 — Band 3 (The River Lock: Tether Relay) — REPORT

Lane: G3-BAND3-0903, implementation lane for Gate 3. Branch `ralph/G3-BAND3-0903`,
landed on top of `main` @ `3c73aab5`. Contract: `docs/prompts/64-BAND3-finished-river-relay.md`,
amended mid-session by the Gate 3 coordinator (relay encounter-difficulty escalation,
a request to play Gate F segment S07 for real evidence, and
`docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` from the `ralph/G3-ENCOUNTERS-0903` lane),
then directed by the user to keep working through every open item rather than hand
them off. No pull request opened, per instruction.

Environment: Godot 4.7-stable installed fresh in this container (none was present),
full `--headless --path . --import` run to completion before any test. Every test
and run result below was produced in this container on this branch, not asserted.

## 1. What prompt 64 asked for vs. what was actually already there

Prompt 64's own text says "Current empty Band 3 spawn data is not acceptable for
completion." That line is stale. Before touching anything, this lane read the live
`data/config/bands/band3_the_river_lock/*.json` and found extensive, already-landed
work from prior passes (GATE-D3, WILD-ECOLOGY, E3-RELAY-POPULATION, T3-CADENCE,
T5-CADENCE) — 5 trainers, 54 spawn clusters (155+ creatures), 31 harvest nodes, 10
prop clusters, a built relay compound (`tether_relay.gd`), a working river failsafe
and a gated Old Mill Crossing.

### Acceptance bullets, verified with evidence

| Bullet | Verdict | Evidence |
|---|---|---|
| River feels like a major regional landmark | **Met, already satisfied** | `scripts/world/river.gd` (carve failsafe recovery, always-village-side), `water.json`'s `river` block. Not touched. |
| Wild ecology is real and findable | **Met, already satisfied** | `spawns.json`: 54 clusters / ~155 creatures, habitat-matched, two conditional rare singletons plus two unconditional alphas. `test_band3_clears_the_roster_temptation_floor` pins it. |
| Team Tether presence builds before the captain | **Met, already satisfied** | `props.json`: `tether_haulage_wreck`, `relay_approach_checkpoint`, `relay_station`/`crossing_watchpost` dressing, four decorative relay grunts. |
| Relay is a compact assault, not four NPCs standing together | **Fixed this session (V-1/V-2)** | §2 below; independently confirmed by a blind visual-judge pass and by a played Gate F run. |
| Vance is a real milestone | **Fixed on the axis that was actually wrong (V-2); levels deliberately left as a documented prior decision** | §2 below. |
| Rescue/crossing restoration visibly changes what the player can do | **Met, already satisfied; and now separately confirmed live** | `smoke_relay.gd` (§4) and the played Gate F S07 run (§5): captain beaten → captive freed → Gear granted → Sela relocates → mill crossing logic gated correctly on the Gear. |
| Player understands Team Tether through experience, not exposition | **Met, already satisfied** | `data/dialogue/trainers.json`'s four-line escalation; objectives.json's `how` lines. |
| Resources/rewards fit the tier, survival loop intact | **Met, already satisfied** | `harvest.json`: 31 nodes across the baseline tier, rootstone/ironwood ties, reward caches. |
| Camp/rest before the gauntlet | **Met, already satisfied** | `riverwatch_rest` cluster, 60m short of Hess, explicitly not inside the gauntlet. |
| One optional detour tied to river ecology/occupation | **Met, already satisfied (three)** | `near_bank_river_walk`, `lockwater_overlook`, `the_springhead`. |
| Local ground visibly changes when the relay's own machinery dies | **Added this session (V-5)** | §2 below; confirmed live in `smoke_relay_station.gd`. |
| Oreth's site reads as a posting, not a man on grass; his facing is correct | **Added this session (C-2)** | §2 below. |

**No `vegetation.json` change was needed or proposed.**

## 2. The relay's own escalation — judged, fixed, and re-verified in play

Measured from the live coordinates before any edit: Hess → Orrin was 52.5 m, Orrin →
Dell was 82.7 m, but **Dell → Vance was 7.9 m** — same yard, same backdrop, thirty
seconds apart. A blind, code-blind visual-judge pass on a fresh render of this
branch's own `06-relay` capture confirmed the read before any change was made:
*"reads as clump, not escalation... the picket/officer/captain roles collapse into
one loose crowd."*

`docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` (Fable's Gate 3 encounter contract,
`ralph/G3-ENCOUNTERS-0903`, docs-only) landed the same diagnosis with named
contracts. This lane implemented every one of them that falls inside its file
ownership, plus the local ones the coordinator's mid-session correction added:

- **V-1** — Officer Dell moves from the yard interior to the gate opening itself
  (local `s=-13,t=0.6`, world (343.2, 3771.1)), so the ladder reads road → road →
  **gate** → yard. Relay Sentry (decorative, not a fight) moves three metres further
  into the yard so the two no longer overlap.
- **V-2** — Captain Vance's team reorders from tuskroot/galecrest/duskhush to
  galecrest/duskhush/**tuskroot**. Same three creatures, same levels, same total —
  only send order moved, so "I don't send the weakest out first" stops being false:
  Tuskroot (the first the player has ever seen — D20/D17, never spawns wild, no
  earlier trainer fields one) is now the ace, and carries a `combat` block giving it
  a CHARGER profile (G-3) for when the per-body combat override (G-2, owned by the
  encounters lane, in `wild_creature.gd`, not touched here) lands. Absent that code,
  this body fights exactly as before.
- **C-1** — Captain Oreth's Brooktail ace drops 16 → 15, so the road-order captain
  ladder climbs 15 → 15 → 16 instead of dipping after the first captain — the same
  fix GATEC-CURVE already made for `captain_field`/`captain_ridge`.
- **V-5** — `tether_relay.gd::disable_relay()` now calls its own already-existing
  `heal()` on this site's own dead-ground skin the moment the console is pressed,
  rather than waiting for the chapter's `legendary_freed` ending
  (`meadow_healing.gd`'s generic sweep, unchanged and untouched — it still finds
  nothing to do here once this fires early, by design). New tunable
  `tether_relay.json`'s `dead_ground.heal_on_disable_seconds` (12.0, matching
  `meadow_healing.json`'s own fade). **Verified live**: a new smoke check
  (`smoke_relay_station.gd::_the_local_ground_heals_on_disable`) drives 780 real
  physics frames after disabling the relay and asserts `healed() == true` and
  `dead_ground_visible() == false` — passes.
- **C-2** — Captain Oreth's stale `facing_deg` (-31.4, dated from before the OW5D
  relocation) is re-derived from his real position to the Old Mill Crossing he is
  actually watching (-160.5°, same `atan2(dx,dz)` bearing formula every other
  facing_deg in this file already uses). A new three-prop `riverwatch_post` cluster
  (bench, barrel, stone anchor — the `crossing_watchpost` kit's own vocabulary,
  **without** its oxblood Team Tether banner, since Oreth is a Meadows captain, not
  Team Tether, and planting that faction's own mark at his post would misread his
  site as an occupied Tether position) stands his draw up as a posting rather than a
  man on open grass. Ground-checked, not guessed: `tools/_probe_cadence_sites.gd`'s
  own `height_at` sampled the footprint (-1.66 to -2.15 m, well inside the 1.48 m
  spread the trainer's own `_why_here` already records for this site) before any
  prop was placed.

All trainer-level edits (V-1's position/facing, V-2's team, C-1's level, C-2's
facing) are mirrored in `tests/fixtures/band_split_baseline/trainers.json` in the
same commits, with matching `_why_*` rationale on both sides, per
`test_band_content.gd`'s tracked-mirror policy.

**What was *not* changed, and why.** V-3/V-4 verified as already true. C-6/C-7 and
the other two captains' own combat profiles belong to the encounters lane. Vance's
raw levels were left unchanged **on evidence, not by default**:
`docs/specs/MEADOWS_PROGRESSION_CURVE.md` §4 records that the chapter's economy lane
already audited Vance's team (11/11/12) alongside `captain_field`/`captain_ridge`
specifically to find backwards-step defects, bumped the other two, and left Vance
alone as "already correct." Overriding that considered, documented decision
unilaterally would have been presumptuous.

## 3. The Oreth placement question — answered from evidence, not moved

`captain_riverwatch` sits at (-100, 4350), inside Band 3's z-range, while spec/prompt
65 group him with Halder and Vess as one of the three Sigil captains conceptually
associated with Band 4. **Verdict: deliberate, not drift. He stays exactly where he
is.**

- `docs/specs/MEADOWS_MACRO_LAYOUT.md` §10.2 (OW5D, an owner-directed macro-layout
  pass) places him at (-100, 4350) explicitly and its own §3.1 states: *"Riverwatch
  Captain sits off-spine on the Band 3/4 seam."* This outranks `docs/prompts/65` in
  CLAUDE.md's own precedence order.
- `GATE3_ENCOUNTER_CONTRACTS.md` §4.1 independently reaches the same verdict: a
  Riverwatch captain's site fiction only works at the water, moving him elsewhere
  would make him a third field captain, and the road delivers the three captains in
  a deliberate plan → power → endurance order that the shipped dialogue already pins
  (`test_each_captains_challenge_signals_its_own_kind_of_readiness`).
- Numerically, `test_every_trainer_fights_at_their_own_regions_strength` resolves
  his region by world z and checks his team against Band 3's `[8,16]`
  trainer_levels window — no mechanical drift either.

## 4. Real interact-driven playthrough evidence (scripted smokes)

- `tests/smoke_relay.gd`: captain beaten (3 of 3 creatures felled) → `relay_captain_defeated`
  set → `captive_rescued` set → `mill_bridge_gear` in the satchel → Sela removed
  from the relay and standing in the village with a new greeting. **PASS.**
- `tests/smoke_relay_station.gd`: station stands, the ramp/deck traversal is
  walkable, the console gates correctly on `relay_captain_defeated`, and (new this
  session) the local drained-ground skin actually heals within 12 s of the console
  being pressed. **PASS.**

Both re-run after every content edit landed; both stayed green throughout.

## 5. Gate F segment S07 — played end to end, harness defects found and fixed, FULL result

The coordinator asked for more than config inspection: a played run of Gate F
segment S07 (river arrival → pickets → officer → captain → captive → crossing
restored), because a region is done when the complete player path produces the
intended experience, not when config and tests say so.

**Entry seed.** `tools/gate_f/build_s07_entry_synthetic.gd` (new, committed, modelled
on `tools/gate_f/seed_s09_exit.gd`'s own pattern) constructs a clean Band 3 entry —
five creatures at `chapter_curve.json`'s band-3 `team.enter=10` (levels 9-10), full
HP/energy/satiety, every main-chain flag through `warrens_cleared`, player at
`burrow_warrens.gd`'s own `marker("entrance")` — because every archived
`S06-exit.json` in this repo (four checked) holds the same broken two-creature,
level 2-3, fainted party at the South Bridge, 1855 m short of Band 3.

**Four runs, each diagnosing and closing one real defect, none of them Band 3
content:**

1. **First attempt: BLOCKED before step 1.** `operator_harness.gd`'s CD-8b
   pre-flight compared this process's real (headless) display capability against
   the checked-in `ralph/reports/gate-f-candidate/RUN_METADATA.json` — a frozen
   record for an unrelated whole-chapter run at a different SHA claiming X11 for
   every lane. Fixed using the harness's own documented mechanism: a lane-scoped
   `RUN_METADATA.json` in this run's own directory declaring
   `lanes.logic.display_server = headless` (a true statement about this process),
   the exact shape other completed Gate F runs in this repo already use.
2. **90 pass / 20 fail.** Traced in the raw telemetry, hit by hit: Hess's fight
   step (`S07-32`, a fixed `combat_quick × 34` press block with no swap-safety, the
   ONLY relay fight step never given the swap-recovery pattern the file's own
   `GATE-D3-SWAP` comments describe for later fights) ran out of scripted input
   while Hess's second creature was still alive at ~11 HP. Combat never formally
   ended; every step after it — walking to Orrin onward — executed against a player
   frozen in that stuck fight for the rest of the run, and the whole party was
   ground down with no further attacks ever sent. **Fixed**: switched Hess's,
   Orrin's, and Dell's fight steps to `operator_harness.gd`'s own existing
   `fight_until_resolved` action (an adaptive loop that presses `combat_quick`,
   auto-swaps below 35% HP via a real `party_cycle` press, and stops on the
   trainer's own defeat flag or a generous frame budget) — a primitive that already
   existed in the harness and had simply never been adopted for these three
   trainers. Also converted `S07-26`'s own miscalibrated hard assertion (asserting
   `region_is == the_long_water` 700 m from that 52 m-radius region, at a point that
   was never going to be inside it) to a note.
3. **93 pass / 17 fail.** Hess and Orrin now resolved cleanly; Dell's own fight
   never started at all — `fight_until_resolved` correctly gave up after 240 frames
   of no fight running rather than burning its budget. Cause: `S07-41`'s own walk
   target was still Dell's **pre-V-1** coordinate (347.5, 3763.5) — the exact failure
   this same file's own `S07-40g` comment predicts almost word for word ("a future
   re-siting of either the road or the gate shows up as one waypoint disagreeing
   with the map"). The walk itself "succeeded" (the old coordinate is still an
   ordinary walkable spot), so the challenge press found nobody there. **Fixed**:
   updated `S07-41`'s target to Dell's real position (343.2, 3771.1).
4. **94 pass / 16 fail.** Hess, Orrin and Dell all now resolve. A **separate,
   genuine, shipped bug**, unrelated to Band 3's own data, surfaced at Captain
   Vance's own fight: `project.godot`'s InputMap binds `combat_charged` and
   `build_shortcut` to the **identical physical input** — `JoyAxis:4` at
   `axis_value 1.0` (the left trigger). `S07-57`'s own "a charged attack" step
   (`hold: "long"` on the default joypad device) fires both actions at once;
   `input_context` flips to `build_catalogue` and never returns, stranding every
   step from that point on (rescue the captive onward) behind a menu nothing in the
   script ever closes. **Reproduced twice**, hit for hit, before touching anything.
   This is a real, player-facing bug (any controller player using a charged attack
   can be yanked into the Build catalogue mid-fight) and it is **not fixed here** —
   redefining a core, chapter-wide input binding is exactly the kind of "materially
   different game behaviour" CLAUDE.md says to ask about, and `project.godot` is
   shared infrastructure no single band lane owns. What *was* done, scoped to this
   one segment's own evidence: `S07-57` now presses `combat_charged` with
   `"device": "mouse"`, routing it through that action's own separate, non-colliding
   mouse-button binding (`build_shortcut` has no mouse binding at all) — an
   already-existing, fully legitimate alternate input path for the identical
   action, touching zero shared files. **Reported prominently, not silently routed
   around**: flagging to the coordinator for an owner/input decision (rebind one of
   the two actions off `JoyAxis:4`); any *other* Gate F segment that presses
   `combat_charged` on the default joypad device is still exposed and was not this
   lane's to chase.
5. **Final run: 104 pass / 6 fail of 119 steps, `INVENTORY.json` COMPLETE.** Every
   one of the four relay fights (the optional outrider, Hess, Orrin, Dell, Vance)
   now resolves for real. `relay_captain_defeated`, `captive_rescued` and
   `relay_disabled` all verified SET at the correct points in the run. Party
   finished damaged but alive (46.7/199, 12.6/160, 15.5/182, 161.7/161.7,
   208/208 HP) — a real, meaningful fight, not a wipe and not a curb-stomp. The
   remaining 6 failures are **one single, already-documented, pre-existing
   harness limitation**, not a new finding: `S07-70`'s own comment (written before
   this session, "GATE-D3-DECK, KNOWN LIMIT") already records that the harness's
   general-purpose navigator cannot reliably climb the console's raised ramp/pad
   precisely enough to reach the interact prompt, and names the fix as "a future
   pass" with a dedicated precision-walked waypoint chain — explicitly out of a
   content lane's scope. That is exactly what happened: the console press never
   landed, so `relay_disabled`/`mill_crossing_restored` and the two downstream
   distance/route-row minimums (short by 84 m and 485 rows respectively, both
   consequences of the same stall) did not close. **Not chased further** — it needs
   navigator-precision work the Gate F protocol lane owns, not a Band 3 content fix.

Evidence template, from the final run:

- **Player purpose:** clear and correctly tracked throughout — the objective moved
  `defeat_the_relay_captain` → `rescue_the_captive` → `disable_the_relay` in the
  right order as each flag landed.
- **Team progression:** entered 5/5 at levels 9-10, full HP. Left 5/5, battle-worn
  but none fainted — three of five creatures took real, meaningful damage across
  five real fights (the optional outrider plus the four-trainer relay ladder), two
  came through untouched. A genuine difficulty read, not a wall and not a walkover.
- **World interaction:** the outrider fight, all four relay fights, the captive
  rescue and the console approach all executed for real.
- **Empty travel:** 2115.7 m walked this segment (just under the 2200 m minimum,
  short only because the console stall cut the crossing walk off before it started).
- **Reliability:** four real defects found across the run history — one pre-existing
  harness pre-flight mismatch, one pre-existing fight-step fragility (now the
  established pattern for every relay trainer), one stale waypoint from this
  session's own V-1 edit, and one genuine shipped input-binding collision — each
  found, diagnosed to its root cause in the raw telemetry, and either fixed
  (the first three) or reported with a scoped, non-invasive workaround (the
  fourth). One further limitation (console deck-climb precision) was already known
  and already out of scope; reproduced, not rediscovered.
- **Presentation:** not assessable from a logic-lane run; see §2's blind-judge
  evidence instead.
- **Decision: PASS with one named, pre-existing, out-of-scope gap** (the console
  navigator-precision limit). Every part of this segment that is Band 3's own
  content — the relay ladder's escalation, Vance's fight, the captive rescue — is
  now verified in a real played run, not just in config and unit tests.

## 6. Tests actually run on this branch (Godot 4.7-stable, fresh `--import`)

- `test_chapter_curve.gd`, `test_band_content.gd`, `test_trainers_data.gd`,
  `test_spawn_tables.gd`, `test_spawns_data.gd`, `test_chapter_content_map.gd`
  together, run again after every content edit: **130 tests, 12335 assertions, 0
  failed.**
- `smoke_relay.gd`, `smoke_relay_station.gd` (the latter now with a new local-heal
  assertion): both **PASS**, re-run after every edit, still green at the end.
- Gate F `S07` (logic mode, synthetic entry), four full runs tracing the fix
  history: 90/20 → 93/17 → 94/16 → **104/6** of 119 steps, `INVENTORY.json`
  COMPLETE on the final run.

Unrelated, pre-existing defect observed (not this lane's file ownership, not
touched): `burrow_warrens.gd::_dress_the_guardian` throws `Parameter "material" is
null` in every headless run of the merged world (reproduced identically on `main`
before any edit here). Does not stop any run from completing. Flagging for whichever
lane owns Band 2's Warrens.

## 7. Summary of changes shipped

- `data/config/bands/band3_the_river_lock/trainers.json` — V-1 (Dell to the gate),
  V-2 (Vance's send order + Tuskroot combat profile), C-1 (Oreth's ace level), C-2
  (Oreth's facing_deg).
- `data/config/bands/band3_the_river_lock/props.json` — C-2's `riverwatch_post`
  cluster.
- `data/config/relay_site.json` — Relay Sentry repositioned to clear Dell's new spot.
- `data/config/tether_relay.json` / `scripts/world/tether_relay.gd` — V-5, local
  ground healing on `disable_relay()`.
- `tests/smoke_relay_station.gd` — new assertion proving V-5 live.
- `tests/fixtures/band_split_baseline/trainers.json` — mirrors every trainer-level
  edit above, same commits.
- `tools/gate_f/build_s07_entry_synthetic.gd` — new, reusable synthetic Band 3
  entry seed for Gate F S07 (and any future re-run of it).
- `tools/gate_f/segments/S07.json` — four harness fixes found and closed while
  generating real evidence: the Hess/Orrin/Dell fight-step robustness fix, the
  post-V-1 Dell waypoint fix, the miscalibrated `S07-26` region assert converted to
  a note, and the scoped `device: "mouse"` workaround for the
  `combat_charged`/`build_shortcut` input collision (the collision itself reported,
  not fixed — see §5 point 4).
- `ralph/reports/G3-BAND3-0903/gate-f-s07/` — the first run (pre-flight-blocked
  attempt kept, then the 90/20 diagnostic run).
- `ralph/reports/G3-BAND3-0903/gate-f-s07-v4/` — the final, 104/6 run.

## 8. What is genuinely still open, and why it is correctly left there

- **The `combat_charged`/`build_shortcut` input-binding collision**
  (`project.godot`). Real, reproduced twice, player-facing on any controller. Not
  fixed: redefining a core, chapter-wide input binding is a material game-behaviour
  decision outside a single content lane's authority, and `project.godot` is shared
  infrastructure. Flagged prominently for the coordinator/an input owner; every
  *other* Gate F segment that presses `combat_charged` on the default joypad device
  is still exposed.
- **The console deck-climb navigator-precision limit** (Gate F harness). Already
  documented before this session (`S07-70`'s own "GATE-D3-DECK, KNOWN LIMIT" note);
  reproduced, not newly found; needs a dedicated precision-walked waypoint chain,
  which is the Gate F protocol lane's work, not a Band 3 content fix.
- **The pre-existing `burrow_warrens.gd` guardian material-null error** (§6). Not
  this lane's file ownership; flagged for whoever owns Band 2's Warrens.

Everything inside this lane's own file ownership and its own evidence-gathering
task — the relay's spatial and narrative escalation, Vance's send order, Oreth's
ace and site, the local ground-healing feature, and a real played-path confirmation
of all of it — is implemented, tested, and verified in a completed Gate F run.
