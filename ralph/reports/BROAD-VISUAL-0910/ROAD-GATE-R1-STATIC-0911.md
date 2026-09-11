# Road Gate / The Rise — R1 static implementation

## Baseline finding

The current production frame reads as a flat ordinary fence leaf under two
plain timber posts and a beam. Its fake 0.22 m lantern boxes, 0.42 m emissive
diamond and 0.16 x 0.14 m lock do not carry threshold identity at player
distance. The leaf, boundary seal, shared key/flag, prompt and open pose are all
working gameplay and remain authoritative.

## Bounded visual pass

All three village exits share one cared-for rural vocabulary through the
existing opt-in `village_dressing` seam:

- installed Quaternius Fantasy `Lantern_Wall.gltf` models fitted from their
  shipped 1.337 m height to an authored 0.56 m target, each with a visible warm
  source and co-located local light;
- shallow post caps and paired knee braces for readable timber joinery;
- installed `Shield_Wooden.gltf`, fitted from its shipped 0.621 m height to a
  0.90 m civic crest, with a small ochre lozenge rather than Team Tether's
  compass language;
- a village-only 2x lock fit so the interaction cue reads against the fence.

Every addition is presentation-only. No new collision shape is created. The
existing leaf remains the only moving part, the lock remains its child, and the
existing `_unlock()` still hides that lock, disables the same collision shape,
rotates the same leaf 90 degrees and disables the same prompt.

## Trustworthy proof plan

`tools/capture_road_gate.gd` now finds the live `RoadGate` under the production
VillageBoundary rather than duplicating its obsolete pre-VP5 coordinate. Two
local-space compositions—road approach and lock/joinery detail—are captured in
locked day/night and disclosed direct-open day/night states (8 frames). The
authored clock is frozen; HUD and independent `SubmersionOverlay` are hidden;
Player is hidden, physics-disabled and kept on verified live ground.

Calling production `open_permanently()` proves only the visual open state; it
does not claim the key or progression was earned. No light, prop, encounter,
weather or pose is injected by the harness.

R1 remains **HOLD** until focused tests and full-resolution production evidence
confirm the installed bounds, readable locked/open hierarchy, night sources,
clear passage and absence of incidental foreground defects.

Static validation is green on the verified Windows package:
`test_village_boundary.gd` reports **14 tests, 199 assertions, 0 failed**,
including construction of the installed dressing, exactly two local lights,
zero presentation collision shapes, village-only lock fitting and the unchanged
open-state source contract. The dedicated capture script also passes Godot's
`--check-only` parse gate.

## R1 production receipt

The Windows Compatibility capture started at
`2026-09-11T13:21:50.3952122Z`, exited zero at
`2026-09-11T13:23:06.6442054Z`, and its manifest reports **8/8 frames,
complete, 0 failures**. Full-resolution inspection keeps the pass: the framed
road threshold now has a clear cared-for silhouette; shield crest, caps and
braces are readable; both installed lanterns provide visible warm sources; and
the locked/open leaf states are unmistakable without changing the route.

The honest self-grade remains **strong POLISH / HOLD for independent review**,
not strict PASS. The underlying leaf is still an ordinary flat fence panel, the
larger lock is readable in the detail pair but small in the long approach, and
the night marker pool is deliberately modest. Large creatures at far frame
right remain background ecology and do not obstruct the location subject.

## R2 bounded response

Independent full-resolution review agreed with that HOLD. R2 adds only the
requested closure: two textured timber diagonals form an X on the moving leaf,
with the lock enlarged to 2.4x and already centered on that brace. The battens
are children of `GateMesh`, so they share the leaf's exact open pose and add no
body. Visible-source emission drops from 0.8 to 0.45 and shifts deeper amber;
the co-located Omni energy rises from 0.55 to 1.15 while its range contracts
from 7.5 m to 5.5 m, producing a stronger bounded pool instead of a pale wash.
R2 remains **HOLD** for the same eight-frame production proof.

R2 focused validation reports **14 tests, 203 assertions, 0 failed**. Its
Compatibility capture started at `2026-09-11T13:31:01.6294200Z`, exited zero at
`2026-09-11T13:32:12.6909685Z`, and the manifest again reports **8/8 frames,
complete, 0 failures**. Full-resolution self-review confirms the locked leaf
now reads as a braced moving gate and the centered lock is legible in both
approach and detail. The open state remains clear. From the oblique open detail
angle the X is edge-on and its batten depth is visible, but it follows the leaf
correctly and creates no traversal change. The deeper amber source is retained;
the broader village night practicals keep its individual pool understated.

Self-grade remains **strong POLISH / HOLD for independent acceptance**. Further
geometry would be scope expansion rather than a response to a remaining
bounded identity defect.
