# Tetherbound — Technical

**What this is.** Where the code lives, how it is shaped, how to build, test,
capture and ship. It replaces `TECHNICAL_ARCHITECTURE.md`,
`GAMEPLAY_SYSTEMS.md`, `specs/PERFORMANCE_BUDGET.md`, the multiplayer spec set
and the art-pipeline docs.

Design intent lives in `GAME_BIBLE.md`. Process lives in `WORKFLOW.md`. This is
the map.

---

# 1. Engine and renderer

- **Godot 4.7-stable, GDScript only.** `config/features` reads
  `PackedStringArray("4.7", "GL Compatibility")`.
- **Renderer: Compatibility (`gl_compatibility`)**, at `project.godot:72`.
  Reversed from an original Forward+ choice after the owner reproduced a hard
  freeze on the shipped Windows build twice, root-caused to a Vulkan
  present/pipeline-compile deadlock specific to the ROG Ally's GPU and driver.
  Compatibility sidesteps Vulkan (GLES3) and matches the renderer every CI and
  visual-judge capture already uses.
  **Cost paid knowingly:** no real directional shadows, no SDFGI, no volumetric
  fog, no SSR — all Forward+-only. **Do not switch back without new on-device
  evidence.**
- Authored at 1920×1080 with `canvas_items` stretch — the ROG Ally's native
  panel resolution.
- Windows x86_64 is the primary export target. Linux x86_64 is kept for headless
  development and CI.
- **One addon:** `addons/terrain_3d/` — Terrain3D 1.0.2, MIT, trimmed to Windows
  and Linux x86_64 binaries only.

---

# 2. The single autoload

Exactly one registered autoload, and it is meant to stay the only one:

```
Game="*res://autoload/game_state.gd"
```

`game_state.gd` owns the party, the satchel/day counter, and everything that
outlives the scene tree, and stands up the pause menu on `_ready()` so the menu
exists in every scene without being hand-instanced. It `preload()`s five other
files under `autoload/` as **composed `RefCounted` modules**, not autoloads —
deliberate, so pure logic stays testable headlessly and separate from the one
thing holding live references.

| Module | Lines | Role |
|---|---|---|
| `autoload/game_state.gd` | 1,548 | root singleton: party, satchel/day, pause menu |
| `autoload/map_state.gd` | 707 | region/map state, fog-of-war, one region contract |
| `autoload/inventory.gd` | 377 | 24 slots + 6-slot hotbar |
| `autoload/party.gd` | 211 | `const MAX_CREATURES := 5`, enforced in `add()` |
| `autoload/item_db.gd` | 170 | item database accessor |
| `autoload/progression_state.gd` | 79 | progression/objective flags |

Everything is reached through `Game.*`. **No reserve/box/PC script exists
anywhere** — confirmed by repo-wide search, matching the hard rule. For
multiplayer, `WorldState` and `PlayerState` live behind `Game` rather than
becoming new autoloads.

---

# 3. Scenes

`run/main_scene` is `scenes/ui/title_screen.tscn`. New Game and Load Game both
end by changing to `scenes/world/meadows_playground.tscn` — **the entire Meadows
is one continuous open-world scene**, not a set of discretely loaded regions.

Its root script `scripts/world/playground_world.gd` (1,640 lines) builds the
world procedurally in one `_ready()` pass: terrain, water, settlement,
vegetation, per-band content, stronghold, tournament. The closest thing to
streaming is `scripts/world/structure_visibility_range.gd` (distance culling).

Subsystem nodes instanced into the world scene: `WorldAudio`, `CombatManager`,
`EncounterDirector`, `CameraRig` (SpringArm3D, shared with `player.tscn`),
`SequenceDirector` (story-beat/dialogue-effect interpreter),
`InteractionArbiter`, `RidingController`, `WorldLook`, `WorldWeather`.

12 `.tscn` files total: `title_screen`, `boot` (headless boot smoke),
`meadows_playground`, `cloudreach_cliffs`, `player`, `creature` (deliberately
scriptless — behaviour attached at spawn time by `encounter_director.gd`),
`combat_hud`, `orb`, `playground_hud`, `game_menu`, `dialogue_panel`,
`name_prompt`, `starter_picker`.

