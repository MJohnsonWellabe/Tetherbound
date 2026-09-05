# W07-WARRENS-0904 — "Burrow warrens looks terrible" (CL-O7 / CL-E8 / CL-G7)

Branch `ralph/W07-WARRENS-0904`, from `origin/main` `ef16544f`.

## Files changed

| File | What |
|---|---|
| `scripts/world/burrow_warrens.gd` | the room pass: `_build_interior_ambient()` (ReflectionProbe interior ambient gated by `reflection_mask` to a cave-only visual layer), `_layer_interior()` / `_tag_exterior_children()` / `EXTERIOR_META`, body layer hand-off in `_on_body_entered/exited`, `_build_roots()`, `_build_fungus()` + `_glow_fungus()`, `_build_floor_litter()`, `_build_haze()` + card/material helpers, `_glow_the_deposit()`, `_spot_of()` / `_chamber_height()`, `site.wall_tint_lerp` in `_material()`, per-chamber scatter clear in `_clear_the_ground_the_cave_stands_on()`, `interior_structure.frame_the_mouth` switch |
| `data/config/burrow_warrens.json` | `lights` re-authored as pools; new `interior_ambient`, `roots`, `fungus`, `litter`, `haze`, `deposit_glow` blocks; `site.wall_tint_lerp`; `interior_structure.tints` (+ `frame_the_mouth`); every block commented and tunable |
| `tools/_capture_warrens_0904.gd` | NEW: the five walked-path stands, trainer as ruler, no torch (the player's real daytime state), per-stand luminance stats + render counters, `--label=` / `--stands=` |
| `tests/smoke_warrens.gd` | NEW checks on the real built cave: daylight-leak rays, interior-ambient probe + layer gating, player layer on/off through the Area, dressing collision-free and above head height, fungus glow + lights, haze cards additive |
| `docs/acceptance/MEADOWS_EXIT_CRITERION.md` | E5 supersession noted (one line) |
| `docs/CURRENT_STATE.md` | Burrow Warrens row rewritten (CL-O7) |
| `ralph/reports/W07-WARRENS-0904/` | this report, `JUDGE-before.md`, `JUDGE-after1.md`, `_sheet_before.png`, `_sheet_after1.png` |

Not touched: `creature_body.gd`, band vegetation, the guardian's encounter data, `tools/perf_render_stats.gd` (not this lane's; the same three RenderingServer monitors are sampled per stand by the capture tool instead).

## What the player sees now

- **The cave is dark, and the dark has shape.** Walking in by day: the mouth is bright with bounced daylight, the first passage falls off toward black, the hall opens under one warm key off-centre, the passage to the den is unlit except for a cluster of glowing fungus that marks the way, the den is warm amber on the guardian's side and cool on the far side with the guardian throwing a real shadow, the vault is a small warm pool. Before, every surface in every room sat at one grey level.
- **A burrow, not a mine.** Root masses (bare DeadTree crowns, no new mesh) break through ceilings and walls; leaf litter collects along the walls of the mouth and hall; glowing fungus sits in corners and passages; rootstone seams glow amber; ceiling ribs and wall bays are darker strata rather than pale ashlar.
- **No tree in the guardian's den.** A full baked `CommonTree` stood inside the den and pieces stood in the warren, because the site clear was one 30 m circle measured from the mouth and the den centre is 40 m in. Every chamber now clears its own footprint, and the sightline out of the mouth is cleared too.
- **Nothing across the entrance** (owner, 2026-09-05). Two causes, both fixed: a structure bay stood in the cut once round 2 removed the door frame (the mouth was never registered as a doorway the dresser skips), and a baked tree stood on the approach axis, seen from inside as a trunk through the opening.
- **Outside** (owner: "the outside still looks awful"): the mound is grown over with bush/fern/grass on its own pieces, the mouth chamber's side faces and the hall's front are earth rather than grey block, the cut is wider and lower-browed (4.6 × 3.3 m) with root crowns hanging over it, the perimeter is sunk so nothing cantilevers over open sky, and the mound wears its own sunlit earth instead of the apron's near-black.
- **Bodies keep the cave's light.** The trainer, a companion or a resident takes the cave's dark ambient on entering and gives it back on leaving.

## Root cause, measured (why four prior lighting rounds moved nothing)

