# F19#5 Meadows piece `sigils`: PASS, hosted on 1c9d3566; F02#7 PASS (routes-west)

**Re-walk on 1c9d3566 (2026-10-12, hosted, 12674 s, fail-fast watchdog attached, never fired):** `passed: true`, no failures; the interim satchel-room path dropped 2 berries once.
- **Ledger:** `route_ledger/sigils_1c9d3566.jsonl.txt`, 4822 m, A7 clean.
- **Strict 250 m: 0 windows over.** The new `b4_candy_ridge_descent_wayside` registered at path 3709 m, splitting the former 271 m stretch from Vess to the gate road.
- **F02#7 verdict: PASS.** The sigils and hall (`route_ledger/hall_45a1dd6a.jsonl.txt`) ledgers together show no §3.1 window over 250 m, and A7 is clean.

## Previous run on 90927824

**Run:** 2026-10-12, hosted on a fallback port. Generated relay input. `passed: true`, no failures, wall time 11629 s.
- Riverwatch, Field and Ridge were each beaten 5/5, with exact XP and exact item rewards.
- **Interim disclosure (coordinator-approved).** Before each captain, the route frees one Satchel slot per reward item that needs a new slot. It uses the real Drop: controller focus, Drop, confirm, with a `satchel_room_dropped` receipt. Here it dropped 2 berries once.
- That drop exists because unfit trainer rewards are lost today: the ledger item_grant carries no leftover. In run `7dbcc236`, Ridge's elixir_guard was lost at 23/24 slots. systems-b owns that bug. This evidence does not claim the full-bag case works.
- **Care during a wild fight:** a wild that engaged during between-fight care was fought, then care was retried whole (`77045956`).
- **Ledger:** `route_ledger/sigils_90927824.jsonl.txt`, 4807 m, A7 clean. Strict 250 m found 1 window: 271 m from "Greet Captain Vess" (path 3594) to the first new find on the gate road (3866), with only repeat species and Chop prompts between.
- **Content fix:** `b4_candy_ridge_descent_wayside` (band 4 pickups.json, a side-tier good_candy about 10 m off the walked line at path ~3730). Re-walk queued.

## Earlier attempts
# F19#5 Meadows piece `sigils`: FAIL, two attempts, stopped (meadows-route-b)

- **Command:** `earned_chain_runner.gd -- --segment=sigils --generated-fixture --save-dir=<root>/sigils/save --receipt=<root>/sigils/receipt.json`. Generated 'sigils' profile (disclosed fixture input).

| Attempt | Source | When (CT) | Wall time | Captains | Failure |
|---|---|---|---|---|---|
| 1 | `513130ed` | 12:26–1:14 PM | 48 min | Oreth 5/5, Halder 5/5 (Field Sigil + TM) | Between-fight care: "Inventory input did not open the Satchel for earned care", right after 3 revives through the same path had worked |
| 2 | `1483dbc1` (adds diagnostic text to that message) | 1:16–2:01 PM | 2800 s | Oreth 5/5, Halder 5/5 | Same care step: "Party-cycle input did not select the available training creature"; 5 presses, active index stayed 2 (wanted 4) |

Vess was not reached in either attempt.

**Leads, not proven.** Both failures are a world verb refused right after a wild victory and revives in Upper Meadows. `encounter_director.gd::_read_creature_control_input` ignores party-cycle while any of these is true:
- a fight is running;
- a trainer battle is active;
- the interaction arbiter is disabled;
- an input owner is set.

The Satchel refusal fits the same pattern, so an ambush or other input holder during care is likely.

Separately, attempt 2 logged 112 `[session] combat_mastery duty … held: unresolved {"durable":true,"ok":true,…}` from t=720 s onward, with **0 releases**. The relay piece logged none. An ok, durable mastery duty that never resolves may block training or deployment mutations. This needs a session/training owner.

**Update (3:40 PM CT).** systems-b measured a Meadows long-fight drain of about 100 mastery duties. `_owner_training_mutation_blocked` was true for 0 frames, so the duty queue does **not** block the Satchel or party-cycle. The "held … 0 released" lines were a logging artifact, fixed in `tb/ev-systems-b` `0d677b6a`. The refusal cause is still open; the next suspect is a modal or input owner (for example a RelicPowerPanel or a dialogue).
