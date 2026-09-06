# Multiplayer acceptance — Stage B

**Status:** in progress. Automated column: **all 24 §17 rows now name a run** — rows 18 and 19 came
off HELD with the realm-shell fix, row 8 gained `smoke_net_shared_boss`, and row 21 is no longer
partial because it reads the character file off disk. Two caveats that matter more than the count:
row 8's evidence covers the FIGHT and not the walk to the Warden, and the §10 scaling multipliers
reach nothing on this tree (finding F1). Owner column: **nothing signed off yet, and no CI run can
sign it.** **Contract:** `docs/MULTIPLAYER_DIRECTIVE.md` §17 (the twenty-four
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
| 8 | A boss encounter together | `smoke_net_shared_boss` — **81 assertions, 0 failures, green three times consecutively from a clean tree.** Two real processes, both piloting a creature, in **`warden_aldis`**'s own fight, at his own placed body inside the stronghold. It asserts what a BOSS is different about and nothing row 7 asserts (no coin, no potion, no item receipt): the record is stamped `kind: "boss"`; both peers are participants in **ONE** record (peer 1's `bound_id` is peer 0's, and peer 1 runs no trainer battle of its own, holds no battle id and has no roster to send out) and it is still that same record after a round change; the boss's HP is **host truth** and both peers' strikes reduce the same number, equal on both to the thousandth; **never HP × players** (§10 / D-MP12) at the two moments it could fire — when the second player ARRIVES, and when the next creature is SENT OUT with two participants — against the authored value and the multiplier the smoke reads out of `data/config/multiplayer.json` itself, plus the config row named as carrying only the two allowed keys; the climax's three world flags (`defeated_warden` and the Warden's two `reward.flags`) land on **both** peers with **no** per-participant receipt, which is `world_facts()` committing them once for the world rather than once per person; and a pilot's swing at its teammate's creature is refused `friendly_target` with the sentence arriving back at the striker, the teammate and the boss both untouched over a window the boss itself did not act in. Since 2026-09-06 it also asserts §10's OTHER two clauses, which finding F1 had measured as reaching nothing and which this smoke could then only print: at two participants the live creature's attack and defence are its authored numbers × `stat_multiplier`, and the **body's own combat config** — the number the swing timer reads, not the one sitting on the instance — is its authored cooldown × `attack_cooldown_multiplier`. **Still owed on this row:** the WALK — the Warden Arena's dialogue, the machine gate and the legendary chamber stay `smoke_boss`'s solo ground | ☐ |
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
| 21 | Disconnect and reconnect | `smoke_net_reconnect_keeps_character` — **53 assertions, 0 failures, green twice from a clean tree.** Re-pointed at the FILE. A peer earns a party (through `party_seam.gd`, the opening's own door), a satchel and a **PLAYER-scoped** flag; writes `user://characters/<id>/character.json` through `Game.autosave_here()`; loses its link (`drop_link`, then the same two calls `_on_server_disconnected()` makes); has its **in-memory character blanked** with the game's own loader so the file is the only copy on the machine; and comes back by the same character id with all three restored, equal to the file key for key, satiety included — having been provably blank one step earlier. One registry row under a new ENet peer id, and the world change made while it was away arrives with the fresh snapshot. **Negative control:** the same drop and blanking, rejoining as a character id that has no file, and the peer correctly comes back empty. **This needed two code fixes** (`ralph/reports/MP-ROWS-8-21-0906/REPORT.md` findings F6, F7): `character_save.gd::apply()` had no caller — every peer wrote the file and nothing ever read one back — and `join()` never told `PlayerState` which character it was joining as, so the write and the read addressed two different names for one trainer | ☐ |
| 22 | Late-join a modified world | `smoke_net_late_join_modified_world` — 21/21 checks; the assertion is a **whole-world diff** of both peers' `Game.world_snapshot()`, empty, not a spot-check | ☐ |
| 23 | Host plays solo when alone | Solo **is** a one-peer session through the same funnel; every solo smoke is this row's evidence | ☐ |
| 24 | Host exits, session saves/ends | `smoke_net_host_join_leave` — asserts the host wrote its world and the client wrote none — **and `smoke_net_host_exit_saves` under load**, 27/27 checks: the host quits mid-fight and both peers' last changes read back off the autosave file | ☐ |

## §21 — reliability

| Item | Evidence | Owner |
|---|---|---|
| Latency / jitter | **MEASURED, and it found a second defect.** 7.A first ran three smokes through the harness UDP proxy at 150 ms delay / 30 ms jitter / 1 % loss; two passed and `shared_wild_fight` lost the friendly-fire refusal MESSAGE while the safety held (F7). Re-measured 2026-09-06 after F7's cause was fixed: the refusal now arrives, and the run failed on something F7 had been hiding — **the two peers drew different health bars, host 96.698 against guest 104.595.** The guest was not wrong, it was one round trip BEHIND, and the smoke was asserting equality within 0.001 immediately after reading the host, i.e. asserting zero latency. It now asserts CONVERGENCE and still fails with the final gap if the two never agree. Re-run under the same profile is in flight | ☐ |
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

- **Row 21's file half — CLOSED, 2026-09-06** (kept in this list because it is where the item was
  carried open). `smoke_net_reconnect_keeps_character` now reads the character
  file: the peer's in-memory character is blanked between the write and the rejoin, so the party,
  satchel and player-scoped flag that come back can only have come off
  `user://characters/<id>/character.json`, and a negative control rejoining as an unsaved id comes
  back empty. It needed two production fixes, recorded as findings F6 and F7 of
  `ralph/reports/MP-ROWS-8-21-0906/REPORT.md` (not 7.A's own F7 below, which is a different lane's
  numbering):
  `character_save.gd::apply()` had no caller at all, and `Session.join()` never stamped the joined
  `character_id` onto `PlayerState` — so `_save_character_here()` wrote the file under a freshly
  minted `peer-<pid>-<usec>` id that no later join could find.

- **`reconnect_window_s` is documented intent, not a timer** (7.A's finding, carried forward and
  still true). `multiplayer.json` says 120 s and that Wave 2 "reads this only as the documented
  intent"; the code does neither — `_on_peer_disconnected()` removes the registry row immediately, so
  the row is gone before any window could expire and `peer_registry.gd::add()`'s
  carry-the-realm-forward branch can never fire for a real disconnect. Nothing is broken for the
  player (the rejoiner re-announces its realm in its own hello) and the smoke rejoins well inside
  120 s, so it is honest under either reading.

- **Friendly fire loses its refusal message under 150 ms jitter** — the safety holds, the sentence
  does not arrive (7.A finding F7, an early `STRIKE_SETTLE` read). Deliberately not tuned: a timing
  constant moved to make one run green is how a real ordering defect gets buried.

- **§10's stat multiplier and attack cooldown reach nothing — CLOSED, 2026-09-06** (kept in this
  list because it is where the item was carried open). Row 8's own claim — *never HP × players* —
  always held; the other two thirds of §10 / D-MP12 reached no creature in any trainer or boss
  battle, because `encounter_director.gd::_scale_opponent_for_the_session()` ran at send-out,
  BEFORE the record was opened or resumed, so the first creature found no record and every later
  one found a participant list §9 had emptied at the round boundary — an identity row. Measured on
  the Warden twice (burrowback 27.750/42.550, galecrest 51.800/27.750, each exactly its authored
  number, with the record beside them saying `stat_multiplier` 1.1). Fixed by lane MP-F1-F2 and
  recorded as `docs/decisions/D112-participant-scaling-keeps-an-unscaled-base-on-the-director.md`:
  the call moved to after the record is live, and an **unscaled base is kept on the director** so a
  row that is re-derived on every join, leave and landed strike lands on `base × row` rather than
  compounding. `wild_creature.gd::refresh_combat_profile()` is the other half — the body snapshots
  its combat config when the fight opens, which is before the record exists, so the shortened
  cooldown would otherwise have reached no swing. HP is still never multiplied, and is now asserted
  at every row including the identity. Two new proofs: `tests/smoke_encounter_scaling.gd` (66
  assertions over three rounds, three participant counts, a join, eleven re-derivations and two
  leaves; 18 failures on the tree before the fix), and `smoke_net_shared_boss`, tightened from
  printing those numbers to asserting them. See `ralph/reports/MP-F1-F2-0906/REPORT.md`.

- **Two pilots in the Warden fight is proven; the WALK to him is not.** Row 8 drives `warden_aldis`
  through `begin_trainer_battle()` — the same call `stronghold_climax.gd` makes, and
  `stronghold_climax.json`'s own words are "there is no boss combat mode and there is no boss
  script". The Warden Arena's dialogue, the machine gate behind him and the legendary chamber remain
  `smoke_boss.gd`'s solo ground and no net smoke enters them.

- **Contract §7's `state_hash` could not agree once two peers held different PLAYER-scoped flags —
  CLOSED, 2026-09-06** (kept in this list because it is where the defect was recorded). `HASHED_KEYS`
  began with `progression`, which `save_game.gd` writes as the world's flags MERGED WITH the local
  player's own, so two peers with byte-identical worlds hashed differently the moment either earned a
  personal flag. `_compute_state_hash()` now sources from `Game.world_snapshot()` — contract §7's own
  promise, "from Wave 1 the hashed set is exactly `WorldState.save_data()`" — and hashes its
  world-only `flags` store. The selection is a pure static, `peer_runner.gd::hashed_subset()`, so it
  can be asserted without two processes: `tests/test_net_state_hash_scope.gd`, 6 tests / 26
  assertions, including the row itself (identical worlds, different personal progress, equal hash)
  and both halves of the control (a world flag, a building, or a different day still diverges; the
  per-process `world_seed` roll still never reaches the hash). Four of the six go red on the old key
  list. The defect went four waves unnoticed because the selection lived inside a heartbeat, inside a
  subprocess, behind a save file, where nothing could assert on it.

- **`place_on_ground` puts a creature metres above the floor inside the Warden Arena — CLOSED in
  the world, 2026-09-06** (lane MP-ROWS-8-21 finding F2; kept in this list because it is where the
  item was carried open). The cause was not the ground query: it was that the fight was being
  STAGED outside the room. `combat_manager.gd::_place_fighters()` forms the whole fight
  `deploy_offset + separation` (~7.6 m) in front of wherever the player engaged, and the Warden
  stands 5 m from his arena's back wall, so a challenge taken up beside him formed 4–5 m outside
  it, at z 7666–7668, where a sweep found **no floor collider at all** — while
  `stronghold.gd::built_floor_height_at()` still claims those metres (its margin is deliberately
  10 m). Every body was seated at the room's floor height of 6.172 and then fell ~8 m. Measured on
  the unfixed tree: the player at y −0.363 and the boss's creature at y −1.241, both outside the
  room, with the player's own creature still at 6.172 inside it. Fixed where the stronghold's own
  comment says it belongs — "containing that drift is `combat_manager.gd`'s own arena-bounds job
  and stays there": the staging is scaled back as one piece when `_arena_bounds()` says the room
  ends before it does. `_arena_bounds()` answers −1.0 for every square metre of open meadow, so a
  fight started outdoors is byte-for-byte the fight it was, and the claim margin is untouched.
  Proven by a new case in `tests/smoke_arena_contain.gd` (21 assertions; 8 failures on the unfixed
  tree, naming the 6.5 m and 7.4 m drops), which also asserts up front that the room really does
  end before the unshortened staging span reaches. The harness's `exact` placement argument is
  unchanged and still works; other smokes now use it.

- **`smoke_net_shared_wild_fight`'s flake and the 150 ms jitter failure were ONE defect — CLOSED,
  2026-09-06** (kept here because it is where both were recorded). The smoke read the host's
  friendly-fire refusal ONCE, after a fixed 15-frame settle. That refusal is the host's answer and
  it comes back over the wire, so the settle bought nothing but "probably long enough on loopback":
  hence 5 of 7 on one branch against 6 of 7 on its base, and hence 7.A's finding F7, where under
  150 ms delay / 30 ms jitter / 1 % loss the safety held but the refusal MESSAGE never arrived. It
  now polls with a budget. Measured after the fix: 3 runs, 3 passes — and **run 3 needed two polls**,
  which is the same race, caught, on loopback. Not a widened tolerance: the assertion still fails if
  the refusal never comes, comes with the wrong code, or comes without a sentence.

- **No net smoke puts a pilot into a CLOUDREACH encounter.** The roadmap's evidence bar asks for a
  "shared Cloudreach encounter" and this is the one item on that list without automated evidence.
  Verified rather than assumed: in `smoke_net_split_realms` the HOST fights, in the Meadows, while
  holding Cloudreach as a shell — the client in Cloudreach gathers and crosses but never engages.
  `smoke_net_realm_owner_disconnect_mid_fight` names the realm but submits no strike there. What is
  proven is that Cloudreach's own world mutations go through the ledger (lane 6.E) and that two
  peers occupy two biomes at once; a Cloudreach fight with two pilots in it is owed.

- **A joiner's swing depends on a spawn-table lottery, and only the smokes that know it are safe.**
  `encounter_director.gd::join_encounter()` binds a joiner to `nearest_live_wild()` — whichever
  ambient creature was closest when it joined — and because wild bodies are not replicated, how far
  that stand-in sits from the host's real opponent is decided by the seeded spawn table. Its combat
  manager then pulls its creature toward the stand-in, so a swing aimed at the host's opponent
  misses. Recorded first as lane MP-ROWS-8-21's finding F10 and fixed there in
  `smoke_net_shared_boss`; `smoke_net_shared_wild_fight` predated the arm and was measured failing
  one run in three under 150 ms jitter (`104.5 -> 104.5 on the host`, while peer 0 landed
  immediately). Both smokes now seat the joiner's local stand-in on the host's opponent before
  swinging, which changes no outcome — protocol §2 resolves every strike against host positions —
  and is what wild replication will do for free when it lands. **The underlying binding is
  unchanged**: any future smoke that has a joiner swing needs the same arm, or the same lottery.

## The verdict

Stage B is done when **every row above reads PASS**, solo Meadows and Cloudreach still play end to
end, and it is all on `main`. Not before, and not on the strength of the automated column alone.