---

# 4. Directory map

```
res://
  autoload/   6 files, 3,092 lines — Game + 5 composed modules (§2)
  scenes/     12 .tscn (§3)
  scripts/    audio(2) boot(2) build(13) characters(3) combat(15)
              creatures(19) data(1 — band_content.gd) debug(1, tools only)
              npc(1) player(7) save(1) story(4) trade(2)
              ui(34, ~21.5k lines — most files)
              world(78, ~43k lines — most lines)
  data/       config/ (~49 files + bands/<1..5>/), creatures/, dialogue/
              (+ bands/), items/, moves/, progression/, recipes/,
              scatter/playground/ (256 baked .bin),
              terrain/playground/ (45 baked .res/.tres), traits/
  assets/     characters/, creatures/tetherbound/<species>/models/, environment/
  shaders/
  addons/     terrain_3d/
  tests/      432 files (248 test_*.gd, 180 smoke_*.gd), fixtures/, helpers/
  tools/      capture/bake/CI/art-pipeline scripts, not shipped
  docs/       the six live documents + reference art
  archive/    history. Do not cold-read.
```

**No duplicate or competing system exists** for inventory, camera,
build/placement, or region loading — each concern has exactly one
implementation. Keep it that way.

---

# 5. The data-driven config rule

**Tunable values live in `data/config/`, never hardcoded in gameplay scripts.**
~49 top-level JSON files cover terrain, combat, weather, tournament, trade,
farm, harvest, catching, the type chart, vitals, performance, palette, menu,
movement and audio.

Even the pause menu is data: `data/config/menu.json` defines the tab list,
actions, grid columns and footer legend. Adding a screen is a JSON entry plus a
script extending `scripts/ui/menu_tab.gd` — never an edit to the shell.
`tests/test_menu_data.gd` fails the build if a tab points at a missing script,
an action isn't in the input map, or a build cost names a nonexistent item.

## 5.1 Band-merged content configs

Several agents can author the Meadows corridor concurrently because content is
split **one directory per band**, not one file per config:

```
data/config/spawns.json                             ← globals only
data/config/bands/band1_lower_meadows/spawns.json   ← band 1's positional entries
data/config/bands/band2_stone_and_root/spawns.json  ← …and so on to band5
```

Same pattern for `props.json`, `harvest.json`, `trainers.json`, `pickups.json`,
`vegetation.json`. A band's ownership is **one path**, so a lane brief names one
directory and that is the entire exclusion.

Every positional entry carries an authored `order` integer. The merge sorts by
`order`, not array index — `encounter_director.gd` seeds each spawn cluster's
scatter/level/IV/trait/shiny rolls from `order`, so it is a **stable identity**
that survives another band's entries being appended. `scripts/data/band_content.gd`
is the loader; `BANDS` is a literal 5-id list, not a directory scan, so a stray
or half-finished directory can never silently load as canon.
`tests/test_band_content.gd` pins merged output against frozen baselines.

`data/config/vegetation.json` is deliberately **not** band-split — it holds
scatter rules, not placements.

---

# 6. Terrain and scatter bake pipeline

- **Terrain is authored macro geography, not runtime generation.** Terrain3D
  owns height, shape and ground materials. The Meadows region ("playground") is
  baked to `data/terrain/playground/` (45 files) via
  `godot --headless --path . --script scripts/world/build_playground_terrain.gd`,
  driven by `playground_heightfield.gd` (height as a pure function of position —
  testable, re-bakeable at any resolution).
- **Vegetation is procedural rules with baked output.** Rules:
  `scripts/world/scatter_rules.gd` + `data/config/vegetation.json` + per-band
  `vegetation.json`. Output: `data/scatter/playground/region_*.bin` (256 files),
  **not** recomputed every boot. Bake entry:
  `scripts/world/bake_playground_scatter.gd`.
