# READY: tb/beings-storm-land (F41#8, F41#18)

STATUS: land

- **Branch:** `tb/beings-storm-land`, cut from `origin/main` b8622117.
- **Arms:** two inherited LANE-BELOW6 arms, judged by LANE-JUDGE on tb/judge 190fd4eb4 (GPU High, panel about 0.7 strict, control 7.53).

| Arm | Flags turned ON | Verdict |
|---|---|---|
| BELOW6-STATICUB-FUR | `creature_coat_flags.json below6_staticub_storm_fur` | `G-below6-staticub-fur-dialogue-c673.md`: SHIP. Officer Nysa frames 5.95 -> 6.45 (+0.50, 3/3); F41#8 Maud and Bryn 6.09 -> 6.27 (+0.18, 3/3); no loss. |
| BELOW6-UNIFORM-CLOTH | `character_body_flags.json below6_uniform_cloth` and `stormwood_character_presentation.json uniform_cloth_floor_1113` (judged together) | `G-below6-uniform-cloth-c673.md`: SHIP, thin. F41#18 row 5.95 -> 6.02 (+0.07, 2/3); dialogue +0.18 (3/3); officers no-loss +0.18 (3/3); no set loses. |

Each flag carries a `_why_on` naming its verdict file and scores.

## One code fix, found by the tests (please read)
With the cloth floor ON, `tests/test_below6_marrow_landed.gd` failed: Captain Marrow's emission floor went from 0 back to 0.04. `stormwood_character_presentation.gd` let the cloth floor overwrite an identity's own floor (`identity_floor_1112`), which would have undone Marrow's landed white-head fix (G-below6-marrow, 4.55 -> 5.95). The block's stated intent is "the lower floor", so it now takes the minimum of the two: every judged uniform (Dace, Varga, Sable, Sera, Maren, Tavi) still gets 0.04, exactly as in the verdict, and Marrow keeps 0. Pin: `test_cloth_floor_never_raises_an_identity_floor` in `tests/test_below6_marrow_landed.gd`.

## Tests
- Pins: `test_staticub_storm_fur_flag.gd` and `test_uniform_cloth_flag.gd` now assert ON with the verdict citations; `test_dark_value_lift_flags.gd` adds `below6_staticub_storm_fur` to `LATER_COATS` (it replaces the Staticub value lift); `test_character_body_flags.gd` adds `below6_uniform_cloth` to `JUDGED_ON`.
- Run: every test file that reads `creature_coat_flags.json`, `character_body_flags.json` or `stormwood_character_presentation.json`, or names Staticub or the emission floor: **110 tests, 3059 assertions, 0 failed** (before the fix: 2 failed, both described above).

## Not closed
F41#8 and F41#18 stay open. Next asks (3/3): opaque shaded cloth with character rim light; a rank accent that reads at normal distance; separate faces for Sera/Maren and Nysa/Varga; break up the row of identical uniformed figures behind Maud.
