# CODEX_START_HERE — Phase 2: visual inventory, catalog and fixes

Owner-authorized working brief (2026-09-28). It sits beside the live set in
AGENTS.md. AGENTS.md and CLAUDE.md still govern hard rules and precedence, and
ART_DIRECTION owns the visual bar. Record status in STATE, not here.

**Starts after Phase 1 (`CLAUDE_START_HERE.md`)**: all four biomes are
function-complete and the biome reorder has landed. The game order is then
**Meadows → Tidewake → Cloudreach → Stormwood**.

## 1. Shape of the phase

| Step | Who | Output |
|---|---|---|
| 2a Capture | 1 Codex lane on a lower-tier model | ~200 captures per biome plus a manifest |
| 2b Catalog | 1 Codex lane on a top-tier model, high effort | A scored defect catalog across all four biomes |
| 2c Fix | 4 Codex lanes on a top-tier model, high effort, one per biome | Fixes worked from the top of each biome's catalog |

Branches:
- `tb/x04-capture` for step 2a;
- `tb/x04-catalog` for step 2b;
- `tb/x04-meadows`, `tb/x04-tidewake`, `tb/x04-cloudreach` and `tb/x04-stormwood` for step 2c.

Evidence goes under `ralph/reports/VISUAL/phase2/`. The catalog is a data artifact
there, not a new live doc.

## 2a. Capture: the inventory (about 200 per biome)

**Goal:** a complete, repeatable picture of everything a player sees. Capture
only; no judging, no fixing.

**Coverage checklist per biome.** Every row needs at least one capture; frequent
things need several.

- **Named locations.** Every named place, landmark, settlement, camp, gate, shrine
  and boss arena. Include one approach shot from the route and one close shot.
- **Route and terrain.** Random samples along the main route and off-route
  (a seeded random walk, logged), plus a skyline and vista from key rises.
- **Creatures.** Every species in the biome: idle, moving, attacking, hurt,
  resting and fainted. Include shiny and alpha variants where they exist, and a
  companion next to the trainer for scale.
- **Characters.** Every NPC, trainer, captain, boss and villager: at their post,
  in dialogue and defeated.
- **Items in the world.** Every pickup, consumable, harvest node, chest, cache and
  prop family, on the ground at normal camera distance.
- **Time and weather.** Day, dusk and night for places on the route. Stormwood's
  storm phases (Calm, Building, Break, Fading), and Tidewake at high and low
  current where it differs.
- **Systems.** Flying (launch, glide, landing, perch), riding, swimming (surface,
  dive, current), catching, fights (open, tell, hit, win, aftermath), camp, bed,
  building and crafting stations.
- **UI.** HUD in exploration and in a fight, the map, the creatures screen, the
  inventory, quick bindings, the journal, dialogue, menus and the device-profile
  1920×1080 view.

**Manifest.** Write one row per capture to
`ralph/reports/VISUAL/phase2/<biome>/manifest.csv`:

```
id, biome, category, subject, location_id, route (main|side|off), time_of_day, weather_or_phase,
pose_or_state, camera (normal|close|vista|ui), frame_path, repro (script + args + seed), commit
```

**Rules for capture:**
- **Normal camera,** unless a row says otherwise.
- **No HUD** except in UI rows and fight rows.
- **Reproducible:** every frame has a script command and seed that re-shoots it.
  Reuse the existing `tools/capture_*` and `tools/_capture_*` scripts before
  writing new ones.
- **Render path:** native GPU Compatibility, or local
  `xvfb-run … --rendering-driver opengl3` if the GPU service is unavailable.
  Record which one.
- **Scale:** creatures are taller than the 1.80 m trainer, so check that the
  framing doesn't hide scale.

**Done when** every coverage row for all four biomes has captures, the manifest is
complete, and one contact sheet exists per category.

## 2b. Catalog: find and score

Judge every capture code-blind against ART_DIRECTION's boards, the key art and the
Palworld bar. Use the `visual-judge` skill. Merge duplicates: one defect seen in
twelve frames is one catalog item with twelve sightings.

**Catalog format.** One row per defect in
`ralph/reports/VISUAL/phase2/catalog.csv`:

