# Shared tournament — two-peer witness

Lane evidence for the Meadows co-op tournament milestone. It records what the
witness proves, what it reproducibly does not, and the measurement behind both.
It is evidence, not a status document; STATE carries the status.

## What this is

`tests/smoke_net_shared_boss.gd` gains an **opt-in** `--tournament` leg. The
file's default invocation remains the Warden regression, unchanged, and no CI
job runs the new leg:

    godot --headless --path . --script tests/smoke_net_shared_boss.gd -- --tournament

Two real processes enter the authored village tournament. Party preparation is
disclosed fixture setup — `tournament_setup` grants five ordinary owned
creatures and registers the first three through `Party`'s own five-member cap
and `set_tournament_selection()`, then requires the shipping
`tournament.gd::team_ready/training_ready/condition_ready` predicates to admit
them. Registration, combat, admission, rewards and reload all use production
doors.

Harness additions, all in `tools/net/peer_runner.gd`:

- `tournament_setup` step — the fixture above. It creates only ordinary owned
  creatures and never exceeds five.
- `tournament` probe — read-only: five owned UIDs, the three registered,
  the climb's flags, whether a trainer battle is live, and readiness computed
  by `tournament.gd` rather than restated.
- `win_trainer_battle` now reports enemy species, hp/max_hp, `quick_ready`,
  `is_fighting`, active hp, fainted and the last refusal on a timeout, instead
  of only frame and swing counts.

## Runs

Four local two-peer runs, Godot 4.7-stable, clean loopback, main `9cf6bde7d`.
Logs are `run-01.log` … `run-04.log` beside this file.

| Run | Leg | PASS | Distinct FAIL |
|---|---|---|---|
| 01 | first execution | 55 | 2 |
| 02 | guest stand-in seated | 55 | 2 |
| 03 | attempt diagnostics added | 56 | 1 |
| 04 | host-view reach gate added | 22 | 2 |

Run 03 is the version that ships. Run 04 is kept because it is the measurement
that decided against its own change.

## What the witness proves (runs 01–03, all three rounds)

For each of `tournament_quarter_mira`, `tournament_semi_tam` and
`tournament_final_oskar`:

- Both peers prepare five owned creatures, register exactly three, and their
  production readiness and three selected IDs are visible.
- The round mints **one** shared encounter record. The second peer **joins that
  record** rather than opening a second fight.
- Both peers receive the round's flag and its authored reward in full — 20
  coins + 2 `potion_small`, 25 + 3 `orb_basic`, 40 + 3 `potion_small` — matching
  `data/config/bands/band1_lower_meadows/trainers.json`.
- The final's `recipe_saddle` flag lands on both peers.
- The reward journal has **one** replicated durable world namespace, is
  identical on host and guest, and carries accepted durable receipts for **both
  stable participant character IDs** on both the coins and the item source.
- Both peers retain their selected three across a production disk reload — host
  through its slot, client through its portable character file, without the
  client replacing the hosted world.

The Warden leg additionally now saves and reloads both peers after the boss
falls, showing the once-only world outcome durable rather than merely
replicated, with its no-personal-receipt journal unchanged.

## What it does not prove — open, reproduced

**A guest cannot land its own damaging blow on the shared opponent.** The check
`peer 1 reduced '<round>' shared opponent HP` fails reproducibly. It is left at
full strength and is not relaxed.

The strike is **not refused**. Run 03 read the guest's local verdict as
`ok=false pending=true code=pending` — the host being asked, not the host
saying no. What fails is the geometry contract §5 step 2 resolves against: the
host does not hold the guest's creature where the guest placed it.

- Run 03, quarter-final: guest asked for `(-22.05, 2.23, -22.70)`; its creature
  stood locally at `(-21.19, 1.20, -22.70)` — a metre lower — and host hp did
  not move across six attempts.
- Run 04 added the Warden leg's host-view reach gate, which re-places until the
  **host** holds the creature within 4.0 m. After 28 placements the host still
  held it **8.86 m** from the opponent. It never converged.

Every host attempt lands on its first try, in every run.

Run 04 also shows why that gate is not kept: spending 28 attempts inside the
quarter-final left `tournament_semi_tam` unable to open, and the run lost its
semi-final and final legs entirely — 22 passes against run 03's 56. The cheap
six-attempt loop is kept so the rest of the chain is actually measured.

This is the same class as the shared-wild strike geometry item STATE already
carries open, and the guest authority gap beside it. It is recorded here rather
than fixed: three attempts were spent on it, which is this project's stop
condition for changing approach.

## Boundaries

- Opt-in only; no CI job runs this leg, and the Warden default is untouched.
- Party preparation is a disclosed fixture, not earned play. It proves the
  production entry conditions admit the prepared five/three, not that a player
  reached them.
- Two peers on clean loopback in one container. No four-peer, no lossy network,
  no device and no export-artifact evidence.
- This does not certify earned chapter pacing, balance, or the tournament's
  presentation. It is a state-and-payout witness.
