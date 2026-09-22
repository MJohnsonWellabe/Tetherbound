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

## UPDATE: the one failure is fixed, and this leg is now 46/0

With `ralph/guest-strike-geometry` present, this leg passes **46 checks, 0
fail** — including `guest moved and landed a hit through ordinary combat
input`, the check this section was written about. Log:
`two-peer-relay-crossing-with-proxy-fix.log`.

The root cause was not in this lane: a remote creature's replication was
perfect to the centimetre while its FOLLOW was 1.4–2.3 m out, so the host
resolved a legitimate swing against a body it was holding somewhere else. See
`MEADOWS-PAYOFFS/proxy-ground-plane`.

**That fix is not in this lane's diff.** This lane's own diff still carries the
failure; the result above is this leg run with that fix applied. The section
below is kept as written, because the reasoning in it — including a correction
I had to make to my own first diagnosis — is the trail that led to the fix.

Two samples were taken. One aborted early on a separate flake
(`host accepted the guest's fresh strike`, 15 checks in); the other completed
the whole chain clean. One flake in two runs is noted, not explained away.

## The original failure — re-diagnosed, then fixed elsewhere

    FAIL: guest moved and landed a hit through ordinary combat input
          (ordinary input pilot hits=0 damage=0.0 frames=1800)

**This section previously claimed the shared failure proved an authority
defect. That was wrong, and the correction is recorded here rather than
quietly edited away.**

The original reasoning was that the tournament leg and this one fail the same
check by different routes — teleport placement there, real movement and presses
here — so the cause could not be a harness artifact. Reading the host's own
strike receipt, instead of inferring from the symptom, showed otherwise. See
`MEADOWS-PAYOFFS/tournament` for the receipt itself:

- The strike is **accepted**, with no refusal code. Admission, identity and the
  reward ledger are not at fault — that much of the original finding holds, and
  this run's `host accepted the guest's fresh strike` check still demonstrates
  it.
- **Every** candidate returns `connects=false`, the opponent included at
  2.44 m, so nothing connected rather than something connecting for no damage.
- The host resolves the step-2 cone from a position on the **far side** of the
  opponent from where the guest placed its creature, so the guest's locally
  derived facing points away from the opponent at the host's origin.
- The host's copy is most likely **correct**: the creature's own AI moves it
  across the settle frames after placement.

On that reading this is substantially a **witness artifact** — the harness
fighting the creature's own movement — not a defect in shared-fight authority.
Re-characterising the check changes what this report claims is proven, so it is
left to the owner rather than done on an agent's initiative. The assertion
stays at full strength meanwhile.

A genuine proxy-divergence bug was found while investigating and is fixed
separately on `ralph/guest-strike-geometry`: both remote proxies compared only
their render target to the owner when deciding to snap, so a body the host's
collision had pinned stayed snagged indefinitely. It is unit-tested and worth
landing on its own merits, and it **did not change this result**.

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
