# D63. The performance ceiling comes off, and the image gets a grade

Kind: conflict

The owner's verdict on the build was that the visuals were "so far off", with
the bar for continuing set at "it looks like Palworld". This record is the
conflict that had to be resolved before any of that was reachable.

## The conflict

`ASSETS.md`, `ARCHITECTURE.md` and `.claude/skills/visual-judge/SKILL.md` all
specified: no post-processing, under 150 draw calls, under 300k triangles,
60fps on an iPhone 12. D24 restated it and added that a judge asking for more
would "break the perf budget and the stated style at the same time".

That budget was already dead. D28 moved the target to a ROG Ally at 1080p and
explicitly released the perf budget, the view distance and the UI layout from
the phone constraint. No rendering document was updated to match, so three
documents and the judge rubric still enforced a device the project stopped
targeting.

The owner lifted the ceiling explicitly for this work: look first, measure
later, no perf ceiling.

## What this permits

A `DefaultRenderingPipeline` in `src/core/Engine.ts`: tone mapping, exposure,
contrast, colour curves, bloom, FXAA, vignette. Every number in `render.json`
under `post`.

This matters more here than it would in most renderers. Every material the game
creates is a `StandardMaterial`, and its fragment shader runs
`clamp(diffuseBase * diffuseColor + emissive + ambient, 0.0, 1.0)` before the
albedo multiply. The only unclamped path is `finalSpecular`, and every material
in the game zeroes specular. So the frame was hard-limited to `albedo * 1.0`:
no highlight, nothing above mid-grey, and nothing for a bloom pass to find.
D54 had already responded to that by authoring all six palettes to sum under
1.0, which is correct for that renderer and is why the world looked evenly lit
and flat. The grade is the lever that was missing.

## Two ordering traps, both load-bearing

Both cost nothing to avoid and are near-impossible to diagnose from a frame.

**`scene.blockMaterialDirtyMechanism`** was set at the top of the `Renderer`
constructor. It makes `_markAllSubMeshesAsDirty` return immediately. Attaching
the pipeline sets `imageProcessingConfiguration.applyByPostProcess`, which
every material forwards into exactly that call. Blocked, materials keep
compiling without `toLinearSpace` while the post-process still applies
`toGammaSpace`, and the whole frame comes out washed grey. It reads as an
exposure problem and is not one. It is now the LAST line of the constructor.

**`Material.freeze()`** sets `checkReadyOnlyOnce`, and five call sites freeze.
Same fix covers it: every material in the game is created after
`new Renderer()`, so with the pipeline already attached they all compile
correctly the first time.

`DefaultRenderingPipeline` is also constructed with `hdr: true`. With `false`
the intermediate target is 8-bit LINEAR, and the banding across shadowed ground
is worse than the problem being solved.

## Cost

`defaultRenderingPipeline` drags in `GlowLayer`, `DepthOfField`, `Sharpen`,
`Grain` and `ChromaticAberration` whether they are enabled or not. Roughly
70-100 KB raw on the vendor chunk, paid deliberately, and the unused effects
are pinned off explicitly so a future Babylon default cannot switch one on.

## What it does not permit

The grade is not a substitute for the work underneath it. The first pass ran
exposure 1.5, contrast 1.32 and globalSaturation 62, and the captured frames
came back neon: pure-green foliage, mustard ground, blown walls, crushed
shadows. The shipped values are roughly a third of that. The grade multiplies
whatever albedo sits under it, so the two cannot be tuned independently, and a
grade pushed hard enough to rescue bad colour will wreck good colour.

`.claude/skills/visual-judge/SKILL.md` is updated in the same change. Left
alone it would have told a blind judge to reject this work on sight.
