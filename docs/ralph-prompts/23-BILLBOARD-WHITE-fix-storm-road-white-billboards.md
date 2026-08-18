# BILLBOARD-WHITE — Fix white cards among storm-road trees

## Goal
Remove the upright white rectangular cards visible among trees near the storm road by fixing the billboard/impostor/material path that produces them. They read as untextured geometry and break the world immediately.

## Likely class, not assumed root cause
The symptom strongly resembles a billboard whose texture/material failed to bind. The project has had a prior landmark-oak/billboard defect in the same general class. Reproduce and identify the exact resource first; do not blanket-disable every billboard.

## Required diagnosis
On current `main`:
- reproduce from the reported storm-road area at normal player camera height;
- isolate the responsible node/instance/layer/model;
- inspect its material, texture path/import, alpha mode, LOD distance, orientation and fallback behavior;
- determine whether the card belongs to vegetation Terrain3D instancing, a custom impostor/LOD, or some unrelated prop.

If a texture is missing, fix the asset/resource reference and fail gracefully when unavailable. If an LOD transition exposes raw geometry, fix that transition. If the object is obsolete, remove it at its authored source rather than hiding one instance.

## Desired behavior
- trees/foliage transition normally at gameplay distances;
- no pure-white or default-material upright cards in the storm-road view;
- alpha edges and orientation remain visually acceptable on Compatibility renderer;
- performance benefits of billboards/LOD are retained if the system is otherwise valid.

## Preserve
- existing vegetation density and siting unless the defective entry itself must be removed;
- collision policy from RG23;
- Terrain3D performance strategy;
- coherent nature asset family;
- no new nature asset family just to replace one broken card.

## Acceptance criteria
1. The current defect is reproduced or proven already absent.
2. The responsible layer/resource is explicitly identified.
3. No white/default-material billboard cards remain in representative storm-road traversal.
4. The relevant trees still render at near/mid/far distances without a worse pop/disappearance.
5. No broad billboard disable causes a meaningful Ally performance regression.

## Testing / verification
Use representative near/mid/far captures through the transition distance and the normal visual-judge process. Run vegetation/art smoke tests. If current main is already clean, close with evidence rather than changing unrelated foliage.

## Definition of done
Storm-road trees read as trees at all supported LOD distances; no unassigned-texture white geometry is visible.