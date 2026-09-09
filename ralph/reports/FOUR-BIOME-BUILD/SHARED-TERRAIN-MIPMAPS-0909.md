# Shared terrain texture mipmaps — 2026-09-09

## Root cause and scope

The four production biomes reuse six terrain albedo/normal pairs under
`assets/environment/terrain/stylised/`. All twelve tracked import sidecars set
`mipmaps/generate=false`, while Terrain3D samples them with mipmapped anisotropic
filters. Production Meadows and Stormwood captures consequently emitted twelve
`Texture ... has no mipmaps` warnings and showed granular/stippled minified ground.

This candidate changes only those twelve sidecars to `mipmaps/generate=true`.
There is no runtime decoder, shader, config, source-image or creature change.
Meadows' near-field macro/grain treatment and Stormwood's realm-local terrain tints
are distinct mechanisms and are outside this correction.

## Four-biome consumers

- Meadows and Stormwood load all six pairs from `terrain_playground.json`.
- Cloudreach loads grass, verge, rock and path pairs from
  `cloudreach_visual.json`; its trail shader also loads shared grass/path albedo.
- Water loads shared grass, path and rock pairs from `water_visual.json`.

## Initialized-resource proof

`tools/probe_terrain_texture_mipmaps.gd` loads the exact twelve production
`Texture2D` resources and checks the sidecar policy and active image mip chain.
After import it exited 0: 12/12 `CompressedTexture2D`, 12/12 at 1024x1024,
12/12 with 10 mip levels, zero failures. Import and probe logs contain no
`ERROR:` or `SCRIPT ERROR:`.

## Representative evidence

Matched production catalogue pairs:

- Meadows baseline `round-ridgeline-night-shadow-20260909T1500Z`; candidate
  `round-terrain-mipmaps-20260909Tfinal`. Player/camera/weather/time match.
- Stormwood baseline `round-shadow-contract-20260909T1418Z`; candidate
  `round-terrain-mipmaps-20260909Tfinal`. Player/camera/Calm phase match.

Both candidate captures completed 2/2 with exit 0 and no Terrain3D missing-mipmap
warnings. The preliminary reviews named TERRAIN-MIPMAPS are retained, but their
input directory disclosed the treatment name. They are superseded for acceptance
by fresh instances reviewing neutral `set-A` through `set-D` folders: see
`VISUAL-SET-A-0909.md` through `VISUAL-SET-D-0909.md` and
`SHARED-TERRAIN-REVIEW-DISPOSITION-0909.md` for the mapping and limits.

The remaining checks use the newest baselines made from the current held scene
sources, avoiding unrelated geometry credit: Windscar Beacon day/night against
`round-windscar-open-beacon-proof2-20260909T1620Z` (source subsequently preserved
by `308881d9d`), and Gull Rest Signal Spire day/night against `20260909T173239Z`
(source subsequently preserved by `a8ec5de76`). No later committed or local delta
touches either production world/visual source before the mipmap candidate.

Both remaining production pairs completed 2/2 with exit 0 and no missing-mipmap,
`ERROR:` or `SCRIPT ERROR:` line. Candidates are
`round-terrain-mipmaps-windscar-20260909Tfinal` and
`round-terrain-mipmaps-gull-rest-20260909Tfinal`. Gull Rest's player transform is
identical and its camera differs by at most 0.00002 m of settle drift. Windscar's
player/camera differ by less than 0.0006 m after the same production surface settle;
the frame id, route-derived heading, scene source and time pins match. These are the
only disclosed transform differences for independent image review.
