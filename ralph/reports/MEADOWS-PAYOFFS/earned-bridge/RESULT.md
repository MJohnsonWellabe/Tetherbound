# F02-a — earned route passes the South Bridge

Status: **prefix passed once (`--through-bridge`, run 4); robustness still open.** That pass predates the harness changes in de7d240bf, dfe2e9dee and f759b4b4e. No run has passed with the current harness, and the run-6 and run-7 fixes have not yet been exercised end to end. F02 is not claimed.

Command (headless, fresh isolated save, no injection/teleport):

    flock <scratch>/godot-writer.lock timeout 5400 godot --headless --path . \
      --script tests/smoke_four_biome_continuous.gd -- --through-bridge

## First failure on base 47774c350 (run 1)

    [meadows_earned_team] FAIL: No living low-level practice-meadow wild is available for earned training
    FRESH CAMPAIGN RESULT {"reached":"village","requested_prefix_passed":false, ...}

The run failed after ten training wins. By then every eligible practice-meadow
wild had been used. Party at failure: ripplet L6, bramblebun L4 (177 xp), mudsnout L6,
mudsnout L5, bramblebun L5. The level-5 entry gate needs all five at L5.
Cause: `pilot_selection()` gave under-level members only +2 on a 0..10
health score, so the L5–6 lead at about 78% HP beat the L4 starter at 50% HP
and took every fight. The starter got only the smaller shared-XP share. The
pilot's own comment says it prefers an under-level creature when carried care
is available.

## Fix

`tests/helpers/meadows_earned_team_segment.gd`: `UNDERLEVEL_PILOT_BONUS = 10.0`
(larger than the whole health-score range). This applies only when carried potions
remain and the fight is training. Selection with no potions left, and outside training,
is unchanged. A unit test covers the observed shape. Diagnostic-only receipts were added
for a refused engage and for an exhausted training pool.

## Passing run (run 4) key receipts

    wild_training_win 6..10 with party_cycle to under-level members (fix active)
    team_ready: ripplet 6, bramblebun 5, mudsnout 6, mudsnout 5, bramblebun 5
    EARNED TOURNAMENT — tournament_quarter_mira won through 2 real opponent defeats and 15 landed attacks
    EARNED TOURNAMENT — tournament_semi_tam won through 2 real opponent defeats and 25 landed attacks
    EARNED TOURNAMENT — tournament_final_oskar won through 3 real opponent defeats and 42 landed attacks
    EARNED BRIDGE — { "trainer": "south_bridge_grunt", "depth": -11.53173828125, "beat": "guardian_admitted" }
    EARNED BRIDGE — { "trainer": "south_bridge_grunt", "wins": 2, "hits": 43, "key_reward": 1,
      "key_remaining": 0, "depth_before": -11.53, "depth_after": 9.44, "beat": "south_bridge_crossed" }
    FRESH CAMPAIGN RESULT {"campaign_complete":false,"elapsed_seconds":1641.74,"failures":[],
      "reached":"south_bridge_crossed","requested_prefix_passed":true}
    EXIT=0

The guardian stayed at its BOSSES spec (Mudsnout 10, Burrowback 12). No change was made to
combat, data or the smoke driver.

## F02-b — reruns 5–7, seed dependence and failure classification

Every fresh save rolls its own world seed (`spawn_tables.json` `roll_new_worlds: true`,
`autoload/game_state.gd:804`). Table clusters 1006 and 1007 near the practice meadow roll
species from `meadows_open` per seed. The team segment now records the seed at the start
(`world_seed` receipt).

### Training pool is seed-dependent (M2 solvency, open owner question)

Seeds 0–1000 were computed with `spawn_tables.plan_for`, counting bramblebun/mudsnout
bodies within the driver's 160 m practice radius, before the level filter.

