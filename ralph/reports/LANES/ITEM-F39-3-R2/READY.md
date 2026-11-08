STATUS: land
BRANCH: tb/item-f39-3-r2  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, F39#3 named destination read, round 2 (coordinator 8 Nov): standing water at the Drowned Garden terrace.

**Ships ON.** The gain beats the noise floor for this frame type (0.00), and 2 of 3 judges prefer the arm.

## Change
- New `scripts/world/water_garden_flood.gd` and `data/config/water_garden_flood.json`, hooked in `scripts/world/water_world.gd` beside the other garden builders (non-simulation builds only).
- One still, shallow water sheet (installed `water.gdshader`) at y 28.5 on the flat 28.2-28.4 m crest the terrace stands on.
  - Cells are built only where the sampled ground lies 0.03-0.35 m below the surface. It never spans a slope, so no edge floats more than 0.35 m.
  - The sheet sits inside a 9 m circle around the terrace, and every cut edge fades over 1.5 m as shore.
  - The colours are lagoon teal. There is no red.
- Render only: no collider, water volume, swim or depth query, route, spawn or save change. The water is 3-35 cm deep, so it reads as wading depth (coordinator OK).
- New `tests/test_water_garden_flood.gd` covers the depth band, the shipped sheet staying on the crest, and flatness.
- v1 was milky and had hard stair-step edges over the foreground. I rejected it by eye and did not judge it. The visibility sheet is `_sheet_visibility_v2.jpg`.

## Round (`qj/F39-3-flood-v2/`)
- Mapped **6.16 -> 6.30 (+0.14)**. Raw base 5.5 / 5.8 / 5.2, arm 5.9 / 5.4 / 5.5.
- Judges 1 and 3 prefer the arm; judge 2 prefers base. The defect went from PRESENT to PARTIAL x2.
- Fit: slope 1.39, r 0.88, RMSE 0.55. CPU only. **GPU re-baseline owed.**

## Pre-ready check (flood ON)
- **Unit tests:** `run_tests.gd --only=` every test that greps `water_world.gd` (test_grass_field_profiles, test_water_first_shore_horizon_stones, test_water_look_model_preload, test_water_return_connection, test_water_surface_material), plus test_water_garden_flood, test_texture_import_policy and test_creature_model_flags (HELD). Result: **30 tests, 2953 assertions, 0 failed**.
- **Smokes that pass:**
  - smoke_water_sealed_anchor_reload (realm reload)
  - smoke_water_garden_records
  - smoke_water_swimming
  - smoke_f33_swim_hazards
  - net `water_swimming` (ALL CHECKS PASSED)
- **`smoke_tidewake_dry_run`:**
  - Tidewake world boot, five world segments and the save reload at tidal all pass.
  - The final "late" segment fails because combined late runs are retired ("use salt_bex, calder, venn, nerissa with saved handoffs").
  - With the flood OFF (main's behaviour; the builder is inert while disabled) the result is identical, so this is pre-existing.
- **`smoke_water_mounted_swimming`:**
  - It fails "water_sirenseal rider art origin remains above sea".
  - It fails identically with the flood OFF, so this is pre-existing. It is a mount seat-height check in deep water, unrelated to a render-only sheet on the garden crest.
- JSON parse of `water_garden_flood.json` is OK.

## Judges' remaining asks (all three)
- The pool reads as a flat painted decal: there is no foam edge, wet-sand darkening, depth gradient or reflection.
- The terraces are still uniform white blocks, with no arch, steps or planting masses.
- The empty sand foreground remains.

**Next idea:**
- A wet-sand band: darken the terrain within about 1 m outside the shore, through a terrain decal or an underlay sheet.
- A foam line along the shore using the shader's existing foam_depth with a wider band.
- A stronger depth gradient: a deeper sheet with a lower max_depth floor encoding.

## Files
- `scripts/world/water_garden_flood.gd`
- `scripts/world/water_world.gd` (6-line hook)
- `data/config/water_garden_flood.json`
- `tests/test_water_garden_flood.gd`
- `ralph/reports/LANES/ITEM-F39-3-R2/**`
