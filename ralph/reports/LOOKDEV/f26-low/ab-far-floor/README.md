# F26 Low: all-realm camera far-floor A/B

Before is the census/route-still frames at `4d75308a`/`445098af` (Low, Compatibility, llvmpipe),
where draw distance clamps every realm camera far to 320 m. After is the same harnesses and stands at `d80a07b5`
(commits 1c71f089 Tidewake, 94929005 Meadows, f51ccb56 Stormwood, d80a07b5 test;
the Cloudreach floor came from main #529 via merge b54b67e8).

Thirty-two matched pairs were shown to a fresh code-blind judge as X/Y with randomised sides
(`blind-key.json` records `after_is`). Decoded result:

- After better: 18. Before better: 0. Same: 14.
- Every flat grey or white world/sky band the judge listed is on the before side (pairs 00, 02, 04, 05,
  10, 11, 12, 13, 15), except pair 17 (`water__veilfall__16`, camera inside rock at the 620 m crown),
  which shows a band on both sides. That pair is still open.
- Missing distant landmarks (cloud sea and islands, Windscar cliffs, Meadows ranges, Veilfall and
  islands) are all on the before side.
- One-side-only differences in creatures, labels or food are live game state, not rendering.

The four sample pair images here are 960 px per side. Full pair set and frames are kept in the lane container only.
No frame time was recorded.

Excluded: the after-fix Stormwood route stills (`stills-stormwood`, run at d80a07b5) logged
`Missing or stale stormwood scatter bake`, because the first Stormwood floor key sat in
`stormwood_world.json`, which is a bake fingerprint input. Those frames are invalid and are not in the pair set.
The coordinator moved the key to `data/config/stormwood_camera.json` (d825d181, merged at 0ccd9f95).
