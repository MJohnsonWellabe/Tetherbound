# Handoff — 2026-09-06 (art-gap lanes, and the grass problem that is still open)

Read `docs/00_START_HERE.md`, then `docs/HANDOFF_2026-09-06.md` (the art-gap closure
plan, §4), then this. This file is the state of the six branches that came out of that
plan, the one problem that is **not solved and needs a fresh pair of eyes**, and the
owner directions that override the older plan.

Nobody is holding these branches. Every session was archived on the owner's instruction;
**someone else takes them to `main`.** No pull requests were opened.

## 1. Owner directions from this session — these override `HANDOFF_2026-09-06.md`

1. **"There is art in the repo for most of these things already, like mushrooms and team
   tether stuff. Find it and use it. Recolor it if you need to. Don't use Meshy."**
   The older handoff's *Source* column is wrong in several rows — it proposes downloads
   for assets already vendored here, and it marks the tether machine as needing owner
   reference art that is already on disk. See §4.
2. **"That completely flat green ground shouldn't exist."**
3. **"Just make the grass universal so it doesn't look like painted green ground."**
4. **"There should be nowhere you can stand that doesn't have grass or isn't a bare dirt
   patch or mud pit or something else. It cannot just be plain green painted on a
   parking lot."** This is an invariant, not a tuning target. It is **NOT MET** — §3.

## 2. The branches

| Branch | Lane | State |
|---|---|---|
| `claude/second-biome-art-plan-470zru` | coordinator (this session) | `main` merged in, cliff option A shipped, crown relief, grass work. See §3. |
| `claude/art-hall-round-0906` | Hall: H1–H5, H7, X1 | wrapped on instruction; read its `ralph/reports/HALL-ART-0906/REPORT.md` |
| `claude/art-warrens-round-0906` | Warrens: W1, W3, W5 | wrapped on instruction; `ralph/reports/WARRENS-ART-0906/REPORT.md` |
| `claude/art-cloudreach-atmosphere-0906` | C4, C5, C3 | wrapped on instruction; `ralph/reports/CLOUDREACH-ATMOS-0906/REPORT.md` |
| `claude/art-cloudreach-dressing-0906` | C6, C7, C8, X3 | wrapped on instruction; `ralph/reports/CLOUDREACH-DRESS-0906/REPORT.md` |
| `claude/art-tether-machine-0906` | H6 | wrapped on instruction; `ralph/reports/TETHER-MACHINE-0906/REPORT.md` |

All five lanes branched from `claude/second-biome-art-plan-470zru`, so that one merges
first. **Trust each lane's own REPORT.md over this table** — they were written at the
moment each lane stopped and this was written before they finished. If a report is
missing, that lane did not get to write one and its branch must be read as a diff.

Lanes 3 and 4 both edit `scripts/world/cloudreach_look.gd` and
`scripts/world/cloudreach_world.gd`. They were given disjoint function lists (lane 3:
`_dress_fog`, `_dress_moorings`, the terrain/`_mesa` geometry, `cloudreach_atmosphere.json`,
the `sky_profile`/`landmass` blocks; lane 4: `_dress_trees_and_stones`,
`_dress_settlement_materials`, `cloudreach_summit_presentation.gd`,
`cloudreach_aviary.json`, the `settlement_materials`/`trees_stones` blocks) but expect to
resolve conflicts there anyway. Every lane was told to append to `docs/CURRENT_STATE.md`
only in its last commit; that file will still conflict five ways.

## 3. THE OPEN PROBLEM: the ground the player stands on is still painted green

**Reproduce it:** render stand `05-upper-cloudreach-cliffhold`.

```
xvfb-run -a -s "-screen 0 1280x800x24" ~/godot-bin/godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_cloudreach_cliff_options.gd -- \
  --out=res://shots/check --only=05-upper-cloudreach-cliffhold
```

The bottom third of that frame — the ground under the trainer's feet — is a smooth flat
green plane with no blades on it. 500,397 grass tufts exist in that realm and not one of
them lands there.

### What is already ruled out, with evidence

Do not repeat these. Each cost a 6-minute render or a 2-minute probe.

