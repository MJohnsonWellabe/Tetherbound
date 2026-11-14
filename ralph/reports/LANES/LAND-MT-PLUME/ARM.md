# LAND-MT-PLUME (F38#30, BROKENHILL round 2): the solid smoke column

**Defect.** The judges' follow-up on the Warrens frames: "the plain white smoke column", or "a solid smoke pillar". The column comes from the F03 lure post `WarrensVaultSignalPost` (band2 props): 26 m of stacked unshaded discs with a 1.4 m foot, an 11 m crown and alpha 0.55. The discs overlap so much that the column compounds into one straight pole.

**Arm** (`overlay.json`; flag-off camfx.json `smoke_plume`, scope `client_presentation`, names only that post). For that column it sets:
- foot ×1.8 and crown ×1.6;
- alpha per disc ×0.6;
- top fade 0.8;
- a downwind lean of 0.32 m per metre of height.

It stays a 26 m signal that marks the site from the road. `props.gd` now builds the `configure_smoke` arguments in `smoke_column_args`; with the flag off they are exactly as authored.

**Test.** `tests/test_warrens_smoke_plume.gd`: 1 test, 0 failed. It checks that with the flag off the column is unchanged, and that posts not named are never touched.

**CPU** (`_sheet_plume_cpu.jpg`, left SHELLSHARDS, right SHELLSHARDS+PLUME; rows: route_day, vista_dusk, walk_03):
- route_day: the pole becomes a soft haze leaning off the hill.
- dusk: a wider, softer funnel that thins at the crown.
- walk_03: barely visible.

The gain is modest. Judge it stacked on SHELLSHARDS, against SHELLSHARDS alone.

**By-eye line:** route_day, above the mouth. A soft leaning haze instead of a hard white pole.

**No-loss check:** the F03 lure still has to read from the road.
