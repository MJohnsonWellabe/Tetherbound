# River Lock / Sela / Mill — co-op witness

Lane evidence for the Meadows river payoff chain. STATE previously recorded this
witness as "prepared in the frozen checkout and parser-checks, but has not run."
**It now runs.** This file records what it proves and what it does not.

## What this is

Two legs, both using production doors.

**Solo** — `tests/smoke_relay.gd`, already in CI, now approaches every claimed
interaction through the live interaction arbiter instead of a fixed offset:
`_approach_prompt()` moves with ordinary input until the **exact** production
provider both is enabled and wins an actionable offer, then presses once.
Relocated NPCs can no longer inherit a stale offset from their former site.
Near-site seating is disclosed fixture setup on supported ground, taken from the
live body's own world facing.

    godot --headless --path . --script tests/smoke_relay.gd

**Two-peer, opt-in** — a `--relay-crossing` leg on
`tests/smoke_net_gate_opens_for_both.gd`. The file's default invocation is
unchanged and no CI job runs the new leg:

    godot --headless --path . --script tests/smoke_net_gate_opens_for_both.gd -- --relay-crossing

It raises only the handshake allowance to 360 s, because two Meadows worlds build
on one machine; gameplay and command bounds are untouched.

Harness addition, in `tools/net/peer_runner.gd`: a read-only `relay_crossing`
probe — which production interaction provider currently wins and whether it is
actionable, which authored conversation is open, whether Sela stands at the relay
or in the village, and the live Mill crossing's own route points. It presses
nothing and mutates nothing.

## Results

Solo `smoke_relay.gd`: **passes.** Captain beaten after 2393 action frames, 3 of
3 creatures felled; `relay_captain_defeated` and `captive_rescued` set; the Gear
carried; the relay empty of her; Sela standing in the village; her greeting
changed `village_rescued_ranger` → `village_rescued_ranger_home`.

Two-peer `--relay-crossing`: **45 checks pass, one fails.** Log:
`two-peer-relay-crossing.log`.

Proven, in one continuous run, with every claimed interaction reached by
ordinary movement and activated by one physical press:

- Both peers deploy owned allies; the host challenges Captain Vance; the fight
  mints one shared encounter and the guest **joins that record**.
- The host **accepts the guest's fresh strike** on Captain Vance's exact
  encounter — a receipt carrying the guest's own peer id, on that encounter,
  `ok=true`, newer than the swing.
- The full authored team resolves (3304 frames, 72 swings, 3 creatures) and
  both peers receive the shared defeat fact.
- The guest reaches the **exact** captive Sela provider by ordinary movement,
  greets her physically, and opens `relay_captive_freed`; both peers receive the
  shared rescue fact; the speaking guest receives **exactly one** Mill Bridge
  Gear.
- Sela moves from the relay to the village on the shared flag.
- The guest reaches the exact Mill gate provider and uses the crossing; both
  peers see the restored Mill fact and the open live leaf; the one earned Gear
  pays for the shared repair **exactly once**.
- Both peers then **normally walk** the restored crossing, arriving within 2 m
  of the far point.
- Relocated Sela opens `village_rescued_ranger_home` and pays **no duplicate
  Gear**.
- Both peers complete a production save/reload and retain the whole
  Captain/rescue/Mill chain; state hashes agree — one shared world.

## The one failure — open, and corroborating

    FAIL: guest moved and landed a hit through ordinary combat input
          (ordinary input pilot hits=0 damage=0.0 frames=1800)

This is **the same gap** the shared tournament witness records in
`MEADOWS-PAYOFFS/tournament`, reached here by a completely different route. The
tournament leg teleports the guest's creature into place and submits a strike;
this leg drives it with the **ordinary combat input pilot** — real movement, real
presses — for 1800 frames. Neither lands. That the two independent routes fail
identically is what makes this a defect rather than a harness artifact.

It also narrows where the defect is **not**. In the same run:

- `host accepted the guest's fresh strike on Captain Vance's exact encounter`
  **passes**. The host admits the guest's strike authoritatively, on the right
  encounter, with the right peer id.
- The tournament leg read the guest's local verdict as `pending`, not a refusal.

So the guest is admitted to the fight, and its strike is admitted by host
authority — it simply resolves to **zero damage**. The failure is in how the
host resolves an admitted guest strike, not in admission, identity or the
ledger. The tournament leg measured the likely reason: after 28 placements the
host still held the guest's creature 8.86 m from the opponent, while every host
attempt lands first try.

The assertion is left at full strength. This is the same class as the
shared-wild strike geometry and guest authority items STATE already carries
open, and it is recorded rather than fixed — three attempts were already spent
on it in the tournament lane, which is this project's stop condition.

## Boundaries

- The two-peer leg is opt-in; the default `gate_opens_for_both` invocation is
  unchanged and no CI job runs it.
- Near-site seating before each approach is **disclosed fixture setup**, not the
  earned kilometres between sites. What is claimed as earned is the movement and
  the press after that seat, and the exact provider is named before every press.
- The fight fixture (`bramblebun` at level 16) is disclosed, not earned play.
- Two peers, clean loopback, one container. No four-peer, lossy-network, device
  or export-artifact evidence.
- This does not certify the river chapter's pacing, balance or presentation.
