# N09-BRIDGE-CHECKPOINT

**Source:** W22-BRIDGE-SIGNPOST-0904's report and its landing-time blind judge (run by
W24-LANDING per the owner directive of 2026-09-05 02:24 UTC; find the full verdict at
`ralph/reports/W22-BRIDGE-SIGNPOST-0904/JUDGE.md` on `origin/main`).

## Why
The landing judge's call: **ship the bridge deck/rail, do not ship the signpost or the
checkpoint dressing as they stand** — but named the remaining gap in each case as "scene and
material work, not new art." This lane closes that gap with existing assets.

## Owns
`scripts/world/south_bridge.gd`'s checkpoint dressing (materials/placement only, not the gate
mesh itself), the signpost's text/decal material (not its base mesh), and the barricade/guard
dressing at the checkpoint.

## Do

**1. Checkpoint barricades need texturing and correct placement (do not ship as-is).** The
"held" read at the checkpoint is currently carried by untextured blockout barricades that sit
BESIDE the road rather than across it. Apply an existing installed material (check
`assets/environment/team_tether/` for barricade/blockade materials already used elsewhere) and
reposition them to actually block/narrow the road rather than sit beside it — per D86 §1 the
barricade should not literally cross the deck itself, but should read as controlling passage
at the checkpoint, not decorating its shoulder.

**2. Guard wears no faction colour (do not ship as-is).** The checkpoint guard currently wears
none of Team Tether's oxblood. Check whether the guard NPC's existing outfit has a tintable
slot (per the humanoid asset inventory, `docs/art/HUMANOID_ASSET_INVENTORY.md`, Team Tether
grunts should already have faction colouring available) and apply it — this should be a
material/tint change on an existing rig, not new clothing geometry.

**3. Gate banners are inconsistent (do not ship as-is).** The hero checkpoint gate's own
banners are blue (from its original Meshy scan); the two staked banners in front of it are the
correct oxblood. From the far bank (30 m, at `place5-bridge-approach`), the gate's blue banners
still fly beside the correct oxblood ones and read as inconsistent. The gate mesh itself is
out of ownership (do not touch it) — instead, either retint the gate's banner material if it's
a separate swappable material slot (check the `.glb`'s material list before assuming this
needs new geometry), or if the gate banner is baked into the mesh, route this specific
sub-item to the coordinator as needing a Team Tether asset lane rather than attempting a mesh
edit.

**4. Signpost legibility (evaluate whether this is in scope before attempting).** The signpost
model itself is called "the right model" by the judge — it fails on legibility, not design:
glyph cap height measures 5–7 px in world frames at a text-to-board contrast of ~1.3:1, against
3.0–11.6:1 in studio turntables. Check whether the signpost's text is a decal/material (in
which case increasing contrast and glyph weight in that material is in scope for this lane) or
baked into UV/geometry detail too fine to read at distance (in which case this is a Bucket-B
art problem — do not attempt a mesh change; record the finding and stop). Only proceed if it's
a material-level fix.

## Verify
- Re-render the exact stands the landing judge used (`_sheet.png`/frames referenced in
  `ralph/reports/W22-BRIDGE-SIGNPOST-0904/JUDGE.md`) after each fix.
- Run a fresh code-blind judge, telling it nothing about what changed, asking specifically the
  judge's own four original questions (from `JUDGE_PROMPT.md` in the same report directory) —
  confirm the barricade, guard colour, and banner-consistency verdicts flip from "do not ship"
  to acceptable, or state precisely what's still short.
- `test_signpost_geometry.gd` and the four-file crossing test set (already exist per W22's
  report) must still pass — you are not changing collision/geometry, only materials and
  placement.

## Acceptance
A fresh blind judge, given the same four questions the landing judge asked, confirms the
barricade and guard-colour "do not ship" verdicts are resolved. Bridge banner consistency is
either fixed or explicitly routed further with a clear reason. The signpost item is either
fixed (if a material-level fix) or explicitly left as a Bucket-B art gap with the check that
justifies that call.
