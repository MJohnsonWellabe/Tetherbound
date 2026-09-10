# Shared grass blade-local arc 01 — retained with grounding

## Mechanism and scope

Native frames repeatedly show the installed grass as narrow, upright spikes or
reeds. The authored tuft mesh has a vertical centerline. The prior shader adds
one quadratic lateral shear in an arbitrary world direction; it does not bend
the ribbon along its authored plane.

This candidate adds one shared `blade_arc_angle` uniform, set to 60 degrees.
Each blade deterministically uses 62.5–100% of that maximum (37.5–60 degrees)
and a stable sign. The shader reconstructs a circular centerline in the blade's
authored ribbon plane before lattice yaw, then applies the existing wind and
per-blade bend unchanged. Taper, normals, palette, density, counts, radii,
masks, clearances, collision, and gameplay are unchanged.

When `blade_arc_angle` is zero, the vertex path executes the former
`local.y = t * h * UV2.y` expression with the same operation order and does not
compute blade-side displacement. `tools/probe_grass_arc_off_control.gd` uses
that path while retaining every live material and shader object.

Because shared bilinear grounding was not a standalone visual winner,
`tools/probe_grass_original_geometry_control.gd` provides the primary matched
control. It extends the nearest-height control, preserves its ShaderMaterial
objects and raw Terrain3D texture-array RIDs, and also sets arc to zero. This
compares the combined candidate with the original nearest-height, straight
centerline presentation at the same camera and HUD. The arc-only OFF tool can
isolate curvature if the primary pair changes visibly.

## GPU validation

`tools/probe_grass_blade_arc_gpu.gd` uses balanced-brace extraction to compile
the exact production `hash12` and `grass_blade_arc` functions in a native
Compatibility `SubViewport`. Run `grass-arc-gpu-first` completed cleanly from
08:33:39 to 08:33:47 with exit code 0 and no failures. Both four-tile passes
were solid green: angle zero verified the helper's mathematical zero/root
contract, and the 60-degree pass verified a fixed root, shortened curved
height, nonzero lateral travel, and opposite deterministic signs. The shader
source SHA-256 recorded by the run was
`a9eb481579a8d3b084c85d1df23eb001e0985c4a63b962410431847c8cbedd3e`.

This proves the actual helper compiles and executes on the target renderer. It
does not prove the ordinary-view silhouette is better.

## Visual decision — combined candidate retained

The grounding-only capture set completed cleanly with 14 candidate and 14 OFF
frames across Meadows, Stormwood, and Water. Blind results were mixed: South
Bridge preferred old nearest placement, Stormwood Glass preferred new
placement, and Water Root Walk preferred old nearest placement. Grounding is
therefore not accepted on its own; exposed taller straight spikes were a noted
risk.

The combined height-plus-arc candidate and combined-original control each
captured 14 clean native frames across Meadows, Stormwood, and Water. All three
fresh blind comparisons preferred the candidate: South Bridge F03/F04,
Stormwood Glass F01/F02, and Water Root Walk F03/F04. See
`JUDGE-GRASS-ARC-SOUTHBRIDGE01.md`, `JUDGE-GRASS-ARC-GLASS01.md`, and
`JUDGE-GRASS-ARC-ROOTWALK01.md`. The judgments consistently identify the bent,
crossing, or fanned blade silhouette as more natural than the prior upright
spikes. The combined change is retained. This does not convert the earlier
mixed grounding-only result into a standalone win.

`grass-combined-performance-first` ran cleanly from 08:43:51 to 08:46:17.
The four passes reported median/p95 frame times of A1 35.630/116.388 ms, B1
35.581/316.112 ms, B2 35.214/222.882 ms, and A2 35.155/321.731 ms. Medians do
not show a typical-frame regression. Both conditions had heavy, inconsistent
p95 hitches, so this receipt does not establish tail performance or isolate GPU
cost. It is a desktop Compatibility run, not an Ally measurement.

The result remains below the supplied commercial reference bar. Judges still
flagged thin geometry, terrain competition, weak creature presentation, and
scene composition. Temporal motion and handheld performance remain unproven.
