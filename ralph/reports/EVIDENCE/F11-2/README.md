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

---

# F11#2 Through disconnect/reload without duplicated grants: PASS

Lane coop-chapters, branch tb/ev-coop-chapters @ cfb316380 (game code unchanged from tb/ev-coordinator). Godot 4.7-stable headless, two real processes, each exit 0, 0 FAIL.
- `drop_at_ack/` (f11_stormheart_drop_at_ack, run Sun 11 Oct ~2:40 PM CT):
  - The guest says Yes, and its link is closed in the physics step that accepted it. The receipt is on its saved character, and the host holds no world receipt yet.
  - The guest rejoins as the same character. The host settles that one claim from the resent claim and the saved receipt; the guest has exactly one Stormheart.
  - Replays are refused before and after both peers reload, and the saved files agree.
- `refuse_drop_at_ack/` (f11_stormheart_refuse_drop_at_ack, run 3:04–3:15 PM CT): the mirror case. The guest's No is cut at its `declined` signal, and the host settles the refusal after the rejoin. The guest never holds a Stormheart, and replays are refused before and after reload.

Disclosed (PROOF RULES v2; no assertion changed):
- Fixtures: the named host save, the initial Crossing Hall portal fixture, and the Dynamo contributors fixture.
- 617f53293: RD-17 portal migration (bc150ca5 pattern) with the guest crossing first, plus the `_tap` process_frame flush.
- cfb316380: peers launch at the title, as the other Stormwood proofs do. Launching into the world scene built the Meadows before hello and missed the 180 s hello budget.
- Scratch copies, wall-clock only: every step's step-level `budget_frames` is max(4×, 12000), `build_allowance_s` is 600 and `budget_s` is 4×.
- Earlier refuse runs:
  - One timed out at #27, the host settling the refusal. It passed in the next two runs at 203 frames.
  - One was invalidated: an accidental duplicate launch into the same output folder deleted the live peers' user data, so the host save failed at #38.
  - Diagnostic prints from those runs were reverted.
