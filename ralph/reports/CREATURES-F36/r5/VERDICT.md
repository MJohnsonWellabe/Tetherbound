# CREATURES-F36 r5: taller than the trainer, via a scale flag (CPU, three judges)

**Verdict:** Duskhush and Brooktail are GPU READY as arm `tb/co-f36-3-on` d13f2db33 (control: main a41e1b30). Bramblebun and Trailpup are left out (gain within noise).

**Target:** GPU ROSTER-1 High (31 Oct, coordinator) item 4, "height above the trainer" for bramblebun, trailpup, duskhush and brooktail. Their measured standing bounds are 3.0 / 3.1 / 2.3 / 2.1 m, ears and crests included.

| Species | Factor | Height | Mapped main | Mapped arm | Gain | "Barely taller than the trainer" (main / arm) |
|---|---|---|---|---|---|---|
| **Brooktail** | x1.4 | 2.10 -> 2.94 m | 5.81 | **6.56** | **+0.75** | PARTIAL x3 / FIXED x3 |
| **Duskhush** | x1.35 | 2.30 -> 3.11 m | 5.81 | **6.31** | **+0.50** | PARTIAL x3 / FIXED x3 |
| Bramblebun | x1.3 | 3.00 -> 3.90 m | 7.11 | 7.26 | +0.15 | FIXED x3 / FIXED x3 |
| Trailpup | x1.3 | 3.10 -> 4.03 m | 6.56 | 6.66 | +0.10 | FIXED x3 / FIXED x3 |

**Fit:** linear, slope 1.50, intercept −3.18, r 0.98, RMSE 0.18. Confirming batch (craft, f36_0_npc:C1). No warnings.

**Arm shape:**
- Flag-off code: `_apply_scale_flags` in `scripts/creatures/creature_species.gd` runs once when the species table loads.
- Config: `data/config/creature_scale_flags.json`, flag `creatures_f36_taller_than_trainer`, `enabled` false.
- An enabled flag multiplies placeholder `height` and collider `radius` by the same factor. Factors below 1 are refused (grow the smaller side, never shrink).
- `footprint_allowance` is unchanged, so radius × allowance scales with the art, as in Mosshock's scale-up.

**Tests:** `test_companion_presence`, `test_creature_rest_pose`, `test_creature_viewport_framing`, `test_rideable_roster`, `test_route_strip_subject_boxes`, `test_stormwood_b_combat_camera_fit` pass with the flag on and with it off (90 tests, 901 assertions, 0 failed each time).

**Landing note:** turning the flag on in shipping also changes these two creatures' gameplay colliders. Brooktail and Duskhush are not rideable and have no bed-fit rule. A spawn-clearance check for their spawn sites belongs with the landing.

**What the judges still see:**
- **Duskhush:** near-black plumage with no rim light and no visible eyes; the faint is a dark heap.
- **Brooktail:** a cartoon face, and a faint end that sits upright facing the camera.
- **Trailpup:** reads as a stock coyote with no element touch.

Sheet `_sheet_r5.jpg`: main on the left, arm on the right; rows are Brooktail and Duskhush. Tiles: standing, hit 050, faint 050, faint 100.
