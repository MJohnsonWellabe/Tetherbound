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
`tests/smoke_warrens.gd` on this state: exit 0, "warrens smoke test passed" (mouth walkable, chambers enclosed, route walked, guardian/heartstone/reward intact).

## Round 12 — the one knob (JUDGE-round11-warrens: "unlit black void, no grain" → `site.exterior_cladding_colour`)

Data change only: the skin gets its own tint `#4a3a2a` (~2× the apron's `#2b2118`) via `_cladding_material()` — same
Ground030 texture, triplanar scale and normal map as `_floor_material(true)`, no interior change, `exterior_cladding_m` 0.4 kept.
One render, `round12-warrens/`:

| region (standing-day) | r10 | r11 | **r12** | window asked |
|---|---|---|---|---|
| left flank median / std | 43.9 / 16.6 | 2.5 / 43.6 | **8.3 / 42.8** | 20–70 / ≥ 12 |
| right flank median / std | 94.1 / 65.6 | 2.8 / 45.8 | **9.1 / 42.3** | 20–70 / ≥ 12 |
| pixel (0.80, 0.42) | (151,144,126) | (3,3,1) | **(12,9,5)** | — |

Std passes, median misses the 20–70 window: the flank sits in the mouth dome's cast shadow and is lit by ambient only, so a
2× albedo lifted it ~3× (3 → 9) but not to 20. Grain is now visible on the flanks at 1:1 (speckle and darker pocks, warm
brown hue (12,9,5) rather than neutral black) — the judge's own preference order (dark earth with visible grain beats black
void) puts r12 closer to the reference than r11, so **r12 is the kept state**; r11 is recorded as the void ceiling.
Approach-day: 20.5 % px changed vs r11, all of it in the top two rows (moving cloud layer, 46–76 % per cell); the mound and
doorway rows are 0–3 % — composition unchanged. Den: 8.0 % px changed vs r11, all on the wandering guardian/trainer cells; wall and ceiling cells 0 % (interior untouched).
Next mechanism if a 20+ median is still wanted: it is a LIGHT problem now, not a material one — either ~4–5× tint
(`#8a6e50`, risks reading as dry clay in the sunlit approach) or a low-energy fill omni at the mouth (the judge's own
suggestion), both one data knob; the skin material path is proven to move the region.
