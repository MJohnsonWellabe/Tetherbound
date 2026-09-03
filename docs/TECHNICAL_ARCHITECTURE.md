# Tetherbound — Technical Architecture Source of Truth

Consolidated from a fresh read-only inventory of `scripts/`, `autoload/`,
`scenes/`, `data/`, `addons/`, `project.godot` and `.github/workflows/ci.yml`
(see `inv_source.md` / `inv_gameplay.md`, produced the same session), plus
`docs/decisions/D01, D02, D05, D09, D14, D27, D54`, `docs/AGENT_WORKFLOW.md`,
`docs/specs/PERFORMANCE_BUDGET.md`, and `docs/TECHNICAL_ARCHITECTURE.md`. Supersedes
`docs/TECHNICAL_ARCHITECTURE.md`, which describes a recommended structure from
before the project existed in its current form — several of its suggested
directories and system names (`InputRouter`, `WorldState`, `AssetRegistry`)
were never built as named; the actual shape is below.

---

## 1. Engine and renderer

- **Godot 4.7-stable**, GDScript only (D01). `project.godot`'s
  `config/features` reads `PackedStringArray("4.7", "GL Compatibility")`.
- **Renderer: Compatibility (`gl_compatibility`)** — verified at
  `project.godot:72`, `rendering/renderer/rendering_method="gl_compatibility"`.
  Reversed from an original Forward+ choice (D01) after the owner reproduced
  a hard freeze on the shipped Windows build twice, root-caused to a Vulkan
  present/pipeline-compile deadlock specific to the ROG Ally's GPU/driver
  combination. Compatibility sidesteps Vulkan (GLES3) and matches the
  renderer every CI/visual-judge capture already uses. Cost paid knowingly:
  no real directional shadows, SDFGI, or volumetric fog (Forward+-only). Do
  not switch back without new on-device evidence.
- Authored at 1920x1080 with `canvas_items` stretch — the ROG Ally's native
  panel resolution.
- Windows x86_64 is the primary export target; Linux x86_64 is kept for the
  headless Linux development/CI environment.

---

## 2. The single autoload: `Game`

Exactly one registered autoload (`project.godot`'s `[autoload]` section,
line 38, with a comment explicitly stating it is meant to stay the only one):

```
Game="*res://autoload/game_state.gd"
```

`autoload/game_state.gd` (1,548 lines) is the root singleton. It owns the
party, satchel/day counter, and everything that outlives the scene tree, and
stands up the pause menu on `_ready()` so the menu exists in every scene
without being hand-instanced into each one (D14). It `preload()`s five other
files under `autoload/` as **composed `RefCounted` modules**, not separate
autoloads — deliberate: pure logic testable headlessly, separate from the
one thing (`GameState`) that holds a live reference to each.

| Module | Lines | Role |
|---|---|---|
| `autoload/game_state.gd` | 1,548 | Root singleton: owns party, satchel/day, mounts pause menu |
| `autoload/map_state.gd` | 707 | Region/map state, fog-of-war, "exactly one" region contract |
| `autoload/inventory.gd` | 377 | Player inventory/satchel (24 slots + 6-slot hotbar) |
| `autoload/party.gd` | 211 | The 5-creature party — `const MAX_CREATURES := 5`, enforced only in `add()` |
| `autoload/item_db.gd` | 170 | Item database accessor |
| `autoload/progression_state.gd` | 79 | Progression/objective flags |

Total: 3,092 lines across 6 files, all reached through `Game.*`. No second
autoload exists or is planned — a duplicate camera, inventory, or region-loader
system was checked for and not found (see §4).

---

## 3. The single world scene

`project.godot`'s `run/main_scene` is `res://scenes/ui/title_screen.tscn`
(boot/title UI). New Game / Load Game both end by
`get_tree().change_scene_to_file("res://scenes/world/meadows_playground.tscn")`
— the entire Meadows is **one continuous open-world scene**, not a set of
discretely loaded regions.

`meadows_playground.tscn`'s root/driver script is `scripts/world/playground_world.gd`
(1,640 lines), which builds the world procedurally in one `_ready()` pass —
terrain, water, settlement, vegetation, per-band content, stronghold,
tournament — rather than streaming chunks. The closest thing to streaming is
`scripts/world/structure_visibility_range.gd` (distance-based culling).

