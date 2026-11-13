# THINGS-EMBERS: the thin line above Ashtusk's back (F36#33 close-out; four aspect species)

**Row.** F36#33 Ashtusk: High 8.03, Medium 7.28 (`G-medium-ashtusk-brooktail-ruler.md`, e44e6ee8). 3/3: "a thin vertical line floats above the back in the standing and hit frames". The same specks sit above Riftfrill and Stormtrail.

**Cause (a game fault, not the stage).** `aspect_vfx.gd` draws the aspect creatures' embers, sparks and motes as small discs in the effect node's own space, but took the billboard axes from the camera in world space. A creature standing side-on to the lens gets every disc edge-on: a thin line. In play this happens at any heading that is not facing the camera.

**Change** (flag `vfx.json aspect_billboard_local_1112`, OFF): the axes are brought into the node's space, so the motes face the lens from any heading. Applies to Ashtusk, Stormtrail, Nightburrow and Riftfrill. Client presentation only.

**CPU** (`_sheet_motes_off_vs_on_cpu.jpg`; top main, bottom arm; Ashtusk, Riftfrill, Stormtrail, hit 000): the lines are gone; each creature has a few small soft motes in its element colour (amber embers on Ashtusk). No script errors.

**Risk.** The motes are now visible as intended; the owner's rule allows a small elemental effect but "no big floating effects". They are small (0.15 of body radius). If judges read them as clutter, the alternative is turning the primary motes off for the pose rows' species.

**Not in this arm.** Ashtusk's tusks through the floor in the hit frame, and the dark plates merging; Brooktail's spots and head.

**Ask.** `capture_f36_poses.gd --whole-body --context --roles=hit,faint` for ashtusk, riftfrill, stormtrail, nightburrow; base vs arm; High, then Medium for Ashtusk.