- **Any change to scatter rules, `vegetation.json`, or a band's
  `vegetation.json` requires re-running the bake and committing the `.bin`
  files.** CI's `verify-scatter-bake-freshness` job fails the build otherwise,
  and a stale bake causes a 5–8 minute live-recompute stall on every New Game or
  load — a real owner-reported regression.
- **Rebaking mid-session does not reach a capture until re-imported.** A
  `--script` capture loads the imported form from `.godot/`. Run
  `godot --headless --path . --import` before capturing, or frames come back
  pixel-identical to the pre-change asset.
- **Never raycast for ground height.** Ask the terrain first —
  `playground_world.ground_height_at(x, z)` — and fall back to a raycast only
  for surfaces the terrain doesn't know about (props, structures). Roughly a
  quarter of downward rays against Terrain3D's heightmap collision silently miss
  where the ground is unquestionably present. `move_and_slide`'s shape casts
  don't share this bug.
- **Cloudreach does not use Terrain3D.** It uses procedural stacked cliff meshes
  in `scenes/world/cloudreach_cliffs.tscn` with the same Meadows surface
  textures and procedural grass/flower family.

---

# 7. Systems map

Where each system lives, what tunes it, and what tests it.

| System | Scripts | Data | Tests |
|---|---|---|---|
| Movement / camera | `player/player_controller.gd`, `player/camera_rig.gd`, `player/player_vitals.gd` | `config/movement.json` | world-boot smokes |
| Interaction | `world/interaction_arbiter.gd`, `prompt_arbiter.gd`, `interactable.gd`, `ui/input_owner.gd` | — | see §9 |
| Dialogue | `ui/dialogue_panel.gd`, `dialogue_runner.gd`, `story/sequence_director.gd` | `data/dialogue/*` + `bands/` | `test_dialogue_runner`, `test_band_dialogue` |
| Objectives | `world/quest_log.gd`; `Game.set_objective()` | `progression/objectives.json` | `test_quest_log` |
| Wild encounters | `combat/encounter_director.gd` (2,207), `combat/spawn_tables.gd` | `bands/*/spawns.json` | `test_spawn_tables`, `test_spawns_data` |
| Combat | `combat/combat_manager.gd` (1,922), `combat_ai`, `combat_math`, `type_chart`, `combat_arena`, `move_projectile`, `target_marker`, `telegraph_glow`, `impact_flash` | `config/combat.json`, `type_chart.json` | `test_combat_math`, `test_combat_ai`, `test_combat_progression`, `test_combat_stagger`, `test_combat_wind`, `test_combat_burst`, `smoke_combat*` |
| Catching | `combat/catch_math.gd`, `orb.gd`, `throw_aim.gd`, `throw_preview.gd` | `config/catching.json` | `test_catch_math`, `smoke_catching`, `smoke_catch_aim_slowdown` |
| Party | `autoload/party.gd` | — | `test_party`, `smoke_hud_no_sixth_slot`, `smoke_party_count_after_catches` |
| Care / rest / bond | `world/night_rest.gd`, `ui/creature_bed_panel.gd`, `world/meadow_healing.gd`, `rest_point.gd`, `creatures/bond_milestones.gd` | `config/bond_milestones.json`, `creature_condition.json`, `meadow_healing.json` | save-format coverage |
| Companion presence | `creatures/companion_presence.gd`, `follower_creature.gd` | `config/companion_presence.json` | `test_companion_presence` (26) |
| Satiety | `player/player_vitals.gd` (`tick_satiety`) | `config/vitals.json` | — (no death logic exists) |
| Progression | `creatures/progression.gd`, `progression_feed.gd`, `chapter_curve.gd` | `config/progression.json`, `chapter_curve.json` | `test_chapter_curve`, `test_progression_feed` |
| Moves / traits / evolution | `creatures/move_db.gd`, `trait_db.gd`, `evolution.gd` | `moves/moves.json`, `tms.json`, `traits/traits.json`, `creatures/species.json` | `test_evolution`, `smoke_evolution`, `test_evolution_links` |
| Creature bodies | `creatures/creature_body.gd` (1,549), `wild_creature`, `creature_instance`, `creature_animator`, `creature_visual`, `creature_condition`, `follower_creature`, `alpha_aura` | `creatures/species.json`, `aspect_variants.json`, `shiny_colourways.json` | `smoke_art` |
| Trainers | `world/trainer_npc.gd` | `bands/*/trainers.json`, `config/trainers.json` | `test_trainers_data` (no >4-level jump; nothing out-levels the boss) |
| Team Tether | `world/tether_relay.gd` (1,728), `tether_sigil.gd`, `severed_spokes.gd` (1,253), `rift_collapse.gd` | `config/tether_relay.json`, `relay_site.json` | world/band smokes |
| Warden / climax | `world/stronghold.gd` (4,847), `stronghold_climax.gd` | `config/stronghold.json`, `stronghold_climax.json` | world smokes |
| Tournament | `world/tournament.gd` | `config/tournament.json` | `test_tournament`, `smoke_tournament_bracket`, `smoke_tournament_consent` |
| Gathering | `world/harvest_node.gd`, `harvest_logic.gd`, `vegetation_harvest_point.gd`, `felled_resource.gd` | `bands/*/harvest.json` | world-build smokes |
| Inventory | `autoload/inventory.gd`, `ui/tab_backpack.gd` (2,303) | `items/items.json` | `test_inventory` |
| Crafting | `ui/craft_panel.gd` | `recipes/*.json` | `smoke_craft_panel_controller` |
| Building | `build/build_placer.gd` (1,123), `build_grid`, `build_snap_contract`, `build_piece`, `build_door`, `world/building_prefabs.gd`, `build/storage_container.gd`, `ui/build_menu.gd` | `items/buildables.json`, `config/building_prefabs.json` | `test_build_*`, `smoke_build_*`, `smoke_free_build` |
| Trade | `world/shop_interior.gd`, `ui/shop_panel.gd`, `trade/creature_trade.gd`, `trade_db.gd` | `config/trade.json` | `test_trade`, `smoke_village_trade` |
| Death satchel | `world/death_satchel.gd`, `player_death.gd` | — | `test_player_death` |
| Day/night, weather | `world/day_cycle.gd`, `world_weather.gd`, `world_look.gd` | `config/art.json`, `weather.json` | `test_day_cycle`, `test_day_cycle_night_contrast`, `test_world_weather` |
| Riding | `world/riding_controller.gd` | `creatures/species.json` `rideable` | `smoke_riding` |
| Map | `world/map_baker.gd`, `autoload/map_state.gd` (707), `ui/tab_map.gd` (1,123) | `config/map_landmarks.json` | `test_map_*` (8 files) |
| Save/load | `save/save_game.gd` (974) | `user://saves/` | `test_save_format`, `smoke_save_persistence`, `test_autosave_fallback` |
| HUD / menus | `ui/playground_hud.gd` (3,904), `tab_creatures.gd` (1,824), `tab_settings.gd`, `party_strip.gd`, `combat_hud.gd`, `game_menu.gd` | `config/menu.json` | `test_hud_widgets`, `smoke_hud_*`, `smoke_menu_*`, `test_menu_data` |

