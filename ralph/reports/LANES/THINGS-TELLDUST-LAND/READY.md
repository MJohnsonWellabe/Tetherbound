# THINGS-TELLDUST-LAND: wind-up dust as one soft low band

STATUS: land

- **Branch:** `tb/things-telldust-land`, cut from `origin/main` 0a57e6d7.
- **Verdict (LANE-SCOUT):** `G-things-telldust.md` (`tb/item-scout-1108` a19cc351), GPU. 3/3 prefer the arm on every set; no loss.

  | Set | Base | Arm | |
  |---|---|---|---|
  | F38#3 High | 7.08 | **7.51** | +0.43 |
  | F38#3 Medium | 7.08 | 7.47 | +0.39 |
  | F38#28 High (Warden 03/05) | 7.16 | 7.47 | +0.31 |
  | F38#28 Medium | 7.29 | **7.55** | +0.26 |
  | F38#11 tell frames | 6.56 | 6.95 | +0.39 |

- **Nothing closes:** F38#3 misses on Medium by 0.03 and F38#28 misses on High by 0.03. Both are near-bar.
- **What ships:** `data/config/combat.json telegraph.soft_style`, five values, with `_why_dust_band_1113`: `dust_size_m` 0.42 to 0.8, `dust_spacing_m` 0.34 to 0.3, `dust_alpha` 0.6 to 0.32, `dust_rise_m` 0.16 to 0.06, `dust_colour` `#9c8763` to `#8a7654`. Config only. Hit geometry and timing unchanged; painted outlines stay off (owner, 24 Oct).
- **Danger cue (the check asked for):** not lost. Judges read the danger from the "! incoming" HUD line on both sides; the old beads read as "a debug particle path", the new band as "kicked-up earth".
- **Tests:** new `tests/test_tell_dust_band_landed.gd` (3 tests: the five values and the verdict; puffs overlap; dust on and outlines off). No older test pinned these values (grepped).
- **Tests run on this branch:** the new file plus all `test_tell*`, `test_telegraph*`, `test_enemy_pattern*`, `test_named_fight_tell*`, `test_combat_arena*` (9 files): 32 tests, 7367 assertions, 0 failed.
- **Scope:** every fight in every realm draws its wind-up dust this way. Only Meadows fights were judged.
- No `.uid` files are included.

## Judges' next asks (3/3)
- Short grounded contact puffs that stay off the creatures' legs and heads (on one grunt frame the band crosses in front of the boar's legs).
- A ground telegraph or wind-up pose, since the dust is not read as a danger cue on its own.
- F38#28: a translucent green vertical plane behind the dog in the Warden hall reads as exposed geometry (2/3); removing it may be the 0.03.
