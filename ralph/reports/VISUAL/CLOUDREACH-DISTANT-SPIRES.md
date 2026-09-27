# Cloudreach cliff/cloud candidate — visual FAIL, C2 open

V10/V20/V28, F08#4. The Cloudreach handoff `b764a197a` was merged at
`86c7ea68f`; main `43e6949f2` at `53514232a`. The current candidate replaces
distant haze meshes with authored limestone spires, gives them lit geology,
and tests a lit cloud deck with original generated cloud cards. Existing
gameplay collision, routes and fall-recovery datum are retained.

The eight-view native candidate failed both Bars A/B. The judge found
crystalline/tree-shaped cloud contours, smooth folded distant cliffs versus
angular near cliffs, a buried stronghold approach, hidden settlement altitude,
rectangular cover and overbright night grass. No F08#4 closure or integration
readiness is claimed. See `cloudreach-c2-candidate/cards-v1-judge.md`.

The original mesh family interprets the inspected Cloudreach Sky Aviary board's
vertical buttresses and shallow broken ledges. Provenance is recorded in
ART_DIRECTION §7. There is no Meshy task for these authored meshes.

Independent source review found no blockers: each mesh is closed, connected,
outward-wound and nondegenerate, with 1,858 vertices and 3,712 triangles.
The generator reproduces the three files exactly. Scoped Godot 4.7 import passed.
This does not certify visual quality or imported runtime geometry.

Current before capture: `53514232a`, 36 native 1920×1080 Windows NVIDIA
Compatibility frames, exit 0, zero skipped. Matching eight before frames and
all eight cloud-card candidate frames are retained in
`cloudreach-c2-candidate/{before,cards-v1}/` with raw logs. The full baseline
remains at `shots/cloudreach-c2-before-53514232a/`. Earlier interrupted work
remains preserved locally; it supplied no verdict.

M10 capture repair removes the forced 1.8 m companion pose and lets production
formation run for 120 physics ticks. Independent source review found no
blocker (`cloudreach-c2-candidate/capture-review.md`); this is not a universal
convergence guarantee. The narrow bridge still crowds the companion. The
obsolete fixture flag was removed from this script, but the chapter runtime
still emits its own unscoped-flag warning; that other lane's config is unchanged.

The cloud sprite is original OpenAI imagegen output, inspected before this
integration trial. Its artifact ID, hash and rejection are recorded in
`cloudreach-c2-candidate/provenance.json` and ART_DIRECTION §7. It is not
accepted final art. The board supplied visual direction, not shipped pixels.

Shortcuts disclosed: scripted progression, stationary production-camera stands,
hidden HUD, fixed60fps, eight-view candidate subset, and a formation-fixture
change between before and candidate. The judge accidentally read embedded
status sections in ART_DIRECTION; its disclosure is retained. This packet
cannot certify motion, unseen settlements or the full C2 matrix.

## Aviary architecture candidate

Original board-backed belvederes extend the four existing masonry piers; gold
ribs replace the timber/iron dome surface. Walking openings, collision and
pylon anchor are unchanged. Native five-frame v1 exposed inward arch faces;
independent source review caught and verified their correction. The corrected
four-frame v2 is in `cloudreach-c2-candidate/towers-v2/`, with source review,
raw logs and focused test report (10 tests, 202 assertions, zero failures).

The separate code-blind verdict is **A: No, B: No**. It recognizes gold ribs,
open arches and slate roofs but finds the shafts post-like and the building
poorly integrated with its terrain. The long/near approach remains a sparse
corridor, the close view crops the roof, and creature/prop materials disagree.
The full verdict is `cloudreach-c2-candidate/towers-v2-judge.md`. These four
daytime stills do not cover night, motion, interiors or full C2.

Next real changes must address the approach/terrace composition, coherent cliff
modules and creature/material hierarchy rather than rejudging these frames.
The checkpoint branch is work in progress, **not READY FOR INTEGRATION**.
