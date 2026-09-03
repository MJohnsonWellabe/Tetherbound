# Tetherbound World and Content — Source of Truth

Status: consolidated reference, drafted from a code+data inventory pass
(read-only, no engine run). Covers world structure, the five Z-bands, the 12
landmarks, the village, major set pieces, the content tables, and the
scatter re-bake rule. See `GAMEPLAY_SYSTEMS.md` for how each system behaves;
this document is where things are and how much of each thing exists.

---

## 1. World structure

The Meadows is **one continuous scene**, not a set of discretely loaded
regions. Root scene: `scenes/world/meadows_playground.tscn`, driven by
`scripts/world/playground_world.gd` (1640 lines), which builds terrain,
water, settlement, vegetation, band harvest nodes, TMs, item caches, the
stronghold, and the tournament in a single `_ready()` pass.

- **Terrain**: Terrain3D plugin (`addons/terrain_3d/`, v1.0.2), authored
  heightfield data at `data/terrain/playground/terrain3d*.res` (45 region
  `.res` files), built/aligned by `scripts/world/build_playground_terrain.gd`,
  `scripts/world/playground_heightfield.gd`, and
  `scripts/world/terrain_region_alignment.gd`. This is authored terrain
  loaded at runtime, not noise-generated live.
- **Vegetation/scatter**: placement rules in `scripts/world/vegetation.gd`,
  `scripts/world/scatter_rules.gd`, executed offline by
  `scripts/world/scatter_bake.gd` / `scripts/world/bake_playground_scatter.gd`
  into pre-baked binary data at `data/scatter/playground/region_*.bin`
  (256 files). Rules come from `data/config/bands/<band>/vegetation.json`
  and `data/config/vegetation.json` / `data/config/grass_field.json`. This is
  a hybrid: procedural placement rules, cached/baked output — not
  regenerated every boot.
- **"Regions"** in this codebase mean Z-axis corridor **bands** (band1..band5),
  whose per-band JSON (spawns/harvest/props/trainers/vegetation under
  `data/config/bands/<band>/`) is merged at boot by
  `scripts/data/band_content.gd`. There is no scene-streaming/chunk loader;
  distance-based structure culling (`scripts/world/structure_visibility_range.gd`)
  is the closest thing to "streaming."
- Only one region exists in `data/terrain/` and `data/scatter/`: the
  Meadows/"playground." This matches the CLAUDE.md hard rule that no Biome 2
  exists until the Meadows exit gate passes.

## 2. The five Z-bands

Source: `data/config/chapter_curve.json` (`regions` array — authoritative
Z-corridor bounds and level bands).

| Band | z_to | wild level band | trainer levels | team size (enter/exit) | Landmarks in band (see §3) |
|---|---|---|---|---|---|
| band1_lower_meadows | 1360 | [2,6] | [2,7] | 3 / 8 | Grandpa's Village, The Pond, The Rise |
| band2_stone_and_root | 3180 | [6,8] | [9,14] | 8 / 10 | The Old Quarry, The Burrow Warrens |
| band3_the_river_lock | 4760 | [9,12] | [8,16] | 10 / 13 | The Tether Relay, The Long Water, The Stonewater Reach |
| band4_upper_meadows_ironwood | 7000 | [11,14] | [13,16] | 13 / 16 | The Ironwood Grove, The Highfield |
| band5_stronghold_approach | rest of map | [14,17] | [15,20] | 16 / 20 | The Ridgeline Watch, The Broken Tower, Meadows Hall/Stronghold |

Numeric detail lives in `docs/specs/MEADOWS_PROGRESSION_CURVE.md` and is read at
runtime by `scripts/creatures/chapter_curve.gd`, enforced by
`tests/test_chapter_curve.gd`, and measured by `tools/_probe_pacing.py`.
Band content (trainers/spawns/harvest) is cut per band and merged by
`scripts/data/band_content.gd` in file order (D54).

