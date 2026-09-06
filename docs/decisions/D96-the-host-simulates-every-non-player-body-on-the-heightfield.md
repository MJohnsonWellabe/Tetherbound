# D96 — The host simulates every non-player body on the heightfield; peers simulate only their own trainer and creature

**Date:** 2026-09-05 · **Decided by:** Fable, Stage B lane 0.A, from `docs/MULTIPLAYER_DIRECTIVE.md` and the codebase facts in `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` §1. Adversarially reviewed before approval.

## Decision

Wild creatures, trainer creatures and bosses are simulated on the host in a **kinematic
heightfield mode** of `scripts/creatures/creature_body.gd`: ground from the analytic heightfield
(`playground_world.ground_height_at` in the Meadows, `cloudreach_world.ground_height_at` in
Cloudreach), no Terrain3D collision dependency, structure collision from the always-present built
nodes, arena `hold_inside` unchanged. Each peer simulates its own trainer and its own deployed
creature and replicates their transforms continuously. A strike intent carries only
`(move, origin, facing)`; the host tests `move_connects` against **its own** opponent position
with a latency tolerance fixed in lane 4.C's brief. A catch attempt carries launch parameters; the
host re-derives the closest approach with `orb.gd`'s pure statics against its own body position
and rolls `CATCH.resolve` with host RNG.

## Why

Directive §4: the server decides enemies, damage and catches. The first draft delegated opponent
simulation to the engaging peer; review showed the same peer would then author both the hit and
the target position, and the host would be a counter, not an authority. Terrain3D collision only
exists within 256 m of the host's camera (`playground_world.gd:477,596`), so the host cannot run
`move_and_slide` bodies far away; but the heightfield is already a pure function the director
trusts over physics (`encounter_director.gd:1781`, `creature_body.gd:1796`), so it can ground
them without collision. Spike S2 (`ralph/reports/MP-0D-SPIKE-HOSTCOST-0905/`) measures the cost
of active clusters keyed on the union of occupants and of heightfield-grounded bodies; its numbers
are cited in `docs/specs/MULTIPLAYER_CONVERSION_MAP.md`.

## Known limitation, recorded

Host-simulated bodies outside the host's own scatter-collision radius do not collide with
vegetation. The code-blind judge watches remote-peer frames for creatures clipping trees; if it
names it, the fix is per-body vegetation probes, not a return to delegation.

## Amended 2026-09-05, after spike S2 (`ralph/reports/MP-0D-SPIKE-HOSTCOST-0905/`)

Two measurements change the mechanism, not the decision. Terrain3D's FULL_GAME collision mode
builds whole-map collision for **+16.1 MB in 3.06 s**, and a heightfield-grounding loop through
`.call()` measured **+11 ms median** over `move_and_slide` for 40 bodies, twice. So: **the host
runs Terrain3D in FULL_GAME collision mode**, and host-simulated bodies keep the existing
`move_and_slide` path everywhere in the Meadows; Cloudreach already has authored mesh collision
and analytic ground. The kinematic heightfield mode is dropped from lane 4.B's scope. Clients
keep Dynamic/Game collision around their own camera. Everything about authority above stands:
the host still owns every opponent body, every HP value, every strike and every catch.

## Attempted and reverted 2026-09-06 — the amendment costs more than memory

Lane 4.B recorded the FULL_GAME switch as unassigned (handover H1). It was implemented
(`playground_world.gd` picking the mode on `is_multi_peer() and is_host()`, a host that started
alone upgrading on `Session.peer_joined`), verified to do exactly what it says in the isolated
peer boot logs — host mode 1 -> 3 on join, client and solo staying at 1 — **and then reverted,
because `smoke_net_movement_two_peers` caught what the decision had not anticipated.**

The measured effect was not the +16.1 MB / 3.06 s S2 priced. From the same spawn, holding the
stick forward for 300 frames:

| Peer | Collision | Walked |
|---|---|---|
| host | FULL_GAME | **14.52 m** |
| client | Dynamic/Game | **1.92 m** (0.86 m in CI) |

The smoke's header documents both peers stopping at **2.71 m**, stable across a 90- and a
300-frame hold. So whole-map collision does not merely add shapes a player might bump into: it
changes where a player can walk, and **a host and a client in the same world then disagree about
their shared geography.** That is a worse defect than the one the switch solves.

It also solves nothing yet. The switch exists so a host can simulate wild bodies anywhere with
real ground beneath them; wild bodies are still not replicated (H1), and nothing consumes
host-side positions until lane 4.C lands. So it was pure cost.

**What the next attempt must settle, rather than assume:** this decision's line that "clients keep
Dynamic/Game collision around their own camera" is the thing under question, not a given. Either
every peer pays for full collision so the geography is shared, or the divergence is measured and
bounded and shown to be invisible in play. Land it with wild-body replication, where the benefit
is real and the asymmetry can be judged against creature behaviour instead of against a trainer's
walk out of a farmhouse.