| Ruled out | Evidence |
|---|---|
| It is a grass DENSITY problem | Density is uniform at x1.00 across every turf surface; raising it changes nothing at this stand |
| It is the patch-bounded cover layers | Fixed. A realm-wide layer now exists and covers 2,138,196 m² of turf |
| It is the ground MATERIAL being untextured | `_textured_material` sets `uv1_world_triplanar` with `uv1_scale` 0.27, so the grass texture tiles every ~3.7 m in world space. Not stretched |
| It is the terrain being mathematically flat | Real, and FIXED separately (see §3.1) — but the plane at 05 stayed flat green afterwards |
| It is the glTF absent-`metallicFactor` defect | `tools/_probe_cloudreach_prop_materials.gd`: **0 of 14** route-detail prop scenes import as metal |
| The surface is not drawn with a turf material | `tools/_probe_cloudreach_surface_id.gd` names it: `upland` / `upland_dry` on `StratifiedCliffBody`, `Ridge*`, `LedgeCap*` — it IS turf |
| `_is_turf_top` was rejecting it | Real defect, FIXED: it accepted exactly one collider name (`Collision`) and refused every ridge, terrace and walkable crown. Now a blocklist |
| Ledge caps were skipped by the collector | Real defect, FIXED: they carry their material as a `material_override` on the MeshInstance, not a surface material. Reading the override first added 94 surfaces and 273,000 m² |
| Tufts were being planted inside the rock | Real, FIXED: `_fill_tuft_at` rejects a tuft when a downward ray finds geometry above it. Cut 602,055 tufts to 500,397 |

### What is NOT yet ruled out — start here

1. **Are tufts placed at that xz at all, or placed and then not drawn?** The one probe
   that would settle it was never run against the *finished* world:
   `tools/_probe_cloudreach_cover_near.gd` counts real MultiMesh instance transforms
   within a radius of a point. It reported **0 instances within 20 m of stand 05** and
   3,823 within 8 m of stand 01 — but it waits only two process frames, and the fill
   takes ~60 s to build, so **that reading may have been taken before the pass finished
   and should not be trusted.** Re-run it with a proper wait first. This is the cheapest
   next step and it forks the whole investigation.
2. **If the tufts ARE there:** they are being culled or shrunk. Suspects, in order —
   `shaders/cloudreach_ground_cover.gdshader` line 50: `camera_clearance` scales a blade
   to **1.5 %** of size within 1.2 m of the camera, easing to full at 2.8 m; the
   MultiMeshInstance `visibility_range_end` (360 m near tier / 900 m far tier) with
   `VISIBILITY_RANGE_FADE_SELF`; or the blades simply being 0.52–0.95 m and
   foreshortening into a mat at that camera pitch, in which case the answer is blade
   height and clumping, not count.
3. **If the tufts are NOT there:** the rejection is one of `_excluded`,
   `_inside_settlement_clearance` or `_near_route` inside `_fill_tuft_at`. A probe for
   this exists — `tools/_probe_cloudreach_turf_rejects.gd` reports which predicate
   refuses a point, in the order the fill asks them. Its last reading within 2–20 m of
   stand 05 was `plantable: 60, route: 47, excluded: 16, no_hit: 37` — **60 samples say
   the ground is plantable**, which is what makes the bare render contradictory and is
   exactly why the count in (1) has to be re-taken.
4. **Consider giving up on cover and fixing the SURFACE instead.** The owner's invariant
   allows dirt: if a surface cannot carry grass, it must not be flat green. Assigning the
   `path` material (or a new mud/dirt material) to whatever draws that plane satisfies
   "bare dirt patch or mud pit" without solving the placement problem at all. That may be
   the cheaper correct answer, and no one has tried it.

### 3.1 What DID get fixed in the terrain (already on the branch)

Only a `CliffMass` mesa got an eroded crown, and even that reached its first contour in
**one triangle per side** — three vertices describe a plane, so every crown in the realm
rendered as a flat disc however much height the model carried. Now: relief lives in
`_crown_height_at` (which the visible crown, its collision copy and every conforming
shoulder all read, so they cannot drift) and `_emit_mesa_top` subdivides so the mesh can
show it. Tunables in `cloudreach_visual.json.crown_relief`.

It is suppressed inside settlement clearances, at the rim, and within
`LINE_PIN_MARGIN_M + LINE_EASE_M` of any road or bridge deck — without that last one a
crown rolls through an authored ribbon and reopens the hole class OP-0905-24/25 closed.

A/B on `crown_relief.enabled`, same tree:

```
off: 41219 samples, 0 holes, 33 mismatches, 892 buried, 530,931 crown triangles
on:  41219 samples, 0 holes, 33 mismatches, 914 buried, 727,157 crown triangles
```

### 3.2 A real bug found on the way, unrelated to grass

