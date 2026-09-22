# Meadows chapter handoff — two peers

Closes the **last** Meadows co-op milestone STATE held open: the Veridian
decision and the Cloudreach gate, in co-op.

It is also the runtime proof the per-participant legendary rule did not have —
and it found that rule **unimplemented in the live game**, which unit tests
could not have shown.

## What it runs

Opt-in `--handoff` leg on `smoke_net_shared_boss.gd`. The file's default
invocation is unchanged and no CI job runs it.

    godot --headless --path . --script tests/smoke_net_shared_boss.gd -- --handoff

Two peers, four ordinary creatures each, seated in the Warden's arena. The host
challenges `warden_aldis`; the guest joins that record; both fell him. The
guest then walks to the machine control and pulls the tether.

## Result: 32 checks, 0 fail

- Both peers receive `defeated_warden` as a shared world fact.
- **The guest, not the host, uses the machine control** and frees the
  legendary. A chapter climax only the host can trigger would not be a co-op
  climax.
- Both peers receive `legendary_freed`.
- **Both peers hold their own Veridian** —
  `[terrapup, bramblebun, trailpup, mudsnout, veridian]` on each.
- Both peers see Meadows hand off to Cloudreach
  (`realm_gate_cloudreach_unlocked`, `realm_key_cloudreach`,
  `cloudreach_chapter_started`).
- Both complete a production save/reload, retain the freeing, and still agree
  on one shared world by state hash.

## The defect this found

`ralph/legendary-per-participant` had implemented the owner's rule as a gate:
`may_receive()` decides whether a peer *may* take the legendary. Its PR said
plainly that no two-peer runtime witness existed and that "two participants
each end up holding a Veridian" was unproven and not claimed.

This leg proved it false. `before-fix-only-the-puller.log`:

```
PASS: peer 1 ... holds its OWN veridian (party: [..., veridian])
FAIL: peer 0 ... holds its OWN veridian (party: [terrapup, bramblebun, trailpup, mudsnout])
```

The guest that pulled the lever got its Veridian. The host, which had just
fought the Warden beside it, got nothing.

**Gating who MAY receive is not the same as causing every participant to BE
offered.** `stronghold_climax.gd`'s stage machine only advances on the peer
that used the machine control — `_stage` is set by that interaction — so on
every other peer it sat at `""` forever and `_hand_over_the_legendary()` never
ran at all.

The fix makes the freeing itself the trigger rather than the interaction: the
flag is a world fact, so each peer sees it land and resolves its own offer, for
itself, against its own belt. `may_receive()` still decides, so a peer that did
not fight, or has already resolved this freeing, is refused exactly as before.

## A second thing the run corrected

The first attempt with a full five-creature belt reported no Veridian on either
peer. That was **the rule working, not failing**: CREATURES requires that at
five the ceremony demands a permanent release or a refusal, and the legendary
is never an owned sixth. The leg now grants four, so the claim under test is
the one the owner's decision actually makes — every participant who accepts
keeps their own.

## Boundaries

- Opt-in; default invocation untouched; no CI job runs it.
- Arena seating and the four-creature party are **disclosed fixtures**. The
  gauntlet before the arena is the `--hall` leg's claim; the spine before that
  belongs to the earned-segment tests.
- **The host could not walk to the machine control.** Across three runs the
  guest reached it every time and the host did not, even standing on the
  authored mark with three attempts, having just fought in the adjoining room.
  The leg therefore has the guest pull the tether — which is the stronger claim
  anyway — but the asymmetry is an **open question about the arena-to-chamber
  passage after the fight**, not something this lane fixed.
- The belt-full path (release-or-refuse ceremony) is not driven here.
- Two peers, clean loopback, one container. No four-peer, lossy-network, device
  or export evidence.
