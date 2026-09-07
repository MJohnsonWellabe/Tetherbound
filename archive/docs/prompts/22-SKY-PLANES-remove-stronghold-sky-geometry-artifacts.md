# SKY-PLANES — Remove unexplained translucent geometry above the stronghold

## Goal
Find and remove the large translucent rectangular planes visible in the sky above/behind the stronghold in storm-pass/stronghold views. This is a root-cause visual defect, not an invitation to hide the symptom with fog or camera framing.

## Known symptom
Multiple rendered viewpoints showed several large semi-transparent rectangles suspended above or behind the stronghold. The backlog does not know the source. Candidate families include:
- LOD/impostor/billboard geometry with a missing/bad texture;
- shadow catcher or debug plane accidentally visible;
- stronghold/castle wall or roof transform/scale error;
- another generated/prefab mesh placed far from its intended parent.

Treat those as hypotheses only.

## Required diagnosis
Reproduce on current `main` first. For every visible plane:
1. identify the actual `Node3D` / mesh / resource responsible (use scene-tree inspection, visibility toggles, remote transform logging, render masks, or a focused diagnostic capture);
2. record its source path and why it is at that world transform;
3. determine whether it is intended geometry rendered incorrectly or geometry that should not be visible at all;
4. fix the producer/source, not the screenshot.

Do not simply delete arbitrary MeshInstance3Ds until the responsible system is known.

## Desired result
- no unexplained translucent/rectangular sky geometry from any normal stronghold/storm-road approach;
- intended castle/stronghold geometry remains intact;
- legitimate billboards/LOD remain functional if they were not the source;
- no new pop-in, missing walls, or broken distant silhouette is introduced.

## Relevant systems to inspect
- `scripts/world/stronghold.gd` and `data/config/stronghold.json`;
- the existing castle/landmark builder and `building_prefabs.json`;
- vegetation/tree billboard or impostor paths;
- any LOD helpers or shadow/decal meshes;
- relocated world transforms after the 8192m corridor move;
- storm-pass capture/probe tooling if still present.

A relocation bug is especially plausible where code mixes local coordinates, world coordinates, and parent transforms; verify instead of assuming.

## Preserve
- stronghold route, collision and machine;
- distant Meadows Hall silhouette;
- intended foliage billboards/LODs;
- performance optimizations unless proven faulty;
- Team Tether materials and lighting.

## Acceptance criteria
1. Current-main captures reproduce the old symptom or establish it is already gone.
2. If present, each plane is tied to a concrete source node/resource before the fix.
3. The root cause is corrected at the producer/config/transform level.
4. Representative approach views show no unexplained sky rectangles.
5. Intended geometry remains present from close and far views.
6. No material/fog hack merely camouflages the artifact.

## Testing / verification
Run relevant stronghold/world smoke tests. Capture the same or equivalent viewpoints where the defect was visible plus at least one different heading/elevation to prove it was not camera-specific. Run the normal blind visual-judge pass. If current main already has no artifact, close as verify-only with evidence.

## Definition of done
The sky around Meadows Hall contains only intentional world/atmospheric geometry, with the exact source of the former rectangles either fixed or proven absent on current main.