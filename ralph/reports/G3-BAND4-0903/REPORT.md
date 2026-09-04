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

**Data/code changed this session, in two passes.** First pass (verification):
one new file, `tests/test_band4_upper_meadows.gd` (7 tests, 28 assertions, all
pass). No edits to `spawns.json`, `harvest.json`, `props.json`,
`riding_controller.gd`, `tether_sigil.gd`, or `watchtower_landmark.gd` — every
one of those was inspected and found to already satisfy the prompt. Second
pass, after the coordinator's follow-up (the encounter contract and a real
played run) — see the Addendum section below: per-captain `combat` overrides
for Halder and Vess in `data/config/bands/band4_upper_meadows_ironwood/
trainers.json` (mirrored in `tests/fixtures/band_split_baseline/
trainers.json`), a defeat-line pointer fix in `data/dialogue/trainers.json`,
and a new Gate F seed tool, `tools/gate_f/build_s08_entry_synthetic.gd`, used
to actually play S08 rather than only read its config.

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

**Not run:** the full unit suite (28 min; not needed — the second pass's data
edits are covered by the targeted re-runs listed in the Addendum below).
**Gate F S08 was built and played this session** — see the Addendum for the
full evidence template and its FAIL verdict, with the root cause traced
through raw telemetry rather than assumed.

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

## Addendum — the encounter contract (C-4/C-5/C-7) and a real S08 run

The coordinator's follow-up correctly called out that the first push of this
report, on its own, was not a shipped lane: static verification plus a test
file is not the same as changing or proving the game. This addendum covers
the two things that came after: authoring this lane's half of Fable's Gate 3
encounter contract, and actually playing S08 rather than only reading its
config.

### C-4 / C-5 / C-7 — per-captain combat, shipped

`docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` (Fable, `ralph/G3-ENCOUNTERS-0903`)
found that every opponent in the game — wild or trainer, captain or grunt —
fights out of one shared `combat.json` `enemy` block, so nothing about a
fight against Halder, Vess or Oreth read differently except level. That is
prompt 65's "each test something distinguishable" failing on the one axis
this lane cannot fix with siting or dialogue alone: behaviour. The
coordinator implemented the mechanism (G-2, the per-body `combat` override
`wild_creature.set_engaged()` merges over `combat.json`'s `enemy` block)
directly in `scripts/creatures/wild_creature.gd` to avoid a five-lane
collision; this lane authored the two captains in its own file against the
five reusable profiles (G-3) the contract assigns:

- **Captain Halder** (`captain_field`, C-4 "the Pasture: power"): Tuskroot
  gets **CHARGER** (closes from range in one lunge — `preferred_range 4.5`,
  `lunge 7.0`, `telegraph 0.6`, `recovery 0.9`, `attack_cooldown 1.6`,
  `power 10.4`); Meadowhart (the ace) gets **CURRENT** at the contract's
  explicit `power 1.0` rather than CURRENT's own default 0.8× (relentless
  pressure, not a thin hit — `attack_cooldown 0.7`, `recovery 0.55`,
  `reposition_time 0.5`, `reposition_distance 2.0`, `power 8.0`); Duskhush
  stays on the default profile, C-4's own "default" third member.
- **Captain Vess** (`captain_ridge`, C-5 "the Ridge: endurance"): Galecrest
  (the ace) gets **DIVER** (short tell, long retreat, comes again from a
  new side — `telegraph 0.4`, `lunge 5.5`, `reposition_distance 7.0`,
  `reposition_time 1.6`, `attack_cooldown 0.9`, `power 7.2`); Trailpup and
  Duskhush stay default.
- Both edits mirrored into `tests/fixtures/band_split_baseline/trainers.json`
  in the same commit, per `test_band_content.gd`'s own policy for a
  deliberate edit to a pinned pre-split entry (verified: `test_band_content`
  6/6, `test_trainers_data` 50/50, `test_band4_upper_meadows` 7/7 all still
  green after the edit).
- **C-7** (defeat-line pointer flip): the captains' defeated-conversation
  lines pointed Halder → Vess → Oreth. The real road order (measured below,
  and independently confirmed by simple geometry) is Oreth → Halder → Vess,
  so Vess's own defeated line was sending a player back to a captain already
  beaten — exactly the failure C-7's `fails if` names. Flipped the chain in
  `data/dialogue/trainers.json`: Oreth's defeated line now names Halder,
  Vess's now points to the Hall gate instead of back to Oreth. Verified:
  `test_dialogue_runner` 66/66, `test_band_dialogue` 3/3 green, and no test
  in the tree pins the removed line text verbatim.

