# Grandpa's House / Yard visual pass — 2026-09-11

## Disposition

Implementation, focused structural validation, and production day/night evidence are complete. Final disposition: **PASS** on the named-location bar.

## Fresh-frame finding

The authoritative `shots/locations/01-village-grandpa-yard-{day,night}.png` pair already gave the farmhouse a strong, distinct two-storey silhouette and a readable warm east door. The immediate yard did not support that quality: one purple-flowered clump filled the lower-left foreground and became the strongest colour/mass in both frames, while the only readable domestic prop was a lone crate at the doorstep. The fenced garden was present farther back, but the south-east walk-up had no lived-in hierarchy connecting house, yard, and farm.

## Bounded change

- Added `grandpa_southeast_work_yard`, a four-piece installed-family harvest/wash nook on the south apron: a modest trestle work table, partly filled apple crate, wooden bucket, and stool.
- Added a 3.15m vegetation footprint centred at `(-16.7, -21.2)` to prevent dynamic grass/cover from growing through the new furniture, while remaining a small worked-yard apron rather than a broad clearing.
- Production r1/r2 isolated the dominant clump to the persistent early-game berry harvest node, order 1036 at `[-9,-19]`: `Bush_Common_Flowers.gltf` at route-wide scale 1.2. R2's deliberately small field footprint did not touch it and was reverted after its bare patch proved the hypothesis wrong. The final change preserves that node's position, prompt, item and three-berry yield, reducing only this close village node's visual scale to 0.48 (about 0.9m across instead of 2.3m).
- The prop cluster stays south of `z=-20.4`, at least 4m from the east door `(-15.7,-16)`. The footprint's north edge stops at `z=-18.05`, leaving more than 1.8m between the disc and the door.
- The interactive farm remains untouched at `z=-9/-6.6`; the house recipe/collision, opening and starter markers, NPCs/prompts, paths, and progression are unchanged.
- Like every band vegetation edit, the new footprint changes the scatter fingerprint. Production capture can safely take the live-compute fallback; the coordinator-owned integrated scatter re-bake still has to absorb this footprint before the final packaged build.

## Validation

- `tests/test_grandpa_yard_visual_identity.gd` checks the exact four-prop story, installed asset resolution, door-lane clearance, tightly bounded footprint, separation from every farm plot, and the dedicated evidence harness's clock/overlay/surface contracts.
- `tools/capture_grandpa_yard_identity.gd` is a dedicated two-frame production harness because the shared location sweep is explicitly out of scope for edits. It applies each authored clock before freezing it, hides both `PlaygroundHUD` and the independent `Water/SubmersionOverlay`, and seats the player/camera against the live collision surface so the ordinary trainer is never parked underground.
- JSON parse checks pass for both edited band configs.
- Focused Godot test result: **5 tests / 42 assertions / 0 failed**.

## Production evidence

Production capture from the dedicated Grandpa harness:

- `ralph/reports/FOUR-BIOME-CONTINUATION-0910/GRANDPA-YARD-IDENTITY/01-grandpa-yard-day.png`
- `ralph/reports/FOUR-BIOME-CONTINUATION-0910/GRANDPA-YARD-IDENTITY/02-grandpa-yard-night.png`

Production r1 and r2 were both **REJECTED for PASS**: the domestic nook read clearly, and the corrected harness proved distinct day/night clocks with no overlay or underground-player defect, but the purple harvest node remained the strongest foreground mass. R2 was still useful diagnosis: its field-only exclusion changed the grass and not the bush, leading directly to the authoritative harvest record above.

R3 passes. The farmhouse and warm door own the composition in both clocks; the retained berry node is a modest ankle/knee-high gatherable rather than a 2.3m foreground wall; and the table/crate/bucket/stool read as one worked domestic task on the right. The farm, fence, and walk-up remain legible. Honest residuals, below the blocking threshold: the harvest node's existing pink interaction sparkle remains conspicuous (especially at night), two low purple cover blooms remain behind it, and the 3.15m work apron reads visibly worn/bare—but it is bounded and occupied rather than an empty bald zone.
