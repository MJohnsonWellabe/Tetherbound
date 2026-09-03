# G3-BAND4-0903 — Band 4 (Upper Meadows / Ironwood) verification report

Branch: `ralph/G3-BAND4-0903`, based on `origin/main` @ `3c73aab5`.

## Summary

Band 4 arrived at this session already carrying an unusually large amount of
prior, well-reasoned implementation (lane tags visible in the data's own
comments: `SF34`, `SF31`, `T3-BAND4`, `T3-ACTIVITIES`, `T3-REWARD`,
`T3-INSTALL`, `T3-DENSITY`, `T3-CREATURES`, `T3-ENCOUNTER`, `T3-CAPTAINS`,
`GATEC-CURVE`, `GATE-D4`/`GATE-D4b`, `ASSESS-REDS`, `VIS-CAST`, `OW5D`, `OW6`,
`WARRENS-LAND-0829A`, `CI-TRAINER-CENSUS`, `TOURNAMENT-1`), predating the
2026-09-02 repository reset. Checked item by item against prompt 65 and
prompt 67's acceptance bullets, almost everything the prompts ask for was
**already true on `main`**, with evidence. This session's job was mostly
verification; where it found real, checkable gaps it either fixed them (none
required an edit inside this lane's own file ownership) or recorded them
below with what it would take.

**Data/code changed this session:** one new file,
`tests/test_band4_upper_meadows.gd` (7 tests, 28 assertions, all pass). No
edits to `spawns.json`, `trainers.json`, `harvest.json`, `props.json`,
`riding_controller.gd`, `tether_sigil.gd`, or `watchtower_landmark.gd` — every
one of those was inspected and found to already satisfy the prompt.

**Tests actually run on this branch**, Godot 4.7-stable headless, fresh
`--import` in this container:
- `tests/run_tests.gd -- --only=test_band4_upper_meadows.gd` — **7 tests, 28
  assertions, 0 failed** (new file, this session).
- `tests/run_tests.gd -- --only=test_trainers_data.gd` — **50 tests, 1386
  assertions, 0 failed** (unchanged; confirms the SF34 captain/sigil suite
  still holds).
- `tests/run_tests.gd -- --only=test_chapter_curve.gd` — **18 tests, 451
  assertions, 0 failed** (unchanged; confirms the five-slot/level-curve
  guards still hold).
- `tests/run_tests.gd -- --only=test_band_content.gd` — **6 tests, 1145
  assertions, 0 failed** (confirms the band-split merge is still identical to
  its tracked mirror — nothing here touched a pre-split entry).
- `tests/smoke_riding.gd` — **passed**: "riding: OK — saddled, mounted,
  ridden, dismounted, and refused when it had to be," including the legendary
  climb-limit case and a mid-fight mount refusal. (One unrelated, pre-existing,
  non-fatal engine error printed during this run — `material_get_instance_
  shader_parameters`/null material while building the Warrens guardian's body,
  `burrow_warrens.gd:2957` — Band 2, not this lane's file, not fatal to the
  smoke's own pass/fail; not investigated further, flagged for whoever owns
  `burrow_warrens.gd`.)

**Not run:** the full unit suite (28 min; not needed — no data outside the
new test file changed) and any Gate F **S08** continuous evidence run. See
"What is still open" below — that is a real, honestly-reported gap, not an
oversight.

## What was verified as already satisfied, with evidence

### Three-Sigil progression reads as three distinct places, tests the spec's three approaches
- **Field** (Captain Halder, Ground-focused, `(170, 5590)`), **Ridge**
  (Captain Vess, Air-focused, `(-280, 6460)`) sit inside
  `band4_upper_meadows_ironwood/trainers.json`. **Riverwatch** (Captain
  Oreth, deliberately mixed "Water/balanced," `(-100, 4350)`) sits in
  `band3_the_river_lock/trainers.json`, per that entry's own `_comment_ow5d`:
  *"OW5D relocation to (-100,4350), section 3.1's own text: 'Riverwatch
  Captain sits off-spine on the Band 3/4 seam.'"* — a deliberate, spec-cited
  placement, not an accident. **Left unmoved**, per the coordinator's brief.
- Pairwise distance: field↔ridge ≈979m, field↔riverwatch ≈1269m,
  ridge↔riverwatch ≈2118m — genuinely separate places, not a cluster. Pinned
  at a 300m floor in the new test
  (`test_the_three_captains_occupy_spatially_distinct_places`).
- `tests/test_trainers_data.gd`'s existing SF34 section (not touched this
  session) already asserts real archetype contrast between the three teams
  (bulk/punch/spread, not just level), unique sigils per captain, the Hall
  gate opening only at 3/3, and a distinct in-fiction readiness line per
  captain ("Not all one type — you'll want a plan, not a favourite" for
  Oreth, etc.).
- `quest_log.gd::_label()` appends `" n/total"` from `count_flags` — the HUD's
  tracked objective genuinely reads `"Defeat the Upper Meadows captains.
  0/3"` → `"...3/3"`, not a hidden flag.