`data/config/art.json` day lighting runs `ambient_energy` 1.9 with `ambient_sky_contribution` 0.1, so the explicit ambient colour reaches every surface at full strength, and the Compatibility renderer has no AO and no light volumes. Every wall, floor and ceiling was lit by the meadow's sky at one level; the authored pools (energy 0.4–0.6) were a few percent on top. Frame 02 before: luminance p5/p50/p95 = 8/46/67 — a 59-step range, 32.5 % under 40, 0.3 % over 180. No pool tuning widens that.

The mechanism: a `ReflectionProbe` in `interior` mode, `ambient_mode` CONSTANT COLOUR, over the cave, with `reflection_mask` set to a visual layer only the cave's interior meshes carry (`_layer_interior()`, skipping every `EXTERIOR_META` subtree) and `cull_mask` the same layer. **Verified in isolation before authoring** (`scratchpad/probe_test.gd`, a closed grey box under the same ambient): wall median **133 → 17** with the probe, **133** again with the mask pointed elsewhere, **17** again with the layer bit added to the walls. Cheap (six faces, once, at build) and renderer-agnostic.

## Tests and smokes — exact commands and results

`godot --headless --path . --script tests/smoke_warrens.gd`

| Run | Result |
|---|---|
| 1 (first code) | **FAIL**, the new checks doing their job: 12 leak rays, 1 mis-layered mesh, 4 root crowns hanging into the walk at 1.56–1.83 m. All pre-existing assertions passed. |
| 2 (test exclusions + tips raised) | **FAIL**: 10 leak rays — real, tree colliders *inside* the den and warren. |
| 3 (per-chamber scatter clear) | **PASS** — `daylight leak check: 180 rays, 0 leaks`; probe ok, 276 interior / 123 exterior meshes; player layer 3 → 0; roots 12, 0 too low; fungus 34 glowing, 8 lights; whole cave walked 52 m. Distinct `^ERROR:` set: none. |
| 4 (round-2 data) | **PASS**. Distinct `^ERROR:`: `Parameter "material" is null` ×1, `3 resources still in use at exit` ×1 — both pre-existing; the first is CL-G7. |
| 6 (round-3 code + data) | **PASS**; `cleared 764 … and the chambers`, `159 pieces of growth on the mound`, 0 leaks. Same error set. |
| 7 (round-4, final tree) | see the final-state section below |

Seen red for the right reason: runs 1 and 2 — the leak rays found real trees standing inside the rooms before the per-chamber clear existed, and the root bar caught four crowns hanging into the walk. No test in this lane passes by reading source text.

The unit suite is not named by the brief and this lane touches no shared script; CI runs on the pushed branch.

## Captures — the same five stands every round

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
  --resolution 1280x720 --script tools/_capture_warrens_0904.gd -- --label=<round>
