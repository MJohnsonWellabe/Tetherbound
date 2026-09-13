# The Highfield hero identity R7 — independent visual judgment

## Verdict: POLISH — improved evidence, not a strict named-location PASS

R7 fixes R6's invalid-looking foliage composition and retains a readable high-summer
pasture, but it does not clear the remaining hierarchy blocker. The drove gate and
stock camp are still low, pale mid-ground details close in value and silhouette to
the surrounding fence rhythm. The large warm tree remains the decisive vertical
landmark, while the recorded nearby bull is not visually distinguishable from the
ordinary herd. Highfield has a coherent identity and is not a FAIL; it still lacks
the immediate herd–hero–gate–camp hierarchy required for strict PASS.

## Evidence integrity — PASS

- `manifest.json` reports `complete: true`, six frame records, and no failures.
  All six listed native 1280x720 PNGs are present as three day/night pairs.
- The disclosure identifies the production Meadows scene, ordinary player,
  Terrain3D, scatter, props, and encounters. Only HUD visibility, clear weather,
  time, and a disclosed 70-degree third-person camera are controlled; it states
  that progress and encounters were not injected.
- Every receipt records zero player displacement, ordinary camera distance near
  6 m, and grounded player clearance. The receipt has no source SHA or per-source
  hashes, so it proves the production scene and capture conditions but not a commit
  identity by itself.
- Native inspection finds no frame inside terrain, props, trunks, or foliage. The
  day/night pairs are materially distinct and preserve the same compositions.

## Strict findings

| Criterion | Verdict | Native-frame evidence |
| --- | ---: | --- |
| Pasture and herd ecology | **PASS** | Rolling flowered grass, woodland edge, road, fencing, and distributed pale herd bodies make all three pairs read as an inhabited summer pasture rather than an empty clearing. |
| Unobstructed composition | **PASS** | Unlike R6 `03/04`, the east pair now has a clean player-to-camp axis. No close trunk or leaf mass hides the camp or right-hand herd. The compressed pair is also clean. |
| Drove gate and stock-camp function | **POLISH** | Wagon/stock structure, small shelter, fire, and fence/gate are visible in `03/04` and `05/06`; the fire gives a useful night cue. At roughly 36–54 m gate distance, however, the gate is only another low pale fence interval and the camp does not establish a commanding working-land threshold. |
| Hero bull and herd hierarchy | **POLISH** | Ordinary pale herd bodies read clearly on the right. Although the manifest records the bull only 11.18–27.73 m away, none of the six frames yields an unmistakable larger bull silhouette; proximity metadata does not replace visible subject proof. |
| Landmark hierarchy | **POLISH** | The warm central tree is consistently the strongest vertical and night landmark. The work complex remains a small horizontal cluster beneath it rather than sharing a single immediate hierarchy with gate, bull, and herd. |
| Day/night readability | **PASS with polish** | Player, pasture grade, woodland boundary, tree, herd, and campfire remain separable at night. The gate, wagon, and fence construction compress heavily into the dark ground, but the location remains navigable and identifiable. |
| Named-location identity | **POLISH** | The pasture/herd/fire/fence combination is specific enough to retain The Highfield as a real place. It does not yet make the named working pasture inevitable in one commercial hero read. |

## Delta and bounded promotion condition

R7 should supersede R6 because it removes the east-pair foliage obstruction without
regressing pasture ecology or night readability. Preserve those gains and the warm
tree/fire cues. Promotion still requires one ordinary player-height day/night pair
where the distinct hero bull is visibly identifiable and the drove gate plus stock
camp rise above the surrounding fence rhythm as a single working threshold. Do not
solve this by returning to close foliage or by enlarging the tree hierarchy further.

## Review-only scope

This commit adds only `REPORT.md`; it does not modify source, tests, manifest, PNG
evidence, scatter, encounters, or production content.
