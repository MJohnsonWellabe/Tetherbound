STATUS: land
BRANCH: tb/item-f38-26
HEAD: (this commit; merged origin/main just before writing)

# ITEM F38#26: P2-020 creature ground contact (Meadows) (LANE-KIT)

## Scores
- Earlier round (parked): fixed-stand re-score, CPU mapped 6.53. The grass-clearing radius arm was flat, so no round was spent on it.
- This round, qj F38-26-8ba717064855-11072338 (CPU llvmpipe, three code-blind judges, 3 anchors):
  base 6.27 -> candidate **6.97** (+0.70). Raw 5.3 5.6 5.5 / 5.8 6.0 6.0. Defect PARTIAL,PRESENT -> PARTIAL (3/3).
- All three judges: the fainted Mosshell (frame 3) is no longer a pale, translucent, floating ghost. It sits as an
  opaque textured shell on the ground.

## Flag (ON, judged gain)
- data/config/creature_pose_settle.json `lanekit_mosshell_scope` (`enabled: true`, `_why_on` naming the round and the
  6.27 -> 6.97 gain). The existing CAUSE-POSES settle (faint grounded + crumple, which rights the belly-up fall onto the
  plastron and plants it; hit grounded) runs for Mosshell only. The roster-wide master stays OFF and tidewake_scope
  stays OFF. Presentation only: no state, no mesh, no size change.

## Code
- scripts/creatures/creature_pose_settle.gd `scoped()`: every enabled top-level `<name>_scope` now unions its species
  (previously only `tidewake_scope` was read). With the master ON, scopes are ignored as before. With no scope
  enabled, the config is unchanged.

## Tests
- test_cause_poses_settle.gd 3/3. The new test covers the scope union, no scope enabled, the master ignoring scopes,
  and the shipped state (Mosshell only).
- JSON parse: creature_pose_settle.json. No textures added, so the texture policy is unaffected.

## Files
- data/config/creature_pose_settle.json, scripts/creatures/creature_pose_settle.gd, tests/test_cause_poses_settle.gd
- ralph/reports/LANES/LANE-KIT/qj/F38-26-8ba717064855-11072338/

## Flags left OFF
- creature_grass_clear.json p2_020_candidate (radius x2.1). It was flat in the earlier round.

## Judges' asks (remaining, frames 1-2 and scene)
- The hare and the owl in frames 1-2 read no taller than the trainer, and they are small and pale behind him. The
  stand is in creature_scale_flags.json, which is not this lane's file.
- Grass still covers some feet (defect PARTIAL). Creatures lack rim light, and the foreground bush is distracting.

## Next idea
- A per-species daylight rim on the two pale stand subjects through the existing coat rim
  (creature_coat_flags.json, mine), so they separate from bright grass. Expected to be modest; this needs a GPU look first.
