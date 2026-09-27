# Cloudreach cliff/cloud candidate — visual FAIL, C2 open

V10/V20/V28, F08#4. The Cloudreach handoff `b764a197a` was merged at
`86c7ea68f`; main `43e6949f2` at `53514232a`. The current candidate replaces
distant haze meshes with authored limestone spires, gives them lit geology,
and now tests bounded density clouds in place of the rejected cloud cards. Existing
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


## Turf-linked ground cover and owner creature findings

Grass now samples the same wet/dry turf colour field as its supporting ground,
with tunable root/tip gains. Opaque blades use the opaque material path; bush
leaf cutouts remain. Independent review caught and corrected wet material use
on dry far fill. Existing sliced-cover smoke passes; eight native 1920x1080
Windows NVIDIA Compatibility frames completed with zero skips and were each
opened. Evidence: `cloudreach-c2-candidate/turf/`.

Blind comparison used X=current, Y=previous buttress native frames; mapping was
withheld. X is preferred modestly by day and clearly at night. Bars A NO/B NO;
full C2 remains open. The judge still flags noisy creature surfaces, creature
overlap, plain cliffs, planting boundaries and weak inhabited depth. The new
verdict is retained without replacing the earlier verdict. Different wild
spawns prevent a clean whole-frame actor comparison.

Owner then identified Galecrest's broken-neck appearance and the solid-pink
Cloudfang. Seven native diagnostic frames reproduce the shiny fallback and
compare Galecrest rest with idle samples. Cloudfang lacks its authored shiny
texture and falls into the legacy magenta multiply. Galecrest's unanimated
neck is intact; motion/weights need inspection before a Meshy rebuild decision.
Neither creature finding is fixed. V30 expanded; V-CX-9 appended.

Shortcuts disclosed: eight stationary production-camera stands, scripted
progression, hidden HUD, fixed60fps; seven separate studio diagnostic frames.
No complete C2 matrix, motion pass, creature PASS, full unit suite or READY.
Native log retains the existing unscoped fly_tutorial_completed flag warning
and absent placement warnings; no shader compilation failure found.


## Cloudfang shiny placeholder repair

V-CX-9 now has an authored region repaint through the existing texture pipeline.
Only the Cloudfang config entry and new shiny PNG/import change. Ordinary,
mesh, spawn odds, save data and shared creature runtime are untouched.
Inspected source atlas and Cloudfang roster reference; provenance records hashes.

Six native Windows NVIDIA Compatibility 1920x1080 Windscar frames compare
ordinary, explicitly reproduced old placeholder and new shiny by day/night.
Production camera and follower retained; fixture party and shiny state set
directly. All six frames and two studio views individually inspected. Two
existing source-colourway tests / 76 assertions pass; independent source review
finds no blocker. Evidence: `cloudreach-c2-candidate/cloudfang-shiny/`.

Code-blind verdict: old placeholder FAIL, new shiny and ordinary PASS for
replacing flat placeholder presentation. Overall Bars A NO/B NO. Remaining:
coarse plated fur, shoulder boundaries, and weak at-a-glance distinction of
the variants at night. No full creature-art, F08#4 or C2 closure claimed.
Galecrest remains next: rest-basis inspection shows its neck turn channel has
only 0.191 alignment to upright yaw, versus 0.98 on the head; motion/weights
still need a reproduced correction before blaming the mesh or calling it fixed.


## Galecrest strained-neck reproduction

The live CompanionLook layer, rather than a broken mesh, reproduces the owner's
specific strained pose. Galecrest's head-forward Y was also selected for the
primary turn, with a 110-degree limit and target at the trainer's feet. An
opt-in Galecrest recipe measures body-up, uses 55/30-degree limits and a target
1.55m above the trainer origin. Other species retain their prior behavior.

Eight native NVIDIA1920x1080 production-camera frames compare the original
settings and candidate by day/night from both Windscar directions. All were
opened. Modifier settings are logged. Thirty-two companion tests /183
assertions pass, including installed Galecrest target movement, transform,
reuse and injury/healed transitions; independent source review clean.
Evidence: `cloudreach-c2-candidate/galecrest-gaze/`. Scoped blind head/neck verdict PASS (old variant FAIL), especially the reverse
view. Overall Bars A/B NO. No full creature, motion-cycle or C2 pass is claimed.

Shortcuts disclosed: staged progression/party, two stands, frozen follower and
idle sought at1.2s, old settings explicitly reconstructed, HUD hidden, fixed60fps,
pinned day/night. No changed model/scale or Meshy generation. Feather breakup,
face and night colour remain art work; the separate authored idle-axis suspicion
is not treated as the proven cause of the live head-look defect.