## 3. The 12 named landmarks

Source: `data/config/map_landmarks.json` (`regions`, world XZ centre +
radius, metres). 9 of these also carry a separate "landmark" key per the
inventory; treat the 12 below as the authoritative POI list.

| Landmark | Centre (X, Z) | Radius (m) |
|---|---|---|
| Grandpa's Village | 6, -22 | 60 |
| The Pond | -342, 507 | 55 |
| The Rise | 88, -43 | 55 |
| The Old Quarry | 403, 1794 | 62 |
| The Tether Relay | 348, 3756 | 48 |
| The Burrow Warrens | -357, 2610 | 45 |
| The Long Water | -150, 4200 | 52 |
| The Ironwood Grove | -345, 5060 | 60 |
| The Ridgeline Watch | -250, 6490 | 55 |
| The Broken Tower | 40, 6800 | 30 |
| The Stonewater Reach | -120, 3420 | 70 |
| The Highfield | 400, 5900 | 65 |

Map system: `scripts/world/map_baker.gd`, `autoload/map_state.gd` (fog-of-war
+ database, D33 — one map database), reveal_radius 80m, minimap_span_m 90m,
9 landmarks pre-revealed at game start (`data/config/map_landmarks.json`).

## 4. Grandpa's Village

- Files: `scripts/world/village.gd`, `scripts/world/village_npcs.gd`,
  `scripts/world/village_boundary.gd`, `scripts/world/village_door.gd`,
  `scripts/world/grandpa_house.gd`, `scripts/world/road_gate.gd`.
- Data: `data/config/village.json`, `data/config/village_npcs.json`
  (19 villagers), `data/config/npc_ranks.json` (4 ranks).
- Region: "grandpas_village," centred (6, -22), radius 60
  (`map_landmarks.json`). Built by `playground_world.gd:1052`
  (`village.call("build")`).
- Rule: D39 — the village economy.

### Village NPC roster (`data/config/village_npcs.json`)

| Name | Role (config_key) |
|---|---|
| Mira | villager_farmer (Meadow Keeper / goods merchant; also a trainer challenge) |
| Oskar | villager_keeper (Bridgehand / creature trader; also a trainer challenge) |
| Tam | villager_smith (Field Scout / blacksmith; also a trainer challenge) |
| Quarry Foreman | villager_quarryman |
| Sela | villager_ranger |
| Kell | villager_keeper |
| Bram | villager_keeper (innkeeper, goods vendor) |
| Halda | villager_ranger |
| Wilhelm | innkeeper |
| Corin | trader |
| Ada | craftsperson |
| Garrick | farmer |
| Old Perrin | local_historian |
| Tobin | lost_traveler |
| Maren | field_researcher |
| Sorrel | alpha_tracker |
| Lark | courier |
| Ren | former_tether_member |
| Rae | villager_farmer |

Vendors confirmed in `data/config/trade.json`: Mira (goods), Oskar
(creatures), Bram (goods).

## 5. Major set pieces

- **South Bridge** — Band 1 gate. Script: `scripts/world/south_bridge.gd`.
- **Old Quarry** — Band 2. Script: `scripts/world/old_quarry.gd`. Introduces
  Rootstone material tier.
- **Burrow Warrens** — Band 2 required dungeon. Script:
  `scripts/world/burrow_warrens.gd` (3327 lines — a hand-built
  interior/chamber graph, one of the largest scripts in the repo).
- **River / Mill Crossing** — Band 3. Scripts: `scripts/world/river.gd`,
  `scripts/world/river_nest_clear.gd`, `scripts/world/mill_crossing.gd`,
  `scripts/world/cart_repair.gd`. Rule: D46 — the river divides the map and
  costs one spoke; D56 — the crossing is open by height, not by a hole.
