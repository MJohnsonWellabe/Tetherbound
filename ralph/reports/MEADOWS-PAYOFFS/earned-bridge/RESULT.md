# F02-a — earned route passes the South Bridge

Status: **prefix passed once (`--through-bridge`); robustness still open** (see "Open").

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

## Open (not fixed here)

- The training pool has zero margin. The driver filter (bramblebun/mudsnout, level <= 5,
  within 160 m of the practice meadow) leaves exactly ten non-caught bodies, and a pass
  needs all ten. Run 3 found no candidate after only three wins (reached=village), and
  the cause is not identified yet. The new `training_pool_exhausted` receipt lists every
  nearby wild with its level, alive, visible and engaged state for the next occurrence.
- Run 2 hit a one-off "The offered wild did not enter combat after Interact"
  during the catch loop. It did not recur in runs 3 and 4. The new
  `wild_interact_refused` receipt now captures its state.
- One warning line: `[village] 'south_bridge_grunt' offered a battle that could not start`,
  logged just before the real admission. It was harmless in this run.
