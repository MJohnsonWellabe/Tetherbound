# F03#1 Meadows optional activities: context and action frames, for a distinctness judge

Captures lane, Low/Compatibility (llvmpipe), 1280x720, real time. This lane captures; it does not judge.

- **Saves (generated, disclosed):** `tools/earned_saves/generate_boundary_save.gd` with `tests/fixtures/earned_saves/generated_boundary_profiles.json`, provenance in `PROVENANCE-*.json`.
  - `relay` (post-Warrens, day 5): vault, Bram, cart.
  - `sigils` (post-relay, day 6): Doss, Juno.
- **Tool:** `tests/capture_activity_lures.gd -- --activity=<id> --save-dir=<save> --slot=0 --act`. It loads like the title screen's Load, walks there with ordinary input, then acts with interact, dialogue and the input combat pilot.
- **r10 (finished about 10:41 PM CT Sun 11 Oct), on `tb/ev-captures`:**
  - Doss at `3641f360`; vault, cart and Bram at `5dde179c`. All four PASS.
  - Juno and herd are unchanged from the earlier rounds.
- **`sheet.jpg`:** vault 2, herd 1, Bram 2, cart 2, Juno 2, plus Doss's first and last frames.
  - **Vault:** the den's "Engage Elder Trailpup" beside the Heartstone on its plinth, then the fight. In these frames the trainer renders normally, with no white blotches.
  - **Bram:** his camp and "Challenge Old Bram", then his bout. His seat is the textured kenney log (`b6046ff7`), with no white box.
  - **Cart (fetch and deliver):** the capture mines the missing stone for Coll with the pickaxe, as an ordinary gather. Coll's thanks follow, with the cart standing again (`band1_broken_cart_repaired`).
- **`sheet-doss-juno.jpg`:** Doss in order, then Juno.
  - The pieces are a 3 m log, a rock and a forked deadwood branch (stylized_nature DeadTree_1), resting on the buckled boards (`b8441336`).
  - Each piece clears with its own prompt; the receipt shows `prompt_won` and `cleared` true for all three. Then the rebuild press: `perch_repaired: true`.
  - The reward is 45 coin and a large potion, once. Wood 2 and fiber 3 are unchanged.
  - Doss's line names the pieces (data only).
- **Capture staging (disclosed, capture-only):**
  - `--morning` freezes the day clock at 08:00 after load.
  - `--wide-dialogue` adds a two-shot camera beside the player-speaker line, on the side away from the follower.
  - Doss 1 is a close capture-camera view of the loaded perch.
  - The trainer now stops beside each piece once its prompt wins.
- **Checks:** `test_item_gate`, `test_world_ledger_races`, `test_reward_delivery_rpc`, `test_flag_scopes` and `test_meadows_activity_qualification` pass (0 failed).
  - `smoke_local_requests` and `smoke_net_gate_opens_for_both` are being run by the coordinator on `tb/ev-coordinator`.
- **Not included:** the Hall activity, which needs all three captains beaten.
