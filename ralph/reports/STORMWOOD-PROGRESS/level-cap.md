# Stormwood Phase 1 level-cap lane

## Change

`data/config/progression.json` now ships `level.cap` at `100`. No production
progression formula or save/autoload/network/scatter code was changed.

`tests/test_progression.gd` adds assertions for the shipped cap, the exact XP
curve at levels 33, 44, 50, and 100, XP crossing level 50, candy at levels 44
and 49, a lower configured cap, and clamping at level 100.

## Numeric evidence

These are calculations from the shipped config and `scripts/creatures/progression.gd`,
not a playthrough. The production function is:

`int(base * pow(float(maxi(level, 1)), exponent))`

With `base=40` and `exponent=1.15`, the production results are:

| Level | XP to next |
|---:|---:|
| 33 | 2230 |
| 44 | 3104 |
| 50 | 3596 |
| 100 | 7981 |

The level-44 value is 3104 because GDScript's `int` truncates the floating
result; an earlier hand calculation recorded 3105 and was corrected to match
the production function. Cumulative XP from level 3 is 32,992 at level 33,
61,863 at level 44, 81,717 at level 50, and 367,099 at level 100. Reaching
level 100 therefore costs 285,382 XP beyond level 50.

Candy/gain-level calculations: starting at level 44, +1/+2/+3 levels reach
45/46/47; starting at level 49, +3 reaches 52 under cap 100; the same +3
reaches only 50 under a temporary cap 50; starting at 99, +3 reaches 100 and
further candy grants zero levels.

The production functions covered are `Progression.xp_to_next` in
`scripts/creatures/progression.gd`, and `CreatureInstance.set_level`,
`gain_xp`, `gain_levels`, and `_apply_level_stats` in
`scripts/creatures/creature_instance.gd`.

## Verification

The focused cap selectors initially passed 4 of 5 tests; the only failure was
the stale expected value 3105 versus production's 3104. After correcting that
assertion, a complete `test_progression.gd` run was attempted with the
installed console Godot:

```powershell
& 'D:\CodexWork\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path D:\Tetherbound-source --script tests/run_tests.gd -- --only=test_progression.gd
```

The run exited with Godot signal 11 before reporting test results. The checkout
had concurrent Godot editor/console processes at the time; this is an
environment/runtime failure, not a reported assertion failure. The earlier
focused run's exact output was 4 passing and 1 stale-assertion failure.