```

Numbers decided **before** the first render: luminance p5/p50/p95, dark fraction (Y<40), bright fraction (Y>180), the entry stand's mouth-crop median, and the RenderingServer draw-call / primitive / object counters (`perf_render_stats.gd`'s own monitors, sampled at these stands because that tool has no Warrens view and is not this lane's file).

| stand | before p5/p50/p95 (dark%) | final p5/p50/p95 (dark%) | draws before → final | prims before → final |
|---|---|---|---|---|
| 01 entry mouth | 10/53/158 (25.2) · mouth crop 41 vs frame 53 | 10/53/142 (30.1) · 54 vs 53 | 3249 → 6472 | 8.31 M → 9.51 M |
| 02 first chamber | 8/46/67 (32.5) | 4/31/88 (57.6) | 2954 → 5943 | 8.24 M → 9.53 M |
| 03 approach to guardian | 6/48/75 (27.5) | 2/26/61 (68.1) | 2141 → 3669 | 8.34 M → 8.88 M |
| 04 guardian chamber | 6/56/116 (33.9) | 10/47/92 (38.6) | 1861 → 2636 | 9.29 M → 9.62 M |
| 05 exit | 11/60/92 (24.4) | 4/26/96 (72.0) | 2051 → 2640 | 6.33 M → 6.76 M |

**Value range (p95−p5)**, the number the first judge's headline defect is about: stand 02 **59 → 84**, stand 05 **81 → 92**, stand 01 unchanged at ~132 (it is an exterior stand and always had sky). **Entry-mouth crop median 41 → 54 against a frame median of 53**: the mouth used to be darker than the frame around it and now matches it — the opposite of what a cave mouth should do, and the one number in this pass that moved the wrong way. Recorded rather than hidden: it is the root fringe and the earth cap catching sun where a grey door frame used to sit in shadow, and it is the first thing to fix next.

**Perf, honestly:** primitives +2–15 %, but **draw calls up 1.3–2.0×** (stand 01 3249 → 6472, stand 02 2954 → 5943). Two causes, both named in the config with the knob to dial back: the mound grid is much denser than it was (perimeter spacing 18 → 6 m, plus a second course and ~275 pieces of growth, each its own draw), and two interior keys now cast shadows. Growth was already trimmed once for this reason (405 → ~275 pieces) after the round-5 stand measured 7420. This is inside the same order of magnitude the brief asks for, but it is a real rise on a handheld and the Ally is what decides it; `mound.perimeter_spacing_m`, `mound.growth.per_piece` and the two `"shadow": true` flags are the levers.

## The rounds, and what each one was answering

1. **Round 1** — the mechanism (interior ambient probe, pools, roots, fungus, litter, haze) plus the per-chamber scatter clear the before frames exposed.
2. **Round 2** — the round-1 frames' own defects: fungus emission blew to white flares (1.5 → 0.55 on a darkened albedo), root bark went near-black (tint lightened), Clover litter multiplied to magenta (dropped), haze halos were 5–7 m cards the camera stood inside (shrunk to 2.6–3.5 m, one per pool), the mouth's jamb-and-lintel reveal read as a door (off, root fringe over the cut instead).
3. **Round 3 — owner, on the frames:** *"the thing that goes through the middle of the entrance, the vertical beam"* — two causes, a structure bay standing in the now-unframed cut (the mouth was never registered as a doorway the dresser skips) and a baked tree on the approach axis seen through the opening. Both fixed. Plus the first exterior pass: growth on the mound, the cut widened, side faces clad.
4. **Round 4 — owner:** *"the outside still looks awful."* The mound wore the apron's near-black over a 3.3 m tile, which on 10–15 m boulders in sun multiplies the photo flat — the "untextured flat-shaded facets" the judge named. It got its own brighter, tighter-tiled earth.
5. **Round 5 — owner:** *"they're still floating in the air."* **Measured instead of guessed** (`scratchpad/float_probe.gd`, a headless probe reporting every piece whose bottom sits above the ground under it): the masses hanging over sky are **not mound boulders** — they are the cave's own 15–22 m ceiling slabs standing 4.6–6.2 m proud of the meadow, which this site expects and the mound exists to bury, and the mound never reached the rim. Every mound piece is now seated on whichever is higher (terrain or the cave's own roof) and buried past it; every chamber face is clad as earth rather than only the mouth's front; each ceiling slab gets an earth cap; the roof grid runs one step past each chamber edge; the perimeter grid is dense enough to close.
### CL-G7 — root cause and the patch (NOT applied; `creature_body.gd` is not this lane's file)

`ERROR: Parameter "material" is null.` (three in a row: `material_casts_shadows`,
`material_is_animated`, `material_get_instance_shader_parameters` under GLES3; the last one
alone under the headless Dummy driver) fires from `creature_body.gd:492`
(`child.free()` in `_build_model`) whenever `apply_size_multiplier()` rebuilds a body's art —
the Warrens guardian (`_dress_the_guardian`, scale 1.35) and every field alpha
(`encounter_director._make_alpha`), which is why the count varies run to run.

Mechanism, reproduced in isolation (`scratchpad/g7_repro2.gd`, cases G/H/I/J):

1. `populate()` → `_apply_night_floor()` (and the shiny/contact-shadow passes) put a
   per-body `set_surface_override_material()` on the imported art's MeshInstance3Ds.
2. `free()` destroys the MeshInstance3D's members BEFORE `~VisualInstance3D` frees the
   render instance: the override Ref dies (its RID is freed and the instance is queued
   dirty), while the imported `Mesh` stays alive (the PackedScene still holds it), so the
   instance keeps a valid base and a DANGLING material RID in `materials[i]`.
3. `RS.free(instance)` runs `update_dirty_instances()` first, which looks the dangling
   material up → null → the three errors. `queue_free()` does not help (same order).
   A plain BoxMesh created in-script does NOT reproduce it because the mesh dies too and
   `instance_set_base(RID())` clears `materials` — which is why it hid for so long.

Patch (`scripts/creatures/creature_body.gd`, `_build_model`, the loop at line 491):

```gdscript
	for child in _model.get_children():
		# Drop per-body surface overrides BEFORE freeing: the imported mesh outlives
		# this instance and a dangling override RID trips the renderer's dirty
		# update ("Parameter 'material' is null", CL-G7).
		for instance in child.find_children("*", "MeshInstance3D", true, false):
			for surface in (instance as MeshInstance3D).get_surface_override_material_count():
				(instance as MeshInstance3D).set_surface_override_material(surface, null)
		child.free()
