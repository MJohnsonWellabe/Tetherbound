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

**Implemented 2026-09-06**, after lane 4.B's handover H1 recorded the amendment as unassigned and
declined to make a world-boot change from a creature-ownership lane. `playground_world.gd` now
picks `COLLISION_FULL_GAME` when `Game.is_multi_peer()` **and** `Game.is_host()`, and a host that
started alone upgrades on `Session.peer_joined` -- the 3.06 s rebuild lands while the joiner is
still applying the world snapshot. The gate is `is_multi_peer()` rather than `is_host()` on
purpose: `is_host()` is deliberately true for solo, for a headless test and for a capture tool
(see `session.gd`'s own reasoning), and answering yes to any of those would spend 16.1 MB and
three seconds on every single-player boot for nothing. Clients are untouched and keep
Dynamic/Game around their own camera.

What this does **not** do, so the gap stays visible: wild creature bodies are still not replicated
to clients, so a client's wilds remain its own local simulation and drift from the host's. Lane
4.B deliberately did not freeze them -- a frozen meadow reads worse than drift -- and
`MP_ENCOUNTER_PROTOCOL.md` §2 already requires the host to resolve strikes against its own
positions, which is what makes the drift cosmetic rather than a correctness bug. Replicating them
is a later lane's work.
