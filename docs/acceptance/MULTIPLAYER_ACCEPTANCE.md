# Multiplayer acceptance — Stage B

**Status:** in progress. **Contract:** `docs/MULTIPLAYER_DIRECTIVE.md` §17 (the twenty-four
minimum-experience items), §21 (reliability), §23 (the human half). **Filled in by:** Fable, from
CI runs and the owner's own LAN session. **Last updated:** 2026-09-06.

The directive's own words: *"Do not call the pass complete after only a two-player movement
demo."* This file exists so that cannot happen by accident. Every row needs an evidence cell that
names a run, not an opinion.

## How a row passes

Two kinds of evidence, and a row usually needs both:

- **Automated** — a named `smoke_net_*` running two real Godot processes in CI's
  `verify-multiplayer-shard` on every pull request. A smoke that only passes on retry is a
  finding, not a pass.
- **Owner** — the item done by hand in a hosted real-game world, on real hardware, over a real
  LAN. `tools/owner/MULTIPLAYER_KICKOFF.cmd` sets the session up; the owner plays it.

**A smoke is not a substitute for the owner column on the rows that are about how it feels.**
Two processes agreeing on a number proves the mechanism; it does not prove a fight is legible with
two people in it, or that a friend's creature reads as theirs. Those are the owner's to say.

## §17 — the twenty-four

| # | Item | Automated evidence | Owner |
|---|---|---|---|
| 1 | Host / load a world | `smoke_net_host_join_leave` | ☐ |
| 2 | Join with up to three | `smoke_net_host_join_leave` (2 peers); **3/4-peer runs owed** — nightly/owner-kit only, never PR CI (S2: four boots = 12.85 GB) | ☐ |
| 3 | Move independently and see one another | `smoke_net_movement_two_peers` — 0.55 m in motion, 0.00 m at rest, against 4.0/1.5 m budgets | ☐ |
| 4 | Deploy and control own creatures | `smoke_net_deploy_two_creatures` — asserts authority, not just presence | ☐ |
| 5 | Shared wild encounters | `smoke_net_shared_wild_fight` | ☐ |
| 6 | First-successful-catch rule | `test_catch_arbitration` (pure, deterministic). **No net smoke** — recorded as owed, not implied | ☐ |
| 7 | A trainer encounter together | *lane 4.D in flight* | ☐ |
| 8 | A boss encounter together | *lane 4.D in flight* | ☐ |
| 9 | Gather without duplication | `smoke_net_pickup_race` | ☐ |
| 10 | Shared pickups | `smoke_net_pickup_race` | ☐ |
| 11 | Build and use shared structures | `smoke_net_shared_building` — includes the host-save-and-reload half | ☐ |
| 12 | Shared storage safely | `smoke_net_storage_concurrency` — one commit, loser told `stale_revision`, 20 wood before and after | ☐ |
| 13 | Trade items | `smoke_net_trade` — conservation across both peers | ☐ |
| 14 | Down / revive another player | `smoke_net_revive` | ☐ |
| 15 | Sleep and advance night | `smoke_net_sleep_vote` | ☐ |
| 16 | Menus without freezing others | **owed** — no smoke yet | ☐ |
| 17 | Ride and Fly while others act | *lanes 6.B / 6.C not started* | ☐ |
| 18 | Transition independently | **HELD** — built by 6.A, refusal re-instated: the shell boot freezes the host past 15 s (D97) | ☐ |
| 19 | Different biomes simultaneously | **HELD** — same cause as 18; the machinery is built and measured, the door is shut (D97) | ☐ |
| 20 | Save world + portable characters | `test_world_save_format`, `test_save_format` (59 tests). **The character half is not yet written** — lane 1.C deferred; a client writes no character file today | ☐ |
| 21 | Disconnect and reconnect | *lane 7.A not started* | ☐ |
| 22 | Late-join a modified world | *lane 7.A not started* | ☐ |
| 23 | Host plays solo when alone | Solo **is** a one-peer session through the same funnel; every solo smoke is this row's evidence | ☐ |
| 24 | Host exits, session saves/ends | `smoke_net_host_join_leave` — asserts the host wrote its world and the client wrote none | ☐ |

## §21 — reliability

| Item | Evidence | Owner |
|---|---|---|
| Latency / jitter | *lane 7.A* — `shared_wild_fight` and the catch race under 150 ms delay / 30 ms jitter | ☐ |
| No duplication under races | `test_world_ledger_races` — 24 tests, 136 assertions, each interleaving seen red first | ☐ |
| Desync detector quiet through every net smoke | contract §7 hashed keys, asserted in `two_peers_boot` | ☐ |
| **Target hardware frame time on the Ally** | **owner-measured only.** `fps.json` from the kickoff, host-side, with a second player connected | ☐ |

## §23 — the human half, which no smoke can supply

| Item | Owner |
|---|---|
| The owner hosts and is joined over a real LAN | ☐ |
| At least one **outside tester** hosts, and three join, without developer help | ☐ |
| That session is recorded in `docs/owner/` like a playtest | ☐ |

## Known-open, carried deliberately

Recorded here so a reader does not have to infer them from silence:

- **Wild creature bodies are not replicated.** A client's wilds are its own simulation and drift
  from the host's. Lane 4.B chose drift over a frozen meadow; `MP_ENCOUNTER_PROTOCOL.md` §2
  resolves every strike against host positions, which is what keeps it cosmetic.
- **Host-side full-map terrain collision was implemented and reverted.** D96 carries the
  measurements and what the next attempt must settle.
- **`smoke_aggression` and the combat-camera smoke are genuinely flaky**, measured against
  untouched bases by two independent lanes.
- **The character save half is not written**, so "portable character" (row 20) is a forward
  assertion rather than a demonstrated behaviour.

## The verdict

Stage B is done when **every row above reads PASS**, solo Meadows and Cloudreach still play end to
end, and it is all on `main`. Not before, and not on the strength of the automated column alone.
