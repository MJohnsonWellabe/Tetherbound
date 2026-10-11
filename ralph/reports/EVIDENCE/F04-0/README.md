# F04#0 Warrens guardian: evidence (lane meadows-fights, branch tb/ev-meadows-fights)

Run 2026-10-11 CT, Godot 4.7-stable headless, Linux container. Base main 9e39d008.

## Result: PASS (smokes). Visual read is pending the coordinator's GPU capture and code-blind judge.

| Check | Commit | Command | Result |
|---|---|---|---|
| Guardian attack witness | ea3a1ebb | `godot --headless --path . --script tests/smoke_warrens.gd -- --guardian-attacks` | PASS: sequence Q, C, Q, C; tell/recovery .85/1.1 and 1.1/1.2; Earth Fist cone/lunge from MoveDB; 1 hit, 2 misses (`smoke_warrens_guardian_attacks.log`) |
| Full Warrens smoke | ea3a1ebb | `godot --headless --path . --script tests/smoke_warrens.gd` | PASS (`smoke_warrens_full_tail.log`) |
| Tell timing pins | d885d383 tree | `godot --headless --path . --script tests/run_tests.gd -- --only=test_named_fight_tell_timing.gd` | 6 tests, 310 assertions, 0 failed |
| Regression units | ea3a1ebb tree | `run_tests.gd --only=test_named_fight_tell_timing.gd,test_enemy_pattern_telegraph.gd,test_telegraph_glow.gd,test_named_fight_profiles.gd,test_f22_action_publication.gd` | 28 tests, 1513 assertions, 0 failed |
| F22 contracts | ea3a1ebb / d885d383 tree | `tests/smoke_f22_pattern_contract.gd`, `tests/smoke_f22_live_pattern_mount.gd` | both pass |

d885d383 only changes the DIVER marker leap (F04#1), which the guardian does not use.

## Root cause of the failed re-proof

At runtime the F22 named pattern `named_warrens_guardian` replaced BOSSES §4.1's authored sequence. It used:
- the generic `wall_check`: 0.9/0.9, raised to 1.00/0.90 by the Meadows chapter floor;
- a `guardian_earth_fist` row with 5 m / 85° / 0 m geometry, not MoveDB's 3.8 m / 72° / 6.5 m.

Both drew the shared magenta cone. `test_named_fight_tell_timing` passed because it never mounts F22 patterns.

## Fix (ea3a1ebb)

- `data/config/combat.json`:
  - new `guardian_wall_quick` row: .85/1.1, the guardian's ordinary geometry, violet `#8f7dff` cone;
  - `guardian_earth_fist`: 1.1/1.2, `move_geometry` (MoveDB range/cone/lunge), orange `#ff9e1f` cone;
  - the guardian's named sequence now runs quick then Earth Fist;
  - both rows carry `bosses_timing`.
- `combat_ai.gd`: a `bosses_timing` row keeps its BOSSES tell and recovery over the chapter clamp. COMBAT's absolute floors (0.8 s tell, 0.6 s recovery) and the 1.1 s heavy floor still apply.
- `wild_creature.gd`: `move_geometry` overlay, plus `tell_colour()` for the attack row's ring, cone and guard cone (falls back to `telegraph.colour`).
- `combat_manager.gd` (warning ring) and `shared_opponent_proxy.gd` (guest cue) use that colour, so guests see the same tells.

Neither tell colour is red, oxblood or magenta.

## Disclosed harness changes (tests/smoke_warrens.gd, no assertion changed)

The smoke failed on unmodified main before any attack ran ("aggressive engage route did not open combat"). Two later systems had made its fixture stale:
1. **Party enrolment.** The fixture adopts a Terrapup but never puts it in `Game.party`, so `_canonical_wild_start_state` refused the fight. It now enrols the creature, as `tools/_capture_vfx_moments.gd` does.
   Coordinator approved this change (2026-10-11). Checked against production: the real starter choice, `scripts/story/sequence_director.gd::_adopt`, calls `adopt_starter` and then puts the creature in `Game.party`. The typed path does it through `autoload/game_state.gd::commit_original_starter`, which calls `party.add(instance)` at line 3211; the legacy path does it through `_give_to_party`, which calls `party.add`. `adopt_starter` alone never touches the party, so the fixture reproduces the production state and hides no game bug.
2. **Where misses are reported.** Production wild strikes are resolved by the director's host simulation (`shared_wild_host_fight.gd`), which reports misses on its own node. The witness now also counts that node's `attack_missed`. Hits already reach CombatManager through `apply_host_enemy_hit`.

## Not addressed here

The re-proof's "camera too close/occluded" finding needs a rendered capture. No camera change was made; the coordinator's capture decides it.
