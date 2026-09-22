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

## What it does not prove — open, and re-diagnosed

**A guest does not land its own damaging blow reliably.** One round of the
three fails this check on most runs; which round varies. The check is left at
full strength and is not relaxed.

The host's own strike receipt, read directly from `encounter_host.gd` rather
than inferred, says what is happening:

```
ok=true  code=(none)
origin=[-21.06, 3.20, -24.75]
[opponent d=2.44 connects=false, creature d=4.38 connects=false,
 trainer d=8.11 connects=false, trainer d=8.11 connects=false]
```

- The strike is **accepted**. No refusal code. Admission, identity and the
  reward ledger are not at fault, and the earlier framing of this as an
  authority defect was wrong.
- **Every** candidate comes back `connects=false`, the opponent included at
  2.44 m.
- The geometry explains it. The guest placed its creature at x = −17.60, the
  opponent stands at x = −19.00, and the host resolves from x = −21.06 — the
  **far side** of the opponent. The guest derives its facing locally as toward
  −x; applied at the host's origin that points away from the opponent, so the
  step-2 cone misses.

**The host's copy is most likely correct.** The creature's own AI moves it
after `place_creature` puts it down, across the settle frames before the strike
resolves. On that reading this is substantially a **witness artifact** — the
harness fighting the creature's own movement — rather than the authority defect
first recorded here. Re-characterising the check accordingly is a change to
what this report claims, so it is left for the owner rather than made on an
agent's own initiative.

### A real but separate bug was found and fixed here

`ralph/guest-strike-geometry` fixes a genuine proxy-divergence defect found
while investigating this: both `remote_creature.gd` and `remote_trainer.gd`
compared only `_render_position` to `net_position` when deciding to snap, so a
body the host's own collision had pinned stayed snagged indefinitely while
interpolation looked perfect. `tests/test_remote_proxy_snap.gd` fails 2 of 5 on
the old rule.

**It does not fix this check.** Scores were 56 pass / 1 fail before it and
56 pass / 1 fail after. It is worth landing on its own merits and must not be
described as the answer to the guest-strike gap.

A second, more aggressive "stall" fix — hard-placing any proxy blocked for 12
frames at 0.35 m — was written, measured, and **discarded**: no improvement in
any run, against a real risk of teleporting creatures through geometry several
times a second.

## Boundaries

- Opt-in only; no CI job runs this leg, and the Warden default is untouched.
- Party preparation is a disclosed fixture, not earned play. It proves the
  production entry conditions admit the prepared five/three, not that a player
  reached them.
- Two peers on clean loopback in one container. No four-peer, no lossy network,
  no device and no export-artifact evidence.
- This does not certify earned chapter pacing, balance, or the tournament's
  presentation. It is a state-and-payout witness.