```
item_id, biome(s), subject, defect (one sentence, observable), sightings (capture ids),
severity, exposure, importance, impact, fix_class (scene|material|lighting|mesh|animation|ui|camera),
owner_lane, est_effort (S|M|L), status
```

**Scoring.** `impact = severity × exposure × importance`, each on a 1–5 scale,
so impact runs from 1 to 125.

| Score | Severity: how bad it looks | Exposure: how often a player sees it | Importance: how much it matters to the story |
|---|---|---|---|
| 1 | Polish nit | Once, in one off-route spot | Optional, off-route, no story role |
| 2 | Noticeable but minor | A few times, one area | Side activity or minor NPC |
| 3 | Clearly below the bar | Repeatedly along one region's route | Main route, regular trainers and wilds |
| 4 | Breaks the look of the scene | Along most of a biome's route, or every fight | Named locations, chapter hubs, companions |
| 5 | Broken or placeholder: clipping, floating, unreadable, missing texture | In every biome, e.g. a shared prop, the HUD or a creature on every route | Finale and boss arenas, legendary scenes, the opening and the ending |

- **Shared assets score once, at their widest exposure.** One fix for a prop used in
  all four biomes beats four local fixes.
- **Order the catalog** by impact, then by impact per unit of effort. Items under
  about 12 impact are recorded but not worked unless they're trivial.

**Done when** every capture has been judged, every defect has a scored row and an
owner lane, and each biome has a top-20 list.

## 2c. Fix: four biome lanes

Each lane works its biome's catalog from the top:
1. Fix the item.
2. Re-shoot its sightings with the manifest `repro` commands.
3. Get a before/after code-blind verdict on those frames.
4. Mark it `fixed` with the commit.

Shared-asset items are owned by the first lane in impact order. Other lanes
wait for that fix rather than fork the asset.

**Rules (hard rules from AGENTS.md apply):**
- **Reference-backed art.** Agents may draft references and run the existing Meshy
  license for scoped current-roster and hero assets. Inspect the reference before
  submitting, record provenance and task IDs, and validate before integrating.
  No new purchases, no roster expansion, no unreferenced text-to-3D and no
  unattended batch generation.
- **One coherent nature/village/prop family.** Oxblood/red is reserved for Team Tether.
- **Scale fixes grow the smaller side.** Never shrink a creature to fit a camera.
- **No gameplay changes.** Collision, encounter positions, flags and camera logic
  belong to the Claude lanes. Ask on the lane channel. New visual work that isn't
  judged yet lands behind a config flag defaulting to off.
- **Import policy.** Runtime 3D textures use VRAM Compressed
  (`tools/art_pipeline/texture_import_policy.py --apply`, then reimport).
  `test_texture_import_policy` and `test_creature_viewport_framing` must pass.
- **Atomic commits** per catalog item, so the coordinator can cherry-pick cleanly.

**Regional bar.** When a biome's top items are fixed, run the ACCEPTANCE
chapter frame matrix and a Bars A/B verdict for the biome. Those verdicts close
the `Bars A/B → Phase 2` notes that Phase 1 left on the board.

**Known starting items.** They're already on the board and in `AUDIT.md`; re-score
them in the catalog rather than trusting their old order.
- The Cloudreach aerie: dome, towers, banners, rock and cloud floor (F08#3), and
  settlements and cliffs (F08#4). The towers and terrace candidates are merged but
  flagged off.
- The Stormheart hero tree, and the Veilfall interior waterfall. Both are rejected
  candidates, unwired, with READMEs.
- The Stormwood scorched Glass Field (flag off), and the Veilfall Pump Hall
  kitbash (flag off).
- Pump, banner and sluice placement (V-CX-14).
- Flat self-lit creature shading, and the static read of fights (Tidewake judges).
- Galecrest polish: feather highlights and alpha-night wings.

## 3. Landing

Each Codex lane lands its own work (owner, 2026-09-28). There is no channel and
no coordinator.
1. Merge `origin/main`.
2. Run the unit suite once, and fix any failures.
3. Update the catalog status and the board rows it closes.
4. Open a PR to `main` from the lane branch, with auto-merge on; CI runs once.
5. At wind-down, push everything. Leave work in progress unwired or flagged off,
   and list it in the catalog.
