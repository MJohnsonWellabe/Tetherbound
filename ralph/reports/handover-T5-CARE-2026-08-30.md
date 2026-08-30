# T5-CARE — building, survival and care, played

**Branch:** `ralph/T5-CARE` off `origin/ralph/LAND-0830I`
**Scope:** `ralph/MEADOWS_EXIT_CRITERION.md` section H (H1–H6) and section I.
**Status:** IN PROGRESS — checkpoint commit. Verdicts below are not final until
each carries played evidence.

## Why this lane exists

Section H was entirely unevidenced. Over a long night of parallel work, lanes
covered visuals, terrain, story, content, combat, performance, reliability and
audio; nobody verified building, survival or creature care by playing them.

## Method

Godot 4.7-stable (the pinned CI version) installed in-session; the real
`scenes/world/meadows_playground.tscn` driven by parsed physical joypad events
through the live InputMap, in the style of `tests/helpers/gate_a_build_segment.gd`.
No config-level assertions stand in for a played path.

## Findings so far (pre-play, from reading the shipping code)

Each of these is a HYPOTHESIS until the play session confirms it.

- **Backpack cannot feed the player.** `tab_backpack.gd::_read_use()` tests
  `creature_food` (line ~1221) BEFORE the player's own `satiety` branch
  (~1231). `berries` is the ONLY item in `data/items/items.json` carrying a
  `satiety` value, and it also carries `creature_food` — so the backpack's Use
  verb always opens the "Who eats it?" creature picker and the player-eating
  branch below it is unreachable from that screen. The picker offers party
  creatures only; there is no player row (`_eligible`, `_apply_to_creature`).
  `playground_hud.gd:3089` (the hotbar slot press) checks `satiety` first and
  DOES feed the player, so the player can eat — but only if they put berries
  on the hotbar. `playground_hud.gd`'s own comment at ~3077 still claims "the
  backpack could always eat berries", which the D68 creature-feeding change
  silently falsified.
- Satiety model itself matches CLAUDE.md: `vitals.json` drain 0.8/min, soft
  `hungry`/`critical` tiers, no death path. `tick_satiety` is called from
  exactly one live branch per frame (walking or riding, mutually exclusive).

## Corrections to earlier prose

- The Gate F note blaming `creature_bed_built_3` on "stick-driven placement"
  needs no code fix on this branch: `home_progress.gd::maybe_set_creature_beds()`
  IS called from both `build_placer.gd` placement paths (`_place` and
  `restore_from_game`). The objective data has additionally been rewritten
  (FIRST-HOUR-FUN-REBUILD) to require ONE bed, so the 3/3 rung no longer ships.

