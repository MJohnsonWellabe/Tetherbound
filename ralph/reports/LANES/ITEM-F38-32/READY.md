STATUS: land
BRANCH: tb/item-f38-32  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, F38#32 P2-035 camp and workshop prop legibility, camp re-dress pass (coordinator 8 Nov).

**Ships ON (coordinator decision 8 Nov).** The corrected ship rule: the gain exceeds the measured noise floor for this frame type (0.00) and at least 2 of 3 judges prefer the arm. Here it is +0.28 with 3/3. The 0.3 minimum used earlier was stricter than the owner's 7 Nov rule.
- `data/config/bands/band1_lower_meadows/props.json` trail_camp: Crate_Wooden, Bag, Rope_1 and Barrel move to (346.4, 939.2), (347.0, 938.4), (345.8, 939.9) and (346.9, 939.9). Each carries `_why_on_f38_32` with the round and 6.58 -> 6.86 (3/3).
- The arm's Bonfire_Fire scale 0.45 -> 0.6 is **not** shipped: it was a no-op, because the ON `camp_floor.prop_scale` already sets Bonfire_Fire to 0.6 (props.gd). The judged frames are therefore identical to what ships.

**Pre-ready check (merged tree):**
- `run_tests.gd --only=` every `tests/test_*.gd` that greps `band1_lower_meadows/props`, `trail_camp` or `props.json` (30 files, including test_band_content, test_trail_camp_composition, test_trail_camp_arrival_identity and test_near6_ms_1104): **207 tests, 12296 assertions, 0 failed**.
- `tests/smoke_authored_camps.gd`: passed.
- JSON parse: props.json.
- The cluster is order 1000, which is not in band_split_baseline's 5 pinned clusters, so there is no fixture mirror.

## Arm (overlay only, `overlay_redress_v2.json`)
- Change, in the `props.json` band1 `trail_camp` cluster (order 1000; outside the 5 clusters pinned in band_split_baseline):
  - Crate_Wooden, Bag, Rope_1 and Barrel move from the camp's west edge, between the tent stand and the camp, to a stores group on the camp floor east of the tent. All four sit within 5.1 m of the 5.2 m floor centre.
  - Bonfire_Fire scale goes from 0.45 to 0.6.
- Unchanged: the tent, bed, fire, seats and the keep-clear. The camp companions, orders 1073 and 1074, are authored VP9 life clusters.
- v1 (stores just west of the tent) crowded the trainer; it was rejected by eye and not judged.
- Visibility (`_sheet_visibility_v2.jpg`): pixels changed were camp_tent 6.0%, camp_bed 3.2% and bonfire_fire 2.0%.

## Round (`qj/redress-r1/`)
- Mapped **6.58 -> 6.86 (+0.28)**. Raw live 5.4 / 5.6 / 6.0, arm 5.6 / 5.8 / 6.2.
- Fit: slope 1.37, r 0.84, RMSE 0.62.
- All three judges preferred the arm by +0.2. Defect calls went from PRESENT x3 to PARTIAL x1, PRESENT x2.
- **Below the session floor of 0.3** (noise floor N = 0.00 in `ITEM-F36-29/READY.md`), (superseded by the corrected rule above).
- Confound, which cannot be removed: `phase2_capture_world_inventory.gd` has no wild-spawn control. It already pins `--seed=2042`, but wanderers still differ between arms; the arm's camp_bed frame has a coyote at the left that the base lacks.

## Judges' remaining asks (all three)
- The props are small, mid-value brown and similar in size, so they merge with each other, the grass and the shadowed ground.
- Fewer, larger, value-contrasting props, with one hero object per site and rim light or separation.
- The bonfire-frame props sit against the busy rock arch.

**Next idea:** fewer and larger camp props, not repositioned ones. Drop the small loose items (rope, bag, bucket), scale the tent and bonfire up to read at the stand distance, and add one lit hero object, such as a lantern on a post, for value contrast.

## Files
`ralph/reports/LANES/ITEM-F38-32/**` only.
