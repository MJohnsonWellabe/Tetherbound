# Finding: the freed legendary has no co-op recipient arbitration

Raised while building the two-peer Hall approach witness beside this file.
It concerns a **hard rule**, so it is recorded rather than fixed: CLAUDE.md
requires that freed legendaries "volunteer, with **one durable recipient per
world offer**", and choosing *which* peer receives it is a design decision the
owner owns.

## What the code does

`scripts/world/stronghold_climax.gd::_hand_over_the_legendary()` builds the
creature and hands it straight to the **local** party:

```gdscript
var party: RefCounted = game.get("party")
if party != null and not bool(party.call("is_full")):
    party.call("add", creature)
    _set_player_flag(_flag("legendary_joined"))
```

- It reads `Game.party` on **this** process.
- `_set_player_flag()` writes a **player** flag, not a world flag.
- On a full belt it sets `Game.pending_catch`, again locally, and the release
  ceremony resolves on that peer alone.

## Why that is a co-op problem

The whole file is peer-unaware. A search of `stronghold_climax.gd` for
`session`, `is_host`, `multiplayer`, `authority`, `peer`, `ledger` or
`world_flag` returns **no matches** — the only hit for any of those strings is
the word "session" inside an unrelated comment about saves. There is no host
arbitration, no ledger intent, and no reward-delivery receipt on this path,
unlike every other shared payout in the chapter.

And the climax is **built on both peers**. Measured directly in this lane's own
two-peer run (`two-peer-hall-approach.log`, peer logs beside it): both peers
print the same construction line for it —

```
[climax] the legendary stands inside the machine: dais 4.06 m up,
         void 7.67 m tall, body 7.08 m, headroom 0.59 m
```

— identical geometry, on host and guest alike.

So on the reading of the code, two peers reaching the freed legendary would
each build their own Veridian and each add it to their own belt, which is two
durable recipients for one world offer.

## What is proven and what is not

**Proven:** both peers construct the climax with identical geometry; the
adoption path consults no session, host, ledger or authority seam anywhere in
the file; the flag it writes is a player flag rather than a world fact.

**Not proven:** that two peers actually *both* end up holding a Veridian in a
live run. That needs a two-peer run continuing past the Warden into the
chamber, which no witness currently drives — this lane's leg stops at the
gauntlet and this file's default leg teleports to the Warden and ends at his
defeat. The inference is strong but it is an inference, and it is labelled one
here rather than written up as a measured result.

## Why it is not fixed here

Fixing it requires deciding **who** receives the offer, and that is a design
decision against a hard rule, not a mechanical repair. At least these are
open:

1. Does the host receive it, the peer who triggered the climax, or the first
   to accept?
2. What do the other peers see — the same volunteer scene with no grant, a
   different acknowledgement, or nothing?
3. If the recipient's belt is full, does the five-creature ceremony block the
   other peers, and may the offer pass to someone else if they decline?
4. Is `legendary_joined` promoted to a world fact with a recipient id, the way
   reward deliveries already carry one?

CLAUDE.md is explicit that a hard-rule conflict is stated in STATE and in the
proposed change, and that the current rule is preserved until the owner
agrees. Nothing on this path has been altered.
