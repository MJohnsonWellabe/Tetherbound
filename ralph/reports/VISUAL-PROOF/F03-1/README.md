# F03#1 Meadows optional activities: one frame each, for a distinctness judge

Captures lane, Low/Compatibility (llvmpipe), 1280x720, real time. This lane captures; it does not judge.

- **Saves (generated, disclosed):** `tools/earned_saves/generate_boundary_save.gd` with `tests/fixtures/earned_saves/generated_boundary_profiles.json`. Provenance is in `PROVENANCE-*.json`.
  - `relay`: post-Warrens, day 5, five L15 creatures.
  - `sigils`: post-relay, day 6.
- **Tool:** `tests/capture_activity_lures.gd -- --activity=<id> --save-dir=<save> --slot=0 --act`. It loads the save like the title screen's Load, walks there with ordinary input, then performs the activity with interact presses, dialogue and the input combat pilot.
- **`sheet.jpg`:** one frame per activity. Vault, herd, Bram and cart are from the r1 run (source `01014cda09`, about 6:44 PM CT Sun 11 Oct). Doss and Juno are r9.
- **`sheet-doss-juno.jpg` (r9, finished about 9:21 PM CT Sun 11 Oct):** the reworked Doss activity in order, plus Juno's reunion.
  - Sources on `tb/ev-captures`: Doss at `f9cc92a5` (Doss rework `2a194d67` and the 44bbda40 port fallback); Juno at `b6046ff7` (its log binds udp/27015). Sigils save; both runs PASS.
  - **Doss (judge r8: same verb as the cart):**
    - Three installed pieces lie across the buckled perch: kenney survival log and small log, stylized_nature rock.
    - Each clears with its own interact prompt. The receipt shows `prompt_won: true`, `cleared: true` and `visible_after: false` for log, rock and branch.
    - Doss's prompt then reads "Rebuild the bank perch". One press sets `river_nest_doss_cleared` and the perch stands straight (`perch_repaired: true`).
    - The reward is 45 coin and a large potion, once. Wood 2 and fiber 3 both before and after: no payment.
    - World flags set in order: met, log, rock, branch, cleared.
  - **Juno:** the patrol fights are won, then the escort reunites the Meadowhart (2.2 m from Juno). The frames are her reunion and her first line.
  - **Staging (disclosed, capture-only):**
    - `--morning` freezes the day clock at 08:00 after load. Without it, the site is reached at about 22:40 and the debris does not read.
    - `--wide-dialogue` takes the dialogue, reunion and debris frames with a capture camera. It sits beside the player-speaker line, on the side away from the follower, pulled back and raised. Judge r8: creatures and the trainer's arm were against the lens.
    - The game's own over-shoulder frames are kept at the source run.
- **Doss rework checks (headless, Sun 11 Oct):** `test_item_gate`, `test_world_ledger_races`, `test_reward_delivery_rpc`, `test_flag_scopes` and `test_meadows_activity_qualification` all pass (0 failed).
  - The ledger race test has peer B clear the debris and peer A rebuild. Only A is paid, no materials are taken, and a partial clear is refused with code `debris`.
  - `smoke_local_requests` and `smoke_net_gate_opens_for_both` were updated to clear the debris with real presses. They were not run in this pass.
- **Bram's white box (judge r8):** his seat was environment/nature `log_large`, which renders untextured. It is now the kenney survival `tree-log` (`b6046ff7`, `_why_f03_1_r8`). Bram was not recaptured, per the assignment, so tile 03 still shows the old log.
- **Smoke column (judge r1):** lightened to `#bdb6ab` at alpha 0.55 (`d43cf52a`).
- **Not included:** the Hall activity, which needs all three captains beaten.