### Route structure is not one captain line
`terrain_playground.json`'s `trail.loops` already authors **three** band-4
loops, each a real `leaves`/`points`/`rejoins` branch off the spine:
`wind_ridge_traverse`, `high_pasture_loop`, `watchtower_spur`. Pinned by the
new `test_band4_has_more_than_one_route_loop_off_its_own_spine` (reads only —
this lane does not own or edit that file).

### Wild ecology — the "effectively one Meadowhart cluster" claim is stale
Measured against the live table: 81 entries, **8 distinct species**
(trailpup 15, galecrest 15, pipwing 15, burrowback 11, meadowhart 9, mudsnout
9, duskhush 6, stormtrail-alpha 1). Meadowhart is 11% of the band's own
table, not a monoculture. A special encounter exists: `stormtrail` is a rain-
gated alpha aspect-variant of trailpup (`level_bonus +4`), the second of two
in the chapter, sited 1380m from its Band-3 sibling so the two can never be
seen together. Both facts pinned by new tests
(`test_band4_wild_ecology_is_not_a_single_species_monoculture`,
`test_band4_fields_at_least_one_alpha_or_special_encounter`) so a future
scatter edit cannot silently regress into the state the prompt described.

### Roster pressure by Band 4, the number prompt 67 asks for
Cumulative distinct wild species across bands 1–4 (`bramblebun`, `brooktail`,
`burrowback`, `duskhush`, `galecrest`, `meadowhart`, `mosshell`, `mudsnout`,
`nightburrow`, `paddlenewt`, `pipwing`, `reedwing`, `riftfrill`,
`stormtrail`, `trailpup`): **15**, against a 5-creature cap — three times
the cap, not merely one creature over it. Band 4 itself introduces no new
species (all 8 of its species were already seen by Band 3); the pressure by
this band comes from accumulated earlier options plus Band 4's own alpha and
higher-level individuals, which matches the chapter's fixed 25-species/one-
evolution-line budget (CLAUDE.md: no new creature meshes). Pinned at a
`MAX_CREATURES + 3` floor by the new
`test_cumulative_roster_pressure_by_band4_beats_the_five_slot_cap` (the
existing `test_chapter_curve.gd::test_the_meadows_offers_more_creatures_
than_the_party_can_hold` only asserts a whole-game floor of 6; nothing
previously measured the number *by this band specifically*, which is what
prompt 67 actually asks for).

### Riding payoff — genuinely useful, not a dead combat slot
`riding_controller.gd::_mountable_body()` only offers a mount on the
player's own **active out creature** (`encounter_director.ally_body()`) — the
same creature that fights. There is no separate "mount slot": riding
Meadowhart means Meadowhart is your current combat pick, so the traversal
choice and the combat choice are the same five-slot decision, not two. Live-
verified this session with `tests/smoke_riding.gd`: saddle refusal without
the item, correct mount/ride/dismount, `10.00 m/s` ride speed against a
`5.00 m/s` walk (2x, matching `movement.json`), camera follow, mid-fight
mount refusal, and safe dismount when the mount is freed out from under the
rider. The legendary's own higher climb tier (`60°` vs the roster's `55°`,
`x2.80` speed with no tack required) is also proven live, not just read from
data.

