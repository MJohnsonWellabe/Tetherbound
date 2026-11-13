# SCENE-TELLDUST3-LAND: the wind-up dust as one coherent low band

STATUS: land

Branch `tb/scene-telldust3-land`, cut from origin/main (after #953).

## Verdict
LANE-JUDGE `ralph/reports/GPU-PASS/1108/G-things-telldust3-grunt-medium.md` (tb/judge ae67d0a5), GPU Medium, base = the round-1 band on main, mapped scores:

| Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| F38#11 fight tell and hit effects | 6.55 | 7.06 | +0.51 | 3/3 |
| F38#3 | 7.24 | 7.28 | +0.04 | 1/3, 2 ties |
| Control F38#38 | 8.01 | 8.01 | | |

Ship rule: a gain above 0, at least two of three prefer on F38#11, no judged set loses. **No criterion closes.** F38#3 stays open (0.22 short at Medium in this batch). F38#11 is at 7.06 at Medium only; it has no High score from this batch.

## What ships
- `scripts/combat/tell_style.gd`: `dust_puff`, with `dust_phase_coherence`. At 1 the puffs share one slow wave along the line instead of each fading on its own random phase.
- `data/config/combat.json` `telegraph.soft_style`: `dust_phase_coherence` 1.0, `dust_size_m` 0.8 to 0.5, `dust_spacing_m` 0.3 to 0.2, `dust_rise_m` 0.06 to 0.04, `dust_max` 260 to 400, with `_why_dust_coherent_1113` citing the verdict and both scores. These are the arm's overlay values as judged. `dust_alpha` and `dust_colour` are unchanged.
- Presentation only. The painted attack outlines stay off, and the wind-up still raises dust (pinned).

## Tests
- `tests/test_tell_dust_phase_coherence.gd` (new): the ON pin with the judged values and the verdict citation; beads with coherence 0 and one band with coherence 1; coherence 0 is the old formula.
- `tests/test_tell_dust_band_landed.gd`: the round-1 pin on size, spacing and rise now pins the round-2 values (0.5 / 0.2 / 0.04). This is a pin update for a judged change, not a skipped test.
- Run together with the landing values: the 41 test files that touch `tell_style`, `soft_style` or `telegraph`, plus `test_flag_scopes.gd` and `test_characterize_flag_keys.gd`: **338 tests, 0 failed.**
- Not run: the full suite.

## Left open by the judges (not in this landing)
- F38#3: the opposing Tether trainer half-hidden behind the boar; the player trainer pressed against Terrapup's muzzle; flat olive grade.
- F38#11: a dirt or stone burst and a recoil pose on hit.
- Flags: Terrapup's HUD element reads "WIND"; a red-orange marker and crate at the bottom right under the HUD.
