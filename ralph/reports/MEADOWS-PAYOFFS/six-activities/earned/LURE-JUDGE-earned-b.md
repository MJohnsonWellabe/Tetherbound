# F03#0 lure judge, set B (code-blind; herd, doss, vault, juno, hall)

**Judge input:**
- the 20 frames in `lure-judge-b/`. Each filename caption gives only the distance and whether the player was on the road, both from the run log.
- the F03 lure criterion and the ruling "visible from road, then readable on approach". For the vault, the "road" is the required Warrens route.

No code, data, config or other reports were opened.

**Frame sources:**
- herd, doss, vault and juno: the earned `seed4_hall` walks. They start at the Hall and walk the chapter in reverse.
- hall: render.yml 36311702392 at cd7dc238, after the alpha pack moved to (-30,7295).

| activity | visible from road | readable on approach | overall |
|---|---|---|---|
| herd | FAIL: no herd readable in the 156 m on-road frame | PASS, marginal: one or two deer, only at about 30 m | **FAIL** |
| doss | FAIL: the canopy hides the smoke at 93 m on the road and at 86 m off it | PASS, marginal | **FAIL** |
| vault | FAIL, marginal: the den doorway shows, but nothing beyond it reads as a light (the guardian is already beaten in this save, so the door and its lit seam are gone) | PASS | **FAIL** (marginal) |
| juno | PASS, marginal: dark smoke at 130 m; the TEAM panel hides its lower half | PASS | PASS (marginal) |
| hall | PASS, marginal: the "Alpha Galec…" nameplate over trees at 86 m, on the road | PASS, marginal | PASS (marginal) |

**Result: 2 of 5.**

## Follow-up (this lane)

The reverse-direction earned walks do not show a first-discovery approach, and the vault's designed lure only exists before the guardian falls. So herd, doss, vault and bram are re-captured at 23ff7817 from disclosed Gate F starts that walk the natural direction (fixture starts are allowed with disclosure, owner ruling on #356 at 07:03):

| activity | start save | why |
|---|---|---|
| herd | `S04-exit-pose-on-road` | village exit, walking north |
| vault | `S04-exit` | Warrens not cleared, so the guardian and the lit vault door are live |
| doss | `S06-exit-band3` | band 3 entered from the south, along the river-loop road with the probe's clear sightlines |
| bram | `S04-exit-pose-on-road` | also recaptured from the natural direction, beside earned run 36311700800 |
