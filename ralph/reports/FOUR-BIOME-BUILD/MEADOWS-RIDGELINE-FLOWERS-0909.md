# Meadows Ridgeline Watch flower composition — 2026-09-09

## Source finding

The blind audit identifies repeated, similarly sized V-shaped blooms across the
Ridgeline Watch frame and asks for clustered cover with quiet ground. The active
production emitter is the enabled `GrassField` flower cover tier in
`data/config/grass_field.json`: it draws 6,000 instances of the established
generated flower mesh through `shaders/cover_tier.gdshader`. While the field is
enabled, `suppress_scatter_layers` suppresses `vegetation.json`'s baked `flowers`
layer. Editing similarly named Band 4 flower anchors would therefore miss the
consumer visible in the canonical frame.

Catalogue stand 08 is `(-250, 6490)`. Its route-forward vector points northeast
toward stand 09 at `(-40, 7010)`. The candidate places three unequal flower masses
on alternating sides of that sightline at `(-254,6517)`, `(-221,6513)` and
`(-252,6543)`, with radii 10, 13 and 15 m. A feathered 72 m local zone centred at
`(-250,6518)` returns exactly to the existing distribution at its boundary.

## Candidate

- Adds optional authored-composition uniforms to the shared cover shader. Their
  defaults are a no-op: zero-radius zone, full quiet keep and zero scale lift.
- Configures the option only on the flower tier. Bushes and forest litter retain
  the old shader distribution and material bindings.
- Inside the Ridgeline zone, the stable lattice and existing drift still decide
  the exact flower positions. The local mask keeps dense cores around the three
  authored masses and reduces isolated survivors between them to an 8% keep floor.
- Cluster cores lift the existing flower's scale by at most 38%, adding a second
  size beat without a new mesh, texture or material family.

The candidate changes no placement count, ring/culling plan, route, terrain,
creature spawn, landmark, actor position, light, weather, collision, harvest or
progression state. Its mask can only remove flower candidates locally and alter
the size of surviving flowers inside those local masses.

## Evidence status

JSON parsing and `git diff --check` pass. The focused `test_grass_field.gd` run
passes 19 tests / 87,822 assertions / 0 failed, including the default-off shader
contract, flowers-only config binding and absence of the authored key on every
other cover tier. Its raw logs contain no `ERROR:`, `SCRIPT ERROR`, parse error or
`FAILED`.

Matched production evidence is retained at
`shots/catalogue/meadows/round-ridgeline-flowers-20260909T124213Z/`. The canonical
Compatibility/OpenGL3 run captured day/night 2/2, with `manifest.complete=true`
and no failures. Both frames keep player `(-250, 6.044, 6490)`, camera
`(-251.905, 8.875, 6485.284)`, and 25 nearby creatures. Raw logs contain no
`ERROR:` or `SCRIPT ERROR`. PID 3752 ran from `2026-09-09T12:42:13.173Z` through
`12:43:40.969Z` (87.80 s); the guard peaked at 72.77% system commit and 255
processes, and none of the 600-second/90%-commit/400-process limits fired.

The day comparison visibly removes much of the evenly sprinkled pale generated
flower tier and reserves more quiet ground. Many green V-shaped plants remain in
the frame, however. Those may belong to an unsuppressed baked groundmat family,
so this lane does not claim that the blind audit's repeated-silhouette gap is
cleared. The frames are supplied for independent code-blind judgment, and this
report makes no claim about the Meadows biome globally.

## Source receipts

Final independent disposition: **A No / B No**, candidate held. The reused
image-only reviewer saw canonical day/night frames09–10 and found repeated
leafy stems and poor night separation of trainer, creatures and terrain.
See `VISUAL-WAVE-IMAGE-REVIEW-0909.md` for the full review and independence
disclosure. Attribution of the remaining green stems precedes any next edit;
the flower-tier change alone does not close the scene's visual gaps.

| File | SHA-256 |
|---|---|
| `shaders/cover_tier.gdshader` | `01AD6207A1FB7AB1840872B46665387E78AAB6AA9F9C515890A3EC2D3501899F` |
| `scripts/world/grass_field.gd` | `E40FAD316D43CA5F4C1D5064FBDC397CE9F859429CBF31AF8A18B2BFBF5D374F` |
| `data/config/grass_field.json` | `EEFE57CA37DE83EBFF518D75FAA3D2D03F33B2F3499C65CC53E2B89B45C96633` |
| `tests/test_grass_field.gd` | `535D89D532713A6052EC4B56AF12B8C9AAB6A667A40E06E5135ADCB60515A03A` |
| production day frame | `5A681698AE4F20BD51A001436A231454FF48A4CC3DA968928427626EF78A3BF3` |
| production night frame | `93BB9D16DF07300360EE501E3DA562AE6A3F83265CE45C5DCC183D0DEE3E0061` |
| production manifest | `C9071B6837467E4076E0D1541726B463D9B6C7843548C3CBE3651567DDCE2A79` |
| wrapper receipt | `716EC300851D26790337985CB876DB9EA542E81E908D361199A0BFCFFCAB1399` |
| memory watch | `65372975D8F8A4C09A33DF7CD16EDEDA4141897E60413893D6E0A6909609C4A2` |
