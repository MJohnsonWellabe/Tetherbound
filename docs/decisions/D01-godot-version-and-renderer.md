# D01. Godot 4.7-stable, Compatibility renderer, GDScript

Kind: implementation

`docs/specs/GAME_DESIGN.md` §4 locks Godot and says "4.x". This pins the specifics so
a version drift is a deliberate act rather than whatever the owner installed
last.

**4.7-stable.** Verified as the current stable at project start: 4.8 and 4.9
release URLs return 9-byte not-found bodies, 4.7 returns a 75 MB binary. The
editor reports `4.7.stable.official.5b4e0cb0f`.

**Compatibility (`gl_compatibility`), reversed from Forward+ — 2026-08-11,
RB4.** This entry originally chose Forward+, betting that the Ally's RDNA3
iGPU (Radeon 780M) would "run Forward+ comfortably." That bet is wrong: the
owner reproduced a hard freeze on the shipped Windows build, twice, and the
on-device data rules out a slow-compile explanation. The boot log
(`user://boot_log.txt`) shows both runs completing every instrumented
phase — terrain, shaders, player, ~16,700-instance vegetation scatter,
settlement — in ~6 seconds, then stopping at the identical last line,
`_ready complete, waiting for first frame`, and never writing the next one.
Task Manager during the hang shows the process `Not Responding` at **0% CPU,
0% disk, 0% network**, memory flat, never resolving after 10+ minutes — not
a device grinding through shader compilation (which would show load), but
the render thread blocked on a call that never returns. That is consistent
with a Forward+/Vulkan present-or-pipeline-compile deadlock specific to this
GPU/driver combination, and inconsistent with everything else in the boot
path, which completes cleanly and quickly every time.

Switching to Compatibility sidesteps Vulkan entirely — GLES3 instead — which
is also the exact renderer every headless CI render and every
`.claude/skills/visual-judge` critique this project has already been judged
against uses (`tools/survey.sh`, D06: "Terrain3D segfaults under software
Vulkan, so the survey runs on OpenGL"). What's actually shipping now matches
what has been screenshotted and graded all along, rather than diverging
from it. **Cost, paid knowingly**: real directional shadows, SDFGI and
volumetric fog are Forward+-only — Compatibility's shadow model is simpler.
Given the alternative is the game not launching at all on the primary
target device, this is not a close call. If Forward+ is worth revisiting
later (a driver update, different hardware), that is a new decision with
its own on-device evidence, not a default to drift back to.

Mobile was never chosen either: Compatibility is not Mobile, and the
original reasoning for ruling out a phone-first renderer class
(`GAME_DESIGN.md` §4: "Phone is not a first-version requirement") still
holds — Compatibility here is chosen for Vulkan-avoidance on Windows, not
for a mobile target.

**GDScript**, per `docs/TECHNICAL_ARCHITECTURE.md`. C# would add a build step, a .NET
dependency on the export machine, and slower iteration, in exchange for typing
this project gets more cheaply from tests.

**Authoring at 1920x1080** with `canvas_items` stretch. That is the Ally's
native panel, so HUD text is designed at real handheld pixel density instead of
being scaled down into it later.

## Cost

Pinning a version means export templates must match exactly. A mismatch fails
the export with a message that does not obviously say "version mismatch". If
the owner's editor and this pin disagree, the export is the thing that breaks.
