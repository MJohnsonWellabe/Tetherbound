# F15#3 — Grandpa acknowledges each current team after a real release-menu release

**Verdict: PASS** — headless two-peer loopback run `net-proof_two_peer-20260926T210103Z`, exit 0, on baseline main `0e2a3b60c9263d4d96d447869d6e34d57efa2506` (the scenario is the only non-evidence change; no product script or proof step was edited).

Criterion: ACCEPTANCE §6.1 **F15#3** — host and guest "receive Grandpa's acknowledgement of each current team, including releases" (T3: "Grandpa recognizes each character's current companions, including releases").

Scenario: `tools/net/proof_scenarios/f15_tidewake_b_grandpa_real_release.json`
Rerun: `tools/net/run_two_peer_proof.sh tools/net/proof_scenarios/f15_tidewake_b_grandpa_real_release.json --out=<dir>`

## What changed from the rejected proof

The coordinator rejected `ralph/reports/TIDEWAKE/f15_grandpa_acknowledges_each_team/PROOF.md` because world flags were ledger-set, parties granted, players teleported, and the release replayed with `remove_at`/`add` (`release_for_catch`). In this run:

| Rejected proof | This proof |
|---|---|
| Release replayed by `release_for_catch` (remove_at then add) | **Real release menu**: the host, at a full five, asks for its Guardian offer at the chamber's real invite prompt; on the Creatures tab the game opens (`_release_stage == "choose"`) the existing `guardian_answer` step focuses Rill's row in `_rows` → `ui_accept` → `_release_stage == "confirm"` → focuses `_farewell_release` → `ui_accept` → `_farewell_done` → `ui_accept`. Controller presses only (step 19). |
| `water_currents_restored` set with `story_flag` | **Set by the game**: the first Guardian resolution settles the world through `scripts/world/water_guardian_reward.gd` (`SETTLEMENT`). The world save captured before the offer lacks the flag (step 32); the after-save has it (step 34). |
| Released creature was replaced by a granted "Newt" | The Guardian takes Rill's holder: `[Acorn, Pip, Rill, Shelby, Volt]` → `[Acorn, Pip, Abyssal Guardian, Shelby, Volt]` (steps 19, 23). |
| Started in the Meadows | Starts in the Tidewake; each player crosses home with `Game.enter_realm("meadows")` (steps 27–28). |

Result at Grandpa (steps 29–30; lines from the dialogue panel's `line_presented`):
- Host, `regional_homecoming_5`: "Acorn / Pip / Abyssal Guardian / Shelby / Volt came home with you." in party order. **Rill is not named**; no guest companion is named.
- Guest, `regional_homecoming_3`: "Kestrel / Bramble / Abyssal Guardian came home with you." No host companion is named.
- `homecoming_seen` is saved on each character (steps 35–36), not in the shared world (step 34). The host's pre-offer character save held Rill and no Guardian or homecoming (step 33). The saved host character after the run lacks Rill (step 35).

## Remaining fixtures, disclosed

| # | Fixture | Why it remains |
|---|---|---|
| 1 | `story_flag defeated_warden` (world, ledger) | Stands in for the Meadows opening, so Grandpa is at home with his homecoming prompt and does not run the intro sequence. It is unrelated to the team or release. |
| 2 | `party_grant` of named companions (host 5, guest 2) | The `water` proof scene boots with an empty belt. Distinct nicknames make the acknowledgement checkable. The release under test is real. |
| 3 | `guardian_fixture` (Veilfall prerequisites + Nerissa's defeat through the ledger; both participants injected into the encounter director, whose own session path journals the reward rows) | Stands in for playing the Veilfall and the Nerissa fight, which is F14's criterion. The same path passes in `f14_guardian_offer_capacity_space`. The freeing press, invite prompt, offer, release menu and settlement after it are all real. |
| 4 | `enter_realm meadows` (production `Game.enter_realm`) | Stands in for walking back to the realm gate. It is the production crossing and loading path. |
| 5 | `grandpa_homecoming` teleports each player beside Grandpa, then presses his real prompt through `interact` | Walking across the Meadows to the house is not this criterion. |
| 6 | Guest half | The guest accepts its own Guardian with room (a real tab Accept). It does not release anyone in this run. The guest team-and-reconnect half already PASSes in `ralph/reports/INVITE-COOP/x05-proof-f15-guest-team-reconnect`. |

## Run notes

- **First attempt FAILED at step 27 (host Grandpa: conversation '', 0 lines).** The Guardian ceremony leaves the in-game menu open on the Creatures tab after the farewell's Done. The menu then owned input across the realm crossing, so Grandpa's `interact` press never reached him. The passing run adds a `menu_toggle {open:false}` step per peer, which closes the menu with the B button (`menu_cancel`) as a player would: one press, shut in 1 frame. Reporting only: it is not clear that an open menu surviving `enter_realm` is a product defect, because a player crossing on foot must close the menu to walk.
- Loopback headless run: local evidence, not internet or Steam acceptance. No screenshots (headless).
- Evidence trimmed for disk: peer home directories and the legacy `saves/slot_0.json` copies were removed. The captured `character.json` files are gzip'd (`zcat` to read). The world saves are kept as captured. Peer `.log` files are excluded by `.gitignore` (`*.log`) and are not in the PR; runner.md and SUMMARY.md carry the step results.
- The runner's full step table follows in `runner.md` (generated, unedited).
