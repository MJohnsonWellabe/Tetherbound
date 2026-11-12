# THINGS-FAINT2-LAND: eight more faints collapse belly-down; ships ON for the rows the judges preferred

STATUS: land

- **Branch:** `tb/things-faint2-land`, cut from `origin/main` 4e35bfbd.
- **Verdict (LANE-SCOUT):** `G-things-faint2.md` (`tb/item-scout-1108` 102221c2), GPU High. The arm was a split; only the winners are here.

  | Row | Base | Arm | Judges |
  |---|---|---|---|
  | pebbik | 7.00 | **7.65** | 3/3 |
  | breezetail | 7.31 | **7.61** | 3/3 |
  | water mangrove monitor | 6.84 | **7.19** | 3/3 |
  | paddlenewt | 6.47 | **6.96** | 3/3 |
  | riftfrill | 6.43 | **6.85** | 3/3 |
  | shadelet | 5.43 | **6.09** | 3/3 |
  | mosshock | | +0.23 | 2/3, rides along |
  | stormraven | | +0.15 | 2/3, rides along |

  Pebbik and breezetail meet the bar at High; Medium captures decide whether they close.
- **Dropped, as judged:** stormtrail (−0.57), trailpup (−0.48), voltwig (−0.44) and sparkit (−0.40), 0/3 each: the crumple read as "cowering, not collapsed" and their side-lying faint is preferred. Cragclaw's head change was level (+0.04). None of these is in the config; the test pins that.
- **What ships (game):**
  - `data/config/creature_pose_settle.json`: `things_faint2_scope` ON with `_why_on` (pebbik, breezetail, shadelet, paddlenewt, riftfrill, mosshock, stormraven); a `faint.per_species` row for each (`force`, `tail_relax`); water mangrove monitor comes off `exclude_species` with its own row (no torso drop, so it is not sunk into the floor).
  - `scripts/creatures/creature_pose_settle.gd`: `crumple.force` (one line; inert without a per-species row).
- **Tests:** `tests/test_things_faint_ground.gd` gains `test_round_two_scope_ships_the_winners_and_not_the_losers`; `tests/test_cause_poses_settle.gd`'s pinned scope list gains the seven species.
- **Tests run on this branch (per-file lines checked):** `things_faint_ground` 4, `cause_poses_settle` 3, `f36_pose_candidates` 1, `rest_faint_settled` 1: 9 tests, 92 assertions, 0 failed.
- **Stage check on this branch (CPU):** pebbik, shadelet and water mangrove monitor end belly-down with no overlay; trailpup is unchanged.
- No texture is touched. No `.uid` files are included.

## What the judges said to carry forward
- Rewarded: prone or side-lying, head on the ground, tail flat. Punished: belly-up, raised haunches, any wing, tail, crest or fin shard sticking up.
- Still open: stormraven's wing stands up like a fin and its hit frame shows a slab tail (3/3); paddlenewt and riftfrill show fin and crest shards; shadelet's feet float in the hit reaction.
- Close-out candidates: water mangrove monitor 7.19, stormraven 7.00.
