# Water deep opacity 01 — retained visual candidate, bounded validation complete

The clean nine-frame diagnostic ran 07:26:18–07:27:56. At the same Gull Rest
open-water camera and daytime clock, setting only `alpha_deep` to 1 removed the
angular underwater colour boundary. Subdividing the two-triangle plane to
63-by-63, disabling fog, and replacing sampled ground height with constant deep
water each retained it. This isolates the visible submerged render contribution:
the boundary is not supported as a plane interpolation, Compatibility fog, or
water depth-colour defect by these controls.

The candidate changes only `data/config/water_visual.json`, from the actual
mounted Water override `alpha_deep = 0.9` to `1.0`. `alpha_shallow` remains
`0.45`; depth, foam, colour, waves, terrain, collision, hazards, swimming, and
water geometry are unchanged. The canonical Water bake must still refresh its
visual-config provenance after acceptance; unchanged terrain binaries are
expected, but must be checked rather than manually restamping the manifest.

`tests/test_water_surface_material.gd` verifies the real WaterSurface factory
binds opaque deep water and retains the authored translucent shallow alpha.
`tools/probe_water_deep_opacity_off.gd` is the matched five-view control: after
the production world mounts, it duplicates only the WaterSurface material and
restores deep alpha to `0.9`, verifies shallow alpha and all four texture
identities are unchanged, then restores the exact production material at exit.

Focused test selector:

```text
--only=test_water_surface_material
```

Native control capture uses the normal Gull Rest wrapper arguments with:

```text
--script res://tools/probe_water_deep_opacity_off.gd -- --output=res://shots/catalogue/water/broad-deep-opacity01-off
```

The four focused factory tests passed cleanly with 27 assertions at
07:35:06–07:35:12 UTC. `water-deep-opacity-candidate-first` completed five native
views cleanly at 07:35:19–07:36:40; `water-deep-opacity-control-first` completed
the same five views cleanly at 07:36:54–07:38:12. The control receipt confirms
deep 1.0/0.9, shallow 0.45 in both, and preserved mesh and texture identities.
The fresh `JUDGE-WATER-DEEP-OPACITY01.md` review prefers the new day/night
pair: the conspicuous angular boundary is absent. Other major qualities are
effectively tied. A key-art alignment remains no; B genre intent is narrowly
yes; commercial-quality acceptance remains no. The candidate remains retained;
the completed bake and opening receipts below supersede the earlier pending note.

The candidate's canonical provenance bake completed cleanly from
08:06:21.452–08:07:34.930 UTC (`water-deep-opacity-provenance-first`, exit 0;
`result.json`, `console.log`, and `engine.log`). It refreshed the Water manifest
only: all 31 existing terrain binary files were byte-identical to their prior
hashes. No terrain geometry was regenerated as part of the visual-config
provenance refresh.

The physical opening regression then completed cleanly from
08:10:04.120–08:11:20.782 UTC (`water-deep-opacity-opening-first`, exit 0;
`result.json`, `console.log`, and `engine.log`). The production path recorded
`swimming=64.487m`, with no post-arrival fixture writes. Its receipt explicitly
says `not earned Stormwood transition`: this is an isolated Water opening and
physical swim, not earned cross-biome progression evidence.

The candidate therefore has clean canonical bake provenance and a clean bounded
Water opening. The earlier diagnostic and native captures still do not establish
underwater camera appearance, continuous swim transitions, temporal stability,
performance, or commercial-quality acceptance.
