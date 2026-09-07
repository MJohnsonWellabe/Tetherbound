# CURRENT_STATE history — moved 2026-09-07

Moved verbatim from `docs/CURRENT_STATE.md` when that file was slimmed to the live
status. History only; nothing here routes current work. See `docs/CURRENT_STATE.md`.

## Stage B (multiplayer) — the CODE is complete, the OWNER EVIDENCE is not — 2026-09-06, branch `claude/tetherbound-roadmap-next-jrcjs8` @ `ad383219`

**Every one of the twenty-four §17 rows in `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` now names a
run.** That file, not this one, is the contract; read it for the per-row evidence and for the
"Known-open" list, which is where the honest limits live.

What that sentence does NOT mean, stated here because a count is the easiest thing in this project
to mistake for a verdict:

- **No row's owner column is signed.** Not one. The directive's §23 needs the owner to host a real
  LAN session, and an outside tester to host for three joiners without developer help, both
  recorded in `docs/owner/` like a playtest. No CI run can supply either, and Stage B does not
  close without them.
- **`verify-multiplayer-shard` has never completed a CI run on this branch.** It has been cancelled
  seven times — every push kills it, because `ci.yml` sets `cancel-in-progress` for any non-`main`
  ref and that job takes ~45 minutes. Every net-smoke number cited anywhere is therefore from a
  LOCAL two-process run. Those are real runs, not claims, but they are not CI evidence and should
  not be described as such until one shard run finishes.
- **None of it is on `main`.** PR #63 is open.

**Update, 2026-09-06 (later the same day): the shard finally ran to completion at `ad383219`, and
`verify-multiplayer-shard` failed** on `tests/smoke_net_realm_owner_disconnect_mid_fight.gd`, at the
exact check named in this file's own honest-limits list above: the first CI-evidenced run of these
two 6.A smokes, and the first thing it found.

Root cause: `tools/net/peer_runner.gd::_step_enter_realm()` called `Game.enter_realm()` through
`Object.call()` and read its boolean return value **without `await`**. `enter_realm()` became a
coroutine when OP-0905-20's loading-overlay change gave it `await tree.process_frame` (twice) —
before that landed, discarding or reading its return synchronously was safe, which is exactly why
`game_state.gd::enter_realm()`'s own header already warned "only a NEW caller that reads the
returned bool needs [await]." `_step_enter_realm()` was that caller and had not been updated.
Reading a suspended coroutine's return value as a `bool` is a fatal script error that aborts the
step before it reaches any `return`, which is why the coordinator logged a bare
`ERROR: peer 0 reported ERROR:` with no detail — `_execute_step()`'s `out` stayed at its default
`{}`. Both 6.A net smokes share this one step handler, so one `await` fixes both.

This also resolves an apparent contradiction with lane MP-REALM-REOPEN's own report, which recorded
both smokes green on a local run: that run predates OP-0905-20 landing on this consolidated branch,
so the interaction between the two lanes was genuinely new to `claude/tetherbound-roadmap-next-jrcjs8`
and had never been exercised together before this CI run.

**A second, separate finding surfaced in local reproduction, and partially fixed here — full
confirmation is blocked by this session's own sandbox, not yet by GitHub's runner:** rerunning
`smoke_net_realm_owner_disconnect_mid_fight` after the fix, the crossing check passes, but the run
went on to trip the harness's 15 s heartbeat-silence guard twice in a row while the host's Meadows
shell built — worst held slice 15,482 ms and 14,039 ms, both attributed to the step following
`vegetation` (`settlement`). `scripts/world/village.gd::build()` had no internal `breathe()` /
`await` at all, so its entire 25-structure construction ran as one indivisible slice inside
`playground_world.gd::_build_settlement()`'s `settlement` step — unlike every other file
`ralph/reports/MP-REALM-REOPEN-0906/REPORT.md` lists as sliced. **Fixed**: `village.gd::build()`
now takes the same `shell_build_budget.gd` slicer as `vegetation.gd` and calls `breathe()` after
each structure, following that file's own established pattern.