Sibling/child subsystem nodes instanced into `meadows_playground.tscn`:
`WorldAudio` (`scripts/audio/world_audio.gd`), `CombatManager`
(`combat_manager.gd`, 1,922), `EncounterDirector` (`encounter_director.gd`,
2,207 — wild spawn/trigger decisions), `CameraRig` (SpringArm3D-based,
shared with `player.tscn`), `SequenceDirector` (`sequence_director.gd`,
1,404 — story-beat/dialogue-effect interpreter), `InteractionArbiter`,
`RidingController` (mountable creatures), `WorldLook` (shared
look/aim-direction utility), `WorldWeather`.

Other top-level scenes (12 `.tscn` total under `scenes/`): `title_screen.tscn`,
`boot.tscn` (headless boot smoke probe), `player.tscn`, `creature.tscn`
(deliberately scriptless — behavior attached at spawn time by
`encounter_director.gd`), `combat_hud.tscn`, `orb.tscn` (thrown capture
projectile), `playground_hud.tscn`, `game_menu.tscn`, `dialogue_panel.tscn`,
`name_prompt.tscn`, `starter_picker.tscn`.

**Gap in this inventory:** the `[ext_resource]`/`instance=` scene-nesting
graph was traced only via script attachments, not full resource-graph parsing.

---

## 4. Directory map

```
res://
  autoload/     6 files, 3,092 lines — Game + 5 composed modules (§2)
  scenes/       12 .tscn — title, boot, world, player, creature, combat, UI (§3)
  scripts/      audio(2,1160) boot(2,163) build(13,3261) characters(3,1296)
                combat(15,8100) creatures(19,4912) data(1,141 — band_content.gd, D54)
                debug(1,863 — test/tools only) npc(1,138) player(7,2383)
                save(1,974) story(4,2131) trade(2,399)
                ui(34,21521 — largest by file count)
                world(78,43040 — largest by line count: terrain, vegetation,
                region content, village/NPC, farming, day/weather)
  data/         config/ (~49 files + bands/<1..5>/, all tunables), creatures/,
                dialogue/ (+ bands/), items/, moves/, progression/, recipes/,
                scatter/playground/ (256 baked .bin), spawns/ (empty — moved
                to config/), terrain/playground/ (45 baked .res/.tres), traits/
  assets/       characters/, creatures/tetherbound/<species>/models/, etc.
  shaders/
  addons/       terrain_3d/ — Terrain3D 1.0.2 (D05), the one addon
  tests/        432 files (248 test_*.gd, 180 smoke_*.gd), fixtures/, helpers/
  tools/        972 files — capture/bake/CI/art-pipeline scripts, not shipped
  project.godot
```

No duplicate/competing system was found for inventory, camera,
build/placement, or region loading — each concern has exactly one
implementation.

---

## 5. Data-driven config rule

Tunable values live in `data/config/` (CLAUDE.md rule 8), never hardcoded in
gameplay scripts — ~49 top-level JSON files covering terrain, combat,
weather, tournament, trade, farm, harvest, catching, the type chart, vitals,
performance, palette, menu, movement, and audio, plus `bands/` (§6). The
pause menu itself is described in `data/config/menu.json` (D14) — tab list,
actions, grid columns, footer legend are all data; adding a screen is a JSON
entry plus a script extending `scripts/ui/menu_tab.gd`, never an edit to the
shell. `tests/test_menu_data.gd` fails the build if a tab points at a
missing script, an action isn't in the input map, or a build cost names a
nonexistent item.

---

## 6. Band-merged content configs (D54)

Five agents can author the Meadows corridor concurrently because per-band
content is split into **one directory per band**, not one file per config:

```
data/config/spawns.json                              ← globals only (respawn_seconds, roles)
data/config/bands/band1_lower_meadows/spawns.json    ← Band 1's positional entries
data/config/bands/band2_stone_and_root/spawns.json   ← ... band3/band4/band5 the same
```

