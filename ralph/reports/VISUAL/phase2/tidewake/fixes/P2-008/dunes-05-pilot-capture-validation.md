# Dunes-05 three-view pilot validation

Source `75042158127633e778649d6a4d91571d838db9d1` includes the dune surface/cover
candidate `e22fdbcb2`. Two native Windows Compatibility OpenGL3 boots produced
three actual 1920x1080 images on NVIDIA GeForce GTX 1060 3GB: Gull Rest beach,
Sluice Isle twin pumps, and First Shore horizon stones. Both manifests report
complete=true and failures=[]; process session 60065 exited 0. The native
processes were absent and the render lock was empty before explicit handoff to
Stormwood. Both production dune gates remain false.

This is a limited diagnostic pilot, not all eight P2-008 sightings or a chapter
matrix. [Independent visual review](dunes-05-pilot-visual-judge.md) is **FAIL**, with
limited Bars A/B **No/No**: the broad gray banks accentuate the unchanged steep
forms, and Sluice's right toe loses its vegetation transition. No enablement or
item closure follows from a successful capture.

## Reproduction and isolation

The process-local resource pack contains exactly two config files,
`data/config/water_dune_terrain.json` and `data/config/water_dune_cover.json`.
Their only difference from committed config is enabled=true. Python rechecked
the complete parsed contents against the disabled source after capture.
Production source/config files were not modified while the full unit suite ran.

The retained pack SHA-256 is
`f28a8ac9e5001c9dd4f435832ebfae777280a94145a759d003c66b6f5b436c12`.
[Reproduction files](dunes-05-pilot-repro/sha256.json) retain the exact pack,
launcher and wrapper text, viewport probe, and stdout/stderr for both boots.
Restore the wrapper/launcher filenames from their `.txt` copies into
`.artifacts/phase2/`, restore the ZIP there, and run the launcher with a fresh
`-Round` value. It uses isolated APPDATA `.local/appdata`, seed 2042,
`--rendering-driver opengl3 --resolution 1920x1080 --fullscreen`, and the
production capture tools. Each raw and compact manifest records the loaded
configs, source commit, ZIP hash and wrapper hash.

The first pilot attempt produced zero frames: the temporary wrapper overrode
`_init()` without invoking its base constructor, leaving an empty render loop.
A minimal headless inheritance probe reproduced this. Explicit `super()` after
the ZIP mount corrected startup; the actual wrapper then reached the capture
tool's intentional headless-display refusal in preflight. The empty attempt
was stopped and released before Meadows' queued capture; this successful retry
used new output/log paths after Meadows' explicit release. It was not a
successful capture or evidence of an engine/world stall.

## Pair validity and visible limits

The three matching dunes-04 after frames are the comparison baseline. Every
player position, selected stand offset and lateral offset matches exactly.
Maximum camera-position difference is 0.000318613 m (Sluice); Gull is
0.000088678 m, and First Shore is exact. Per-frame hashes and measurements are
in [dunes-05-pilot-comparison.json](dunes-05-pilot-comparison.json).

Both compact rounds verify: two location tiles and one route tile, each derived
from an inspected native 1920x1080 image. Original raw files remain local under
`.artifacts/phase2/p2008-dunes-05-pilot-retry-after-{locations,routes}/`.
Do not stage those raw images. Script/parse/compile errors were absent; the
existing deprecated physics-interpolation warning remains in the retained logs.

Root inspection finds that exposed rock now replaces the smooth pale Sluice
bank, but large angular sand edges persist at Gull's cap and foot and on distant
First Shore island skirts. Grass is more sparse in some formerly continuous
areas, yet the First Shore contour ribbon and weak distant ecological layering
remain visible. These observations leave the candidate disabled and justify an
isolated material-mask diagnostic before another material change. Dynamic wild
creature positions can differ; the fixtures do not prove traversal, performance,
earned progression or full-region visual acceptance.
