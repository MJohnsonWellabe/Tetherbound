# F03#1 Meadows optional activities: the coordinator's r11 frame list, cart and Juno 2 redone in r12

Captures lane, Low/Compatibility (llvmpipe), 1280x720, real time. This lane captures; it does not judge.

- **Saves (generated, disclosed):** `tools/earned_saves/generate_boundary_save.gd` with `tests/fixtures/earned_saves/generated_boundary_profiles.json`, provenance in `PROVENANCE-*.json`.
  - `relay` (day 5): vault, Bram, cart.
  - `sigils` (day 6): Doss, Juno.
- **Tool:** `tests/capture_activity_lures.gd -- --act --wide-dialogue --morning`. It loads like the title screen's Load, walks with ordinary input, then acts with interact, dialogue and the input combat pilot.
- **r11 (finished about 12:02 AM CT Mon 12 Oct):** source `tb/ev-captures` at `d0310695`. Vault, Bram, cart and Doss PASS. The herd frame is unchanged.
- **`sheet.jpg`:**
  - **Vault:** engage, then the fight.
  - **Bram:** a two-shot with his challenge prompt, then the fight start. The fight-mid frame has a white dust haze, so it was not used.
  - **Cart (r12, `f480af6a`, finished about 1:24 AM CT Mon 12 Oct):**
    1. Coll's request while the cart is broken. A clip shader hides the low-side wheel on the one-piece wagon, and a wheel-only copy of the same mesh lies flat beside it.
    2. The prompt at the cart before the press: "Repair the cart: hand over wood, stone, fiber". It names the hand-in once the satchel holds all three.
    3. The cart whole and upright with Coll's thanks. Coll now stands at his cart as the installed `villager_keeper` body his portrait uses.
  - **Juno:**
    1. Her ask.
    2. The escort, with the Meadowhart following (r12, `c52871f8`). The band-4 Tether holding smoke is now light grey (`_why_f03_1_smoke_r11`), so the black sky spike is gone.
    3. The reunion.
- **`sheet-doss.jpg`:** Doss in order.
  - Each debris piece clears with its own prompt (receipt: `cleared` true for all three), then the rebuild press (`perch_repaired: true`).
  - 45 coin and a large potion, once. Wood and fiber are unchanged.
- **Scene fixes:**
  - **Logs:** the kenney logs paint from a flat palette and read as a peach cylinder. `props.gd` gains an optional `bark`, which lays the installed stylized_nature `Bark_NormalTree` texture and normal map over every surface (triplanar). It is applied to Doss's log and to Bram's seat. The rock (stylized_nature) and the branch (DeadTree_1) already carry their own textures.
  - **Vault side room:** the warm pool goes 1.1 → 2.4 (range 9 → 12) and the door bounce 0.3 → 0.8 (`_why_f03_1_r10`).
- **Staging (disclosed):**
  - The clock is frozen at 08:00.
  - Two-shot capture camera, kept at least 1.6 m above the ground.
  - Doss 1 is a capture-camera close-up.
  - For perch shots, the follower is stowed by calling the same `dismiss_active_creature` the recall key calls. The synthetic key press did not reach it, which left the Bramblebun standing in Doss's fire.
  - **Juno 1** is from a staged teleport beside Juno and back.
    - Not a game bug: her prompt is "Challenge Juno" and her last line offers a bout. Interact accepts it and cancel declines. The r11 helper pressed interact.
    - The r12 helper reads her ask, then cancels, and no fight starts (`fight_started: false`).
- **Open (found, not fixed):**
  - A thin bright floor/wall seam line crosses the vault side room behind the Heartstone plinth. It is cave geometry, not a capture artefact.
  - The vertical cyan stroke is the game's cyan arc beside the trainer, present in every frame.
- **Checks:** `test_item_gate`, `test_world_ledger_races`, `test_reward_delivery_rpc`, `test_flag_scopes` and `test_meadows_activity_qualification` pass. The coordinator runs the two smokes on `tb/ev-coordinator`.