That fix alone did not close the gap in this sandbox (second run: still 14,039 ms). Timing each of
the 13 distinct prefab templates village.json places, in isolation with no other Godot process
running, found the true per-structure cost is small — under 1.4 s for the heaviest (`workshop`),
under 4 s total for all thirteen, cold. The ~14 s figure only appears inside the full net smoke,
which runs three concurrent Godot processes (coordinator + 2 peers) competing for this sandbox's 4
vCPUs alongside the interactive agent session itself — a load `ralph/reports/MP-REALM-REOPEN-0906/
REPORT.md`'s reference box did not carry, and a GitHub Actions runner (dedicated to the one CI job,
nothing else scheduled against it) is not expected to either. So the per-structure slicing fix
ships as a genuine, low-risk correctness improvement regardless, but the specific 14-15 s figure
reads as this sandbox's own concurrent-process contention, not a cost inherent to the world build.
Not yet re-verified against GitHub's actual runner before this note was written. If
`verify-multiplayer-shard` still reports `peer silent` on either 6.A smoke after this fix, the next
suspect is per-module resource loading inside `building_prefabs.gd::_build_template()` (each
prefab's first placement loads every module's `.gltf`/`.obj` from disk), which would need the same
`breathe()` threaded one level deeper, not a different mechanism.

**Update, 2026-09-06 (later still): `verify-multiplayer-shard` completed a real 46-minute run on
GitHub's own runner for the first time ever** (run 34049435929, commit `ac6c752e`, dispatched
manually — see below). Both 6.A smokes passed; the enter_realm and village.gd fixes above are
confirmed on real CI evidence, not just local runs. Exactly one of ~29 net smokes failed:
`smoke_net_riding.gd`, "peer 1 started a fight WHILE peer 0 rode: ... peer 1 ERROR (no verdict)".
Root cause: `race()`'s per-call deadline defaults to `step_budget_frames` (3000 frames, ~55 s
wall-clock) unless a race entry names its own `budget_frames`. Peer 1's `engage_wild` call passed
`require_record: false` — documented behavior for a CLIENT's wild fight (4.C H1: wilds are not
replicated, so the record never binds) — which makes `_step_engage_wild()` GUARANTEED, every run,
to spend its full 20 + settle(240) + bind_budget(600) = 860 physics frames before returning. That
is only ~3.5x the 3000-frame default at nominal speed, thin next to how generously this file's
own `fly`/`shared_boss` cousins budget a step whose cost is known up front. Reproduced locally
(twice: red without the fix, green with it — `smoke_net_riding: 43 assertions, 0 failures`).
**Fixed** by passing an explicit `budget_frames: 6000` on that one race entry — the clock widened,
not the claim; `_all_passed(round_five)` still requires the fight to actually start.

**Also, per owner direction after this run's 46-minute wall-clock (job 101530442523, 17:45–18:31
UTC, ~29 two-process net smokes sequential in one job): `verify-multiplayer-shard` is now a 5-way
matrix.** A new `discover-net-smokes` job holds the existing floor/roster check unchanged and
publishes the file list; the matrix shards it round-robin (`index % 5`), which happens to land the
two heaviest smokes (`realm_owner_disconnect_mid_fight`, `split_realms`) on different shards
without any hand-tuning. Surveyed all 29 net smokes for genuine duplicates first (owner's second
ask) — every one has a distinct player-visible claim tied to a distinct lane/directive item; the
closest pair, `host_join_leave` vs `host_exit_saves`, is deliberately a quiet-exit/mid-fight-exit
pair per their own headers. Nothing removed. No coverage lost, no assertion weakened, sharding and
the one real bug fixed — that is the whole change.

