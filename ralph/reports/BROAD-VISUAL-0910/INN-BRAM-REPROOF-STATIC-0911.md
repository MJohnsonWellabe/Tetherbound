# The Village Inn / Bram — final reproof preparation

## Static disposition before production proof

The existing eight-frame evidence is useful for the public facade but is not a
current acceptance receipt. It finished at 03:51 on 2026-09-11, four minutes
before commit `5ca77869e` rebalanced the common room and corrected Bram's facing.
The former report's claims that the interior is still uniformly warm and that
the harness parks the player underground are therefore stale.

Full-resolution review retains the broad porch, two readable signs, paired
visible lanterns, barrels and bench. It also found one bounded frontage defect:
the cream primitive below the bench reads as an untextured slab in both doorway
frames. It is replaced by the installed Quaternius Fantasy `Bag.gltf`, within the
same prop family and with measured clearance from the 1.6 m doorway lane.

## Required production proof

`tools/capture_inn.gd` now writes a fresh ten-frame receipt to
`INN-BRAM-REPROOF`: front, corner, doorway, Bram/bar and guest tables, each at
authored day and night. The closer customer-side bar composition must prove
Bram facing the arriving customer while keeping the stock shelves, sign,
counter service and visible candle in the same frame. The tables view must prove
that the central route remains open and the cool fills recover material colour
without flattening the room.

The harness freezes the authored clock, hides both the ordinary HUD and the
independent submersion overlay, and records all frames plus exact completion
metadata in a manifest. For each composition it seats the hidden,
physics-disabled Player on verified live ground at the patron camera's x/z;
that lets the production NPC tracking path face Bram toward the actual viewer
instead of an off-camera spawn ghost. It does not inject NPC poses, progress,
encounters, lighting or weather.

## Acceptance bar

- Exterior still reads immediately as a public inn from both settlement faces.
- No primitive cream luggage slab remains under the bench.
- Bram's face and front silhouette are readable at speaking distance.
- The bar reads stocked and warm, while plaster, timber, rug and skin retain
  distinct colour and value.
- Day and night common-room frames are both navigable and free of clipped,
  floating, blacked-out or foreground-dominant defects.
- All ten expected frames exist at 1280x720 and the manifest reports complete.

No production render has been run for this preparation. Final grade remains
**HOLD** until the fresh receipt is captured and independently inspected.

## R1 production rejection and R2 correction

R1 completed 10/10 on the Windows Compatibility renderer, but is rejected:
Bram visibly presents his back to patrons in all four interior frames. Those
pixels falsify the earlier source-only `Vector3.FORWARD` assumption. The
installed male rig's visible face is local +Z, so Bram is restored to +90
degrees, which points that visible face east toward the Inn doorway.

Root review also retained the facade/bag change while grading the long common
room POLISH rather than PASS: its plain counter and two empty table surfaces
remain procedural and sparse. R2 therefore adds four shallow, visual-only
timber joinery panels to the existing counter face and two fitted installed
Fantasy-family tabletop clusters (`FarmCrate_Apple` and `FarmCrate_Empty`).
They add no collision, stay outside the x=0 customer route, and do not change
the tables, counter, Bram, vendor interaction, doorway or room footprint.

R2 remains **HOLD** until the same ten-frame production set proves Bram's face,
the tabletop occupation, the unchanged clear route and both authored clocks.

## R2 harness finding / R3

R2 again showed Bram's back even after the rest yaw changed. Inspection of the
production path found why both yaws photographed identically:
`npc_body.gd::_process` turns every nearby NPC toward the actual Player. The
harness hid and disabled Player processing but left that node at spawn, so Bram
correctly tracked an invisible off-camera body. R3 seats that hidden,
physics-disabled Player at each camera's x/z on a verified live ground sample,
then allows 72 physics frames for ordinary NPC tracking before capture. This
does not pose Bram; it proves the face a real patron at that position sees.

Root full-resolution review retained R2's joinery and requested only that both
tabletop crates shrink about 18 percent. Their scale is now 0.67 (from 0.82),
with positions, no-collision contract and the accepted room layout unchanged.

## R3 production receipt

R3 passed the focused suite on the Windows package: **6 tests, 38 assertions,
0 failed**. The production Compatibility capture started at
`2026-09-11T12:52:54.0478749Z`, exited zero at
`2026-09-11T12:54:17.5001802Z`, and its manifest reports **10/10 frames,
complete, 0 failures**.

Full-resolution inspection accepts the runtime-facing correction: Bram's face
and front silhouette are unmistakable in both customer-side bar frames. The
smaller table crates now remain secondary to the tables and open center route;
the counter joinery, installed exterior bag, signs, lanterns and public facade
remain clean at both clocks. No cropped peripheral occupant remains in the
current interior compositions.

The honest final self-grade is **strong POLISH**, not strict PASS. The exterior
is recognizable and commercially composed, and the interior is functional,
lit and occupied, but the long common room still has a broad, plain procedural
shell that keeps it below the character/creature finish bar. There is no
remaining bounded defect in this Inn change worth expanding the round for.
