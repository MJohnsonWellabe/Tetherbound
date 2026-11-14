# BEINGS-THUNDERTUNNEL-FAINT: the faint shows a face instead of a ball (F36#80)

**Status: CPU-ready, NOT queued.**

**Row:** F36#80 Thundertunnel poses, GPU High 6.04.

**Defect, quoted (G-things-t4-rescore, 3/3):** the faint end is a "faceless ball". (The same panel's other asks are the flat pinkish-tan material, white cracks that read as mud, and a single cartoon eye; two judges ask for new art. This arm addresses the faint only.)

## Cause, and how it was confirmed
Thundertunnel is not in any settle scope, so it plays its raw faint clip. That clip rolls the body over, belly toward the camera, and curls it: by faint-075 the head is turned away and the end pose is a grey rounded mass with no face (CPU base frames).

Confirmed by two runs with only the scope changed:
- the standard settle (side-lie and head lift) leaves it the same ball, because the body is already past the side-lie limits;
- a forced belly-down crumple (the recipe that shipped for Pebbik, Breezetail, Shadelet, Paddlenewt and others in `things_faint2_scope`) rights the roll: the body lands slumped forward, head down, with the eye and snout showing.

## Change
`data/config/creature_pose_settle.json`:
- new `beings_thundertunnel_scope` (OFF), species `thundertunnel`;
- `faint.per_species.thundertunnel`: `crumple.force` true, `tail_relax` 1.0 (inert while the scope is off).

Overlay: the scope on. No code change.

## CPU before and after
`_sheet_cpu_base_top_arm_bottom.jpg` (hit 000, hit 050, faint 050, faint 100). Base faint-100: grey rolled ball, no face. Arm faint-100: slumped mole with its head on the floor and the eye visible. The standing and hit frames differ only at the feet (the settle plants them on the floor).

## By-eye line for the GPU lane
`thundertunnel-faint-100`: the eye and snout are visible at the low front of the body. If it is still a round mass with no face, hold.

## Risks
- The arm's faint is a hunched slump, not a side-lie; judges may call it "still upright" or "cowering" (the crumple lost that way on Stormtrail, Trailpup, Voltwig and Sparkit). If so, park it after this round.
- The settle's hit pass now runs for Thundertunnel (grounding, a small recoil only if the clip barely moves). hit-050 looks the same on CPU.

## Landing notes
Scope ON with `_why_on`; turn `test_scope_is_off_and_thundertunnel_only` into an ON pin and update `test_off_the_settle_does_not_reach_thundertunnel`. Run `test_things_hit_per_species.gd` (it checks which species the settle reaches).
