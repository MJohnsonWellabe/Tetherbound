# S10d findings (attempt 2, run against the corrected gorge-carve fix)

S10d completed (`INVENTORY.json`: `complete: true`, 26 pass / 2 fail / 0
delegated). Two real, distinct, and non-catastrophic events:

## 1. A natural wild encounter fainted the deployed creature (not a bug)

Inherited from S10c: at t=227.7-313.1 in S10c's own run (position
(6.92,4.95,7315.73), on the approach-drain leg), a wild creature engaged
Bramble in combat. The harness's `move_to` loop only drives movement input,
not combat moves, so Bramble took 38 small hits passively (2.33s apart,
6.3-7.6 damage each) over ~85 seconds and fainted; `combat_end` then fired
and the walk resumed normally. This is the world doing exactly what its own
design says it should: "the world is not frozen" during the post-win
walk-back, and a wandering wild creature can still start a fight (flagged
as a real risk in `ralph/reports/handover-T2-S10-COST-2026-08-30.md`, never
previously observed because no run had completed the walk far enough to hit
it). Not a defect -- a real, honest consequence of a synthetic walk-only
harness meeting a live game system, worth recording rather than hiding.
`S10c-exit.json`/`S10d-exit.json` both carry Bramble fainted (hp 0/249.6);
the other four party members are untouched.

## 2. The Tether-Relay-to-Warrens leg fell 1490m short, because of an
   unbeaten trainer my hand-authored seed never accounted for

S10d-97 (walk to the Burrow Warrens, target (-420,2470)) stopped at
(339.0,6.0,3752.0), 1490.2m short (80 held frames along the way). Just
before it, S10d-96 (`interact` near the Tether Relay) opened a real
`trainer_no_usable_creature` conversation ("Your creature can't fight like
this... a bed will do it, or something to revive it on the spot" --
consistent with #1 above, since Bramble is fainted and nothing is deployed
after `S10d-09a`'s recall). `relay_officer_dell` stands at (347.5,3763.5),
14m from the stall point, and `defeated_relay_dell` was never included in
this lane's hand-authored seed flag list (`tools/gate_f/
build_s10b_synthetic_seed.gd`) -- only `relay_captain_defeated` is, because
that is the one flag `objectives.json`'s 26-entry main chain actually
requires. A real player reaching this point in a real playthrough would
very plausibly have already beaten Dell, Hess and Orrin along the way (they
guard the same ground the main chain's own `defeat_the_relay_captain`
objective sends the player through) -- this lane's seed simply does not
carry that history, because it was built to satisfy the main chain's
26 required flags, not every optional trainer along the route.

**This is a seed limitation, not a game defect.** Nothing in `road_gate.gd`,
`meadow_healing.gd`, or the trainer/encounter systems is implicated; an
unbeaten Team Tether officer correctly refusing to be fought with nothing
sent out, and correctly holding the player's attention for a beat, is
exactly the designed behaviour. Flagged rather than "fixed", because fixing
it would mean either inflating the seed with flags the main chain does not
require (misrepresenting what a "clean, minimum-viable" S10b-exit looks
like) or teaching the walk to fight back (out of this lane's scope).

## What still worked

The walk recovered from both events on its own: `S10d-exit.json`'s final
position, (1.17,-2.88,1337.71), is ~8m from the South Bridge target
(0,1330) -- the segment's third `move_to` (S10d-98) reached its real target
even though the second one (S10d-97) fell short. Party of 5, version 16,
flags intact, day 9. Proceeding to S10e from this save.
