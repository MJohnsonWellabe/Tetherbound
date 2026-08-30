# Handover — T1-CREATURE-RIG, 2026-08-30

Branch `ralph/T1-CREATURE-RIG`, off `origin/main` at `bf815014` (COORD: unify
the Meadows exit criterion), merged forward with `origin/ralph/T3-INSTALL`
(`14f177cc`) as a prerequisite — that branch's species.json/spawn_tables.json
wiring for the five new creature meshes, and its NPC-rank work, had not
landed on `main` yet, and this task is a direct continuation of two things
that branch's own handover named as open.

Read first: `ralph/reports/handover-T3-INSTALL-2026-08-30.md` sections 1 and
3, `CLAUDE.md`, `ralph/MEADOWS_EXIT_CRITERION.md` sections B and C,
`ralph/conventions.md`, `docs/ASSET_LEDGER.md`.

## Priority 1 — rig the five new creature meshes: DONE, by a different recipe than the brief guessed at

**`MESHY_API_KEY` was confirmed unset in this container early in this
session** — `python3 tools/art_pipeline/meshy.py check` printed
"MESHY_API_KEY is not set", the same wall T3-INSTALL's own handover
recorded hitting on this exact task. The owner supplied a working key
(515 credits, verified) partway through this session, but **it turned out
not to be the actual blocker.**

`tools/art_pipeline/meshy.py`'s own `cmd_rig` docstring says plainly:
"Meshy documents this as HUMANOID-only, and Terrapup is a quadruped, so
this is expected to fail or produce nonsense for creatures." The brief
correctly anticipated this ("if the humanoid rigger cannot take them, say
so precisely rather than forcing it") and asked to check for a creature
equivalent — `tools/art_pipeline/finish.py` already has one, and every
existing production creature in the roster (Bramblebun's own original mesh
included) already went through it: `finish.py rig <species> --kind
quadruped` runs a **local, offline Blender pipeline** —
`rig_quadruped.py` places a 15-bone skeleton from the mesh's own geometry
(legs found by clustering the lowest-quarter vertices into four quadrants,
spine along the long axis, head/tail over the front/rear overhang — no
hand-placed bones) and skins it with automatic weights; `animate_quadruped.py`
then authors the same six clips (idle/walk/run/attack/hit/faint) every
other creature ships. **Zero Meshy credits.** Only `finish.py texture`
touches Meshy, and none of these five needed retexturing.

### What was run, for all five (Sparkit, Cindercub, Shadelet, Frostclaw, Bramblebun redesign)

```
mkdir -p assets_raw/<species>/build
cp assets/creatures/tetherbound/<species>/models/creature_<species>_lod0.glb \
   assets_raw/<species>/build/textured.glb
python3 tools/art_pipeline/finish.py rig <species> --kind quadruped
python3 tools/art_pipeline/finish.py install <species>
```

All five produced a clean rig (15 bones) and the standard 6 clips.
Sparkit, Shadelet and Bramblebun redesign came back with **0 unweighted
vertices**. Cindercub (35/27342) and Frostclaw (20/26840) triggered
`rig_quadruped.py`'s own "UNWEIGHTED VERTICES PRESENT — these will tear in
animation" warning, so neither was installed on a vertex count alone.

**New tool: `tools/art_pipeline/blender/pose_check.py`.** Renders a rigged
model at a named action/frame instead of its rest pose, specifically to
answer "does this actually tear" with a frame rather than a guess — the
same "a rendered frame, not a passing parse test" standard
`ralph/conventions.md` asks for everywhere else. Both Cindercub and
Frostclaw were rendered at the `attack` clip's most extreme pose (frame
10 — full rear-up, both forepaws slammed down) and came back clean, no
visible tearing. All five species now have a posed evidence frame at
`ralph/reports/T1-CREATURE-RIG/shots/pose_check/<species>_attack10.png`.

### The Bramblebun redesign now ships