**Correction to the note above:** the first two pushes this session (`44cdff76`, `db75bc91`) did not
fire the `pull_request: synchronize` CI trigger, so `workflow_dispatch` (manual) was used as a
workaround, matching an earlier session's same workaround on a different branch (runs
34026997741/34021074221). The THIRD push (`fe5b3bc1`, this section's own commit) DID fire it
automatically (run 34053109567, `event: "pull_request"`, started 15 s after the push) — so the
trigger is real but unreliable/latent here, not simply broken. Manually dispatching after a push
as a safety net, and checking whether an auto-triggered run has already started before doing so
(to avoid a redundant duplicate consuming a concurrency slot), is the safer default for anyone
continuing this branch.

**One more real bug found in that same auto-triggered run** (`verify-multiplayer-shard (4)`,
job 101540419206): `tests/smoke_net_deploy_two_creatures.gd` failed to even PARSE --
`SCRIPT ERROR: Parse Error: The function signature doesn't match the parent. Parent signature is
"_proxy_for(int) -> int"`, at line 172. `tests/helpers/net_harness.gd` (the base class every net
smoke extends) already declares `_proxy_for(target_port: int) -> int` for Contract §9's udp_proxy
mechanism; `smoke_net_deploy_two_creatures.gd` independently declared its OWN unrelated helper
under the same name (`_proxy_for(bodies: Dictionary, peer_id: int) -> Dictionary`, finding a
replicated creature's proxy row) -- two lanes picked the same name for two unrelated things, and a
same-named override with a mismatched signature is a GDScript parse error, so this file has
silently contributed zero real coverage until the sharded run's shard-4 startup surfaced it as a
hard failure. This had ALSO failed the same way in the original 46-minute monolithic run
(`smoke_net_deploy_two_creatures.gd failed on attempt 1/1`, 17:50:27 UTC) -- missed in that run's
first pass here because "failed on attempt" doesn't match a `FAIL:`/`FATAL:` grep pattern; a second,
fuller sweep of that log confirmed it.

**Fixed**: the local, file-scoped helper renamed to `_creature_proxy_for` (its two call sites
updated to match); `net_harness.gd`'s own `_proxy_for` is untouched, since it is the shared base
every other net smoke also depends on. Scanned every `func` name in every `tests/smoke_net_*.gd`
file against every `func` name in `net_harness.gd` programmatically after the fix -- zero remaining
collisions across all 29 files. `godot --check-only` on the fixed file parses clean.

### What was built, in the order it will matter to a player

A person starts or loads a world from the title screen and up to three friends join by address or
off the LAN beacon (`session.gd`, `peer_registry.gd`, the Players tab). Solo is a one-peer session
through the same funnel, so there is no second implementation to rot. They see each other move
(0.55 m in motion, 0.00 m at rest, against 4.0/1.5 m budgets), deploy and pilot their own
creatures, and fight one wild together with the host arbitrating every strike and the health bar
being one number. A catch race resolves to exactly one owner and tells the loser why. They gather,
build a camp, share a chest and trade, all through `world_ledger.gd`, which answers every intent
with a delta or a refusal code a player can be shown. One goes down and the other revives them.
Menus do not freeze anybody else. Night falls when everyone sleeps. The story advances once for
the world while tutorials and fog stay personal, and a character behind the world's progress can
join it and act immediately. One player rides or flies while the others carry on. Two players stand
in two different biomes at once. A world is host-owned and a character is portable between worlds.

### The three defects worth remembering, because each was invisible in a green run

1. **`OfflineMultiplayerPeer`.** With no session, `multiplayer.is_server()` returns **true** and
   `get_unique_id()` returns **1**. Any guard shaped "am I the server, if a peer exists" is unsound
   in this engine and passes in every headless test. Ask the session (`Game.is_multi_peer()`).
2. **A green run with FEWER assertions is a compile failure passing vacuously.** A GDScript file
   that fails to parse contributes exactly one failure however many tests it holds; `int(null)` and
   `bool(null)` abort a function rather than failing it. Check a positive count, never "0 failed".
   This caught four separate false passes across the stage.
3. **A fixed-settle read of a HOST verdict is a race, not a wait.** One pattern accounted for three
   separately-recorded problems: `smoke_net_shared_wild_fight`'s 5-of-7 flake, lane 7.A's finding
   F7 (under 150 ms jitter the friendly-fire safety held but the refusal MESSAGE never arrived),
   and a latent red in `smoke_net_shared_boss`'s retry loop, whose exit condition never waited for
   the refusal it then asserted on. `pending` is the host being asked, not the host saying no.

### Two findings fixed in the game rather than the harness, at the end

- **§10's participant scaling reached nothing.** HP was never multiplied by players — that rule
  held — but the stat multiplier and attack cooldown never arrived: the scaler ran before the
  encounter record was live, read an identity multiplier and returned on its own guard. The Warden's
  creatures fought at their authored numbers while the record was stamped 1.1. No test caught it
  because every §10 test asserted on the table and on the record and none asserted the multiplier
  reached a creature. Fixed with an unscaled base kept per opponent (D112);
  `smoke_encounter_scaling` was 66 assertions / 18 failures before and 0 after.
- **The Warden's fight formed outside his room.** Recorded first as `place_on_ground` floating a
  creature; that was the symptom. The staging was leaving the arena, and the floor claim then
  answered a floor with no collider under it. `smoke_arena_contain`'s new staging case was 21
  assertions / 8 failures before and 0 after.

### Owed, and not to be quietly absorbed

- `smoke_aggression`'s flake rate is **unmeasured**. Two lanes called it flaky against untouched
  bases; the attempt to measure it produced nothing, probably eaten by the same
  `run_net_smoke.sh` `tail -f` that makes a finished run look stuck when its stdout is captured.
- Wild creature bodies are not replicated: a client's wilds drift from the host's. Lane 4.B chose
  drift over a frozen meadow and every strike resolves against host positions, which is what keeps
  it cosmetic — but two people will see creatures in different places. That is a design decision
  the owner should confirm rather than inherit.
- The v22 slot file is still written alongside the D100 split; retiring it is its own change.
