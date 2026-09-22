# Earned Warrens approach and exit — two peers

Closes STATE's "earned Warrens approach/exit beyond the prepared segment", the
last Meadows co-op milestone besides the chapter handoff.

## What the prepared segment already did, and did not

`smoke_net_shared_wild_fight.gd --guardian` already proved a great deal: shared
guardian admission, both peers piloting by ordinary input, both live vault
openings, the full addressed reward to two distinct stable characters, five
retained UIDs through reload, and one replicated delivery journal.

Two things it did **not** do, which is why STATE held it as *prepared* rather
than earned:

1. **The guest was teleported onto the fight.** Only the host walked in.
2. **Nobody left.** The segment ended with both peers standing in the
   guardian's chamber. A cleared dungeon nobody can walk out of is not cleared.

## What this adds

**Earned approach.** The guest now walks the same authored legs the host walks
— entrance → mouth → hall — on its own movement input, then closes the last
few metres to the guardian itself. Being carried to a fight proves the fight;
walking in proves the approach.

**Earned exit.** After the clear, the rewards and the reload, both peers walk
back out — hall → mouth → entrance — and the run ends with a state-hash check
that they still hold one shared world on the way out.

The entrance seat stays **disclosed**: the kilometres of Meadows spine that
reach the Warrens belong to `test_meadows_earned_warrens_segment.gd`, not to
this file.

## The wedge, and why the walk retries

First two runs: one clean, one with the guest stopping **9.80 m short** of the
guardian and, on the way out, **13.69 m short** of the mouth
(`before-retry-wedged.log`). Always the guest, never the host.

`move_to` drives ordinary movement input in a straight line — it does not
path-find. Inside a cave that is usually fine and occasionally is not: a peer
clips a corner and stops with the target still metres away.

So a leg now backs off toward where the peer came from and takes the leg again,
up to three times — what a player does when they snag on a corner. **The
assertion is unchanged**: the peer must still arrive under its own movement.
The attempt count is printed when a leg needs more than one, so a leg that is
quietly getting harder is visible rather than silent.

A fixed, larger frame budget was the alternative and was rejected: it hides a
wedge as a slow walk instead of reporting it.

## Result

Three consecutive runs, **42 checks each, 0 fail**:

```
PASS: guest walked the authored Warrens mouth leg on its own legs
PASS: guest walked the authored Warrens hall leg on its own legs
PASS: guest reached the guardian by ordinary movement
PASS: peer 0 walked out of the cleared Warrens on its own legs
PASS: peer 1 walked out of the cleared Warrens on its own legs
PASS: both peers still hold one shared world after leaving the cleared Warrens
```

## Boundaries

- The `--guardian` leg is opt-in; the file's default invocation is unchanged.
- Entrance seating and the level-16 five-creature party are disclosed fixtures,
  not earned play.
- Runs were taken with `ralph/guest-strike-geometry` present, which is what
  makes the guardian's shared strikes land reliably. That fix is not in this
  diff.
- Two peers, clean loopback, one container. No four-peer, lossy-network, device
  or export evidence.
- This does not certify Warrens pacing, balance or presentation.
