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
- ~~**The host could not walk to the machine control.**~~ **WRONG, and
  corrected below rather than deleted, because this lane asserted it as fact.**
  The original text said the guest reached the control every time and the host
  never did across three attempts, and called it an open question about the
  arena-to-chamber passage after the fight. There is no such question and the
  room was never involved. See "What the host's walk actually was" below.
- The belt-full path (release-or-refuse ceremony) is not driven here.
- Two peers, clean loopback, one container. No four-peer, lossy-network, device
  or export evidence.

## What the host's walk actually was

Measured with the `--arena-passage` leg's locomotion/lockout probe, immediately
after the Warden falls:

```
peer 0 (host):  locomotion=false  dialogue=true   fighting=false  trainer_battle=false
peer 1 (guest): locomotion=true   dialogue=false  fighting=false  trainer_battle=false
```

`warden_aldis` carries a `victory_conversation`, and it opens on the peer that
**fought** him — the host. The guest only joined the encounter record, so it
never gets one. `sequence_director`'s lockout reads an open panel as modal and
calls `set_locomotion_enabled(false)` every frame it is up; this repository
already records that exact shape of finding at
`peer_runner.gd::_step_dismiss_dialogue`, for a joining peer's opening dialogue.

The part that made it look like a room: `stick_navigator.gd::walk_to` only
counts a frame toward the caller's budget when the body **can** walk. While it
cannot, it waits in a hold loop bounded by `HELD_FRAMES` — 36,000 frames, ten
minutes — **without consuming the budget at all**. So the coordinator's step
deadline expires and returns `no verdict`, which is indistinguishable from a
body that walked and failed to arrive.

That also disposes of the second wrong explanation, which this lane reached
before the right one: that the host was simply slower than the coordinator's
55 s wall clock. Budgets of 2400, 900 and 400 frames all behaved identically,
because the budget was never advancing. A sweep built to test that hypothesis
was itself ordered largest-first, so its later samples were taken on a peer
already desynced by the first timeout — measuring nothing.

**The fix is what a player does:** the leg now presses through the conversation
on both peers using the existing `dismiss_dialogue` step. Result:

```
PASS: peer 0 read the Warden's victory line and got its legs back
      (closed the opening dialogue in 2 presses; locomotion now true)
PASS: peer 1 read the Warden's victory line and got its legs back
      (no dialogue box was open; locomotion now true)
[arena-passage] peer 0 budget 400: PASS | arrived within 3.50 m of (-17.0, 7650.2)
[arena-passage] peer 1 budget 400: PASS | arrived within 3.50 m of (-17.0, 7650.2)
```

The host walks the same ~30 m and arrives at the **smallest** budget on its
first attempt. Two button presses were the whole of it.

The guest still pulls the tether, on its original merit alone: a chapter climax
only the host can trigger is not a co-op climax.
