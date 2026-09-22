# smoke_net_shared_wild_fight — the withdrawal seam

ROADMAP Phase 0 item 1: "Resolve actual new regressions before adding gameplay
scope." This file is **red on main** — run `35595222911` failed with exactly one
job, `verify-multiplayer-shard (1)`, on this smoke — and it failed a *different*
assertion each time it was observed, which is what made it look unfixable.

## Reproduced locally first

Not diagnosed from CI logs. Run locally on this checkout:

| Run | Result |
|---|---|
| 1 | 102 pass, 0 fail |
| 2 | 98 pass, **fail** — `guest final withdrawal reached host ledger before host final leave` |
| 3 | **fail**, same assertion |

Roughly one run in two, matching CI.

## Root cause

The failing dump showed the host's participant list still holding **both**
peers sixty polls after the guest pressed to withdraw:

```
"participants": [2001676719.0, 1.0]
```

The obvious reading — that the poll budget was too short — is wrong. Sixty
polls is ample, and instrumenting the guest's own view immediately before the
press showed it was in perfectly good shape:

```
guest saw { "bound_id": "1:1", "fighting": true, ... }
```

Bound to the right encounter, fighting, and its press produced no disengage at
all. No refusal was logged either.

The cause is an **edge lost to a guard window**:

- `combat_manager.gd::begin()` arms a 0.25 s `_input_guard` every time a
  manager binds a fight.
- `_process` skips `_read_player_input()` **entirely** while that guard is up.
- `_flee_pressed()` reads `Input.is_action_just_pressed("combat_run")` — an
  edge.

So a single injected press landing inside a guard window is not deferred. It is
**gone**. The smoke pressed once and then polled, which assumes the one edge it
offered survived an arbitrary guard window.

This is a harness defect, not a game one. A real player whose disengage does
not register presses again; nothing in the rule under test says it must land on
the first frame it is offered.

## The change

Press until it takes, bounded, re-checking the host ledger between attempts.
**The assertion is unchanged and un-relaxed** — the guest's withdrawal must
still reach the host ledger before the host's final leave. Only the assumption
that one edge survives is dropped. The failure message now reports how many
presses it took, so a future regression is visible rather than silent.

## Evidence it works

Ten runs after the change: **nine green, one failure on a different seam.**

Run 11 is the decisive one: it reports **`after 2 press(es)`**. The retry
engaged and carried a run that would previously have failed. Before the change
one run in two failed here; after it, this seam has not failed once in ten.

## A second seam, also fixed here

Run 15 failed on a **third** thing, the two-encounter staging:

```
FAIL: B has a distinct encounter id from A (A '1:1', B '1:1')
FAIL: B uses a distinct ordinary wild body from A (same instance id)
```

The host flees A and then calls `engage_wild` to start a separate fight B. But
`engage_wild` teleports to `nearest_live_wild()`, and a peer that has just fled
is **still standing beside the creature it fled** — so the nearest live wild is
A's own body and the "second" encounter comes back with the first one's id.

`engage_wild` now takes `exclude_body_id`, and the smoke names A's body when
staging B: walk past it, the way a player looking for a different creature
does. The exclusion reads the director's own creature list rather than keeping
a second idea of what is alive.

## What is still open — a seam this lane did not fix



Run 15 failed on the **friendly-fire staging**, not the withdrawal:

```
FAIL: the host saw peer 0's creature as a connected friendly candidate
      ([{ "connects": false, "distance": 2.27, "owner_peer_id": 0.0, ... }])
FAIL: the host refused it with `friendly_target` after 40 poll(s)
      (got code 'replayed_action')
```

The friendly candidate reports `connects: false` at 2.27 m, so the
`friendly_target` refusal never fires and the action is re-read as a replay.

That is the **same `connects=false` geometry family** tracked in
`MEADOWS-PAYOFFS/tournament` and `river-sela-mill` — and it has since been
**fixed at root**, on `ralph/guest-strike-geometry`: a remote creature's
replication was perfect while its follow was 1.4–2.3 m out, so the host
resolved geometry from a body it was holding in the wrong place. See
`MEADOWS-PAYOFFS/proxy-ground-plane`.

That fix is **not in this lane's diff**, and this lane does not claim it. What
this lane can report is that the friendly-fire seam did not recur in seven runs
with that fix present. Seven runs is encouragement, not proof.

## Result

With this lane's two fixes, and the proxy fix present:

| Batch | Result |
|---|---|
| before any fix | 1 of 3 green |
| withdrawal fix only | 9 of 10 green; run 11 shows `after 2 press(es)` |
| + staging fix | **4 of 4 green**, six consecutive clean runs across batches |

No test was skipped, disabled or quarantined, and no assertion was weakened.

No test was skipped, disabled or quarantined.
