# LAND-MT-GRASSGROVES: Tidewake dune grass in clumps with open sand between

**Rows.** F39#19 (6.92; the "flat beige sand" half of what holds it), F39#1 shore landforms 6.14, F39#15 6.14, F39#27 6.16.
- No-loss: F39#30 frame matrix, F39#2 (islands in frame), F13#5 (the T2 views show dune edges).

**Defect.**
- G-land-mt-cragcut, 3/3: "the dune is one overexposed beige mid-tone with evenly scattered grass tufts".
- G-rescore-stale-ext-tidewake, 3/3: the shores want "clumped dune grass in groves".

**Cause, and how I know.**
- The Tidewake grass is one camera-following field (`water_world.gd` `_stand_up_ground_cover`). Its profile is built in layers, and the look profile's `dune_grass_candidate` is applied **last**.
- `dune_grass_candidate` (ON) sets `density_gain` to 0.6 and the bare-gap thresholds, so the colonies stay thin and even.
- Round 1 changed `water_dune_cover.json` and showed nothing at Venn, because that layer overwrote it. Round 2 puts the values in `dune_grass_candidate` itself.

**Change.** Overlay only, in `tidewake_look.json` `dune_grass_candidate`:
- `density_gain` 0.6 to 1.2;
- `clump_patch_start` / `clump_patch_full` 0.56 / 0.66 (fewer, denser clumps);
- `clump_contrast` 1.0;
- `dune_gap_start` / `dune_gap_full` 0.42 / 0.55 (wider bare gaps).

**CPU before / after.** `_sheet_grassgroves_off_vs_on_cpu.jpg`, left base, right arm:
- **top:** the Venn fixed t-000 view (camera B composition);
- **bottom:** First Shore horizon stones route_day.

At Venn the grass gathers into denser patches with bare sand around them. At First Shore the foreground carries a real tuft cluster in front of open sand. 0 script errors.

**By-eye line for the GPU lane.** Venn t-000 and First Shore route_day: the grass stands in distinct clumps with bare sand between, not an even scatter of single tufts. If it is still an even scatter, the overlay did not apply: hold.

**Risks.** A near-camera clump can cover the trainer's feet in third-person frames (F39#27 was "grass around named characters"; the named-character clearance rules still apply). Watch F39#27 and any dialogue frames on dunes.