Same pattern for `props.json`, `harvest.json`, `trainers.json`. A band's
ownership is one path (`data/config/bands/band3_the_river_lock/`), so a lane
brief names one directory and that is the entire exclusion — per-config
sharding would have made it four separate collision surfaces per lane.

Every positional entry carries an authored `order` integer; the merge sorts
by `order`, not array index or band order — `encounter_director.gd` seeds
each spawn cluster's scatter/level/IV/trait/shiny rolls from `order`
(falling back to index if absent), so `order` is a stable identity that
survives another band's entries being appended. `scripts/data/band_content.gd`
(141 lines) is the loader; `BANDS` is a literal 5-id list, not a directory
scan, so a stray/half-finished directory can never silently load as canon.
`tests/test_band_content.gd` pins the merged output against frozen
pre-split baselines.

`data/config/vegetation.json` is deliberately **not** band-split — it holds
scatter rules, not placements, and there's nothing per-band to own.

---

## 7. Terrain and scatter bake pipeline

- **Terrain3D 1.0.2** (`addons/terrain_3d/`, MIT, D05) owns height, shape and
  ground materials. Terrain is **authored macro geography**, not runtime
  procedural generation. The one Meadows region ("playground") is baked to
  `data/terrain/playground/` (45 `.res`/`.tres` files) via
  `godot --headless --path . --script scripts/world/build_playground_terrain.gd`
  (930 lines), driven by `scripts/world/playground_heightfield.gd` (1,800
  lines, height as a pure function of position — testable, re-bakeable at
  any resolution).
- Vegetation/scatter: procedural PLACEMENT RULES
  (`scripts/world/scatter_rules.gd`, 1,572 lines; `data/config/vegetation.json`
  + per-band `bands/<band>/vegetation.json`) produce a **baked, cached
  output** (`data/scatter/playground/region_*.bin`, 256 files), not
  live-recomputed every boot. Bake entry point:
  `scripts/world/bake_playground_scatter.gd` (64 lines).
- **Freshness guard.** A stale bake against `vegetation.json`/
  `terrain_playground.json` causes a 5-8 minute live-recompute stall on every
  New Game/load — a real owner-reported regression. `scatter_bake.gd::is_fresh()`
  checks a fingerprint, asserted by `tests/test_playground_bake_is_committed_and_fresh`
  and by CI's own dedicated `verify-scatter-bake-freshness` job — added
  because the same assertion once sat red inside a 40-file unit shard,
  undetected, while every following commit was docs-only and skipped the
  code jobs entirely.
- **Rebaking mid-session does not reach a capture until re-imported.** A
  `--script` capture loads the imported form from `.godot/`; run
  `godot --headless --path . --import` before capturing, or the frames come
  back pixel-identical to the pre-change asset.
- **Never raycast for ground height (D09).** Ask the terrain first —
  `playground_world.ground_height_at(x, z)` — and fall back to a raycast
  only for surfaces the terrain doesn't know about (props, structures).
  Roughly a quarter of downward rays against Terrain3D's heightmap collision
  silently miss where the ground is unquestionably present; `move_and_slide`'s
  shape casts don't share this bug.

---

## 8. Save format

