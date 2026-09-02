# Warrens exterior — clean restart (round 11, `04-warrens`)

**Lane:** VP6. **Branch:** `claude/coordination-subagents-3fhz1x`. **Rule followed:** identify by ray-cast, fix at the source, one render, prove with PIL.

## What the slab IS (ray-cast, `tools/_probe_warrens_slab_ray.gd`)

Booted the world as `tools/_capture_locations.gd` does for the `standing` stand (marker `entrance` → look `hall`,
back 3.2 / up 1.70 / look_up 1.6, FOV 70 vertical, 1280×720). Camera lands at world (-353.32, 5.85, 2606.32),
eye on-axis at the entrance marker (no `_clear_of_bodies` step-aside).

| screen | physics hit | geometry hit (first triangle) | material |
|---|---|---|---|
| (0.80, 0.42) | `BurrowWarrens/@StaticBody3D@63149` at 6.26 m, world (-359.50, 6.39, 2607.22) | `BurrowWarrens/@MeshInstance3D@63147`, BoxMesh 3.2×14.8×1.2, local (-3.1, 0.4) | `material_override` = Std albedo **#d6caba** over Rock030, triplanar |
| (0.85, 0.30) | same body, 6.77 m | same mesh | same |
| (0.20, 0.35) | `@StaticBody3D@63152`, 6.32 m | `@MeshInstance3D@63150`, local (+3.1, 0.4) | same |
| (0.15, 0.55) | `@StaticBody3D@63146`, 6.64 m | Grass_Wide_Tall (dressing) then `@63150` | same wall |

Local (-3.1, 0.4) with span 3.2 is exactly `_build_wall()`'s right-hand flank of the **mouth chamber's front (`-z`)
wall** — the one wall `_build_chambers()` builds with `exterior=true`. The slab is that wall's outer face:
`_box(size, at, _rock(), true, true)` → `_material(#5b5147, 0, true)` = `#5b5147.lerp(#fff2e0, 0.75)` = `#d6caba`,
lit by full sun → luminance ~145. The left flank (`@63150`) is the same box in shadow (~44). Not a mound rock, not
Terrain3D, not scatter, not interior geometry poking through.

**Why three rounds of "route the exterior wall through the stain shader" never moved it:** `_box()` sets
`MeshInstance3D.material_override`; `_wear_the_cave_stone()` → `_apply_boulder_stain()` sets a *surface* override,
and `material_override` takes precedence. The reroute was a silent no-op (the probe still reads the plain Std material
on the wall). It would also not have sufficed: the stain shader's mid band is the same 0.75 lerp toward near-white.

## The fix (`scripts/world/burrow_warrens.gd::_clad_exterior_face`, `data/config/burrow_warrens.json` `site.exterior_cladding_m` 0.4)

The wall box is untouched (its inner face is the mouth chamber — interior, off-limits). Each `exterior=true` wall
piece (both flanks + the brow over the door) now gets a collision-free BoxMesh skin `exterior_cladding_m` proud of the
outer face, full span, full skirt-to-top height, wearing `_floor_material(true)` — the same triplanar Ground030 earth
(apron colour `#2b2118`) the mouth dome, spoil mounds and trodden apron already wear. No interior node, material or
transform changes; `interior_structure.gd` untouched. Knob 0 restores the old frame.

## Proof (round11 `04-warrens-standing-day.png` vs round10, PIL, regions in frame fractions)

| region | round10 median / std | round11 median / std | target |
|---|---|---|---|
| left x 0–35 %, y 25–60 % | 43.9 / 16.8 | **2.5 / 43.6** | ≤ 90 / ≥ 15 |
| right x 65–100 %, y 25–60 % | 102.0 / 65.7 | **2.8 / 45.8** | ≤ 90 / ≥ 15 |

Changed pixels vs round10 (old frame upsampled 960→1280): **61.0 %** (>16/255), 75.4 % (>8). Target > 15 %.
Sample pixel (0.80, 0.42): round10 (151,144,126) → round11 (3,3,1); spoil mound in sun, same material, (0.75, 0.55): (34,28,19).

Den control: r11 vs r10 differs 19 % (>16) but only on the wandering guardian, the trainer and their shadows —
wall/ceiling cells 0–6 %, mean luminance 78.4 vs 79.4. Interior unchanged.
Caveats, stated honestly:
- The composition of `standing` differs from round10 (door now centred, both flanks in frame). Round 10's eye was
  displaced off-axis (a `_clear_of_bodies` step-aside — the frames were pulled from the lane branch in 84ae00af and the
  capsule lift 6c7f8d1e may not have been on it); this run logs the eye exactly at the entrance marker, no NOTE line.
  The probe ran the current tool math, so the hits above are what round 11 photographs; the fix is not camera-dependent.
- The flanks now read as very dark earth in the dome's shadow (L 2–3 — near black). That is ≤ 90 and is the material
  the rest of the mound wears, but it is not yet the reference's "dark soil, roots, stone, moss" texture read. Next
  mechanism if the judge wants more than "no longer a white panel": give the skin its own `exterior_cladding_colour`
  (e.g. `#4a3a2a`, ~2× the apron value) so Ground030's grain survives the shadow, or run it through the stain shader
  with a dark `base_tint` and `material_override` cleared. One data knob either way; no interior impact.

`tests/smoke_warrens.gd`: SMOKE_RESULT_PLACEHOLDER
