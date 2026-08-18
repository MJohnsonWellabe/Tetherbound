# STRONGHOLD-MAT — Verify and fix stronghold material presentation

## Goal
Reproduce the owner-reported stronghold presentation problem on current `main`: close/approach views read as flat black slabs / grey boxes rather than a finished Team Tether stronghold. **Verify before changing anything**, because current `stronghold.gd` now contains a later multi-tone castle palette and comments documenting a prior fix for the exact "plain grey" complaint.

## Current evidence
Current `scripts/world/stronghold.gd` already has:
- reusable `StandardMaterial3D` creation;
- base stone plus light/dark stone accent values;
- timber/metal/faction trim palette plumbing;
- reserved Tether oxblood/teal palette reads;
- a comment quoting the owner complaint that the stronghold was too sterile/plain grey and explaining the later palette work.

`data/config/stronghold.json` also supplies stone/floor/Tether colors. Therefore do **not** assume the old screenshot still represents current main.

## Required workflow
1. Render/reproduce current stronghold from the normal player approach and inside representative spaces.
2. Determine whether the defect survives.
3. If current main already reads as intentional stone/castle/Tether architecture, close with captures and no material churn.
4. If it still reads black/grey/blockout-like, trace exactly which geometry/material path is bypassing the current palette and fix that systemic path.

## Desired visual result
- old cut-stone fortress shell reads as architecture, not primitive debug boxes;
- visible value/material separation between wall, floor, trim, base course, timber/metal accents where authored;
- Team Tether oxblood and teal hardware reads as bolted-on industrial occupation of the older stone site;
- close-range surfaces remain legible under day/night lighting;
- distant approach retains strong silhouette and faction identity;
- do not overtexture into noisy realism: primary world target remains the Meadows key art's stylized realism and coherent palette.

## Diagnose, do not repaint blindly
Inspect:
- `_build_chambers`, `_build_passages`, `_build_trim`, `_build_conduits`, approach ramp/skirt, doors, lights, and any prefab/model material overrides;
- whether relocated stronghold geometry has a path using default material/null material;
- whether Compatibility-renderer emission/lighting is crushing intended albedo;
- whether any visual is actually an unrelated transform/sky-plane defect (SKY-PLANES owns that).

If one builder is using a fallback color while others use the palette, repair the source rather than assigning one-off materials to every mesh.

## Preserve
- five-space compact stronghold route and collisions;
- current stronghold location/layout unless a visual defect is specifically caused by a broken transform;
- faction reserved colors;
- installed Tether machine asset;
- no new creature or human generation;
- performance appropriate for Ally.

## Do not
- do not regenerate the stronghold from scratch;
- do not change combat/progression gates;
- do not flatten all surfaces into one global tint;
- do not treat the owner’s old screenshot as proof current main is still broken;
- do not solve SKY-PLANES/BILLBOARD-WHITE here unless root cause is literally the same material path and the fix is safely shared.

## Acceptance criteria
1. Current-main reproduction exists from approach + close interior/outer-works views.
2. No unexplained black/default-grey/blockout surfaces remain on authored stronghold architecture.
3. Stone, floor, architectural accents, and Tether hardware are visually distinct but cohesive.
4. Day and night both remain readable.
5. Existing route/collision/combat behavior is unchanged.
6. If the issue was already fixed, the task lands only evidence/bookkeeping rather than unnecessary retuning.

## Testing / verification
Run relevant stronghold smoke tests and `smoke_art` if applicable. Because this is visual-affecting, capture representative frames and follow `ralph/conventions.md` blind visual-judge convergence using `docs/reference/tetherbound-meadows-keyart.png` as primary world target. Judge palette, landmark language and mood—not pixel fidelity.

## Definition of done
The stronghold reads as a deliberately materialed old fortress industrialized by Team Tether from both approach and close play, or current main is proven already to do so and no redundant rewrite is made.