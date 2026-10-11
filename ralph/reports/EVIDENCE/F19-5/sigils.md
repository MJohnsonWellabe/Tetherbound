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
