# F11#2 — Stormwood legendary offers through disconnect/reload without duplicated grants: PASS

- **Command:** `GODOT_BIN=<godot 4.7> tools/net/run_two_peer_proof.sh <scratch copy of tools/net/proof_scenarios/stormwood_f11_disconnect_guest_rejoins_answers_once.json>` (two real ENet processes).
- **Source:** `tb/ev-coop-loop` at `19b70236` (= `tb/ev-coordinator`, with the RD-17 portal fixture, the owner_passive F48#3 fix and the `_tap` fix).
- **Run:** 2026-10-11, 1:54–2:05 PM CT. `Verdict: PASS`, exit 0, every step met its expectation. Full table: `PROOF.md`.
- **Flow:**
  - Both players cross the Crossing Hall Stormwood portal, guest first.
  - Both fought the Dynamo; the host says Yes to its Stormheart.
  - The guest's link drops while its offer is still owed. It rejoins from the title screen as the same character, still holding nothing and having answered nothing. It says Yes once and then holds exactly one Stormheart.
  - A second drop and rejoin: still exactly one, and pressing the prompt again offers nothing.
  - The host reloads its slot in place and the guest re-applies its character from disk. Neither prompt offers anything, and each holds exactly one Stormheart, its own.
  - The guest's saved `character.json` keeps one Stormheart.
- **Disclosed setup:** host named save `proof_saves/host_meadows_stormwood_route_open`; the guest starts as a fresh trainer; the Hall/Stormwood portal fixture (`initial_hall_position_and_open_route_no_earned_credit`); the Dynamo fight fixture (`stormheart_fixture`).
- **Slow-host scaling (scratch only, not committed):** scenario `budget_s` 2100 → 6300 in the scratch copy; `multiplayer.json` `test_budgets` raised to 900 / 3600 / 7200 locally.
- **Expected not-PASS rows:**
  - `enter_realm` after a rejoin is "ANY": the rejoin already stands in Stormwood.
  - `stormheart_answer` after an answer is expected FAIL: nothing is offered.