**Other systems present:** `world/farm_logic.gd` / `farm_plot.gd` (berry farm),
`world/burrow_warrens.gd` (3,327 — hand-built chamber graph),
`audio/world_audio.gd` + `audio_manager.gd` (6 buses: Master, Music, Ambience,
SFX, Creatures, UI), and the region set-piece scripts `old_quarry`, `river`,
`river_nest_clear`, `cart_repair`, `mill_crossing`, `south_bridge`,
`watchtower_landmark`, `torch_prop`, `pickup_glow`, `key_pickup`, `tm_pickup`,
`item_cache_pickup`, `item_gate`.

## 7.1 Known open technical item

**The clock has no memory.** `world_look.gd::_ready()` starts every world at
08:00 and nothing saves or restores it: `save_game.gd` has no clock key, a realm
crossing and Continue both rebuild the scene, and a rest snaps to morning by
design. Night sits at the far end of a 600-second day, so in normal play it is
often never reached at all. The fix is a `save_game.gd` / `game_state.gd`
change.

`is_dark()`'s window (`art.json` `dark_from_hour` / `dark_to_hour`, 22 → 3, 125
real seconds) is the true-dark semantic every torch, camp fill light and
creature emission floor switches on. It is **deliberately narrower** than the
visible dusk→night→dawn sweep; dusk and dawn are transitions and are not part of
it. Measured frame luma across the sweep, one camera: hour 8 = 114.5, 18 = 90.5,
20 = 77.0, 22 = 54.7, 0 = 29.5, 3 = 43.2.

