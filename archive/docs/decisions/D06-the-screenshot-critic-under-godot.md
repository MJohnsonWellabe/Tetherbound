# D06. The blind screenshot critic, rebuilt for Godot

Kind: implementation

The Babylon prototype's most valuable tool was a survey of fixed camera
viewpoints, assembled into one contact sheet, handed to a sub-agent that saw
only the frames and the reference images — never the code, never the
conversation, never what had just changed. It produced the three findings that
ended that stack, none of which were visible in a diff or a green test suite.

That harness drove a browser with Playwright and does not survive the engine
change. This is the replacement.

## It works, and it earned its place on the first run

`--headless` disables rendering, so the survey runs under Xvfb with a real
display. The very first frame ever captured of the M1 playground showed the
ground rendering as a **grey checkerboard**: Terrain3D's "no textures assigned"
placeholder. The baked slope-driven colour map was not being displayed at all.

Every check before that had passed. The unit tests read the heightfield, the
smoke check read region counts, heights and collision. All of them were correct
and all of them were blind to the fact that the ground was a checkerboard,
because none of them looked at a pixel. That is the entire argument for this
tool, demonstrated on its first use.

The fix was `Terrain3DMaterial.show_colormap`. The second finding, one frame
later, was that the rocky rises rendered white and read as snow-capped peaks in
a meadow — the palette's masonry grey is correct for a cliff in shade and far
too light for a sunlit slope after tonemapping.

## The renderer caveat, which used to be real and now mostly is not

Originally: the project shipped **Forward+**, these frames were captured on
**Compatibility**, and that gap — no SSAO, no volumetric fog, no SDFGI,
different shadows — was a real, standing limitation of what a survey frame
could be trusted to judge.

**As of `docs/decisions/D01`'s 2026-08-11 reversal (RB4), the project ships
Compatibility too.** The Ally freeze root-caused to a Forward+/Vulkan
render-thread stall, and switching the shipped game's own renderer to
Compatibility fixed it. This survey harness now matches the shipped game's
actual renderer rather than diverging from it — a strictly better position:
composition, terrain shape, silhouette, colour relationships, camera framing
AND lighting/shadow behaviour are all now judged on the same pipeline that
ships.

Kept for the record, since it explains why Compatibility was chosen for the
survey specifically (not just inherited from the later renderer switch):
software Vulkan (lavapipe, via `mesa-vulkan-drivers`) was installed and does
render Forward+ — verified, `Vulkan 1.4.318 - Forward+ - llvmpipe` — but
**Terrain3D segfaults under lavapipe** during region streaming, consistently,
before any frame is captured. Compatibility renders the same scene without
complaint, which is one more reason it was the safer choice even before RB4
made it the shipped choice too.

## One rule from the old rubric that is deliberately dropped

The previous rubric told the critic the performance budget — draw calls,
triangles, "no post-processing" — and the critic dutifully policed it from
screenshots. It then rejected work on grounds it could not actually see, and
the budget it was enforcing had already been superseded and never updated.

**A critic looking at pictures judges pictures.** Performance is measured with a
profiler on the target device. The rubric in
`.claude/skills/visual-judge/SKILL.md` carries this explicitly.

## When it runs

Built now, not run as a critique yet. The player is a grey capsule and the
ground is flat colour by slope; `CLAUDE.md` is explicit that biome look,
creature appeal and combat readability must not be judged on placeholders, and
a critic pointed at this build would return a long list of things already
scheduled.

The first real pass is M7 for the biome and M11 for creatures. Until then the
survey is still worth running after any rendering change, for exactly the reason
above: it is the only check that looks at a pixel.
