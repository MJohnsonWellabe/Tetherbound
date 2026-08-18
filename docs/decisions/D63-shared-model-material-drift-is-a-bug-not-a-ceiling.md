# D63 — Shared-model material drift is a bug, not a ceiling, until checked

**Date:** 2026-08-18 · **Decided by:** direct diagnosis (`MAT-BLOCKOUT`), following
the precedent `EV2-landmark-oak` already set once for a single asset.
**Source:** `ralph/BACKLOG.md`'s `MAT-BLOCKOUT` entry; `ralph/NOTES.md` (dated
2026-08-18) has the full before/after evidence.

## The decision

**Before recording a landmark asset as needing new art, check whether the SAME
model is placed correctly somewhere else in the codebase.** If it is, the
defect is very likely a material/retint bug in the code path that placed it
wrong, not a limit of the asset itself — and the fix is to make the two
placement paths agree, not to generate or replace anything.

This is not a new rule so much as the second time the same failure shape has
been found and fixed, which is what makes it worth a decision doc rather than
just a `NOTES.md` entry:

- `EV2-landmark-oak`: `CherryBlossom_3.gltf` rendered in its native pink/purple
  because `vegetation.json`'s `grove` layer retint keyed `Leaves_TwistedTree`
  and never `Leaves_CherryBlossom`, the model's own actual material name.
- `MAT-BLOCKOUT`: the Old Quarry's rootstone deposits rendered in
  `Rock_Medium_1/3.gltf`'s native pale, cool-toned diffuse because
  `harvest_node.gd` (a hand-placed-node code path) never applied the retint
  `vegetation.gd`'s MultiMesh scatter path already applies to the identical
  models elsewhere in the same meadow.

Both looked, at a glance and from a distance, like "this asset just isn't good
enough" — round 1 of Band 2's own blind-critique loop couldn't even see it
(the defect only became visible once the survey cameras moved close). Both
were actually a config/code-path mismatch: one consumer of a shared model
had been retinted or retextured, and a second consumer of the exact same
model had not.

## What this does not cover

Not every defect on a shared model is this shape. `MAT-BLOCKOUT` itself found
a genuine, separate ceiling in the same asset family once the colour bug was
fixed: `Rocks_Diffuse.png` (the texture all three `Rock_Medium` variants
share) carries a baked low-poly-to-highpoly hatch/facet artefact that no tint
or model swap within the family can reach, because it is baked into the one
file every candidate shares. That half was fixed by substituting a different,
already-installed, already-vetted photographic texture
(`terrain_playground.json`'s own `Rock030` material) for that one material
name — still no new asset, still no Meshy spend, but a real texture swap
rather than a tint, and the kind of fix that only becomes available when the
project already has a better texture installed elsewhere to reach for.

So the check this decision asks for is specifically: **is the same model
already placed correctly somewhere else in this codebase?** If yes, look
there first. If the defect survives matching the two placements, it may still
be a real ceiling — but check the cheap explanation before writing the
expensive one down.

## What it does not change

- `CLAUDE.md`'s no-new-Meadows-meshes and no-generation-without-reference-art
  rules are untouched. This decision is about diagnosis order, not about when
  generation is or isn't allowed — a genuine ceiling is still a genuine
  ceiling, and Meshy spend rules apply exactly as before once one is actually
  found.
- `vegetation.gd::_warn_about_shared_models` already existed and already
  covers the narrower case (one model claimed by two *vegetation* layers).
  This decision generalizes the same suspicion to any second code path that
  places a model vegetation.json already retints or retextures — hand-placed
  nodes (`harvest_node.gd`), prefabs, or anything else that `load()`s a model
  from the same asset packs.