---

# 8. Save format

- `scripts/save/save_game.gd`, a plain `RefCounted` — no node, no scene, so it
  is testable headlessly. `VERSION = 16`, with 16 migration steps recorded in
  the file's own version-history comments.
- **Storage:** `user://saves/`, one JSON file per slot. `SLOT_COUNT = 5`,
  `AUTOSAVE_SLOT = 0`; slots 1–4 are reached through the pause menu's Save tab.
- **Never fatal on load.** A missing, corrupt, or newer-than-this-build save
  leaves the game untouched rather than guessing.
- **Serialized:** party (individuality rolls, traits, shiny), full
  inventory/hotbar **including empty slots** (slot position is player-visible
  state), progression flags, satiety, map fog/database, death satchels (multiple
  persist), placed buildings, felled vegetation, farm-plot and bed state, player
  pose, world seed, bond milestones.
- **Autosave** fires into slot 0 on an interval and on rest/camp actions.
- **Deliberately not persisted:** storage-container contents (a placed chest's
  inventory isn't linked back to its registry entry), and auto-load on boot —
  opt-in only, because CI's smoke tests share a `user://` directory and an
  auto-loading save would cross-contaminate unrelated test scenes.
- For multiplayer, saves split into a **host-owned world file** and a
  **portable character file**. Realm-local poses, buildings and death satchels
  are tagged per realm so two worlds never share coordinates.

---

# 9. Input and the softlock guard

`project.godot`'s `[input]` block defines every action with **both** a keyboard
binding and a joypad binding. Controller is primary, keyboard the fallback. Every
defined action is referenced somewhere — no unused actions.

`project.godot` **is the defaults and is never written to at runtime.** The
settings screen snapshots the input map at boot and layers rebinds on top, so a
default changed later still reaches players with an existing settings file.

**A known default clash, by design:** `menu_cancel` and `combat_run` both
default to Escape / gamepad B. The pause menu refuses to open mid-fight by
default; `inventory` (I / Y) is the way in that never conflicts. Either binding
is movable in Settings → Controls.

## The `input_owner` group contract

`scripts/ui/input_owner.gd` is a shared static-method **group contract**, not a
global "menu open" boolean. Any panel that should own input joins the Godot
group `&"input_owner"`; world-verb pollers (movement, hotbar, interaction) call
`INPUT_OWNER.current(get_tree())` and refuse to act if a node in that group
reports itself open.

Most panels (`craft_panel`, `storage_panel`, `swap_panel`, `game_menu`,
`creature_bed_panel`, `shop_panel`) also pause `get_tree()` while open, which
alone stops world pollers since `PlaygroundHUD` inherits
`PROCESS_MODE_PAUSABLE`. Every cursor-driven panel stores `_mouse_before` on
open and restores `MOUSE_MODE_CAPTURED` on **every** close path.

`build_menu.gd` is the one deliberate non-pauser ("Valheim feel") and is exactly
where a real softlock leak was found: a d-pad press on the same physical button
as a hotbar slot both selected a build piece and ate a satchel item, because the
HUD kept polling underneath the live-but-non-pausing menu.
`suppress_pause_reopen()` separately guards a controller B press that closes one
panel from also re-opening the pause shell on the same input edge.

> **A new panel that doesn't join `input_owner`, or doesn't restore mouse mode
> on every exit path, reproduces this bug class.**

Multiplayer note: **menus never pause a multi-peer session** — the `input_owner`
gate, not the pause, is what stops world verbs there.

---

# 10. Multiplayer

- Transport is **Godot ENet on a listen server with two channels**.
- The **host simulates every non-player body** on the heightfield and is truth
  for the clock. Terrain collision must stay resident for separated peers, never
  only around their average position.
- Different biomes at once are **headless realm shells on the host**.
- **Each peer renders its own rig.** Bodies, chosen names and selected characters
  replicate.
- Catches, pickups, storage and trades are **host transactions with versions** —
  a repeated request or reconnect cannot duplicate an award or an item.
- **Sleep is a vote.** Downed precedes death, and a death satchel has an owner.
- Scaling is **composition-first**; rewards are per-participant, with an
  unscaled base kept on the director.
- **Every story flag has a declared scope**, and an undeclared one is a test
  failure.
- **Item trading is in; creature trading is out.**

---

# 11. Tests

- `tests/run_tests.gd` is a headless `SceneTree` script plus `tests/test_case.gd`.
  It discovers every `test_*.gd` under `res://tests/`, runs every method
  starting with `test_`, and exits non-zero on any failure. **432 files**: 248
  `test_*.gd` (pure logic — damage and catch formulas, stat growth, party rules,
  save round-trips) and 180 `smoke_*.gd` (broader scene and system checks).
- **Run:** `godot --headless --path . --script tests/run_tests.gd`
- **Shard:** `-- --shard=I/N` runs the Ith of N **round-robin** slices —
  round-robin because cost isn't evenly spread alphabetically.
- **Select:** `-- --only=veg_corridor`, or
  `-- --only=test_veg_corridor.gd::test_specific_case`. A selector matching no
  file is a hard error (exit 2), so a typo can't silently run and pass the whole
  suite. `--only` filters first, then `--shard` slices what's left.
- No GUT. The harness is ~130 lines.

---

# 12. CI

`.github/workflows/ci.yml`. Three things, in the order they catch problems: the
project imports clean, the tests pass, the Windows export actually builds.

Reworked from 57 executed jobs to ~15 after "having one hour CIs is
unacceptable" — **job count was the real cost**, not per-job runtime (10,187 s of
actual work across 57 jobs, but 45m46s wall clock, almost entirely GitHub's
account-wide runner queue). Six jobs that fanned into 43 per-smoke jobs now run
those tests as sequential steps inside one job each.

