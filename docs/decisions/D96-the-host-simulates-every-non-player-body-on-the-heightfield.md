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

## Attempted and reverted 2026-09-06

Lane 4.B recorded the FULL_GAME switch as unassigned (handover H1). It was implemented
(`playground_world.gd` choosing the mode on `is_multi_peer() and is_host()`, a host that started
alone upgrading on `Session.peer_joined`) and confirmed to do exactly that in the isolated peer
boot logs: host mode 1 -> 3 on join, client and solo staying at 1. `smoke_net_movement_two_peers`
then went red on the CLIENT, and it was reverted.

Holding the stick forward for 300 frames from the same spawn, across four runs:

| Head | host | client |
|---|---|---|
| `adba6b6c` — last CI-green head, **baseline** | 14.52 m | **2.71 m** |
| `2a5f271e` — with the switch | 14.52 m | 1.92 m local, **0.86 m in CI** — FAIL |
| `947ba214` — switch reverted | 14.57 m | 2.66 m — PASS |

Two conclusions, of different strength.

**Settled: the host's 14.5 m is not a regression and not this switch.** It is already there at the
baseline. The movement smoke's header claimed both peers stop at 2.71 m; that was true when
written and is not true now, and nobody noticed because 14.52 clears a 2 m bar as easily as 2.71.
The comment has been corrected in the smoke.

**Not settled, and stated as the weak claim it is: the switch appears to degrade the CLIENT's
walk** — 2.71 and 2.66 without it, 1.92 and 0.86 with it — even though a client's own collision
mode is untouched. Two runs either side is not proof, and no mechanism has been established. The
plausible one is that the host's 3-second collision rebuild fires on `peer_joined`, exactly while
the joiner is settling into the world, but that was not demonstrated.

The revert stands on grounds that do not depend on resolving it: the switch buys nothing until
wild bodies are replicated (H1) and something consumes host-side positions (lane 4.C), so carrying
an unexplained effect for no present benefit is a bad trade.

**What the next attempt must do:** establish the mechanism for the client effect before landing,
and settle whether this decision's line that "clients keep Dynamic/Game collision around their own
camera" survives — a host and a client disagreeing about their shared geography would be worse
than the problem the switch solves. Land it with wild-body replication, where the benefit is real.

**Method note, because it cost two wrong public claims.** The first blamed the switch for the
host's 14.5 m; the revert left it at 14.57 m. A revert that turns a test green is not evidence the
reverted change caused what the test measured. The second reasoned from the smoke's header as
though it described the current tree. Run the baseline; read the numbers, not the comment.