- **Tether Relay (mini-stronghold)** — Band 3. Scripts:
  `scripts/world/tether_relay.gd` (1728 lines), `tether_sigil.gd`,
  `severed_spokes.gd` (1253 lines), `rift_collapse.gd`. Data:
  `data/config/tether_relay.json`, `data/config/relay_site.json`,
  `data/dialogue/relay.json`. Rule: D49 — the machine is generated without
  its prisoner; D55 — a severed spoke may not block the road it is not
  severing.
- **Upper Meadows / Ironwood Grove** — Band 4. Introduces riding unlock and
  three Regional Captains (per `docs/specs/MEADOWS_PROGRESSION_SPEC.md` §3).
- **Stronghold / Meadows Hall / Warden / legendary chamber** — Band 5.
  Scripts: `scripts/world/stronghold.gd` (4847 lines, the largest world
  script — occupation state, structures, triggers),
  `scripts/world/stronghold_climax.gd` (658 lines — `_place_warden()`,
  `warden_body()`). Data: `data/config/stronghold.json` (`KEEP_CHAMBERS`
  includes `warden_arena` and `legendary_chamber`,
  `scripts/world/stronghold.gd:1350`), `data/config/stronghold_climax.json`.
  Built by `playground_world.gd:1509` (`_build_stronghold_climax()`).
  Note: `assets/characters/warden/warden_lod0.glb` is the already-rebuilt
  Warden model per CLAUDE.md — do not reopen historical "unmodelled"
  claims.

## 6. Content tables

| Content | Count | Source |
|---|---|---|
| Species | 25 | `data/creatures/species.json` `.species` |
| Evolution lines | 1 line, 2 branches (mudsnout → tuskroot / ashtusk, D71) | same file |
| Legendary | 1 (veridian) | same file |
| Moves | 48 | `data/moves/moves.json` `.moves` |
| TMs | 14 | `data/moves/tms.json` `.tms` |
| Items | 56 | `data/items/items.json` `.items` |
| Recipes | 16 (7 base + 5 rootstone + 4 ironwood) | `data/recipes/recipes*.json` |
| Build prefabs | 20 | `data/config/building_prefabs.json` `.prefabs` |
| Buildables | 11 | `data/items/buildables.json` `.buildables` |
| Traits | 8 | `data/traits/traits.json` `.traits` |
| Village NPCs | 19 | `data/config/village_npcs.json` `.villagers` |
| Dialogue conversations | 130 | summed across `data/dialogue/*.json` + `data/dialogue/bands/*.json` |
| Dialogue lines | 339 | same files |
| Objectives | 33 (27 main + 6 local) | `data/progression/objectives.json` |
| Trainers (field) | 29 (9+4+5+5+6 per band) | `data/config/bands/*/trainers.json` |
| Wild spawn-table entries | 283 (68+57+54+81+23 per band) | `data/config/bands/*/spawns.json` |
| Harvest/gathering nodes | 131 (40+26+31+26+8 per band) | `data/config/bands/*/harvest.json` |
| NPC ranks | 4 | `data/config/npc_ranks.json` `.ranks` |
| Tournament rounds | 3 | `data/config/tournament.json` `.rounds` |
| Landmarks/POIs | 12 | `data/config/map_landmarks.json` `.regions` |
| Regions/bands | 5 | `data/config/chapter_curve.json` `.regions` |
| Boss encounters | 1 (the Warden) | `stronghold_climax.gd` / `stronghold.json` `warden_arena` |
| Terrain region files | 45 `.res` | `data/terrain/playground/` |
| Baked vegetation scatter regions | 256 `.bin` | `data/scatter/playground/` |
| Shiny colourways | 10 | `data/creatures/shiny_colourways.json` |

## 7. Per-band content counts (from §6, broken out by band)

| Band | Trainers | Wild spawn entries | Harvest nodes |
|---|---|---|---|
| band1_lower_meadows | 9 | 68 | 40 |
| band2_stone_and_root | 4 | 57 | 26 |
| band3_the_river_lock | 5 | 54 | 31 |
| band4_upper_meadows_ironwood | 5 | 81 | 26 |
| band5_stronghold_approach | 6 | 23 | 8 |
| **Total** | **29** | **283** | **131** |