**Jobs, in dependency order:** `changes` → `verify-scatter-bake-freshness`,
`verify-unit-tests` (4 shards), `verify-veg-corridor`, `verify-scatter-rules`,
`verify-harvest`, `verify-core-verb-shard`, `verify-gate-a-ui-build-shard`,
`verify-combat-shard`, `verify-regions-shard`,
`verify-owner-regressions-shard`, `verify-gate-evidence-shard`,
`verify-continuous-core-known-red` → `export` (only on `main`, needs every
`verify-*` green).

## The docs-only skip and its traps

Every `verify-*` job is conditioned on `needs.changes.outputs.code == 'true'`.
`changes` always runs unconditionally, so a run always has at least one executed
job and concludes `success` — a run where every job skips concludes `skipped`,
which the merge workflow's trigger refuses.

> **Do not add `paths-ignore: ['**.md']` to the push trigger.** For `push`
> events a non-matching filter means GitHub creates **no run at all**, no
> `workflow_run` event, and a doc-only branch would never merge or even be
> deletable.

No-build paths: markdown anywhere, plus `site/`, `docs/`, `ralph/`, `.claude/`.
A `.json` under `data/` or a workflow file still triggers the full build.

**Two traps already paid for.** Diffing against `github.event.before` let a
branch that pushed code, then pushed a docs-only bookkeeping commit, get every
verify job skipped with a green "success" — fixed by diffing against the
merge-base with `origin/main` for non-`main` pushes. And `grep -q` under
`pipefail` exits on first match, SIGPIPEs the upstream `printf`, and makes
`pipefail` report the whole pipeline failed even though the match succeeded —
which flipped a 767-file non-doc diff into "documentation only, skipping the
build" and nearly shipped an untested consolidation. Fixed by capturing filtered
lines to a variable first. **Fail-safe: an empty diff builds** rather than
silently shipping.

