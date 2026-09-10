# Shared grass grounding 01 — retained as part of combined grass correction

## Cause and scope

The shared grass shader previously rounded every arbitrary tuft XZ position to
one Terrain3D height texel. The error is real across all three field-enabled
biomes:

- Meadows: 461 eligible local points, 2m terrain spacing, median absolute error
  0.081m, p90 0.3355m, p99 2.4085m; 56 buried and 41 raised by more than 0.2m.
- Stormwood Glass: 507 eligible points, 2m spacing, median 0.07697m, p90
  0.1714m; 22 points beyond 0.2m.
- Water Welcome: 381 eligible points, 1m spacing, median 0.04856m, p90
  0.18824m; 32 points beyond 0.2m.
- Water Horizon: 488 eligible points, median 0.08141m, p90 0.11959m; 5 points
  beyond 0.2m.

Receipts are in `shots/diagnostics/grass-grounding-meadows-second/`,
`grass-grounding-stormwood-first/`, and `grass-grounding-water-first/`. The
first diagnostic attempt had a `Variant pop_back` parse failure; the corrected
tool used an explicitly typed `Node` and rounded seam coordinates.

Only `shaders/grass_field.gdshader` changes production behavior. It reconstructs
height bilinearly at the tuft position. When all four footprint texels belong
to one Terrain3D array layer, an explicitly linear sampler performs one
texel-centred `textureLod` at LOD 0. Across a region seam, four explicit texel
fetches mix heights from their separate layers. Corner lookups use search mode
0 so a missing region cannot be silently substituted; missing neighbours fall
back to the previous nearest coordinate, which retains Terrain3D's search mode
1 behavior.

Packed control and terrain colour retain their existing nearest fetches. The
candidate does not change holes, material masks, clearances, density, geometry,
normals, palette, seed, camera following, scatter, collision, or gameplay.

## GPU validation

`tools/probe_grass_height_sampler_gpu.gd` extracts the exact production
`get_index_coord` and `grass_surface_height` function bodies with a balanced
brace parser. It renders them through a 128x16 native Compatibility
`SubViewport` using five 4x4 RF texture-array layers with known polynomial
heights and a real region map.

Run `grass-height-gpu-first` completed cleanly from 08:18:25 to 08:18:34 with
exit code 0 and no errors. All eight binary GPU comparisons passed within
0.0002: interior, X seam, Z seam, four-region corner, negative-X seam, negative
interior, exact texel, and missing-neighbour nearest fallback. Every sampled
tile read `[0,1,0]`. The full actual/expected receipt is in
`.artifacts/broad-visual-0910/runs/grass-height-gpu-first/console.log`.

The focused shared grass unit run `grass-height-unit-first` completed cleanly
from 08:18:57 to 08:19:05 with 22 tests and 87,832 assertions.

`tools/probe_grass_nearest_height_control.gd` is the matched OFF capture
wrapper. It now fails explicitly when the mounted world has zero target
materials. For each live target it keeps the same ShaderMaterial object, swaps
only the Shader to restore the prior nearest height fetch, and restores all
ordinary uniforms plus raw Terrain3D `_height_maps`, `_control_maps`, and
`_color_maps` RIDs. It restores the original shaders and bindings at finish.

## Remaining evidence

Native matched capture completed cleanly across all three worlds: 14 candidate
frames and 14 nearest-height OFF frames, with no engine errors. The three blind
location verdicts were mixed: South Bridge modestly preferred the old nearest
placement, Stormwood Glass preferred the interpolated placement, and Water
Root Walk modestly preferred the old nearest placement. See
`JUDGE-GRASS-HEIGHT-SOUTHBRIDGE01.md`, `JUDGE-GRASS-HEIGHT-GLASS01.md`, and
`JUDGE-GRASS-HEIGHT-ROOTWALK01.md`. This does not establish visual acceptance;
the newly exposed full-height straight blades may increase foreground
competition even where grounding is more accurate.

The baseline measurement tool always evaluates
the previous nearest lookup against `Terrain3DData`; rerunning it does not
measure this candidate's GPU residual and must not be cited as candidate
improvement. Matched candidate/OFF gameplay frames must show fewer visibly
buried or floating tufts across Meadows, Stormwood, and Water, including steep
slopes and region seams, without new surface discontinuities during movement.

Bilinear reconstruction is an approximation of the terrain surface. It can
differ from Terrain3D's exact triangle split inside a texel, especially on sharp
features. The same-region path costs one filtered vertex fetch; seam vertices
cost four. Target-hardware GPU timing remains required. The clean synthetic GPU
probe establishes lookup correctness and renderer support, not visual benefit,
live-terrain residual, temporal stability, or handheld performance.

The later combined grounding-plus-blade-arc comparison completed with 14 clean
candidate and 14 clean original-control frames across the same three realms.
Fresh blind judgments preferred the combined candidate at South Bridge,
Stormwood Glass, and Water Root Walk. Grounding is retained as part of that
combined correction; the evidence does not claim it won independently.