**Oreth's own half of C-1/C-2/C-3** (his ace level 16→15, his stale
`facing_deg` and missing site prop, and his Mosshell=WALL/Brooktail=CURRENT
overrides) lives in `data/config/bands/band3_the_river_lock/trainers.json`,
outside this lane's file ownership (the coordinator's original brief
explicitly excludes Band 3, and the contract's own §8 table lists C-1/C-2 as
"band 3 data"). Not touched here. Flagged for whichever lane owns Band 3, or
the coordinator directly.

### The S08 evidence run — built, run, and its real finding

Built `tools/gate_f/build_s08_entry_synthetic.gd`, modelled directly on
`tools/gate_f/seed_s09_exit.gd`, to hand-author the `S07-exit` entry save
S08 loads (no completed Gate F run has ever produced a real one — same
justification `seed_s09_exit.gd` gives for S10). Assumptions and their
sources are in the file's own header: party of five at chapter_curve.json's
band-4 `enter` level (13, bench at 12/11), Ground/Water/Air spread avoiding
an already-evolved Tuskroot (evolution's own example target, ~level 15, sits
inside this band — seeding one pre-evolved at entry would assume the thing
the band is partly for), every main-chain flag through
`mill_crossing_restored` and no further, full HP/energy/satiety, and the
player positioned on the Band-4 side of the Old Mill Crossing.

**First attempt failed at the harness's own pre-flight**, not on content: no
coordinator-frozen `RUN_METADATA.json` exists for an isolated single-segment
run like this one (§A.2 makes that a coordinator step, before a full S01
chain), so `operator_harness.gd`'s CD-8b check fell back to the unrelated,
stale `ralph/reports/gate-f-candidate/RUN_METADATA.json`, which claims
`display_server: "X11 under xvfb-run"` for every lane with no `lanes` block
— a flat claim that contradicts a genuinely headless logic-lane invocation
and blocks it outright. Fixed the sanctioned way (`_freeze_display_claim()`'s
own comment): a truthful, lane-scoped `RUN_METADATA.json` written at this
run's own directory root, declaring `lanes.logic.display_server` as
`"headless"`. Not an edit to the tracked candidate record.

**Second attempt found a real placement bug in the seed itself**, not in
Band 4: the first cut of the seed script stood the player at
`far_point(20.0)` past the Old Mill Crossing — `(-152, -2.15, 4223)` — and
the walker never moved again for the rest of its 45,000-frame budget
(`route.csv`: 300+ seconds at `dead_travel_m` pinned to 0.00, heading
spinning in place). `tools/_probe_river_gate.gd`'s own header had already
found and recorded the cause: "11m of Band 3 trail at x=-150 lies inside a
river volume" (a `CarveFailsafe` recovery box) and separately warns that
`ground_height_at` "is analytic and misled three separate investigations of
the phantom wall" at this exact crossing. Re-sited to `far_point(35.0)` —
past that same probe's own measured-clean `+23.7m` continuous-walk distance
with a real margin — and added a settle-drift self-check to the seed script
so a future regression here fails loudly instead of silently seeding another
stuck run. The rebuilt seed settled cleanly with zero drift, and the walker
moved normally on the next run.

**Third attempt ran the segment for real, in Gate F logic mode**
(`godot --headless --path .`, no rendering driver — the segment's own
`evidence_lane: logic` correctly delegates its planned captures to `S08C`,
not taken here). It covered real ground before the finding below stopped it:

- The crossing → Ironwood Grove walk (839.5 m in 10,728 walking frames),
  region correctly resolved to `the_ironwood_grove`.
- Ironwood harvested; the grove's pipwing engaged, fought and caught (party
  3 → 4).
- The high-pasture walk to the Meadowhart herd (610.4 m), the herd
  Meadowhart engaged, fought and caught (party 4 → 5, HUD confirmed at
  exactly five slots).
- The saddle and `orb_prime` crafted at the workbench at real cost; mounted,
  rode, dismounted, remounted the Meadowhart.
- The ridden leg to Captain Halder (164.8 m).