**Export job:** runs only on `main` after every `verify-*`. Caches the Godot
binary and export templates (1.2 GB) and the `.godot` import cache. Two import
passes — "cold" (tolerates a known cold-registration abort) then "verify" (must
succeed).

A landed branch does **not** reliably publish a Windows build — `release.yml`
runs on human pushes to `main` and on explicit dispatch. Check the release asset
timestamp before telling the owner something is playable.

---

# 13. Capture and render invocation

> **`--headless` combined with `--rendering-driver opengl3` hangs forever.**
> Verified on a bare scene: the process prints its first line and sits silently
> until killed — no error, no crash. This is the single most expensive trap in
> the project's history; it cost multiple abandoned capture attempts, one of 43
> minutes, before being root-caused.

**Correct invocation for any capture:**

```
xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path . \
  --rendering-driver opengl3 --resolution 1280x800 --script tools/<capture>.gd
```

`--headless` remains correct and fast for **tests**, which render nothing.

- **A fresh container has no `.godot/` import cache.** Run
  `godot --headless --path . --import` once before any script-driven capture —
  without it, viewpoints silently render flat or empty rather than erroring.
- **Re-import after any asset or bake change**, or frames show the old asset.
- `tools/capture_diag_minimal.gd` is a 120-second smoke for this invocation
  shape. If it can't write a PNG, fix the invocation before blaming the capture
  script, the scene or the box.
- **Hung captures leave zombies.** Before pruning a worktree:
  `for pid in $(pgrep -f "godot --headless"); do echo "$pid $(readlink /proc/$pid/cwd)"; done`
  and `kill -9` anything whose cwd reads `(deleted)`.

---

# 14. Performance

The budget is derived from three checkable things: numbers measured on the live
tree, `project.godot`'s committed render settings, and Godot 4.7 Compatibility's
documented behaviour. It is explicitly **not** a ROG Ally frame-rate guarantee —
no development container has the hardware.

- **Headline:** the Meadows Hall must build to **≤ 4,000 draw calls** at the
  `hall_approach` camera stand. Baseline was 2,743 draws / 23.70M primitives /
  3,069 objects; one free geometry fix — skipping redundant keep-chamber
  parapets hidden behind a neighbouring chamber's wall — took it to 2,665.
- **Lights:** ≤ **4** shadow-casting Omni/Spot lights reaching any one location,
  a conservative slice of the shared 2048² shadow atlas. Interior lights are
  budgeted per-design instead (the Hall's own 12, measured against finale
  readability).
- **Scatter density:** under Compatibility, draw calls track MultiMesh **batches
  in the frustum**, not instances inside them, so raising density inside an
  existing batch is nearly free in draw-call terms and is bounded by GPU
  throughput instead — which no container can measure. Measured local density
  swings 17.7 to 1,168.9 placements/ha across seven authored locations, which is
  deliberate clumping, so **no single per-hectare ceiling is set**.
- **Perf proxy** (draws and primitives, not FPS): `tools/perf_render_stats.gd`.
  Provisional: `band1_open` ≤ 7,500 draws / 12.0M primitives; `hall_approach`
  ≤ 4,000 draws.
- **What still needs the real device:** actual frame time and GPU throughput.
  That is the owner's measurement on the Ally.

Render-side reproduction never uses `--headless` with a rendering driver;
structural and CPU-side measurements correctly do.

---

# 15. Large files

Nine files exceed 1,500 lines. None duplicates another's job — each is large
because its region or system is large. Listed as future split candidates, not as
defects:

| File | Lines |
|---|---|
| `scripts/world/stronghold.gd` | 4,847 |
| `scripts/ui/playground_hud.gd` | 3,904 |
| `scripts/world/burrow_warrens.gd` | 3,327 |
| `scripts/ui/tab_backpack.gd` | 2,303 |
| `scripts/combat/encounter_director.gd` | 2,207 |
| `scripts/world/grass_field.gd` | 1,980 |
| `scripts/world/vegetation.gd` | 1,967 |
| `scripts/combat/combat_manager.gd` | 1,922 |
| `scripts/world/water.gd` | 1,909 |
