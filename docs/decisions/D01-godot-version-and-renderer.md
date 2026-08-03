# D01. Godot 4.7-stable, Forward+, GDScript

Kind: implementation

`docs/GAME_DESIGN.md` §4 locks Godot and says "4.x". This pins the specifics so
a version drift is a deliberate act rather than whatever the owner installed
last.

**4.7-stable.** Verified as the current stable at project start: 4.8 and 4.9
release URLs return 9-byte not-found bodies, 4.7 returns a 75 MB binary. The
editor reports `4.7.stable.official.5b4e0cb0f`.

**Forward+**, not Mobile or Compatibility. The Ally is an RDNA2 part and runs
Forward+ comfortably, and the previous prototype's single loudest defect was an
absence of real shadows. Forward+ is the renderer with proper directional
shadows, SDFGI and volumetric fog available if wanted. Mobile would trade that
away for a device class this project explicitly does not target
(`GAME_DESIGN.md` §4: "Phone is not a first-version requirement").

**GDScript**, per `docs/TECHNICAL_START.md`. C# would add a build step, a .NET
dependency on the export machine, and slower iteration, in exchange for typing
this project gets more cheaply from tests.

**Authoring at 1920x1080** with `canvas_items` stretch. That is the Ally's
native panel, so HUD text is designed at real handheld pixel density instead of
being scaled down into it later.

## Cost

Pinning a version means export templates must match exactly. A mismatch fails
the export with a message that does not obviously say "version mismatch". If
the owner's editor and this pin disagree, the export is the thing that breaks.