The brief asked to re-verify it specifically once animation was possible.
It is: `data/creatures/species.json`'s `bramblebun.placeholder.model` now
points at `bramblebun_redesign/models/creature_bramblebun_redesign_lod0.glb`.
The only reason T3-INSTALL reverted it (a static, unrigged mesh regressing
the game's most-seen creature) no longer applies — the posed render shows
a clean rig with the redesign's own larger, antlered silhouette, matching
the owner's size guide's "larger and more substantial" direction.

### A real trap paid for here, for whoever touches creature `.glb`s next

Overwriting a `.glb` on disk does not reach the game until Godot's import
cache is refreshed — `ralph/conventions.md`'s art-pipeline section already
documents this for renders, and it is equally true for `smoke_art.gd`.
The first post-install `smoke_art.gd` run still reported "bramblebun has
no AnimationPlayer" against the **stale cached import** of the old,
unrigged mesh (`.glb` mtime newer than the `.import` sidecar, confirmed
directly). `godot --headless --path . --import` (re-run once, ~1 minute)
fixed it; the second `smoke_art.gd` run is clean — see Tests below.

`data/creatures/species.json`'s `animations` block for all five species
was already pre-authored by T3-INSTALL/T3-CREATURES pointing at exactly
`{idle, walk, run, attack, hit, faint}` — the same role names and clip
names `animate_quadruped.py` produces — so no species.json edit was needed
beyond the model path swap and refreshing the `_comment_art`/
`_comment_redesign_0830` provenance notes.

## Priority 2 — the 15 unplaced civilian/trail NPC bodies: DONE

All 15 are now placed, each with a real greeting or challenge/defeated
conversation, using every one of the config_key entries T1-NPC-CAST already
wired into `data/config/art.json`.

**12 non-battle roles** — `innkeeper` (Wilhelm), `inn_helper` (Nessa),
`trader` (Corin), `craftsperson` (Ada), `creature_caretaker` (Fenn),
`farmer` (Garrick), `local_historian` (Old Perrin), `lost_traveler` (Tobin),
`field_researcher` (Maren), `alpha_tracker` (Sorrel), `courier` (Lark),
`former_tether_member` (Ren) — are new entries in
`data/config/village_npcs.json`'s `villagers` array, each with a simple
`greeting` (no `greeting_when` branching needed — these are flavour NPCs,
not progression-gated). Greeting conversations live in
`data/dialogue/village.json`. Names, personalities and greeting lines are
written from the owner's own Meadows NPC Design Board
(`docs/art/reference/npc-board-2026-08-30/00_MEADOWS_NPC_DESIGN_BOARD.png`)
role blurbs, read directly rather than guessed at.

**3 Battle roles** — `young_trainer` (Kip), `rival_trainer` (Talon),
`wandering_trainer` (Faye) — are standalone `trainer_npc.gd` placements in
`data/config/bands/band1_lower_meadows/trainers.json` (orders 1020-1022,
appended past the band's baseline-fixture size per
`tests/test_band_content.gd`'s own documented append-only rule), the same
shape Bryn/old_champion_bram already use rather than a `village_npcs.json`
greeting-flow battle. Each has an authored team drawn from species already
resident in Band 1 (bramblebun, pipwing, mudsnout, terrapup, paddlenewt —
all single-typed, keeping `test_dual_type.gd`'s no-dual-typed-roster-creature
rule clean) at levels inside the band's own `chapter_curve.json`
`trainer_levels` band of [2, 7] (none of the three is a `gate_fight`, so
they are checked against that band, not the corridor ceiling). Challenge and
defeated dialogue is in `data/dialogue/bands/band1_lower_meadows.json`.

`wandering_trainer` was first authored `rechallenge: true` (the board's own
"enjoys friendly battles" blurb reads like the one trainer worth meeting
twice) and reverted: `tests/test_trainers_data.gd`'s
`test_a_beaten_trainer_cannot_be_challenged_again`/
`test_a_beaten_trainer_greets_instead_of_challenging` assert every trainer
in the table becomes genuinely unchallengeable once beaten, with no
`rechallenge` exception carved out, and `old_champion_bram`'s own comment in
the same file records this exact call being made deliberately once already
("an optional trainer who can be farmed is exactly the thing prompt 30's
rule exists to prevent"). Matched that existing convention rather than
reopening it or weakening the test.

### Placement method — not eyeballed

New tool: `tools/_probe_civilian_placement.gd`
(`godot --headless --path . --script tools/_probe_civilian_placement.gd`,
no rendering needed — it is a pure data/analytic-terrain probe, ~1s to
run). For every candidate position it reports:

- ground height and slope from `playground_heightfield.gd`'s own analytic
  field — the same class the runtime terrain, `village.gd`'s own
  placement, and every existing probe in this repo (`tools/_probe_ow5b_
  footprint_slope.gd` etc.) already use, so this needed no bake and no
  world boot;
- `path_factor` at the point, so a candidate cannot land on a dirt road
  the way one first draft did (three of the first-pass candidates were
  literally standing in the middle of a path or the well's own junction —
  the probe caught it, they moved);
- distance to every relevant building's footprint, using the exact
  radius formula `village.gd::_ground_clear_radius` uses at runtime
  (half-diagonal of the prefab's own module extent, from
  `building_prefabs.json`, plus the same 0.7m `CLEAR_MARGIN`) — not a
  guessed clearance number;
- distance to every already-authored person (`village_npcs.json`'s eight
  existing villagers, `trainers.json`'s existing Band 1 roster, and every
  other new candidate), so nothing stacks two people within 3m of each
  other or lets two trainer challenge-prompt radii (4.2m each) overlap.

Two of the twelve non-battle NPCs — Maren (field researcher) and Sorrel
(alpha tracker) — were deliberately placed at the pond-crossing cluster
(the empty `ranger_station` building and the mill crossing,
`village.json`'s own structures at `[-350,507]`/`[-382,514]`) rather than
adding to the village square's own crowding: the ranger station has stood
empty since Sela moved into the square (SE27), and a field researcher /
alpha tracker fit that building and that setting far better than a tenth
body in an 18m-radius square already carrying eight people, three
structures' worth of clutter and two practice arenas.

## Tests

Targeted run (`godot --headless --path . --script tests/run_tests.gd --
--only=test_trainers_data.gd,test_band_content.gd,test_dual_type.gd,
test_dialogue_runner.gd,test_chapter_curve.gd,test_hud_widgets.gd,
test_evolution.gd,test_evolution_links.gd,test_input_context_collisions.gd`),
run twice: **183 tests / 4416 assertions after Priority 2's placements
(0 failed after the `rechallenge` fix above — the first run of that set
caught exactly that one real defect, 2 failures, both the same cause), then
203 tests / 4274 assertions after Priority 1's model swap (0 failed)** —
the second run's smaller total is `test_hud_widgets.gd`/portrait-adjacent
methods dropping out and evolution tests joining in, not a coverage loss;
both runs are 0 failed.

`tests/smoke_art.gd`: **could not complete in this container, honestly
reported rather than left pending.** Three attempts: an unbounded run
before any rig work existed ran 36+ minutes with zero output and had to
be killed by hand; a bounded (10 min, hard `timeout`) run right after
installing the rigged meshes correctly caught a real defect ("bramblebun
has no AnimationPlayer") against the *stale* cached import of the
pre-rig mesh (see the import-cache trap above) — genuinely useful signal,
not a hang; a third bounded (10 min) run after `godot --headless --path .
--import` refreshed the cache ran the full world build cleanly (same
log as every other successful boot this session) and then produced
**zero further output for the remaining ~7 minutes before the timeout
killed it** — i.e. it hung somewhere in its own per-creature checks, not
in the world build, and not on a real defect this time.

This is a pre-existing container characteristic, not a regression from
this lane's changes: the very FIRST attempt hung identically before any
creature was touched. Rather than accept an inconclusive "maybe it would
pass," ran the actual code `smoke_art.gd`'s model checks exercise —
`creature_body.gd::setup()` — through `tools/preview_creatures.gd`
instead, which stages every species alone (no full-world boot) and
completed in well under a minute: **wrote `shots/_creatures.png` for
all 25 species, `sparkit`/`cindercub`/`shadelet`/`frostclaw`/`bramblebun`
among them, no errors.** This exercises the same real placeholder-build/
animator-wiring path `smoke_art.gd`'s own scale/collider checks use, just
without the sibling checks (shiny variants, vegetation LOD survival,
human-fit) that only run inside the full world. Evidence:
`shots/_creatures.png` (not committed — this tool writes outside
`ralph/reports/`, matching its own existing convention; regenerate with
the command above if needed).

No dedicated `village_npcs.json` data-validity test file exists (unlike
`trainers.json`, which `test_trainers_data.gd` owns) beyond
`test_dialogue_runner.gd`'s `test_every_conversation_a_villager_can_open_
really_exists`, which is in the targeted run above and passed — every one
of the 12 new `greeting` ids resolves in `data/dialogue/village.json`,
double-checked by hand with a small script cross-referencing both files
before that test run, same result.

## Evidence

- `ralph/reports/T1-CREATURE-RIG/shots/pose_check/` — all five newly-rigged
  creatures, posed at the `attack` clip's most extreme frame, through
  `tools/art_pipeline/blender/pose_check.py`. Confirms real skin
  deformation with no tearing, not just a skins/animations count.
- `ralph/reports/T1-CREATURE-RIG/shots/01-square-inn-side.png` — one real
  in-game frame, the actual playground world (real terrain, real grass,
  the real inn structure) with Wilhelm (innkeeper) standing correctly on
  the ground beside the inn, through `tools/_capture_t1_creature_rig_npcs.gd`
  (loads the same scene `tools/survey.gd` uses, real placement code,
  unmodified).
- The placer's own boot log for that same run: `[village_npcs] placed 18
  of 20` (2 short is correct and expected — Sela and Kell are both gated
  behind progression flags unset on a fresh world, per their own
  `place_when` entries) and `[trainers] placed 20 trainer(s)` with **no
  `push_error` lines** — every villager and trainer, the 15 new ones
  included, found valid ground under `stand_at()`.

### A note on this container's performance, for whoever runs the next full-world capture

Booting `scenes/world/meadows_playground.tscn` and letting it fully settle
(the ~240-physics-frame pattern `tools/survey.gd` uses) is reliable — it
completed identically, twice, logging every construction phase
(terrain, 248,542 scattered props, 315k+ grass tufts, all placements) in
well under the time it then spent stuck in the RENDER loop afterward.
The per-frame cost of actually drawing that scene under `llvmpipe`
software rendering in this specific container is severe enough that a
9-viewpoint capture with the settle frames `survey.gd` normally uses did
not finish in 36+ minutes; a version with settle frames cut roughly 10x
(30 world-settle, 20 per-view, 3 pose) still only completed 1 of 9 views
in an 8-minute hard timeout. That one view is real and is the evidence
above. Nothing here suggests the WORLD is broken — construction succeeds
every time and reports the same numbers — only that many-viewpoint capture
tools should expect this container's render throughput to be much lower
than `tools/survey.sh`'s own historical timings assume, and should budget
accordingly (fewer viewpoints, or a much longer bounded timeout) rather
than trust the old per-frame cost estimates.

## What's still dark, ranked by player impact

1. `campfire_traveler`/`traveling_merchant` — unchanged, still blocked on
   a fresh Meshy generation against a resting-pose reference (same as
   every prior lane's record).
2. Everything else T3-INSTALL's own "still dark" list named (the Aspect
   variant decal mask, camp kit style break, `roll_new_worlds`, the
   trainer-defeated-line bug, the 13 remaining reader-less config keys) is
   untouched by this lane — out of scope for a rig-and-placement task.
3. This lane's two new tools (`tools/_probe_civilian_placement.gd`,
   `tools/_capture_t1_creature_rig_npcs.gd`, `tools/art_pipeline/blender/
   pose_check.py`) are scratch/evidence tools, not wired into CI or the
   test suite, matching every other `_probe_*`/`_capture_*` tool's own
   convention.
