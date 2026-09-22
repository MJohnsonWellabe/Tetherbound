# The guest-strike gap, measured and fixed

This closes the defect tracked across three lanes — `MEADOWS-PAYOFFS/tournament`
(a guest could not land a damaging blow), `river-sela-mill` (the same, through
ordinary movement input) and `shared-wild-stability` (the friendly-fire seam's
`connects=false`). All three were the same bug.

## How it was found, after four wrong turns

Earlier attempts guessed at causes and adjusted the witnesses. This one
measured, by placing a creature and then striking **nothing** — just sampling
where each peer held each body over the frames a real attempt spends settling.

The decisive step was reading the owner's published position **off the wire on
the receiving peer**, beside the position that peer was actually holding:

```
own        = (-24.52, 1.20, -20.97)   the guest's real creature
host_net   = (-24.52, 1.20, -20.97)   what the HOST RECEIVED -- exact
host_holds = (-25.69, 1.20, -21.88)   where the HOST was HOLDING it
```

**Replication was perfect to the centimetre. The follow was 1.4–2.3 m out and
never converged.** That single line ruled out every publish, authority, ledger
and identity explanation at once.

## Why it broke shared fights

`encounter_director.gd::_host_strike()` resolves the protocol's step-2 geometry
from `striker.call("centre")` — the host's own copy of the guest's creature. A
proxy held a couple of metres off makes the host resolve a legitimate swing
from the wrong place, and `_host_strike()` returns the same `ok` verdict whether
or not `delta.hit` is true. So the strike was accepted, with a valid receipt on
the right encounter and the right peer id, and scored `connects=false` against a
body the host was holding somewhere else.

The cause is ordinary: `remote_creature.gd` keeps its collision **mask** (only
its layer is cleared), so the opponent, the other player's creature or a rock
can stop the proxy short of its owner. `move_and_slide()` then never recovers,
because the render target is already correct — it is the body that is stuck.

## Three attempts, and what each measured

| Attempt | Result |
|---|---|
| Snap when the body diverges past `SNAP_M` (6 m) | Correct but insufficient: the real error is 1.4–2.3 m, well inside 6 m. Kept — it is a real hole — but it did not move the end-to-end score. |
| Hard-place after 12 stalled frames at 0.35 m | **Worse.** The proxy oscillated — gap 5.11 → 2.32 → 3.13 → 3.56 → 2.38, height swinging 1.2 m to 3.7 m — because forcing the whole vector fights gravity. Discarded, then re-tested on evidence and discarded again. |
| Correct the ground plane, leave height to physics | Lateral error went to **zero**, exactly. But pinned laterally every frame, the body climbed its obstacle and sat at y 4.64 against the owner's 1.20. |
| **Take the owner's whole position when physics has lost it** | **Fixed.** |

The height detail is why the last one is right: the owner's published height
agreed with the receiving peer's to the centimetre in *every* sample, before
any correction existed. The owner has already done its own ground query, so
there is nothing a floor query on the receiving side can add except a fight it
loses.

## Result

Follow, after the fix — converged and stable:

```
own        = (-23.23, 1.20, -20.78)
host_net   = (-23.23, 1.20, -20.78)
host_holds = (-23.23, 1.20, -20.78)   exact by t=40, held
```

Shared tournament witness, two peers, all three authored rounds:

```
PASS: peer 0 reduced 'tournament_quarter_mira' shared opponent HP
PASS: peer 1 reduced 'tournament_quarter_mira' shared opponent HP
PASS: peer 0 reduced 'tournament_semi_tam'     shared opponent HP
PASS: peer 1 reduced 'tournament_semi_tam'     shared opponent HP
PASS: peer 0 reduced 'tournament_final_oskar'  shared opponent HP
PASS: peer 1 reduced 'tournament_final_oskar'  shared opponent HP

57 checks pass, 0 fail
```

Against 56 pass / 1 fail before, with the guest landing **no** blow in the
failing round. **The guest now lands its own damaging blow in every round.**

`tests/test_remote_creature_follow.gd` — 5 tests, 7 assertions — pins the
measured numbers as the case that must be corrected, and guards the two
directions this could go wrong: ordinary interpolation lag must still be
smoothed, and a height difference alone must never trigger a correction.

## Boundaries

- Two peers, clean loopback, one container. No four-peer, lossy-network or
  device evidence.
- The correction is confined to remote proxies on non-authoritative peers. No
  protocol, ledger or reward change.
- `shared-wild-stability`'s friendly-fire seam is the same family and is
  expected to benefit, but that is **not** re-measured here and is not claimed.
