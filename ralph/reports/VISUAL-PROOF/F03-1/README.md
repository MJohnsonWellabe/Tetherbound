# F03#1 Meadows optional activities: one frame each, mid-action, for a distinctness judge

Captured Sun 11 Oct 2026, finished about 6:44 PM CT, by the captures lane. Source tb/ev-captures `01014cda09` (tb/ev-coordinator merged). Low/Compatibility (llvmpipe), 1280x720, real time. This lane captures; it does not judge.

- **Saves (generated, disclosed):** `tools/earned_saves/generate_boundary_save.gd` with the committed profiles from `tests/fixtures/earned_saves/generated_boundary_profiles.json`. Each save went through the production Load/Save validation; provenance is in `PROVENANCE-*.json`.
  - `relay`: post-Warrens, day 5, five L15 creatures. Generated on render.yml run 38175936474.
  - `sigils`: post-relay, day 6, standing at Old Mill Crossing. Generated locally.
- **Tool:** the existing `tests/capture_activity_lures.gd -- --activity=<id> --save-dir=<save> --slot=0 --act`.
  - It loads the save the way the title screen's Load does, then walks there with ordinary input only, until the lure is on screen and the prompt is offered.
  - `--act` then takes the activity's own action: interact, dialogue answers, and any fight via the input combat pilot.
  - Walk budget scaled 360 s → 1500 s game time for vault, herd, Bram and cart (pre-approved slow-host scaling; the default budget ran out on the 1.7 km walk from the Warrens).
- **Result (`results.log`):** all six PASS ("lure seen and the activity's prompt was offered") and each completed its action:
  - vault: fight won;
  - herd: watched, and the grazing ground was marked;
  - Bram: fights won;
  - cart: Coll's repair dialogue;
  - Doss: gathered wood and fiber, the repair, then the reward;
  - Juno: two patrol fights won, the escort reunited.
- **`sheet.jpg`:** one frame per activity. Full action sequences are in the per-activity frames at the source run; the six chosen frames are in `frames/`.
- **Not included:** the Hall activity needs all three captains beaten, which neither profile has.
