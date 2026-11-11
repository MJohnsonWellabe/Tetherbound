# FLOOR2-CAMP-LAND: Trail Camp decluttered, a sign that reads from both sides, plain-wood gate, ships ON (F38#32)

STATUS: land

- **Branch:** `tb/floor2-camp-land`, cut from `origin/main`.
- **Verdicts (LANE-SCOUT):**
  - G-floor2-camp-r2 (`tb/item-scout-1108` ebb0ebcc3), GPU High: F38#32 **6.26 → 6.91**, no frame loses. Tent and bed +0.07 (2/3); bonfire +1.83 (3/3), mostly the stand fix. The near-oxblood flag on the gate is gone.
  - G-floor2-camp-r2-signfront (`tb/gpu-frames-1108` 071f2dcc1): from the front the board reads "TRAIL CAMP" left to right.
  - Medium not captured.
- **What ships (game):**
  - `scripts/world/props.gd`: a per-cluster `hero_candidates` block in the head `props.json`; `drop_models` leaves listed models out (the `prop_scale` hook is there but unused).
  - `scripts/world/trail_camp_roadside_threshold.gd`: `single_sided_labels` and `wood_tint`.
  - `data/config/props.json`: `hero_candidates.trail_camp` ON with `_why_on`: rope, bag, fern and clover left out; single-sided sign labels; gate timber #6b6152. **Nothing is scaled.**
- **What ships (capture tooling):** `data/config/capture_stands.json heading_overrides`: `meadows__inventory__prop__bonfire_fire` heading 90, with `_why`.
  - **The old planned stand was broken, not just unflattering:** heading 0 put the trainer on top of the TRAIL CAMP gate (inside-collision reseat), so the frame showed the board across the foreground and no bonfire. The stand move fixes that; it was accepted only together with the in-game sign fixes, so no stand hides a defect.
- **Test added:** `tests/test_trail_camp_hero_landed.gd` (4 tests): flag on with the cited score, no `prop_scale` and the four dropped models, one-faced labels and a timber colour with no red cast (built gate checked), and the bonfire stand at heading 90.
- **Tests run on this branch:** `trail_camp_hero_landed, trail_camp_composition, trail_camp_arrival_identity, band_content, capture_stand, near6_ms_1104, catalogue_capture_stand`: 36 tests, 1687 assertions, 0 failed.
- **Not included:** attempt 1's scale-ups (lost on GPU), and every other `tb/floor2` candidate.

## Follow-ups (next camp arm, not this landing)
- The board's frame and an inner upright still use the orange-brown wood; the lettering is wider than the board, so the T runs under the left brace.
- A crimson clump by the chest and pumpkin near the tent is in Team Tether's reserved red.
- Grass clear radius and contact shadows round the props.
- The campfire itself is new art (LANE-MESHY). `camfx.json flame` is an existing OFF candidate for the "flat yellow cone flame" that may be worth a look there.
