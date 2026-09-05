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