## Bounded cloud volumes and cliff/cloud palette

V10/V20/V28 continues from e02080ecf, with current main e59b0c97d already
integrated. Rejected camera-facing cards are replaced by 110 deterministic
bounded cloud volumes. This is an original project shader, guided by the
inspected Sky Aviary board; no new Meshy task or external purchase. Proxy tops
stay under sampled cloud safety heights. Recovery CloudSea, routes and collision
are unchanged. The shader integrates soft density with opaque-depth truncation
and an interior edge fade; independent review found and verified both repairs.
A native plane/pillar diagnostic shows cloud in front of intersecting geometry
and foreground occlusion. Five-point terrain clearance is not full-footprint
proof; Ally cost remains unmeasured.

Six native production-camera frames (01/12/17/25/30/32), all individually
inspected, remain blind **A NO / B NO**. Gate altitude reads, especially at
night; far chalk-white stone, flat cloud expanses, bare settlement integration,
material scale and ground-cover boundaries still fail. Frame32 also shows
interpenetrating wild flyers and rectangular road shadows: appended V-CX-10.
The existing four environment tests pass 31 assertions; the detached-node
warning from the old cliff-wall test remains in the raw log.

A same-camera three-frame diagnostic rules out absent imported texture and fog
as the main explanation for white distant stone: it remains pale with both fog
and material aerial blend disabled. Nine additional frames compare R/S/T
palettes at arrival day, Windscar day and arrival night. The independent judge
narrowly prefers S's cooler rock/cloud separation, explicitly **not** an accepted
pass; both bars remain NO. S now uses normal config material construction, verified by three additional
native normal-script frames (01/12/30), individually inspected, exit0/zero
skips. The comparison fixture is not needed for the selected treatment.
Near tan rock versus distant pale rock and settlement/cliff composition are the
next substantial work; another subtle palette iteration is insufficient.

Evidence: `cloudreach-c2-candidate/cloud-volume/` includes before cards, six
volume frames, diagnostic captures, all nine palette frames, failed verdicts,
source review, provenance, fixtures and raw logs. Before-card backgrounds use
matching prior turf views; creature gaze/motion differ. Palette variants share
the running world/camera but creatures animate. Shortcuts disclosed: staged
flags and party, teleported registered stands, clock pinned, HUD hidden, no
played journey/combat; subset stills do not prove full C2 or motion acceptance.
No READY FOR INTEGRATION and no criterion closure.
## Settlement structure trial and unsupported yard planting

At baseline5c886d80f, ten native day/night diagnostic views of Cliffhold and
Galefoot confirmed the same-level cottages and unsupported vegetation. An
original project-authored northwest retaining arcade interpreted the inspected
Sky Aviary board using installed masonry materials. Three matched production
C2 views21/25/32 were rendered before/after. Independent source review found
no collision/route change;168-solid geometry smoke passed. Blind review tied
architecture in every pair and narrowly preferred the baseline: the close
lookout foundation looked less integrated. Bars A/B NO. The entire game
candidate was reverted; sources and evidence remain only under
`cloudreach-c2-candidate/settlement-terrace`. No generation, purchased asset or
reference pixels were involved. Further below-floor decoration is not the
next structural approach; occupied terraces must read in the actual layout.

The retained bug repair tags only each settlement's flat yard/precinct planting
patches with its supporting floor bounds. Unsupported roots are discarded
after the original random draws and count toward the requested total, keeping
every supported tuft's transform rather than resampling extra edge density.
An outboard flower prop moves onto the crown. Untagged patches, route surfaces,
house transforms and collision remain unchanged. Six focused tests pass with
587assertions; independent revised source review finds no blocker.

Ten native after frames and their ten before counterparts were individually
opened. Some edge planting disappears, but the floating clump at the left of
Cliffhold court003/004 remains. Blind review narrowly preferred the repair in
four views and tied six; grounding FAIL and Bars A/B NO for both versions.
V-CX-11 is open. The next diagnosis must locate
that actual MultiMesh instance and its supporting surface; the route patch
sampler uses linearly interpolated centre-line heights while the generated
shoulder is clamped to nearby walkable surfaces, a lead rather than a proved
attribution. Evidence: `cloudreach-c2-candidate/yard-bounds`.

Shortcuts disclosed: stationary production rig, scripted progression, hidden
HUD, fixed60fps. The settlement diagnostic parks the companion behind camera
and uses its existing upward pitches (recorded in manifests); it is not full
C2 or motion proof. The arcade's C2 comparisons keep the native companion;
wild/follower poses differ. All renders used native Windows NVIDIA1920x1080
Compatibility. No full unit suite, Ally telemetry, F08#4 closure or READY.
