# Legendary offer — every participant keeps their own

Implements the owner's decision of 2026-09-21, which **amends a hard rule**.

## The decision

CLAUDE.md read: *"Freed legendaries volunteer, with one durable recipient per
world offer."*

The owner replaced it with: **every participant in the fight that freed the
legendary receives their own offer, and each participant who accepts keeps
their own.** A non-participant receives nothing, and no character is offered
the same freeing twice.

Asked explicitly whether this meant one creature contested between
participants or one each, the owner chose **one each** — in a four-player game,
up to four Veridians in the world.

Amended together, as the routing rules require:

| Document | Was | Now |
|---|---|---|
| `AGENTS.md` / `CLAUDE.md` (identical twins) | one durable recipient per world offer | every participant receives their own offer and keeps their own |
| `docs/design/CREATURES.md` | "One host-owned world offer has one durable stable-character recipient" | per-participant offers, bound to stable characters |
| `docs/design/BOSSES.md` §Warden | "the one legendary offer uses stable-recipient ownership" | each fight participant receives their own offer |
| `docs/design/BOSSES.md` out-of-scope list | "copied co-op legendary rewards" listed as out of scope | **removed**; what stays out of scope is granting to a non-participant, or to the same character twice |

## The defect this answers

`ralph/reports/MEADOWS-PAYOFFS/hall-coop/LEGENDARY-RECIPIENT.md` recorded it:
`stronghold_climax.gd::_hand_over_the_legendary()` added the creature to the
**local** `Game.party` with no session, host, ledger or authority seam anywhere
in the file — while the climax is **built on both peers** (measured, identical
geometry on host and guest). Every peer running it would have taken one,
participant or not, and nothing prevented the same character taking one twice
across a reload.

## What changed

A pure rule, `stronghold_climax.gd::may_receive()`, with the three inputs as
parameters rather than reads so it is testable without a world, a session or a
save: who this peer is, who fought, and whether this character already resolved
this freeing.

`_hand_over_the_legendary()` now consults it before granting. Each peer decides
only **for itself**, which is why no host arbitration is needed and why two
peers cannot race for one grant.

Participation comes from the **world's own reward journal**, not a live
encounter record — the record is gone by the time the legendary is freed, the
fight being over. The journal is not: the Warden pays through the same
per-participant `reward_grant` machinery every shared payout uses, each accepted
delivery carries the recipient's **stable character id**, and it replicates to
every peer. `MEADOWS-PAYOFFS/tournament` already proved that journal carries
both participants' ids and survives reload.

### The empty-set case, which is the one that could have broken solo

A solo freeing publishes no shared reward receipts at all, so the participant
set is empty. Refusing on an empty set would strand **every solo ending**. The
rule therefore reads an empty set as "this is the only player", which is what
it is — and an empty character id is still refused when others *did* fight, so
an unidentified peer cannot claim a place in a known participant set.

## Evidence

`tests/test_legendary_per_participant.gd` — 7 tests, 9 assertions, 0 failed:

- a participant receives their own offer;
- **every** participant receives one, not just the first — the point of the
  amendment;
- a non-participant receives nothing, however close it stands;
- no character is offered the same freeing twice;
- a solo freeing still grants, including on a save predating stable character
  ids;
- idempotency holds solo as well as in co-op;
- an unidentified character is refused when others did fight.

`tests/smoke_gate_e_finale.gd` — the **solo** ending still passes end to end
after the gate: the tether fails, `legendary_freed` is set, the freed creature
steps clear of the machine, the garrison withdraws and the objective chain
terminates.

## Boundaries — what is NOT proven

- **No two-peer runtime witness exists for this yet.** No smoke currently
  drives two peers past the Warden into the chamber, so "two participants each
  end up holding a Veridian in a live session" remains unproven. The rule and
  its inputs are unit-proven; the end-to-end claim is not made.
- The journal lookup keys on the Warden's trainer id (`warden_aldis`, config
  override available). A chapter whose legendary is freed by something that
  pays no per-participant reward would produce an empty set and fall to the
  solo reading. Stormwood and Tidewake must verify their own freeing paths
  before relying on this.
- Belt-full behaviour is unchanged: the existing five-creature release ceremony
  still resolves on the receiving peer.
