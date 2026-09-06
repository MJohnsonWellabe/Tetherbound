# Multiplayer acceptance — Stage B

**Status:** in progress. Automated column: 23 of the 24 §17 rows name a run; only row 8 does not, and row 21 is partial. Owner column: nothing signed off yet. **Contract:** `docs/MULTIPLAYER_DIRECTIVE.md` §17 (the twenty-four
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
| 2 | Join with up to three | `smoke_net_three_peer_session` — 22/22 checks, first attempt, three processes in one session — and `smoke_net_four_peer_session` — 32/32, first attempt. Both `verify-multiplayer-wide` only (`workflow_dispatch` + nightly), never PR CI: four concurrent Meadows measured **12.54 GB** here against spike S2's 12.85 GB (−2.4 %) | ☐ |
| 3 | Move independently and see one another | `smoke_net_movement_two_peers` — 0.55 m in motion, 0.00 m at rest, against 4.0/1.5 m budgets | ☐ |
| 4 | Deploy and control own creatures | `smoke_net_deploy_two_creatures` — asserts authority, not just presence | ☐ |
| 5 | Shared wild encounters | `smoke_net_shared_wild_fight` | ☐ |
| 6 | First-successful-catch rule | `test_catch_arbitration` (pure, deterministic) **and `smoke_net_catch_race`** — **45 assertions, 0 failures**, green twice from a clean tree: two peers throw at one wild creature at a shared wall-clock instant, exactly one is granted, the loser is refused `already_resolving` with a sentence, and creatures owned across both peers rise by exactly the winner's own `caught` bit. The **full-belt half is still owed**: the host's roll is genuinely random and nothing can pin it over the wire, so a catch landing into five owned creatures is asserted only as an invariant a breakout satisfies vacuously | ☐ |
| 7 | A trainer encounter together | `smoke_net_boss_rewards_each_participant` — 30 checks, peer 0 challenges Bryn through `begin_trainer_battle()`, peer 1 joins in progress, the `defeat_flag` is written **once for the world** and lands on both peers, and each peer gains Bryn's authored 20 coin + 1 potion **undivided**. Passed on attempt 3; attempts 1–2 were failures of this lane's own new harness arm (findings F4, F5), not of game code | ☐ |
| 8 | A boss encounter together | **owed.** The multi-participant payout path is the same one row 7 proves, and `smoke_boss` / `smoke_gate_e_finale` / `smoke_cloudreach_finale` are green solo — but **no net smoke has ever put two pilots in the Warden fight**. Row 7's evidence is not borrowed for this row | ☐ |
| 9 | Gather without duplication | `smoke_net_pickup_race` | ☐ |
| 10 | Shared pickups | `smoke_net_pickup_race` | ☐ |
| 11 | Build and use shared structures | `smoke_net_shared_building` — includes the host-save-and-reload half | ☐ |
| 12 | Shared storage safely | `smoke_net_storage_concurrency` — one commit, loser told `stale_revision`, 20 wood before and after | ☐ |
| 13 | Trade items | `smoke_net_trade` — conservation across both peers | ☐ |
| 14 | Down / revive another player | `smoke_net_revive` | ☐ |
| 15 | Sleep and advance night | `smoke_net_sleep_vote` | ☐ |
| 16 | Menus without freezing others | `smoke_net_menu_does_not_freeze_peer` — **61 assertions, 0 failures**, green twice from a clean tree. Solo still truly pauses; in a session the tree is **not** paused (D102), the other player keeps walking, gathering through the ledger, building and jumping throughout, and the player holding the panel is stood down by `input_owner.gd` and gets the world back on close. Run with the panel on the host and on the client. **This needed a code fix**: all six panels still set `get_tree().paused = true` unconditionally and `pause_local` did not exist | ☐ |
| 17 | Ride and Fly while others act | `smoke_net_riding` — 43 assertions, 0 failures, first attempt: the rider sits **0.00 m** from the authored seat in motion and at rest, wears the saddle its owner built, and stays mounted through five rounds while peer 1 builds, drops, picks up, walks and starts its own fight. `smoke_net_fly` — 46/0, first attempt: peer 1 is airborne four rounds while peer 0 builds, drops, picks up and engages a wild, and a forged landing anchor 500 m from the host's position is refused | ☐ |
| 18 | Transition independently | `smoke_net_split_realms` — **40 checks, 0 failed**, and `smoke_cloudreach_transition` green. **The hold is lifted:** `can_enter_realm()` no longer refuses a multi-peer session, and both smokes carry their `# peers: 2` headers again. Worst held frame on a Cloudreach shell went 21,947 ms → **1,099 ms**; worst 60-physics-frame window (the number the harness actually needs) 22.8 s → **4.4 s** | ☐ |
| 19 | Different biomes simultaneously | `smoke_net_split_realms` — two players stand in two biomes at once, gather and fight in both simultaneously, then swap; plus `smoke_net_realm_owner_disconnect_mid_fight` (**23 checks, 0 failed**), where a realm's world state reaches disk when its last occupant vanishes mid-fight. **Directive rule 16 is met.** Margin note: a Meadows shell's worst window is 9.9 s against the harness's 15 s limit, held down by isolating one indivisible 7.4 s Terrain3D region load — real, but not generous | ☐ |
| 20 | Save world + portable characters | `test_world_save_format`, `test_character_save_format`, `test_legacy_slot_split_never_touches_the_original`, `test_split_key_coverage_equals_v22` and `test_save_format` run as one shard on the integrated head: **90 tests, 527 assertions, 0 failed** (2026-09-06, `--only=save_format`). Plus `smoke_net_host_join_leave`, which asserts the host wrote a world file, the client wrote none, and the client wrote exactly one character file — its own | ☐ |
| 21 | Disconnect and reconnect | `smoke_net_reconnect_keeps_character` — 23/23 checks. **Partial:** 7.A wrote it while the character save did not exist, so it asserts the session-side restore only. Lane 1.C has since written `user://characters/<id>/character.json`; re-pointing this smoke at the file is owed (see §"Known-open") | ☐ |
| 22 | Late-join a modified world | `smoke_net_late_join_modified_world` — 21/21 checks; the assertion is a **whole-world diff** of both peers' `Game.world_snapshot()`, empty, not a spot-check | ☐ |
| 23 | Host plays solo when alone | Solo **is** a one-peer session through the same funnel; every solo smoke is this row's evidence | ☐ |
| 24 | Host exits, session saves/ends | `smoke_net_host_join_leave` — asserts the host wrote its world and the client wrote none — **and `smoke_net_host_exit_saves` under load**, 27/27 checks: the host quits mid-fight and both peers' last changes read back off the autosave file | ☐ |

## §21 — reliability

| Item | Evidence | Owner |
|---|---|---|
| Latency / jitter | **RAN, and something broke.** 7.A drove three smokes through the harness UDP proxy at 150 ms delay / 30 ms jitter / 1 % loss. Two pass fully. `smoke_net_shared_wild_fight` keeps the friendly-fire **safety** but loses the refusal **message** to the striker — an early `STRIKE_SETTLE` read (finding F7). Recorded and characterised, deliberately **not** tuned | ☐ |
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
- **The v22 slot file is still written alongside the D100 split** (lane 1.C, 2026-09-06). D100
  replaces `user://saves/slot_<n>.json` with the two new files; 1.C writes the two new files and
  keeps writing the slot, because `save_game.gd::slot_path()` is read by the Gate F operator
  harness, by `tools/net/peer_runner.gd`'s desync hash (on every peer, host and client) and by
  nineteen test files. `load_slot()` still reads the slot. Retiring it is a separate change with
  its own blast radius; see `ralph/reports/MP-1C-CHARSAVE-0906/REPORT.md`.

- **`verify-multiplayer-shard` ran no net smokes at all until 2026-09-06.** Its "Discover
  peers:2 net smokes" step carried two nested count-floor `if`s with one `fi` between them —
  an unclosed `if`, so the whole step was a bash syntax error and the shard failed at discovery
  before launching a peer. Fixed with this lane's registration edit; every automated cell above
  that names a `smoke_net_*` is evidence from a local run or from a shard run after that fix,
  not from one before it. Reproduce on any earlier checkout by extracting that `run:` block and
  running `bash -n` over it.

- **A catch into a full belt is not proven over the wire.** See row 6.

- **The reconnect smoke does not yet read the character file.** `smoke_net_reconnect_keeps_character`
  was written (lane 7.A) while `user://characters/` did not exist; lane 1.C wrote it hours later on a
  parallel branch. The smoke asserts the session-side restore and says so in its own header. Pointing
  it at the file on disk is a small, named piece of work, and row 21 stays **partial** until it is done.

- **Friendly fire loses its refusal message under 150 ms jitter** — the safety holds, the sentence
  does not arrive (7.A finding F7, an early `STRIKE_SETTLE` read). Deliberately not tuned: a timing
  constant moved to make one run green is how a real ordering defect gets buried.

- **No net smoke has ever put two pilots in the Warden fight** (row 8). The payout path row 7 proves
  is shared, and that is an argument, not evidence.

## The verdict

Stage B is done when **every row above reads PASS**, solo Meadows and Cloudreach still play end to
end, and it is all on `main`. Not before, and not on the strength of the automated column alone.