- `scripts/save/save_game.gd` (974 lines), a plain `RefCounted` (no node, no
  scene), testable headlessly (D27). `VERSION = 16` (as of the
  bond-milestone-ladder migration, D70; 16 migration steps recorded in the
  file's own version-history comments).
- **Storage:** `user://saves/`, one JSON file per slot. `SLOT_COUNT = 5`
  (`AUTOSAVE_SLOT = 0`); slots 1-4 reached through the pause menu's Save tab.
- **Never fatal on load** — a missing, corrupt, or newer-than-this-build
  save leaves the game untouched rather than guessing.
- **Serialized:** party (individuality rolls, traits, shiny), full
  inventory/hotbar including empty slots (slot position is player-visible
  state), progression flags, satiety, map fog/database, death satchels
  (multiple persist, per the hard rule), placed buildings, felled
  vegetation, farm-plot/bed state, player pose, world seed, bond milestones.
- **Autosave:** `Game._tick_autosave()` (game_state.gd:566) fires into slot 0
  on an interval and on rest/camp actions.
- **Deliberately not persisted:** storage-container contents (a placed
  chest's inventory isn't linked back to its registry entry); auto-load on
  boot (opt-in only — CI's smoke tests share a `user://` directory and an
  auto-loading save would cross-contaminate unrelated test scenes).
- Tests: `tests/test_save_format.gd`, `tests/smoke_save_persistence.gd`,
  `tests/test_autosave_fallback.gd`.

---

## 9. Input contexts and controller-first mapping

- `project.godot`'s `[input]` block defines every action with **both** a
  keyboard/mouse binding **and** a joypad binding — controller is the
  primary input, keyboard the fallback (move/look/jump/sprint/interact/
  inventory/map/hotbar/combat/build/backpack/menu/torch actions, all checked).
- `project.godot` **is the defaults and is never written to** at runtime —
  the settings screen snapshots the input map at boot and layers the
  player's rebinds on top, so a default changed later still reaches players
  with an existing settings file.
- `data/config/input_contexts.json` holds additional context-sensitive
  mapping data.
- **A known default-binding clash, by design:** `menu_cancel` and
  `combat_run` both default to Escape / gamepad B. The pause menu refuses to
  open mid-fight by default; `inventory` (I/Y) is the way in that never
  conflicts. Either binding is movable via Settings > Controls.

### The `input_owner` group contract (softlock prevention)

`scripts/ui/input_owner.gd` is a shared static-method group contract, not a
single global "menu open" boolean. Any panel that should own input joins the
Godot group `&"input_owner"`; world-verb pollers (movement, hotbar,
interaction) call `INPUT_OWNER.current(get_tree())` and refuse to act if a
node in that group reports itself open (`player_controller.gd:217`). Most
panels (`craft_panel.gd`, `storage_panel.gd`, `swap_panel.gd`,
`game_menu.gd`, `creature_bed_panel.gd`, `shop_panel.gd`) also pause
`get_tree()` while open, which alone stops world pollers since
`PlaygroundHUD` inherits `PROCESS_MODE_PAUSABLE`; every cursor-driven panel
stores `_mouse_before` on open and restores `MOUSE_MODE_CAPTURED` on every
close path. `build_menu.gd` is the one deliberate non-pauser ("Valheim
feel"), and is exactly where a real softlock leak was found and fixed: a
d-pad press on the same physical button as `hotbar_2`/etc. both selected a
build piece and ate a satchel item, because the HUD kept polling underneath
the live-but-non-pausing menu — `input_owner.gd`'s `current()` gate exists
specifically to close this (owner report OW10). `suppress_pause_reopen()`
separately guards against a controller B press that closes one panel from
also re-opening the pause shell on the same edge.

**A new panel that doesn't join `input_owner` or doesn't restore mouse mode
on every exit path reproduces the same bug class.** No such gap was found in
this pass, but every panel's every early-return/error exit path was not
individually traced.

---

## 10. Test harness

- **Location:** `tests/run_tests.gd` (headless `SceneTree` script), plus
  `tests/test_case.gd`. Discovers every `test_*.gd` under `res://tests/`,
  runs every method starting with `test_`, exits non-zero on any failure.
  432 files total: 248 `test_*.gd` (pure-logic unit tests — damage/catch
  formulas, stat growth, party rules, save round-trips, per D02's scope),
  180 `smoke_*.gd` (broader scene/system checks).
- **Basic invocation:** `godot --headless --path . --script tests/run_tests.gd`
- **Sharding:** `-- --shard=I/N` runs the Ith of N round-robin (not
  contiguous) slices of the discovered file list — round-robin because the
  suite's cost isn't evenly spread alphabetically (`test_veg_corridor.gd`,
  the historically most expensive file, sorts last).
- **`--only=` selector:** comma-separated substring selectors, e.g.
  `-- --only=veg_corridor`, or `-- --only=test_veg_corridor.gd::test_specific_case`
  to narrow to a method too. A selector matching no file is a hard error
  (exit code 2), so a typo can't silently run (and pass) the whole suite.
- `--only` and `--shard` compose: `--only` filters first, then `--shard`
  slices what's left.
- No GUT — `add_repo` refuses cross-owner GitHub adds and `bitwes/Gut` isn't
  under the owner's account (D02). The harness is ~130 lines.

---

## 11. CI shape

`.github/workflows/ci.yml`. Three checks, in the order they catch things:
project imports clean, tests pass, the Windows export actually builds.
Reworked 2026-09-01 (owner: "having one hour CIs is unacceptable") from 57
executed jobs down to ~15 — job COUNT was the real cost, not per-job runtime
(measured: 10,187s of actual work across 57 jobs, but 45m46s wall clock,
almost entirely GitHub's account-wide concurrent-runner queue wait). Six
jobs that fanned into 43 per-smoke-test jobs now run those tests as
sequential steps inside one job each.

**Jobs** (dependency order): `changes` (always runs, unconditionally
succeeds — see below) → `verify-scatter-bake-freshness`, `verify-unit-tests`
(4 shards), `verify-veg-corridor`, `verify-scatter-rules`, `verify-harvest`,
`verify-core-verb-shard`, `verify-gate-a-ui-build-shard`,
`verify-combat-shard`, `verify-regions-shard`, `verify-owner-regressions-shard`,
`verify-gate-evidence-shard`, `verify-continuous-core-known-red` → `export`
(only on `main`, needs every `verify-*` job green).

**The `changes`/docs-only skip, and its traps:**

Every `verify-*` job is conditioned on `needs.changes.outputs.code == 'true'`.
`changes` always runs unconditionally, so the run always has at least one
executed job and concludes `success` (a run where every job skips concludes
`skipped`, which `ralph-merge.yml`'s trigger would refuse). **Do not add
`paths-ignore: ['**.md']` to the push trigger** — for `push` events a
non-matching filter means GitHub creates NO run at all, no `workflow_run`
event, and `ralph-merge.yml` triggers on exactly that: a doc-only branch
would never merge or even be deletable. No-build paths: markdown anywhere,
plus `site/`, `docs/`, `ralph/`, `.claude/`; a `.json` under `data/` or a
workflow file still triggers the full build.

Two traps already paid for: diffing against `github.event.before` (fixed
2026-09-02) let a branch that pushed code, then pushed a docs-only
bookkeeping commit, get every verify job SKIPPED on the second push with a
green "success" — fixed by diffing against the merge-base with `origin/main`
for non-`main` pushes. And `grep -q` under `pipefail` exits on first match,
SIGPIPEs the upstream `printf`, and makes `pipefail` report the whole
pipeline FAILED even though the match succeeded — flipping a 767-file
non-doc diff into "documentation only, skipping the build" and nearly
shipping an untested consolidation; fixed by capturing filtered lines to a
variable first. Fail-safe: an empty diff builds rather than silently shipping.

**Export job:** runs only on `main` after every `verify-*` job. Caches the
Godot editor binary/export templates (1.2 GB) and the `.godot` import cache.
Two import passes — "cold" (tolerates a known cold-registration abort) then
"verify" (must succeed).

---

## 12. Capture/render invocation rules

**`--headless` combined with `--rendering-driver opengl3` hangs forever** —
verified on a bare scene: the process prints its first line and sits
silently until killed, no error, no crash. This is the single most
expensive trap recorded in `docs/AGENT_WORKFLOW.md`; it cost multiple
abandoned capture attempts (one 43 minutes) before being root-caused.

**Correct invocation for any capture:**

```
xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path . \
  --rendering-driver opengl3 --resolution 1280x800 --script tools/<capture>.gd
```

`--headless` remains correct (and fast) for **tests**, which render
nothing — it is specifically `--headless` plus a real rendering driver that
hangs.

**Hung captures leave zombie processes.** Before pruning a worktree, check
for orphaned processes pinned to a deleted directory:
`for pid in $(pgrep -f "godot --headless"); do echo "$pid $(readlink /proc/$pid/cwd)"; done`
— `kill -9` anything whose cwd reads `(deleted)`.

**A fresh container has no `.godot/` import cache.** Run
`godot --headless --path . --import` once before any script-driven capture —
without it, viewpoints silently render flat/empty rather than erroring.

**`tools/capture_diag_minimal.gd`** is a 120-second smoke test for this
invocation shape — if it can't write a PNG, fix the invocation before
blaming the capture script, scene, or box.

---

## 13. Performance budget summary

`docs/specs/PERFORMANCE_BUDGET.md` (T1-PERF, 2026-08-30) derives a budget from
three checkable things: numbers measured on the live tree, `project.godot`'s
committed render settings, and Godot 4.7 Compatibility's documented
behaviour — explicitly **not** a ROG Ally frame-rate guarantee, since no
container in this project has the actual hardware.

- **Headline number:** the Meadows Hall must build to **≤ 4,000 draw calls**
  at the `hall_approach` camera stand (baseline 2,743 draw calls / 23.70M
  primitives / 3,069 objects; one free geometry fix — skipping redundant
  keep-chamber parapets hidden behind a neighboring chamber's wall — took
  it to 2,665).
- **Light budget:** ≤ 4 shadow-casting Omni/Spot lights reaching any one
  location (a conservative slice of the shared 2048² shadow atlas).
  Interior lights are budgeted per-design instead (e.g. the Hall's own 12,
  measured against finale readability).
- **Scatter density:** under Compatibility, draw calls track MultiMesh
  batches in the frustum, not instances inside them, so raising density
  inside an existing batch is nearly free in draw-call terms and is bounded
  by GPU throughput instead, which no container can measure. Measured local
  density swings 17.7 to 1,168.9 placements/ha across seven authored
  locations — deliberate clumping, so **no single per-hectare ceiling is
  set**.
- **What still needs the real device:** actual frame time / GPU throughput.
  This document states structural ceilings that are hardware-independent in
  shape and names on-device tests to close the rest.

Render-side reproduction never uses `--headless` with a rendering driver
(§12); structural/CPU-side measurements correctly do use `--headless`.

---

## 14. Largest files — candidates for future splitting

From a full `wc -l` pass across `scripts/` and `autoload/` (9 files exceed
1,500 lines):

| File | Lines | What it holds |
|---|---|---|
| `scripts/world/stronghold.gd` | 4,847 | Team Tether stronghold: occupation state, structures, triggers |
| `scripts/ui/playground_hud.gd` | 3,904 | Top-level in-world HUD: hotbar, tab routing, prompts, vitals |
| `scripts/world/burrow_warrens.gd` | 3,327 | Meadows dungeon sub-region, own chamber/connection graph |
| `scripts/ui/tab_backpack.gd` | 2,303 | Backpack/inventory UI tab |
| `scripts/combat/encounter_director.gd` | 2,207 | Decides when/where wild encounters trigger, spawns `creature.tscn` |
| `scripts/world/grass_field.gd` | 1,980 | Grass rendering/interaction field |
| `scripts/world/vegetation.gd` | 1,967 | Vegetation placement/harvest runtime |
| `scripts/combat/combat_manager.gd` | 1,922 | Core real-time combat loop |
| `scripts/world/water.gd` | 1,909 | Water body rendering/logic |

The task brief's five named candidates are exactly the top five above by
line count; the remaining four (also over 1,500 lines) are listed for
completeness. No dead code or duplicate system was found among them — each
is large because its region/system is large, not because it duplicates
another file's job.

---

## 15. Addon

One addon: `addons/terrain_3d/` — Terrain3D 1.0.2 (D05), a native
GDExtension terrain system, MIT license, trimmed to Windows x86_64 + Linux
x86_64 binaries only (dropping Android/iOS/macOS/Web halves the committed
size). Confirmed in active use across 10 runtime scripts including
`scripts/creatures/creature_body.gd`, `scripts/creatures/wild_creature.gd`,
several `scripts/combat/*.gd` files, and `scripts/world/{trainer_npc,world_look}.gd`.
Backs the baked terrain (§7) and scatter (§7) data.

Two Terrain3D-specific engine gotchas recorded in D05, both cost real time
once each: `data_directory` must be assigned after the node is in the tree
and a frame has passed (setting it earlier leaves `data` permanently null
with no error, and the player stands on empty space that looks like it's
working); and the first import on a clean checkout exits non-zero due to the
extension's cold class-registration behavior on shutdown — CI tolerates the
first import pass and gates on the second (§11).