### Ironwood tier is real preparation, gatherable inside its own region
- `band4_upper_meadows_ironwood/harvest.json` fields the tier's own nodes
  inside Band 4 (the file's own `_comment_ironwood_d4` records finding and
  fixing the earlier gap: before this, the only ironwood anywhere was five
  Band-2 nodes near the Warrens, so a player who skipped that dungeon spur
  reached Band 4's captains with none). 8 ironwood-item nodes counted in the
  live file; pinned at a floor of 3 by the new
  `test_band4_fields_its_own_gatherable_ironwood`.
- `recipes_ironwood.json` spends it on real utility: `orb_prime` (top
  catching tier), `ironwood_haft_axe`/`_pickaxe` (permanent tool upgrade),
  `potion_large` (80 HP) — final-assault preparation, not a collectible.

### Camp/home rhythm
Two authored field camps sit in Band 4 (`harvest.json`'s own `ASSESS-REDS`
comments): one beside the ironwood grove, one on the eastern loop between
Captain Field and Captain Ridge, each carrying its own local wood/stone/fiber
so a rest point can actually be resupplied from itself. Per the OW6 walked-
route measurements already recorded in `trainers.json`, Captain Halder sits
~28.7 walked minutes into the corridor and Captain Vess ~33.2 — real
distance from the village, with two camps positioned to make a field stop a
genuine choice rather than a mandatory hike back to Grandpa's.

### Optional content competing with the captain route
`patrol_ridgeline` (an optional Team Tether fight at the watchtower spur,
unguarded, no sigil/flag anything else reads) and `pasture_drover_juno` (an
independent rival trainer sited as a warm-up before Captain Halder) both
exist and are neither of the three required captains. `lost_creature_rue`
adds a small side story (a "lost creature" Team Tether beat) off the spine.
Pinned by the new `test_band4_fields_at_least_one_optional_trainer_outside_
the_sigil_gate`.

### Regional identity contrast
`watchtower_landmark.gd` builds a real ruined-watchtower silhouette (spec's
"ruined watchtower" identity item), sited to close the chapter's
second-worst authored-content gap per its own header comment. Props/
trainers together give high pasture (Halder), wind ridge (Vess, "everything
east of here measures 43 to 76 degrees of rock"), and old-growth ironwood
grove — three visibly different sub-biomes inside one region, plus Team
Tether patrol dressing (banner, rope, crate camp) at the watchtower.

## What was found but is not this lane's file to fix

**The Riding Saddle recipe still does not cost Ironwood**, despite the
Ironwood tier having landed. `data/recipes/recipes_rootstone.json`'s
`saddle` recipe carries its own `_comment_ironwood`, written when Ironwood
did not exist yet: *"IRONWOOD SEAM, for SF31... When SF31 lands, add ONE
line to `cost` — `{ "id": "ironwood", "n": 2 }` — and take the `wood` count
down to 2... nothing in `scripts/world/riding_controller.gd` or anywhere
else reads this cost, so that edit is the whole change."* SF31
(`recipes_ironwood.json`) has landed. Spec Band 4 and prompt 65 both name
the saddle's cost explicitly as "Rootstone **and** Ironwood," and today it is
Rootstone-only. `recipes_rootstone.json` is not in this lane's file
ownership (`data/recipes/` was not listed, and it is plausibly the
G3-ECONOMY lane's territory alongside `progression.json`/
`chapter_rewards.json`). **Flagged for the coordinator** — a one-line,
already-fully-specified fix, low risk, directly closes a real spec gap. This
session did not reach the coordinator via cross-session messaging
(`ListAgents` reported no reachable peer at the time); recording it here per
the report contract instead.

## What is still open

**No Gate F S08 continuous evidence run was built or executed for Band 4**
this session (the segment named in `docs/acceptance/GATE_F_MASTER_PROTOCOL.md`:
"crossing → ironwood → saddle & riding → three captains → three Sigils").
`tests/smoke_riding.gd` is a generic riding smoke, not a Band-4 segment
walkthrough; no `smoke_band4`/`smoke_upper_meadows` file exists yet. Building
one to the standard `smoke_gate_b_continuous.gd` sets (a scripted walker
driving South Bridge → Ironwood → all three captains → Hall gate, recording
the evidence template: team comp before/after, dead-travel intervals,
captain-by-captain difficulty, camp/home decisions) is a substantial build in
its own right — comparable in scope to that file — and was not attempted
this session given the size of the verification pass already required. This
is the one acceptance item from prompt 65 ("Evidence run") this report
cannot claim: everything else was checked against real data, real code, and
one live smoke run; the *continuous, band-length* play-through is not yet
proven end to end for Band 4 specifically, only for its individual pieces.

**No render/blind-visual-judge pass was run.** Prompt 65 is substantially a
mechanics/pacing prompt (three captains, route structure, ecology, riding,
resource tier) rather than a composition prompt like Band 1's 2.1–2.7 tasks,
and every site in the touched files carries a `MEASURED`/ground-probed
`_why_here` from prior passes, so this was judged lower priority than the
data/mechanics verification above given the session's time budget — but it
means the subjective "does this look and feel like the chapter's high-level
frontier" half of the acceptance bar is unverified by this pass.

**The pre-existing `material_get_instance_shader_parameters` null-material
error** seen during `smoke_riding.gd` (Burrow Warrens guardian dressing,
`burrow_warrens.gd:2957`) was observed but not investigated — Band 2, outside
this lane's ownership, and non-fatal to the smoke it appeared in.

## Roster-pressure number (prompt 67's explicit ask)

**15** distinct catchable wild species encountered across bands 1–4, against
the 5-creature cap — measured against the live merged spawn tables, not
estimated, and now pinned by a test so it cannot silently regress.

## Acceptance bullets from prompt 65 — met vs. open

| Bullet | Status |
|---|---|
| region feels like the chapter's high-level frontier | **Data/mechanics: met** (see above); **visual: unverified**, no render pass run |
| ecology is rich enough to support team choice | **Met** — 8 species in-band, 15 cumulative, one alpha |
| open and old-growth compositions both work | **Data supports it** (high pasture / wind ridge / old-growth all sited and distinguished); not visually judged |
| Ironwood matters | **Met** — gatherable in-region, spent on real utility |
| riding pays off | **Met** — live-verified, no dead combat slot |
| captains are memorable and spatially distinct | **Met** — distinct archetypes (existing tests) + distinct sites (new test, ≥300m apart) |
| three-Sigil progression is clear without feeling like a checklist corridor | **Met** — legible `n/3` HUD tracking, three loops off the spine |
| roster pressure is real before the legendary | **Met, measured** — 15 species by Band 4 |
| **continuous evidence run (S08)** | **Open** — not built/run this session |