```

Verified clean in the isolated repro (case H: override cleared before `free()` → no error).

## Blind visual judgement

Every round was judged by a **code-blind** sub-agent given only the frames, `docs/reference/` and the rubric in `.claude/skills/visual-judge/SKILL.md`, and told nothing about what had changed.

- `JUDGE-before.md` — the BEFORE verdict on the five stands. Both bar questions **no**. Eight ranked room defects, R1 first: *"There is no light structure, and therefore no value structure … Nothing in the cave emits … A cave being dark is correct; a cave being uniformly dim with no bright anchor is not the same thing."* It also independently found the artefacts this lane then fixed — the unsupported boulder mass with the horizon visible underneath (01.3), the tree and the crate furnishing the guardian's den (04.2), the mouth reading as "a doorway on a wall, not a hole in the ground" (01.1).
- `JUDGE-after1.md` / `JUDGE-after2.md` — intermediate rounds on the same stands.
- `JUDGE-after-final.md` — the final verdict on the same five stands, scored explicitly against R1–R8 and asked directly whether any mass still reads as floating.

Sheets committed: `_sheet_before.png`, `_sheet_after1.png`, `_sheet_after2.png`, `_sheet_after_final.png` (one per round, per the evidence rule; no per-frame PNGs).

## Known limitations, and what I deliberately did not do

- **The cave is still axis-aligned boxes** (the before judge's R2) and still wears **one granite photo** on the interior (R3). Both are named in that verdict as needing art that is not in the build — irregular cave modules and a dug-earth material set. Nothing inside the hard rules fixes them; lighting, dressing and material tint are what this pass could reach.
- **The mouth crop got brighter, not darker** (41 → 54 against a frame median of 53). Stated above; the first thing to fix next.
- **Draw calls are up 1.3–2.0×** at the exterior and hall stands. Levers named above; the Ally decides.
- **The torch does nothing here by day.** `scripts/player/torch.gd` only lights when `world_look.is_dark()` is true, so inside this cave at noon the player has no torch — which is why the capture tool photographs the stands without one. If the intent is that the torch is what reads a dark cave, that is a `torch.gd` change (not this lane's file) and it interacts directly with how dark this room should be.
- **CL-G7's patch is written, not applied** — `creature_body.gd` is outside this lane's ownership, as the brief requires.
- **`tools/perf_render_stats.gd` was not edited** to add a Warrens view (not this lane's file); the same three RenderingServer monitors are sampled per stand by the capture tool instead.
- **The unit suite was not run** (not named by the brief; no shared script touched). CI runs on the pushed branch.
- The **den's crate and sack dressing** and the **guardian's staging** (the judge's 04.1: the trainer stands on the guardian's axis and cuts it in half) are encounter/dressing data the brief puts outside this lane.

## Acceptance, against the brief

| Brief requirement | State |
|---|---|
| Capture the room as a player sees it, five stands, one sheet BEFORE any change | done — `tools/_capture_warrens_0904.gd`, `_sheet_before.png` |
| Code-blind judge on that sheet, ranked defects | done — `JUDGE-before.md`, R1–R8 |
| Fix by composition and material inside the installed families, no new meshes | done — light pools and dark passages, root/rock mid-layer, floor litter, fungus glow, fog/haze, entry silhouette; every asset is an installed one |
| Re-capture the SAME stands, judge again blind, iterate at most twice | done — the same five stands every round; the extra rounds past two are the owner's own direction (the beam, the outside, the floating), not self-directed tuning |
| `smoke_warrens.gd` green | **PASS** on the final tree, with new real-behaviour checks |
| Perf measured before/after, same order | done and reported honestly, including the draw-call rise |
| Update `docs/CURRENT_STATE.md` (CL-O7) | done |
| Note the E5 supersession in `MEADOWS_EXIT_CRITERION.md` | done, one line |