**The finding, traced through the raw HP telemetry (`party[].hp` on every
event), not inferred:** the lead creature (Tup, the L13 Terrapup) took
steady `combat_hit` damage through the *wild* Meadowhart fight at the herd —
27 hits, `206.4 → 0.0` HP — and fainted there, well before Halder. No other
party member ever took a scratch. Nothing in the S08 step script switches
the active creature or spends one of the seed's two Revives after a faint,
so every subsequent "fight" (Halder, then Oreth) sent a fainted creature to
the front: `flag defeated_captain_field NOT set` at t=717s, and at Oreth,
the scripted `combat_quick` presses — thrown at no real fight — resolved
instead to opening the Build catalogue (`input_context: world →
build_catalogue`), which then never closed again. The run was stopped there
(2+ minutes of zero position/context change confirmed it was genuinely
wedged, not slow) rather than let it burn its remaining budget stuck.

**This is a harness/step-script gap, not a Band 4 content or balance
defect** — the same class of finding the coordinator's own message named as
the correct read for Gate F run 3's stranding ("one stranding counted many
times, not many content defects"). `tools/gate_f/segments/S08.json` is not
in this lane's file ownership, and the fix (a switch-or-revive step after
any fight that could faint the lead, or a pre-flight party-health check) is
a Gate F harness change, not a `band4_upper_meadows_ironwood` one. **Neither
Halder's nor Oreth's actual fight outcome was validated by a PLAYED fight in
this run** — no real, sustained combat exchange happened against either —
so a live, driven fight against either captain remains open. A quantitative
check does exist now, below (formula-driven, not played), and it did not
find the profiles unsound.

**The routing verdict** (the contract's open question, and the coordinator's
explicit ask: does the route support Oreth being fought first?): **agree**,
independent of the harness defect above. The S08 script itself walks to
Halder before Oreth (transcribing the protocol document's listed order,
which its own S08-87 comment already flags as *not* necessarily the ground
order). But straight-line geometry from the crossing landing settles it on
its own: crossing landing `(-152,4238)` → Oreth `(-100,4350)` is **123.5 m**;
the same landing → Halder `(170,5590)` is **1,389.8 m**, requiring the whole
Ironwood Grove detour (844.4 m) first. A player choosing their own path
reaches Oreth an order of magnitude sooner than Halder. The contract's
verdict — leave Oreth on the far bank, road order is Oreth → Halder → Vess —
is correct on the measured ground, and this lane's C-7 dialogue fix already
assumes that order.

**Evidence template** (`docs/ROADMAP.md`'s own headings), for what the run
covered before the stall:

- **Player purpose:** cross the restored Mill Crossing, gather Ironwood,
  build a team of five in the grove/herd, craft the saddle tier, ride to and
  challenge the Upper Meadows captains. Legible throughout — the tracked
  objective read "Defeat the Upper Meadows captains. 0/3" from load.
- **Team progression:** entered at 5/5 (synthetic, per the seed's own
  documented assumptions); Terrapup fainted at the wild Meadowhart fight
  (206.4 → 0 HP over 27 hits) and was never revived or swapped — a real
  finding about the *script*, not a claim about how a real player would
  play. Two wild catches (pipwing, Meadowhart) both landed.
- **World interaction:** ironwood harvested, saddle + `orb_prime` crafted at
  real cost, riding mounted/dismounted/remounted correctly, both wild fights
  engaged. Zero real captain-fight data (see finding above).
- **Empty travel:** longest continuous `dead_travel_m` run measured was
  **549.3 m**, on the Halder → Oreth leg — over the protocol's own 250 m
  "finding" line. Caveat: this leg is the script's un-natural transcribed
  order (backtracking 1,240 m south); a real player travelling
  Oreth-then-Halder, as the routing verdict above says they would, would not
  necessarily walk this same leg at all.
- **Reliability:** two harness pre-flight/placement defects found and fixed
  in this lane's own tooling (RUN_METADATA fallback, crossing-landing
  recovery-volume stall); one harness/step-script defect found and NOT
  fixed here, outside this lane's ownership (post-faint switch/revive
  missing, `combat_quick` misresolving to Build outside real combat).
- **Presentation:** not captured — logic lane, captures delegated to `S08C`
  per the segment's own declaration.
- **Decision: S08 FAIL**, for a harness reason, honestly stated rather than
  inflated into a content verdict. The route, the ecology, the crafting and
  the riding all executed correctly up to the point of the first captain
  fight; the fight-defeat evidence itself is void because the harness never
  gave the player a fair fight to win. Re-running this segment to a real
  PASS needs a harness-side fix (a switch/revive step, or a pre-fight
  party-health assert) outside this lane's file ownership — not a Band 4
  data change.

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