`cloudreach_look.gd::_near_route` is called once per candidate tuft — hundreds of
thousands of times per build. It had an early-out for exactly that, and **it did
nothing**: it computed whether both route endpoints were more than 260 m away and then
ran `pass`, so the segment loop ran regardless. It could not simply be promoted to
`continue` either — a route longer than 260 m end to end can pass close to a point both
of whose endpoints are far away, and the causeways do. Replaced with per-route bounding
boxes built once.

## 4. Corrections to `HANDOFF_2026-09-06.md` §4, verified against the repo

The older plan proposes downloads and owner-art blockers for things already on disk.

- **W1 mushrooms** — it wants a 54.8 MB AssetQuest kit. Unnecessary: `Mushroom_Common`
  and `Mushroom_Laetiporus` are installed, `Mushroom_Oyster` and `Mushroom_RedCap` are
  vendored, plus `mushroom_red.glb` and `mushroom_pickup.glb`. Six silhouettes.
- **H1 torch** — it wants a KayKit download. `Torch_Metal.gltf`, `Lantern_Wall`,
  `Chandelier`, `CandleStick_Stand` are all vendored.
- **X1 brazier** — "none licence-clean found". `Cauldron.gltf` + `CandleStick_Stand` /
  `Barrel_Holder` + `Torch_Metal` + `camp_flame.glb` + `campfire_stone_ring.glb`.
- **X3 aviary bird** — "not found licence-clean". `ollie-the-songbird.glb` exists, plus
  `pipwing`, `reedwing`, `galecrest`. Reusing an existing creature mesh as a static prop
  is not a new creature mesh, so D23 §20 is clear.
- **H6 tether machine** — marked "Meshy hero object, owner reference art required".
  **Both halves are wrong.** The board is in the repo at
  `docs/art/reference/15_Legendary_Tether_Machine.png`, and `ASSET_LEDGER.md:67` records
  the shipped mesh as generated from four crops of exactly it. There is also in-repo
  precedent for authoring Team Tether hero geometry without Meshy —
  `tools/art_pipeline/blender/build_hall_props.py` authored all five bespoke Hall props
  procedurally against the boards' scale bars, and its header argues that authored
  geometry is a *better* fit for readable silhouettes than Meshy was.
- **C2 ledge structure** — the fallback is not the Kenney cliff kit (that was option C;
  the owner picked A). `Rock_Big_1/2` and `Rock_Medium_1..4` are vendored in the same
  nature family the world already uses.
- **C9 jade boulders** — **already fixed.** `_place_local_prop` routes rocks through
  `apply_stone_palette` today. Verify before re-fixing.

The unused reservoir, for anyone sourcing: Quaternius fantasy props 94 vendored / 16
installed; medieval village 176 / 64; stylized nature 117 / 46; and
`assets/buildings/quaternius_castle/` is 21 installed `.obj` towers, walls and a banner
referenced nowhere outside `archive/`.

## 5. Environment notes that cost this session real time

- **Godot is not preinstalled in these containers.** Install the CI pin:
  `curl -sSL -o godot.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip`,
  unzip to `~/godot-bin/godot`, then `godot --headless --path . --import`.
- Rendering works on software GL (llvmpipe) via
  `xvfb-run -a -s "-screen 0 1280x800x24" ... --rendering-driver opengl3`. Never pass
  `--headless` together with a rendering driver.
- **Costs here:** a Cloudreach world smoke ~2–4 min; a two-stand render ~6 min; the
  ground-truth smoke ~2.5 min. Never run two Godot processes at once (a boot is 2–3 GB,
  a render ~7 GB). Budget accordingly — a guess costs six minutes, a probe costs two.
- `json.dump` reformats whole files. Edit JSON with targeted text insertion.
- The other traps still apply: `docs/HANDOFF_2026-09-06.md` §6.

## 6. Still open from the older plan, untouched by any lane

- **W2** the Meadows-wide grass palette (`meadow_grass_Color.png` bake / grass tint).
- **W4 / X2** creature style unification — an ink-outline/speckle decision for the whole
  roster in `creature_visual.gd`, and any guardian proportion pass. **Owner call.**
- **OP-0905-02** build placement from the play screen — needs one Ally reproduction;
  headless cannot hit-test a real mouse click on a catalogue cell.
- **OP-0905-07** Gil's face.
- The **CI known-red pair** (`verify-gate-b-full-known-red`,
  `verify-continuous-core-known-red`) still time out every run and nobody owns them.
  They cancel themselves, which makes the RUN conclusion read "cancelled" — judge CI by
  job conclusions, never by the run badge.
