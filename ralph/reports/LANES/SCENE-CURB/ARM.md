# SCENE-CURB: an authored stone curb for the Warden arena's edge (F38#28, new approach)

Row: F38#28 Warden fight. 6.81 at High and Medium on the strictest panel today (control 7.53); `G-scene-hallwalls-r2.md`. The wall-moss approach (HALLMOSS, HALLWALLS r1 and r2) is parked after two rounds.

The one recorded defect left, PARTIAL 3/3: "replace the thin teal floor arc and the left-wall teal strip with an authored boundary (stone curb, rope or inlay)".

## Cause

The arena's edge is `combat_arena.gd _build_boundary`: an open, unshaded, additive teal cylinder 0.45 m tall at alpha 0.12 in this arena (`boundary_per_trainer_candidate`). On the stronghold's dark floor it reads as a thin glowing arc, which the judges call a UI line rather than part of the hall. Confirmed in the ray probe from HALLWALLS: `CombatArena/Boundary`, albedo #59d1db at alpha 0.12, is the surface there.

## Arm

Overlay (`overlay.json`): `combat.json arena.boundary_curb_1113.enabled` true. Flag-off code on `tb/scene`:
- For the trainers listed (only `warden_aldis`), `arena_boundary_for` marks the arena `boundary_style: curb`.
- `combat_arena.gd _build_curb` then lays a ring of low bevelled stone blocks (0.13 m tall, 0.34 m wide, 0.9 m long, 6 cm gaps) on the floor along the same circle, each with a thin brass inlay on top, instead of the glowing wall.
- The blocks use the installed Rock030 stone texture, world-triplanar. Two MultiMeshes, no collider and no shadow.
- Radius, staging and the soft wall that holds the fighters in are unchanged. Every other fight keeps the ring.
- Test `tests/test_arena_boundary_curb_flag.gd`. It caught a first-cut bug where the blocks pointed at the centre; they now lie along the circle.

## CPU

`capture_f38_fight.gd --trainer=warden_aldis --frames=5 --attack --dodge --tell-frames --preset=Low`, frame 03, brightened 2x because the hall is dark on CPU: `_sheet_cpu_arm_brightened.jpg`. The curb reads as a stone ring with a brass line across the arena floor.

## By-eye line for the GPU lane

Warden 03 at High: no thin glowing teal arc on the floor. In its place, a low segmented stone curb with a warm brass line, ringing the fighters at the same radius. If the teal arc is still there, the trainer id did not match: hold it.

## Not changed, and why

The teal strip at the foot of the left wall is a Team Tether floor conduit (`stronghold.gd` interior live conduits, the occupation's teal energy lines). It is the faction's hardware, not the arena edge, so this arm leaves it. If the judges still name it, it is a stronghold-dressing call for the coordinator.

## Risks and no-loss frames

- The curb must still read as the fight's edge (COMBAT: players need to know where the ring is). The brass inlay is there for that.
- No-loss: Warden 05 and 08, and one non-Warden fight (F38#3 grunt 03), which must be identical.
- With HALLWALLS parked, this is the only F38#28 arm.