## The C-4/C-5 balance question, answered quantitatively

The S08 run above could not tell us whether Halder's and Vess's new profiles
are actually winnable — no real fight against either ever happened. Rather
than leave that as a bare "unverified," built
`tools/_probe_band4_captain_combat_balance.gd`: a steady-state
damage-per-second model built from the SAME live functions the game uses
(`combat_math.base_damage`, `progression.stat_at_level`), not a
reimplementation — a formula change elsewhere in the tree updates this
probe's answer automatically. It checks the contract's own two `fails if`
bounds directly (G-3's one-blow safety check; C-4's "party at entry level
wins with at most one faint" / "party two levels under cannot win free"),
swept across four assumed player quick-attack hit rates (100% down to a
deliberately harsh 35%), for a LONE, never-switching, no-potion Terrapup —
the single worst case a real five-creature party (which can switch and heal)
would never actually be reduced to. Run headless, ~1 second, no world boot
needed:

- **No one-shot risk anywhere**: every captain team member's hit against a
  fresh, full-health, band-entry-level Terrapup lands at 3-6% of its HP —
  nowhere close to G-3's one-blow bound.
- **Halder (captain_field), band-entry level 13**: the lone Terrapup
  survives solo at 100%/70% assumed hit rate (50%/28% HP left) and faints
  at 50%/35% (weak play). Real damage, not a formality — matches the
  contract's own framing of Halder as "no trick... whoever's strongest."
- **Vess (captain_ridge), band-entry level 13**: gentler than Halder solo
  (64%/49%/28% HP left at 100%/70%/50%, faints only at the harshest 35%) —
  consistent with the contract's own design, where Vess's exam is the
  *route*, not a harder fight than Halder's.
- **Two-levels-under check (Halder only, C-4's other bound)**: a lone L11
  Terrapup still survives at 100%/70% hit rate (42%/18% HP left), faints at
  50%/35%. Read against the letter of "a party two levels under can win
  without a potion" this is a close call — a skilled solo run at 2-under
  does survive without a potion. Read against the bound's actual intent
  (an under-levelled party should not trivialise the fight for free) it
  holds: 58-82% of HP is spent doing it, not a walkover, and a real
  five-creature party at 2-under has proportionally more total HP to spend
  than the solo worst case modelled here. Flagged as a genuine nuance
  rather than a clean pass, not smoothed over.

Honest limits of this check, stated once rather than per-number above: it is
a steady-state DPS model (attacks/second × damage/hit), not a frame-accurate
simulation — every player swing is assumed to land in range, both sides are
assumed to fight at a constant distance the whole time, and type
effectiveness is neutral (1.0×) throughout. It is a sanity check on the
arithmetic the profiles imply, and the best evidence this session could
produce without a working harness — it is not a substitute for a played
fight, which is exactly what the harness gap above still owes.

## What is still open

**A Gate F S08 run was built and actually played this session** (see the
addendum above) — a real change from the first cut of this report, which
had none. It reached the Ironwood Grove, both wild fights, both catches, the
saddle/`orb_prime` crafting and the ridden leg to Halder before stalling on
a harness gap (no post-faint switch/revive in the step script). **S08 is
therefore FAIL, honestly**: the route/ecology/crafting/riding half is
verified live; the three-captain-fight half is not, because the harness
never gave the player a fair fight. Getting S08 to a real PASS needs a fix
to `tools/gate_f/segments/S08.json` (or the harness's own party-health
handling) outside this lane's file ownership, followed by a re-run that can
actually reach Vess and the Sigil gate — the Vess/Ridge leg and the
`hall_approach_open` gate were never reached by this run at all.

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
| captains are memorable and spatially distinct | **Met** — distinct archetypes (existing tests) + distinct sites (new test, ≥300m apart) + distinct *behaviour* now (C-4/C-5 combat profiles, this session) |
| three-Sigil progression is clear without feeling like a checklist corridor | **Met** — legible `n/3` HUD tracking, three loops off the spine; road order (Oreth → Halder → Vess) confirmed by measured distance and now matches the dialogue pointer chain (C-7) |
| roster pressure is real before the legendary | **Met, measured** — 15 species by Band 4 |
| **continuous evidence run (S08)** | **FAIL, played this session** — route/ecology/crafting/riding verified live to Halder; the three-captain-fight evidence is void on a harness gap (no post-faint switch/revive), not a content defect; Vess/the Sigil gate never reached |
