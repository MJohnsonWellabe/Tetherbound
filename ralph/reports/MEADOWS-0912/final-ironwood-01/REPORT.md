# First Ironwood — production visual judgment

**Visual verdict: PASS for the OWNER-0912 washed-out approach complaint. The full
Tier 2 #8 row remains HOLD until the new story path is exercised in production.**

The capture manifest is complete (`complete: true`, 8/8 expected PNGs, no
failures), and all eight 1280 × 800 frames were inspected at original resolution.
This judgment covers production pixels only; it does not treat the static dialogue
contract as proof that a player can hear the new explanation.

| Criterion | Verdict | Evidence |
|---|---|---|
| Scale remains impressive | **PASS** | `01-long-road-world-tree-*` and `02-southwest-world-tree-*` establish a canopy and trunk mass many times larger than the surrounding mature trees. `03-root-district-*` preserves that scale at ordinary approach distance rather than relying only on a remote silhouette. |
| Approach no longer washes out white | **PASS** | All four day views retain a green canopy, brown trunk, darker branch separation and visible bark/fissure variation. The tree is pale relative to ordinary forest trees, but it is not an untextured white mass. |
| Texture/material survives near and far | **PASS with polish** | `01-*` and `02-*` retain the broad colour blocks at distance; `03-*` shows bark and leaf variation close enough to reject the missing-texture failure. The cyan inner fissures are much brighter than the bark at night, but the trunk outline and canopy remain visible and the object does not read as an emissive white tree. |
| Route and workyard relationship | **PASS** | `03-root-district-day` gives a clear ordinary approach with the path and lower trunk; `04-ironwood-workyard-*` remains a separate human-scale work area rather than intersecting the colossal trunk. The ordinary grove trees partially mask the base in long views but do not hide the destination. |
| Day/night readability | **PASS with polish** | Day views are consistently legible. At night the tree remains unmistakable and its branch/trunk structure survives, though the cyan fissures are strong and the unlit workyard loses some small-prop detail. Neither issue recreates the owner's washed-white approach defect. |
| Story reason | **NOT PROVEN BY PIXELS** | The capture cannot show the Juno → Halder dialogue/objective explanation. Static coverage exists in `tests/test_ironwood_story_0912.gd`; a real interaction/objective receipt is still required before the combined row is Complete. |

## Remaining minimum proof

Exercise the production Juno prompt and Halder follow-up through the real dialogue
runner, confirm the objective/flags retire correctly, and preserve the accepted
visual state above. No additional Ironwood recapture is required unless that runtime
work changes the location or its materials.