## 8. Scatter re-bake rule

Vegetation/prop placement is **baked**, not computed live. The rule that
must be followed whenever band content, terrain, or scatter rules change:

1. Rules live in `scripts/world/scatter_rules.gd` and per-band
   `data/config/bands/<band>/vegetation.json` /
   `data/config/vegetation.json` / `data/config/grass_field.json`.
2. The bake is run offline via
   `scripts/world/bake_playground_scatter.gd` (invoked directly with
   `godot --headless --script <path>`, per its own header comment — it is
   not called from anywhere else in-repo, which is expected for an offline
   CLI entry point, not dead code).
3. Output lands in `data/scatter/playground/region_*.bin` (256 files as of
   this inventory) and must be committed alongside the rule/data change that
   produced it.
4. CI enforces freshness: `.github/workflows/ci.yml` job
   `verify-scatter-bake-freshness` fails the build if the committed `.bin`
   output does not match what the current rules/data would produce — i.e. a
   stale bake is a CI failure, not a silent drift.
5. Terrain has the same authored-not-generated shape: baked via
   `scripts/world/build_playground_terrain.gd` into
   `data/terrain/playground/terrain3d*.res` (45 files).

Any change to `scripts/world/scatter_rules.gd`, `data/config/vegetation.json`,
or a band's `vegetation.json` requires re-running the bake and committing the
resulting `.bin` files before the CI freshness job will pass.

---

## 9. What must not change

Per CLAUDE.md hard rules, binding over any lower-level convenience:

- **Meadows-only.** No Biome 2 implementation until the Meadows passes its
  exit gate. Any reconnection view to a future biome is distant/non-enterable.
  Only one region's terrain/scatter data exists in the repo today — this is
  itself evidence the rule is being followed, not just documented.
- **No new creature meshes or Meshy generations for Meadows.** All 25
  species use installed creature meshes; differentiate with materials,
  textures, modest scale, animation, VFX, habitat, behavior, traits, and
  encounter context instead. Never spend a Meshy generation without
  owner-supplied reference art.
- **One nature family, one village family, one prop family.** Meshy is
  reserved for Team Tether hero objects (pylons, relay apparatus, the tether
  machine).
- **Reuse the installed humanoid cast.** Six production humanoid rigs exist
  (trainer, Grandpa, Warden, villager male, villager female, Team Tether
  grunt) per `docs/art/HUMANOID_ASSET_INVENTORY.md` — that document is
  authoritative for current availability/reuse, superseding older prose in
  `archive/docs/art/HUMANOIDS_PRODUCTION_REPORT.md` and `docs/art/REFERENCE_CANON.md`.
  A new humanoid mesh is exceptional and requires owner-supplied reference
  art plus a real unmet player-facing need.
- **The Warden is already rebuilt** from the owner-supplied board-16
  character sheet — do not reopen historical notes claiming otherwise;
  inspect `assets/characters/warden/warden_lod0.glb` instead.
- **Five creatures total, no storage.** No reserve box or hidden sixth slot
  anywhere in world/content design (enforced in code — see
  `GAMEPLAY_SYSTEMS.md` §Party).
- **No hunting/butchering, no shields, human never fights, creatures don't
  perform base jobs.** These constrain what world content (harvest nodes,
  combat set pieces, village jobs) can ever be designed to require.

---

## 10. Caveats

Drafted from a read-only code+data inventory pass; no engine run performed.
Landmark-vs-"landmark key" double-count in `map_landmarks.json` (12 regions,
9 separately-keyed "landmarks") was not fully disambiguated — treated here
as one 12-entry POI list. Scene-nesting graph (which `.tscn` instances which
other `.tscn`) was not independently traced beyond script-attachment greps.