| bodies | share of seeds | after 4 catches (1 opening + 3 team) |
|---|---|---|
| 14 | 28.9% | 10 |
| 11 | 22.1% | 7 |
| 10 | 26.2% | 6 |
| 7 | 22.9% | 3 |

Reaching L5 on all five took **10 wins** in both run 4 and run 5 (award 30+16L,
bench share 0.5). Only the 14-body class (about 29% of seeds) finishes without waiting for
respawns. The other classes are short by 3, 4 or 7 wins, which costs up to one 300 s
respawn cycle per exhausted pool: about 5 minutes of waiting for the 7- and 6-body classes,
and up to about 15 minutes for the 3-body class. Run 3 was a 7-body seed and stopped at
3 wins, which matches exactly. Spawn density is unchanged here; this is routed to the owner.

Harness change (de7d240bf): when the pool is exhausted, the pilot waits in world for the
soonest eligible production respawn, taking at most one cycle. There is no skip, teleport
or state write. Run 5 (seed 1376461701, 1006 rolled trailpup): exhausted at 7 wins,
logged `training_respawn_waited` after 186.5 s, then `team_ready` on win 10.

### Shared defect: a caught wild respawns as the player's creature (filed by lead)

`encounter_director.gd` CAUGHT branches (local around line 4847, hosted around line 2912)
leave the body's `instance` pointing at the creature now in the party (`_resolve_catch`
adds that same object). 300 s later `_tick_respawn` calls `revive_at_home()`, which runs
`instance.heal_fully()` and makes the body visible again.

Live evidence from run 5, across the respawn wait: the HP of all four caught members jumped
(62→118, 31→124, 24→118, 16→104) while the uncaught starter stayed at 104. The pool
receipt shows 0_2, 0_3, 1070_1 and 1070_2 carrying the party's levels (4/5/6).

### Failure classification

| run | seed | first failure | class |
|---|---|---|---|
| 1 | not recorded | training pool (under-level pilot never fielded) | harness, fixed 4e93a36e4 |
| 2 | not recorded | catch engage refused once | no recurrence in runs 3–7; diagnostic 45ca6f9da |
| 3 | not recorded (7-body class) | training pool exhausted at 3 wins | seed variance plus no respawn wait; harness fixed de7d240bf |
| 4 | not recorded | **pass** (`south_bridge_crossed`) | — |
| 5 | 1376461701 | Halda gave `tournament_halda_condition` about 12 s after a ready rest | unexplained; readiness print added e06b56965 |
| 5b | 1376461701 (pinned) | opening catch: creature lost after 3 assisted misses (`reason=ground`, the orb hits rising terrain just short of the assist's predicted point) | shared throw-assist prediction, plus slow aim letting the fight run on |
| 6 | 1901707716 | camp: `_place_fixture` recorded a hard failure for an unreachable bed stance, although the next candidate spots succeeded | harness (a missed candidate is now non-fatal) **plus unexplained blocking, open**: three approaches stopped about 4 m short with only terrain contacts. That may be real walkability at the build patch, or the respawned caught 1070 mudsnouts. The `bodies_near_target` print (4e2c937ec) has not been read yet. |
| 7 | 1787955782 | team catch aim: `line_of_sight_blocked` for 3×12 s from the same spot at 7.3 m | harness, fixed (`aim_recovery` repositions; unit test) |

Result: 1 pass (run 4) against a target of 3, from 8 attempts (runs 1–7 plus 5b). Full runs were stopped at lead direction.

**The respawn wait passes through a shared defect.** While waiting, the caught members were fully healed by the shared catch-respawn defect (run 5: 62→118, 31→124, 24→118, 16→104), and a revived caught body is the player's own creature standing in the world. Until that defect is fixed (filed with the coordinator), a pass that includes a respawn wait is easier than intended play. It must be re-run after the fix before it can count.
Remaining: the marshal refusal (needs a run with the e06b56965 print), the shared
throw-assist ground miss, and the shared catch-respawn defect.
