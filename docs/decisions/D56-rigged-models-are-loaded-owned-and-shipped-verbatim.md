# D56. Every rigged model is loaded owned, never cloned, and never geometry-optimized

Kind: implementation

Two independent bugs were compounding into the same symptom: a rigged
creature or character occasionally rendered as a screen-filling dark shard
instead of its body. This had been investigated and written off as an
unfixable SwiftShader headless-rendering artifact across at least three
earlier sessions. It was not. Both root causes were in the asset pipeline and
the mount code, and both are now fixed and covered by a permanent probe.

## Root cause 1: `instantiateModelsToScene` shares the source skeleton

`mountRig` (`src/anim/Rigs.ts`) used to call
`container.instantiateModelsToScene(..., { doNotInstantiate: false })`, which
hands back `InstancedMesh`es that share the SOURCE container's skeleton. Every
live pal of the same species was writing its own AnimationGroup's bone
matrices into that one shared skeleton on the same frame, and whichever pal
wrote last that frame is the pose every instance of that species rendered.

**Fix:** the entity now owns its container outright. `loadContainerOwned`
(`src/core/AssetLoader.ts`) does a fresh, uncached `LoadAssetContainerAsync`
per mount; `container.addAllToScene()` adds the container's own nodes,
skeleton and AnimationGroups directly, with no instantiate and no retargeting.
Disposal is one `container.dispose()`. The browser's HTTP cache still makes
the second and later downloads of a species free.

## Root cause 2: the optimizer's geometry passes corrupt some skins

The rigged transform in `scripts/optimize-assets.mjs` ran
`dedup/prune/weld/resample/quantize` on every model, skinned or not.
Measured directly: a model's inverse bind matrix scale went from 1.0 (raw
source) to 0.014 after that pipeline ran. Six specific creature sources
(all from the poly.pizza "Animated Animals"/"Birds" packs — cindercub,
sparrowick, grazehorn, thistleback, cragpup, ashmane) render as exploded
shards in Babylon once their skin passes through those transforms, even
though the geometry itself is intact (raw vertex extent 0.07 units) and
plenty of other models from the same packs (the "Ultimate Monsters" set,
and all five humanoids) survive the exact same pipeline untouched.

Proven independently of the game: loading the RAW downloaded `.glb` for
those six species into a bare scene with zero game code reproduces the
explosion, and loading a pipeline-processed file from a working species
does not. So the fault is in what Babylon's skinning does with those
specific six source rigs once geometry-optimized, not in anything this
project's runtime code does with them.

**Fix, two parts:**

1. Skinned models get NO geometry passes in `slim()`
   (`scripts/lib/glbtool.mjs`) — only clip pruning (drop animations the game
   never plays) and texture compression. The skin ships exactly as authored.
   Rigged budget ceilings raised to 1000 KB (creatures) / 1900 KB
   (characters) to cover verbatim skin data; these are lazy-loaded per spawn,
   never on the boot path, so the cost lands when a creature first appears.
2. The six sources that still explode even verbatim (something about those
   specific rigs and this Babylon version) are recast onto Kenney Cube
   Pets — the pack ASSETS.md already named as the per-species fallback. Cube
   Pets ships **no skin at all** (node-TRS animation only), which puts it
   outside this entire bug class by construction. Its clip set is
   `{static, idle, walk, run, eat, dance, gesture-positive,
   gesture-negative}` — no attack/hit/faint, mapped to `null` in
   `models.json` per the existing "a missing verb is data, not a crash"
   contract (D45). The species read is kept as close as the pack allows
   (fox for the ember-starter fox kit, deer for the horned grazer, lion for
   the maned quadruped, etc.).

## The permanent check

`tools/rigcheck-bounds.mjs` loads every creature and character exactly as
`mountRig` does, computes each mesh's bounding box THROUGH the skeleton
(`refreshBoundingInfo({ applySkeleton: true })`), and fails if anything
exceeds 20m — a real animal is never that big. Run it after any change to the
rigged pipeline, a poly.pizza source swap, or a Babylon upgrade; this bug
class has no static check that catches it before it ships.

## What this replaces

Earlier sessions attributed the wedges to headless SwiftShader rendering and
told future sessions not to chase it. That guidance is retracted. The wedges
were real, reproducible on both software and (per the raw-file test, which
doesn't touch the game's renderer setup at all) any Babylon WebGL context,
and are now fixed and verified by a tool that runs in under thirty seconds.
