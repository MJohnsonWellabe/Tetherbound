STATUS: ride-along (judged, passes the ship rule; every gain is under 0.5, so batch it with a larger Stormwood landing, e.g. LANE-THINGS' Nysa creature clearance; do not land it alone)
BRANCH: tb/below6-stormdeck-ride (cut from origin/main 3b7d04b5; READY is in the same commit)

# Stormheart dressing: warm deck wood, cloth banners, aged split wood, ON (LANE-BELOW6, 12 Nov 2026)

## Verdict
`ralph/reports/GPU-PASS/1108/G-below6-stormdeck.md` on `tb/item-scout-1108` d54613a5 (GPU High, three code-blind judges):

| Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| F41#15 row (3 frames) | 4.62 | 5.10 | +0.48 | 3/3 |
| Split-facing frame | 4.50 | 4.90 | +0.40 | 3/3 |

Nothing loses. The GPU lane's hue pre-check: deck 322/324 degrees -> 27/23; every arm reading is between 15 and 50. No judge sees pink or red on the arm. High only.

## What lands
- `data/config/stormheart_presentation.json`: `built_detail.deck_wood_warm_1112`, `built_detail.banner_cloth_1112`, `split_bark_finish.aged_heartwood_1112` ON with `_why_on`.
- `scripts/world/stormheart_tree.gd`: the deck tint switch and the banner cloth.
- `scripts/world/stormheart_split_bark.gd`, `scripts/world/stormheart_split_wood.gdshader`: the `weathering` parameter (0 = unchanged).
- `tests/test_below6_stormdeck_landed.gd`: the three flags ON and citing the verdict; the aged wood fully grey under a khaki tint; the unjudged candidates below OFF.

## Unjudged flag-off code that comes with `stormheart_tree.gd`
The file on `tb/below6` also carries two candidates that have not been judged. They are OFF, pinned OFF by the test above, and change nothing while off:
- `ramp_body_1112` (`_ramp_body`), with `tests/test_stormheart_ramp_body.gd`, which pins the entrance ramp's collision byte-identical.
- `heartwood_1111.core_v2` and `scripts/world/stormheart_heartwood_core.gdshader` (parked after three CPU looks).
If the coordinator would rather land only judged code, say so in the NOTE and I will cut the file down.

## Tests
Run in the lane checkout (main 3b7d04b5 merged) with the flags ON: `--only=stormheart,below6_stormdeck_landed,stormwood_world,smoke_stormheart_ascent`: 13 test files, 40 tests, 5094 assertions, 0 failed. That includes the tree's pinned physics tests. No full suite. No new asset.

## Still named by the judges
Nysa's frame is unchanged (a storm creature fills it); Marrow's hair still blooms white; the dialogue box covers him from the chest down; the sky is a flat purple band; the split-facing stand shows two flat bark walls with no crown or core.
