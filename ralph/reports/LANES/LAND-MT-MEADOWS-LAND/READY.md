# READY: tb/land-mt-meadows-land

STATUS: land. Two GPU-judged ships (LANE-JUDGE, tb/judge, 13 Nov), same batch.

**DUSKRIDGE** (G-land-mt-duskridge).
- Dusk vistas 6.41 -> 7.10 (+0.69, 3/3).
- F38#24 day frames level at 6.56 (no loss).
- The ridge's haze turns cool blue-violet when the live fog is warm, and thins.
- Files: `shaders/meadows_ridge_far.gdshader` (`warm_haze_*` uniforms, off at their defaults), `data/config/meadows_ridge_vl.json` (`shader.warm_haze_mix` 0.85, `warm_keep_scale` 0.6, `_why_warm_haze`).

**BROKENHILL** (G-land-mt-brokenhill).
- F38#30 5.06 -> 6.48 (+1.42, 3/3), clears 6.
- Warrens no-loss set 5.68 -> 6.06 (+0.38, 2/3); no set loses.
- The Meshy mound shell gets world-space relief, rock on steep faces and outcrop patches, and bushes and ferns along its base.
- Presentation only; no collider.
- Files: `scripts/world/burrow_warrens.gd` (`_hill_broken_setup` and helpers, used only when the flag is on), `data/config/burrow_warrens.json` (`bank.hill_shell.broken.enabled` true, `_why_on`).

**Not in this branch.** The lane's flag-off back range layer (`meadows_ridge_vl.gd` `back_layer`) stays on `tb/land-mt` until judged.

**Tests run** (headless, on this tree's files): 12 tests, 60 assertions, 0 failed.

| Test file | Tests | Assertions |
|---|---|---|
| `test_land_mt_meadows_ships.gd` (new pin) | 2 | 10 |
| `test_meadows_ridge_vl.gd` | 4 | 20 |
| `test_warrens_meadow_match.gd` | 3 | 19 |
| `test_warrens_hill_shell_r2.gd` | 2 | 7 |
| `test_warrens_shell_seat_f38_30.gd` | 1 | 4 |

The Warrens runtime smoke was not run (selective checks; presentation only).
