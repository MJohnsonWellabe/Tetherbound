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

## Priority 1 — rig the five new creature meshes: BLOCKED, confirmed directly

**`MESHY_API_KEY` is unset in this container.** Checked directly, not
inferred: `python3 tools/art_pipeline/meshy.py check` prints "MESHY_API_KEY
is not set" and exits without attempting a network call. This is the exact
wall T3-INSTALL's own handover already recorded hitting on this identical
task ("Any new Meshy generation, including... a rig pass for the five new
creature meshes — no API key in this lane, same as every other lane that has
hit this wall").

Per the brief's own instruction, a *rig* call against an already-generated
mesh is in-scope work (it spends no new Meshy generation credit) — but the
Meshy auto-rigger is a cloud API endpoint, and this pipeline has no local,
offline substitute for it. `animate_humanoid.py`'s own local Blender bake
needs a rigged/skinned input to produce clips from; nothing downstream of
the rig call can proceed without one either. This is a genuine environment
blocker, not a judgement call to escalate for spend authorisation — there is
no owner decision this lane could make that would unblock it locally, since
the key simply is not present in this session.

**What's unchanged from T3-INSTALL's own record:** all five `.glb`s
(Sparkit, Cindercub, Shadelet, Frostclaw, Bramblebun redesign) remain
single-mesh, no-skin exports. Sparkit/Cindercub/Shadelet/Frostclaw still
spawn in their authored bands (species.json/spawn_tables.json, already
wired by T3-INSTALL) and stand at correct scale/material but play no
idle/walk/attack/hit/faint clips. The Bramblebun redesign stays reverted —
`bramblebun.placeholder.model` still points at the original animated mesh —
for the same reason T3-INSTALL gave: swapping the game's most-seen creature
for a frozen static pose would be a regression, not an install.

**Recorded in `docs/ASSET_LEDGER.md`** under a new "T1-CREATURE-RIG"
sub-entry rather than worked around.

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

### Tests

Targeted run (`godot --headless --path . --script tests/run_tests.gd --
--only=test_trainers_data.gd,test_band_content.gd,test_dual_type.gd,
test_dialogue_runner.gd,test_chapter_curve.gd,test_hud_widgets.gd,
test_input_context_collisions.gd`): **183 tests, 4416 assertions, 0
failed**, after the `rechallenge` fix above (the first run of this same
set caught exactly that one real defect: 2 failures, both explained by the
same cause).

No dedicated `village_npcs.json` data-validity test file exists (unlike
`trainers.json`, which `test_trainers_data.gd` owns) beyond
`test_dialogue_runner.gd`'s `test_every_conversation_a_villager_can_open_
really_exists`, which is in the targeted run above and passed — every one
of the 12 new `greeting` ids resolves in `data/dialogue/village.json`,
double-checked by hand with a small script cross-referencing both files
before that test run, same result.

`tests/smoke_art.gd`: [FILL IN — running at handover time]

### Evidence

New tool: `tools/_capture_t1_creature_rig_npcs.gd` — loads the REAL
playground scene (`scenes/world/meadows_playground.tscn`, the same one
`tools/survey.gd` uses), settles it, and shoots 9 viewpoints at the new
NPCs' actual world positions through the real placement code
(`village_npcs.gd`/`trainer_npc.gd`, unmodified) — not a neutral-backdrop
lineup. Confirms grass/terrain/structures are actually present in frame per
`ralph/conventions.md`'s evidence rule.

[FILL IN — render results once the capture finishes]

## What's still dark, ranked by player impact

1. The five new-mesh creatures' no-rig/no-animation defect — genuinely
   blocked on `MESHY_API_KEY`, not a data or placement problem. Whoever
   picks this up next needs a working key in the container; the recipe
   itself (`meshy.py rig` + `animate_humanoid.py`) is unchanged and
   already proven on the 22 NPC bodies.
2. `campfire_traveler`/`traveling_merchant` — unchanged, still blocked on
   a fresh Meshy generation against a resting-pose reference (same as
   every prior lane's record).
3. Everything else T3-INSTALL's own "still dark" list named (the Aspect
   variant decal mask, camp kit style break, `roll_new_worlds`, the
   trainer-defeated-line bug, the 13 remaining reader-less config keys) is
   untouched by this lane — out of scope for a rig-and-placement task.
