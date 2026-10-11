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

## Round 2: code-blind judge FAIL fix (2026-10-11, about 11:50 AM CT)

**Judge finding.** The capture was `tb/ev-captures` 53d9616f (`ralph/reports/VISUAL-PROOF/F04-0/`). Earth Fist showed only a small amber ring at the guardian's feet, and the quick showed the same ring in purple.

**Cause (game bug).** `enemy_pattern_telegraph.gd::begin` set `top_level = true` *after* `add_child`. Godot keeps the node's current global transform at that moment, and the cue builds its vertices in world coordinates. Under the translated `BurrowWarrens` parent at (−357, 3.8, 2610), every F22 pattern cone was therefore drawn about 2.6 km from the fight. A headless trace confirmed it: `cue_global` equalled `parent_global`. Only the warning ring (`telegraph_glow.gd`) reached the screen. Any F22 pattern cue whose creature's parent is not at the world origin had the same fault. `lunge_lane.gd` already sets `top_level` before `add_child`, so it was not affected.

**Fix.**
- `top_level` is set before `add_child`.
- Each row may now set its own fill:
  - the guardian quick (`guardian_wall_quick`) is an outline-only violet wedge (`cue_fill_alpha` 0);
  - Earth Fist is an orange wedge (`cue_fill_alpha` 0.5) that fills in over its 1.1 s tell (`cue_fills`, material alpha 25% → 100%). The wedge uses the move's own `range` and `cone_degrees` and follows the locked heading.

Both wedges really reach about 8.5 m, because contact spacing between the two large bodies floors the reach. The quick's wedge is therefore not drawn smaller than its real hit area.

**Local self-check (not judge evidence).** `local_render/`: xvfb + llvmpipe `opengl3`, 1280×720, `smoke_warrens.gd -- --guardian-attacks --capture-dir` with the den fixture teleport, at Earth Fist fill 0.32 (the final value is 0.5). Frame 01 shows the violet outline wedge with its tip past the Terrapup; frame 02 shows the filled orange 72° wedge.

**Proofs at this commit.**
- `smoke_warrens --guardian-attacks` PASS: Q, C, Q, C; 1 hit, 2 misses.
- Units PASS: `test_enemy_pattern_telegraph`, `test_named_fight_tell_timing`, `test_telegraph_glow`, `test_named_fight_profiles`, `test_f22_action_publication` (28 tests, 1513 assertions, 0 failed).
- `smoke_f22_pattern_contract` and `smoke_f22_live_pattern_mount` PASS.

## Round 3: coordinator-approved items (b) and (c) (2026-10-11, about 12:40 PM CT)

**(b) Tether Commands meter.**
- `combat_hud.gd` now anchors the meter bottom-centre (`PRESET_CENTER_BOTTOM`, growing upward, 24 px margin). It used to sit 160 px above the party strip, over the play space.
- `tether_command_meter.gd` drops the trailing " ×" unavailable mark; the existing muted colour carries that state. The pouch count now reads "(N held)", so Item throw shows "25  (0 held)" instead of "25 ×0 ×".

**(c) Den cairn.**
- The amber spikes on a dark root-rock base are `DenRootstoneCairn`. It is built in code (`burrow_warrens.gd::_build_warrens_landmark_motif`), not from JSON, so its placement now reads `burrow_warrens.json` → `landmark.den_cairn_offset`. The fallback is the old (5.2, 4.4).
- It moves to (−12.5, 12.5) from the den centre: 17.7 m out, which is outside the guardian's 16 m arena (centred on the den) and inside the 19.5 m den shell. That corner (−x/+z) is clear of both the hall>den passage (−z edge) and the den>vault passage (+x edge). The cairn is non-colliding.
- `GuardianRootNest` was not moved. It is the guardian's own low root bed, at most 0.42 m tall, at its spawn point (den centre + (0, 4)), deliberately inside the arena, and below the guardian's forelegs.

**(d)** The coordinator recorded it as an owner decision for the end.

**Proofs at this commit.**
- `smoke_warrens` (full) PASS.
- `smoke_warrens -- --guardian-attacks --guardian-settled-approach` PASS: natural admission after a 46.2 m input walk from hall to den; Q, C, Q, C; 1 hit, 2 misses.
- Units PASS: `test_combat_hud_handheld_floors`, `test_burrow_warrens_visual_identity`, `test_f24_host_commands`, `test_enemy_pattern_telegraph`, `test_named_fight_tell_timing` (57 tests, 3071 assertions, 0 failed).
- `smoke_combat_hud_left_column` PASS.
- Local llvmpipe frames `local_render/r3_*` (self-check, not judge evidence): the Commands lane at bottom-centre, the cairn beyond the arena edge, and the Earth Fist wedge solid by mid-tell.
