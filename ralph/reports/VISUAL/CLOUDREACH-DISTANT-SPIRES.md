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

## Limestone buttress candidate and summit trial disposition

One inspected original reference was submitted to Meshy task
`01a0e3c1-a953-719a-9c87-e05490ca595f`, using 30 existing credits. The raw
candidate had 61 nonmanifold edges after seam welding. A closed reconstruction
and 12,000-triangle reduction passed topology checks. Direct UV transfer was
rejected after inspecting all four turntable views: source seams smeared into
zigzags. The replacement preparation unwraps the closed mesh and bakes source
diffuse colour without lighting. Its four inspected views retain fractures,
ledges and moss without the smear. This validates a candidate for an in-game
trial, not C2 acceptance. Provenance and preparation evidence are under
`cloudreach-c2-candidate/buttress/`.

Two summit crown-cut trials were rejected before rendering. A 0.9 bank slope
introduced steep join fins (12 smoke failures); slope 1.6 with a wider floor
also exposed floating supports (14 failures). Both changes were reverted.
The restored crown passed the same complete smoke, including solo/co-op
geometry and two real input walks, with zero failures. No approach improvement
is claimed from those trials. Raw logs are retained with the candidate evidence.

The owner also rejected the lime-green foreground clump in Windscar frame 12.
Cloudreach's two imported roadside grass batches now use muted olive materials
instead of their saturated palette swatches; shared source assets are unchanged.
Three existing route-verge tests / 60 assertions pass. The matching native
daylight frame confirms the colour change. The 8-frame candidate run completed
at 1920x1080 on Windows NVIDIA Compatibility, exit 0 and zero skips; all eight
individual frames were opened. Separate dense ground cover remains too bright
at night, and pale distant cliff/cloud integration remains unsolved.

Shortcuts disclosed: candidate subset, scripted progression, hidden HUD,
stationary production-camera stands; this packet does not certify full C2 or
motion. The first launch was stopped after a missing extracted texture
dependency; the complete dependency was copied and the corrected run succeeded.
Local scoped-import UID warnings fell back to the valid texture path.

Two supplemental native night frames at the exact Windscar 12/13 stands also
completed with zero skips and were individually inspected. The broad grass
stays subdued blue-grey. Independent blind review of the eight-frame set plus
these night views gives **A: No, B: Yes** (genre/readability only, not quality
parity). The full visual gate remains failed. See `buttress/visual-judge.md`.
The next work remains coherent foliage/ground response, cliff-cloud integration,
inhabited vertical architecture and actor readability. No READY is claimed.
