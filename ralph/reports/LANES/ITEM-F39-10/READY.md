STATUS: land
BRANCH: tb/item-f39-10  HEAD: 8f3d1c6c39cf8adc98c9fbed667c03bc886c5e53 (this line added in the next commit)

# ITEM F39#10 P2-009 water and island depth (LANE-TW)

- **Score:** GPU 6.19 live.
  - CPU quick judge `qj/F39-10-f404e4723b4d-11072351`: base 7.15 -> candidate **7.25 mapped** (+0.10). Two judges scored it +0.1 and one tied.
  - All three judges call the "uniform light cyan" defect FIXED or PARTIAL on both sides.
  - The gain is small, but it is a judged gain over live, so it ships ON per the lane rule. The CPU base already maps 7.15, so the row needs its GPU pass (High, then Medium).
- **Flag/value turned ON** (`data/config/tidewake_look.json` `shore_water_candidate.water`, the section live in play; `_why_f39_10_on_1108`):
  - `mid_depth_m` 3 -> 6
  - `depth_falloff` 11 -> 24
  - `depth_band_break_m` 1.0 -> 2.2
  - Colours and `wave_strength` are unchanged.
- **Not used:** a first overlay targeted `cause_tidewake.sea`. That section is OFF in play, so the frames did not change and the overlay was not judged.
- **Tests:** added the F39#10 assertions in `tests/test_tidewake_look_profile.gd` (score recorded, falloff 24). The file passes: 10 tests, 267 assertions, 0 failed.
- **Files touched:** `data/config/tidewake_look.json`, `tests/test_tidewake_look_profile.gd`, the LANE-TW qj verdict, this report.
- **Judges' remaining asks:**
  - The shallow bands are smooth, airbrushed concentric rings that look procedural.
  - The dunes are flat and over-bright.
  - The Lastlight frame has no water and reads as a black untextured cliff slab plus a tent.
- **Next idea:** break the shallow rings with a sand-bar and reef pattern in the shallow tint (noise on the shallow/mid stop, not on depth). Separately, give the Lastlight cliff a material and dressing pass (another subject; it scores on this row because its frame is in the set).
