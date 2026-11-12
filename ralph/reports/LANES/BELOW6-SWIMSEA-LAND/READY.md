STATUS: land

# tb/below6-swimsea-land: the swimmer's surface stroke and the restored sea (F39#5, F39#14, F39#17)

**Verdict for both:** GPU High, G-below6-swim-sea-r5 (`ralph/reports/GPU-PASS/1108/G-below6-swim-sea-r5.md` on tb/item-scout-1108 5c800b975).

| Flag (ON, with `_why_on`) | Row | Score | Prefer arm |
|---|---|---|---|
| `data/config/human_swim_visual.json surface_crawl_1112` | F39#5 | 5.45 -> 5.98 | 3/3 |
| | F39#14 | 5.74 -> 6.12 | 3/3 |
| `data/config/water_current_flow_visual.json restored_sea_1112` | F39#17 | 6.08 -> 6.27 | 2/3; S3/S4 restored +0.10 (no loss) |

**Code**
- `scripts/player/trainer_model.gd`: the flag's `swim_pose` is merged last; `arm_recover_lift` and `arm_reach_scale` keys (no-ops at their defaults).
- `scripts/world/water_restored_sea.gd` (new) and its attachment in `scripts/world/water_veilfall.gd`.

**Tests** (0 failed with both flags ON, run with `test_human_swim_visual.gd`, the swim tests and the current-flow tests; older swim-pose pins pass unchanged)
- `tests/test_below6_swim_landed.gd`, `tests/test_below6_restored_sea_landed.gd` (pins: ON, verdict cited, numbers).
- `tests/test_surface_crawl_flag.gd`, `tests/test_water_restored_sea.gd`.

**Scope**
- Swim: pose keys only. Capsule, camera, speed, stamina and the network packet are unchanged; a remote trainer runs the same pose code from the packet it already gets.
- Sea: client presentation driven by the existing replicated world fact `water_currents_restored`, read once a second (sea shader values by time-of-day preset, visibility of the existing drift floaters). No flow, physics, route, save or authority change.

**Not closes:** all three rows are still below 7.5. Remainders named 3/3: boots as dark blobs behind the swimmer's head, the pinwheel seam in the wake foam, the surf rings as flat concentric bands, the hard dark wedge across the water.

This branch replaces `tb/below6-swim-land` and `tb/below6-restored-sea-land` (same content, split); both can be deleted.
