# READY: tb/land-mt-grassgroves-land

STATUS: land. GPU-judged ship (LANE-JUDGE G-land-mt-grassgroves-r2, tb/judge c9938aeaf, 13 Nov).

**Verdict.**
- F39#1 6.07 -> 6.23 (+0.16, 3/3).
- Tidewake routes no-loss 5.87 -> 6.11 (+0.24, 3/3).
- Venn level at 6.51; F39#15 level.

**What.** Tidewake dune grass in denser, fewer clumps with wider bare gaps. The values sit in `tidewake_look.json` `dune_grass_candidate`, the section `water_world.gd` applies last to the grass field (round 1 set them one layer earlier and was overwritten). Presentation only.

**Files.** `data/config/tidewake_look.json` (`dune_grass_candidate`: `density_gain` 1.2, `clump_patch_start` 0.56, `clump_patch_full` 0.66, `clump_contrast` 1.0, `dune_gap_start` 0.42, `dune_gap_full` 0.55, `_why_grassgroves`); `tests/test_grassgroves_ships.gd`.

**Tests run** (headless, on this tree's config): 27 tests, 573 assertions, 0 failed.

| Test file | Tests | Assertions |
|---|---|---|
| `test_grassgroves_ships.gd` (new pin) | 1 | 6 |
| `test_water_dune_cover.gd` | 10 | 237 |
| `test_water_dune_groves.gd` | 5 | 48 |
| `test_tidewake_look_profile.gd` | 11 | 282 |
