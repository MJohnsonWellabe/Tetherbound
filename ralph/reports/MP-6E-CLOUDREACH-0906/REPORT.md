# MP-6E-CLOUDREACH — the world mutations that were still writing directly

**Lane:** Stage B Wave 6, lane **6.E** (Cloudreach runtimes, farming, camps).
**Branch:** `claude/mp-6e-cloudreach`, from `claude/tetherbound-roadmap-next-jrcjs8`
at **`6c5189fb`** ("6.A's two smokes never opened the road to Cloudreach"). Not
rebased mid-run.
**Engine:** Godot **4.7.stable.official.5b4e0cb0f**, installed headless at
`~/godot-bin/godot`; `--headless --path . --import` run twice before anything else.

**One sentence.** Cloudreach's chapter progression — every act completion, every
captain's defeat, every storm anchor going dark, ~100 world flags in all — was a
local `set_flag` on whichever peer ran the code and reached nobody else; it now
submits an intent the host commits, and so do the three flags the physical
runtime wrote itself, the summit relays, and the payout half of a farm bed.

---

## 0. The single most important number in this report

The `verify-multiplayer-shard` job **has not run since a merge before this lane's
base commit**. Its "Discover peers:2 net smokes" step is a *bash syntax error*:
two `if [ "$count" -lt 20 ]` blocks share one `fi`. `bash -n` over the extracted
`run:` script says `line 97: syntax error: unexpected end of file`. That is F1
below; it is fixed here, because registering a smoke means editing that block
anyway. **Every lane that believes its net smoke is gated by CI should re-read
that step.**

---

## 1. THE AUDIT — every direct world mutation in `scripts/`

Method: `grep` across `scripts/` for each write surface `WorldState` exposes —
`set_flag` on any store, `set_farm_plot`, `register_building`,
`register_death_satchel`, `placed_buildings`/`harvested_vegetation`/
`felled_vegetation` assignment, and `advance_day` — then each hit classified
against `data/progression/flag_scopes.json` (world vs player) and against the
lane roster. **Player-scope writes are not defects**: a personal tutorial beat or
a saddle receipt is one trainer's fact and belongs in that peer's own store
(D99). Only a **world** write that never crosses the wire is a divergence.

### 1a. Converted by this lane

| # | Writer | What it wrote | Verdict |
|---|--------|---------------|---------|
| 1 | `realm_chapter_progression.gd::_set_flag` (via `realm_chapter_events.gd`, `cloudreach_chapter.gd`) | Every Cloudreach act, objective, count and side-chain flag — ~100 **world** ids | **CONVERTED** → `set_world_flag` / `grant_player_flag`, realm `"cloudreach"` |
| 2 | `cloudreach_physical_runtime.gd::activate` | `set_physical_flag` (the three shrine vanes) — **world** | **CONVERTED** → `set_world_flag`; the repair cost now settles on the delta |
| 3 | `cloudreach_physical_runtime.gd::encounter_won` | `defeat_flag` — **world** | **CONVERTED** → `set_world_flag` |
| 4 | `cloudreach_physical_runtime.gd::encounter_won` | `cloudreach_payout:<id>` — **player** receipt, previously invisible to the ledger | **CONVERTED** → `grant_player_flag` |
| 5 | `cloudreach_finale_controller.gd::disable_relay` | `relays[].flag_id` — **world** | **CONVERTED** → `set_world_flag` |
| 6 | `farm_plot.gd::_harvest` | the crop payout + the bed's record | **PARTLY CONVERTED** → `harvest` intent on `farm:<realm>:<index>#<ripe_on_day>`; the bed's record is mirrored off the delta. Residual in 1c |

### 1b. Audited, correct as they stand — no conversion needed

| Writer | Why it is not a gap |
|--------|---------------------|
| `rest_point.gd` | **Writes nothing at all.** Its rest verb is `night_rest.gd::rest()` (lane 5.D's sleep vote), its craft prompt opens a panel, and its authored creature bed calls `build_real(false)`, which deliberately does *not* set the objective flag. The lane brief named this file; the audit's answer is that there is nothing here to convert. |
| `home_progress.gd` | **Already converted** (lane 5.A). `_grant()` submits `grant_player_flag` through `story_ledger.gd` and only falls back locally when there is no transport. Re-read line by line, not taken on trust. |
| `night_rest.gd:179` | `player_slept_at_home` is **player** scope and every peer runs its own night (5.D's design). Correct as a local write. |
| `night_rest.gd:410,422` | `peer_registry.set_flag(peer, "sleeping", …)` is the replicated peer row, not a world flag. Different API, same name. |
| `sequence_director.gd:508` | `opening:beat:<x>` is **player** scope — 5.A's rule is that the opening's *gates* stand down while its *beats* stay personal. |
| `sequence_director.gd:773` | Already the `offline`-only fallback under 5.A's `story_ledger` submission. |
| `realm_gate.gd:121` | Already the `offline`-only fallback under 5.A's `set_world_flag`. |
| `alpha_pins.gd:257` | `alpha_pin_intro_seen` is **player** scope ("I have seen this explained once"). `alpha_pins.gd` already reads `wild_once_` off the **world** store explicitly. |
| `swap_panel.gd:451` | `oskar_swap_taken_` is **player** scope. Also a modal panel — the owed-smokes lane. |
| `riding_controller.gd:635` | `saddle_fitted_` is **player** scope; the file is lane 6.B/6.C's. |
| `tournament.gd:550–572` | All four `tournament_*_ready`/`_fed` ids are **player** scope readiness checks, recomputed from this player's own party. |
| `item_gate.gd:69` | Writes a **world** gate flag — but `try_open()` **has no live caller**. `gated_crossing.gd:410` and `road_gate.gd:510` both say in comments that they deliberately do *not* use it. Dead write path; recorded rather than converted. |
| `vegetation.gd:2076–2077` | `sync_state_to_game` mirrors the live bitset into `Game` immediately before a save. Lane 3.B already converted the *decision* (`deplete_vegetation` intent, `veg_deplete` scene op); this is the save seam, and lane 1.C owns it. |
| `player_death.gd:186` | `register_death_satchel` — converted by lane 3.C (owner + explicit realm). |
| `world_look.gd:211`, `night_rest.gd:157,403` | `advance_day()` — already host-gated inside `Game.advance_day()` (D105, lane 2.A). |

### 1c. **UNCONVERTED — the known gaps, written down**

These are real. Each one is a place two players can still disagree.

| # | Writer | Scope | Why not converted here |
|---|--------|-------|------------------------|
| G1 | `farm_plot.gd::_till`, `::_sow`, and the bed record in `::_harvest` | world (`WorldState.farm_plots`) | **There is no ledger op for a farm plot.** `world_ledger.gd` has no `set_farm_plot` intent and `WorldState._apply_op` has no `farm_set` case — and both files are explicitly outside this lane. See §4 for the exact patch. Mitigated but not closed: the *payout* is arbitrated, and every peer returns the bed to worked soil off the committed delta, so the visible state converges after a pick. Till and sow remain local-only. |
| G2 | `meadow_healing.gd:441` (`_open_the_barriers`) | **world** (`road_gate_open`, `hall_approach_open`) | Meadows post-Warden world response. No lane owns it; it is not Cloudreach, farming, camps or rest. A client that beats the Warden opens its own gates and nobody else's. **Real divergence, unowned.** |
| G3 | `burrow_warrens.gd:2943` (vault prize flag), `:3345` (`warrens_cleared`) | **world** | Meadows Warrens. No lane owns it. Same shape as G2. |
| G4 | `stronghold_climax.gd:1036` (`_set_flag` → `legendary_freed`, `legendary_settled`) | **world** | Meadows finale. No lane owns it. (`_set_player_flag` at :1053 is already correct — `legendary_joined` is the belt owner's fact.) |
| G5 | `encounter_director.gd:2193` (`wild_once_<order>`), `:3582` (`defeat_flag`), `:3588` (trainer reward flags) | **world** | `scripts/combat/*` is lane 4.C/4.D's. `_record_trainer_defeat_for_the_session()` at :3576 suggests the session path exists and this is its fallback — worth 4.D confirming rather than 6.E guessing. |
| G6 | `creature_bed.gd:420` (`creature_bed_built`) | player, **shared** (D99 residual) | A bed built by a client grants the flag to that peer only; `home_progress.gd::maybe_set_creature_beds` grants the *ladder* through the ledger but this direct write beats it to the first rung. Small, and `build_placer.gd` (3.C) calls the converted path too, so the observable effect is one peer's flag arriving early rather than a divergence. Recorded, not fixed — the file is lane 3.C/5.D-adjacent. |

**Camps and home progress:** the brief asked for "the camp/home progress". The
audit's answer is that there is nothing left there — `home_progress.gd` is
lane 5.A's converted file (1b), `camp_tent.gd`/`campfire.gd`/`player_bed.gd` write
no world state of their own (they are `build_placer.gd` records, converted by
3.C), and `rest_point.gd` writes nothing. G6 is the only camp-shaped residue.

---

## 2. What changed, file by file

| File | Why |
|---|---|
| `scripts/world/realm_chapter_progression.gd` | `dispatch()`/`reconcile()`/`_complete()`/`_set_flag()` take an optional `writer: Callable(flag) -> verdict`. With one, a flag is an intent; without one (a unit fixture — this file is pure and node-free by D02) it is the same local write it always was. The result dictionary gained `pending`, merged like `changed`. |
| `scripts/world/realm_chapter_events.gd` | Supplies the writer. `_write_flag()` chooses `set_world_flag` vs `grant_player_flag` by `progression_state.scope_of()` and stamps **`realm_id`**, never `Game.current_realm`. New `reconcile_now()` so there is exactly one place that knows a chapter flag is an intent. |
| `scripts/world/cloudreach_chapter.gd` | Its two direct `CHAPTER_LOGIC.reconcile()` calls now go through the adapter (`_reconcile()`); `_inspect_anchor` says nothing on `pending` rather than reporting a count that has not committed. |
| `scripts/world/cloudreach_physical_runtime.gd` | Three flag writes converted; `activate()` restructured so the repair cost, the message and `interaction_completed` are a `_settle_interaction()` that runs on commit — immediately on host/solo, on the delta on a client. Landing objectives and the flight trial got the same treatment, with the bond eligibility captured at landing time (`_fly_bond_eligible()`), because a round trip later `_fly` has forgotten which creature carried the flight. |
| `scripts/world/cloudreach_finale_controller.gd` | The relay flag is a `set_world_flag` intent stamped `"cloudreach"`. |
| `scripts/world/farm_plot.gd` | Picking is a `harvest` intent on a per-crop-cycle claim id. New `harvest_refused` signal (the host's own refusal has no other surface — `intent_refused` only fires for the peer a `_rpc_verdict` was addressed to). `setup()` gained an explicit `realm_id`. |
| `scripts/world/playground_world.gd` | One line: the bed's realm comes from `world_realm()`, the world that placed it. |
| `data/progression/flag_scopes.json` | `farm:` added to the **world** prefixes, beside lane 3.B's `vegetation:` and `felled:`. An unscoped id is a `push_error`. |
| `tools/net/peer_runner.gd` | Two arms (`farm_stand`, `farm_pick`) and one probe (`farm`). The bed, the prompt press and the intent are all shipping code; the arm only plants the crop and holds the press until the shared instant. |
| `tests/smoke_net_farm_race.gd` (+ `.uid`) | The new net smoke. |
| `.github/workflows/ci.yml` | F1's syntax error fixed; count floor **regenerated from the files on disk** (21, not "20+1"); `tests/smoke_net_farm_race.gd` added to the named roster. |

**Not touched, as instructed:** `autoload/game_state.gd`, `autoload/world_state.gd`,
`scripts/net/world_ledger.gd`, `scripts/net/ledger_rpc.gd`, `scripts/net/session.gd`,
`scripts/save/*`, `riding_controller.gd`, `fly_controller.gd`,
`tests/helpers/net_harness.gd`, the six modal panels.

---

## 3. The shape, and the traps it was written around

1. **Solo is not a second path.** Solo *is* the host: `submit()` commits
   in-process and emits the delta *before it returns*. `smoke_playground`'s berry
   farm section is the proof — `after pick: +4 berries, state=tilled`, exactly
   what it printed before this lane.
2. **`pending` is not a refusal.** Nothing local moves on it: no cost spent, no
   crop, no tool wear, no message, no signal. A lost race then looks like the
   thing simply staying put, which is the correct picture.
3. **The delta drives the visible change, and the delta is checked FIRST.**
   Every settle handler here asks "does *this delta* carry the flag" before it
   asks "did I have a claim out". Written the other way round —
   `if _taken: return` — the winner's own feedback is dropped **on clients only**,
   because `ledger_rpc.gd::_rpc_delta` sweeps the `progression_restore` group
   *before* it emits `delta_applied`. Lane 3.B paid for that ordering; it is
   restated in each handler's own comment so the next reader does not re-pay it.
4. **D97: every intent carries an explicit realm, and none of them is
   `Game.current_realm`.** `realm_chapter_events` stamps its own `realm_id`;
   `cloudreach_physical_runtime` and `cloudreach_finale_controller` stamp the
   const `REALM_ID = "cloudreach"`; a farm bed stamps the realm of the world that
   placed it. This is why `story_ledger.gd::write_flag()` is **not** used here
   despite doing the same scope routing: its `realm_of()` reads
   `Game.current_realm`, which is right for a dialogue line the local player is
   having and wrong for a record.
5. **`OfflineMultiplayerPeer` is never asked anything.** Nothing added here reads
   `multiplayer.is_server()` or `get_unique_id()`; host-ness is `Game.is_host()`
   inside `ledger_rpc.submit()`, which is the session's answer.

---

## 4. G1 in full: the farm op that does not exist

For whoever owns `world_ledger.gd`/`world_state.gd` next. Two additions close it:

```gdscript
# scripts/net/world_ledger.gd — commit()'s match, plus:
func _set_farm_plot(intent: Dictionary, peer_id: int, realm: String) -> Dictionary:
    var index := int(intent.get("index", -1))
    if index < 0:
        return _refuse("set_farm_plot", peer_id, "malformed", "That bed has no identity to record.")
    return _commit([{"op": "farm_set", "scope": "world", "realm": realm,
        "index": index, "plot": intent.get("plot", {})}], "set_farm_plot", peer_id, realm)

# autoload/world_state.gd — _apply_op()'s match, plus:
        "farm_set":
            set_farm_plot(int(op.get("index", -1)), op.get("plot", {}) as Dictionary)
            return true
```

`farm_plot.gd`'s `_till`/`_sow` then submit instead of calling
`game.set_farm_plot`, and `_on_delta_applied` grows a `farm_set` branch beside its
claim branch. The `harvest` claim this lane added stays: it is what stops two
peers being paid for one crop, which `farm_set` alone would not.

Two design notes for that lane:

* **The realm must be on the op** — `farm_plots` is indexed by position in
  `data/config/farm.json`, so a Cloudreach farm would collide with the Meadows one
  at index 0 the day one exists. Today the array is realm-blind; that is a latent
  bug, not a new one.
* **Sowing should be `first-writer-wins`, not last.** Two peers sowing one bed in
  the same tick should produce one crop with one ripening day; a plain
  last-write-wins `farm_set` silently costs the loser a seed.

---

## 5. Commands run, and their counts

Every command below was run on this box against this branch.

| Command | Result |
|---|---|
| `~/godot-bin/godot --headless --path . --import` (×2) | clean, exit 0 both times |
| `--headless --check-only --script` on each changed script (8 files) | all clean |
| `run_tests.gd -- --only=test_realm_chapter_progression.gd` | **8 tests, 115 assertions, 0 failed** |
| `run_tests.gd -- --only=test_farming.gd` | **23 tests, 160 assertions, 0 failed** |
| `run_tests.gd -- --only=test_cloudreach_physical_runtime.gd` | **6 tests, 547 assertions, 0 failed** |
| `run_tests.gd -- --only=test_cloudreach_finale.gd` | **4 tests, 76 assertions, 0 failed** |
| `run_tests.gd -- --only=test_flag_scopes.gd` | **11 tests, 241 assertions, 0 failed** |
| `run_tests.gd -- --only=test_home_progress.gd` | **10 tests, 14 assertions, 0 failed** |
| `run_tests.gd -- --only=test_cloudreach_chapter_data.gd` | **16 tests, 1848 assertions, 0 failed** |
| `run_tests.gd -- --only=test_cloudreach_cast_dialogue.gd` | **8 tests, 956 assertions, 0 failed** |
| `run_tests.gd -- --only=world_ledger` | **24 tests, 136 assertions, 0 failed** |
| `tests/smoke_playground.gd` | **`smoke: OK`** — berry farm section: `beds placed: 6`, `after till: state=tilled hoe durability 40 -> 39`, `after sow: state=sown`, `after pick: +4 berries, state=tilled` |
| `tools/net/run_net_smoke.sh farm_race` | **ALL CHECKS PASSED, 28 checks, first run** — run dir `/tmp/net-farm_race-20260906T104632Z`, both peers `unexpected_exit=false` |
| `bash -n` over the extracted `Discover peers:2` script | **syntax error before**, **OK after** |

Every assertion count above is the suite's own reported number, not a claim about
how many `assert_*` lines the file contains. No test in this lane was retried.

### Solo regression smokes named in the brief

| Smoke | Result |
|---|---|
| `smoke_playground` | **`smoke: OK`**, first run, exit 0 |
| `smoke_cloudreach_arrival_walk` | **`CLOUDREACH ARRIVAL WALK OK`**, first run, exit 0 |
| `smoke_cloudreach_transition` | **`CLOUDREACH TRANSITION OK meadows -> cloudreach -> meadows`**, first run, exit 0 |
| farming smoke | none exists as a separate file; farming is covered inside `smoke_playground`'s "berry farm" section (above) and by `test_farming.gd` |

Nothing was retried. No run in this lane went red and then green.

`smoke_cloudreach_arrival_walk` prints one non-fatal warning —
`Cloudreach physical placement needs a surface: cr_candy_broken_route_good_07
(-88.9, 465.4, 2335.0)`, from `_resolve` inside `_sync_pickups_and_camps`. That
code path is **not touched by this lane** and the smoke reports OK. It is stated
here rather than omitted, and honestly: **I did not bisect it against the base
commit**, so "pre-existing" is an inference from the diff, not a measurement.

---

## 6. The net smoke, in its own words

`tools/net/run_net_smoke.sh farm_race`, one run, **28 checks, all PASS**, both
peers alive at the end. The interesting lines:

```
PASS: SETUP: both peers name the same crop cycle ('farm:meadows:90#1' / 'farm:meadows:90#1')
the berries in the world before the race: 0 (peer 0: 0, peer 1: 0)
peer 0 farm: { "claimed": true, "press": "submitted", "refusals": [], "satchel": { "berries": 3.0 }, "state": "tilled" }
peer 1 farm: { "claimed": true, "press": "submitted",
               "refusals": [{ "code": "already_taken", "reason": "Someone else already gathered that." }],
               "satchel": {  }, "state": "tilled" }
PASS: exactly one crop was picked: 0 berries before, 3 after (peer 0: 0 -> 3, peer 1: 0 -> 0)
peer 1 lost by shape A: refused `already_taken` -- 'Someone else already gathered that.'
```

The run produced **shape A** — both intents in flight before either delta landed,
which is the interleaving the shared press deadline exists to create and the one
that actually exercises the host's arbitration. Both peers' beds went back to
`tilled` off the delta, which is the mirror this lane added; on `main` peer 1
would have been paid three berries as well.

**One cosmetic note, so the log is not misread.** The post-race probe prints
`"flag": "farm:meadows:90#0"` on both peers, not `#1`. That is correct: after the
pick the bed is `{state: tilled, ripe_on_day: 0}`, and `claim_flag()` is computed
from the bed's CURRENT cycle. The assertion that matters — that both peers named
the same crop — is made **before** the race, where both read `#1`.

**What this smoke does NOT cover:** the Cloudreach chapter conversion, which is
the lane's largest. See H1.

---

## 7. Findings

**F1 — `verify-multiplayer-shard` has been dead since a merge before this base.**
Two `if [ "$count" -lt 20 ]` blocks, one `fi`. `bash -n` over the extracted
`run:` script: `line 97: syntax error: unexpected end of file`. With
`set -uo pipefail` and no `-e`, bash parses the whole script before running any
of it, so the step fails outright and no peer smoke runs. **Reproduction:**
extract the `run:` body of the "Discover peers:2 net smokes" step at
`6c5189fb:.github/workflows/ci.yml` and run `bash -n` on it. Fixed here. The
count floor is now **21**, regenerated with the loop the block's own comment
prescribes, not incremented.

**F2 — the ledger has no farm op, and the two files that would carry one are off
every Wave-6 lane's list.** G1 above; patch in §4. This is not a defect anybody
introduced — `farm_plots` predates D103 and simply was not in any converting
lane's file set. It needs to be *assigned*.

**F3 — three unowned Meadows world writers.** G2 (`meadow_healing.gd`), G3
(`burrow_warrens.gd`), G4 (`stronghold_climax.gd`). Each writes a world flag
locally, each is the kind of "a gate opened / a boss fell / the machine is dead"
fact D99 classifies as world, and none of them is in any lane's file list that I
can find in `ralph/reports/MP-*`. **Reproduction for G2:** two peers in a session,
the client beats the Warden; `meadow_healing._open_the_barriers()` sets
`road_gate_open` in the *client's* `WorldState.flags`; the host's road gate stays
shut and the host's save records it shut. Not fixed here — other lanes' territory,
and the brief says a defect elsewhere is a finding with a reproduction.

**F4 — `cloudreach_payout:` receipts were invisible to everything.** They are
player-scope, so before this lane they went to `Game.local.flags` and stayed
there. That is *nearly* right — a payout receipt is personal — but it means a
peer that reconnects re-earns the payout, because nothing durable on the host
remembers it was paid. Converted to `grant_player_flag` here, which puts the
grant in the host's committed stream; the deeper question of whether a reward
receipt should be world-scope (`reward_grant`'s `reward:<source>:<peer>` shape,
D106) belongs to lane 4.D and is **not** decided here.

**F5 — `realm_chapter_progression.gd`'s result dictionary gained a key.** Callers
that construct the same shape by hand (`cloudreach_chapter.gd::_emit_event`'s
null-adapter fallback, `realm_chapter_events.gd`'s two early returns) were
updated. A caller elsewhere that builds `{"accepted", "changed", "completed_ids",
"granted_flags"}` literally will read `pending` as absent, which `bool(null)`
makes `false` — the safe answer. No such caller was found.

---

## 8. Handovers

**H1 — a Cloudreach net smoke is still owed.** The lane's largest conversion (the
chapter flags) is proved by unit tests and by reading, not across two processes.
The reason is measured, not an excuse: a two-peer Cloudreach smoke needs *four*
Meadows-class world builds in one run (each peer boots the Meadows then
`enter_realm`s Cloudreach), and lane 6.A shipped exactly that shape twice and
could not run either one. The one this lane shipped costs two builds and was run
locally. **When it is written it must grant `realm_key_cloudreach` explicitly and
say in the check text that the grant is SETUP** — 6.A's smokes did not, and their
failure read as "enter_realm refused" when the truth was "nobody had the key".

**H2 — G1 (the farm op) needs an owner.** §4 has the patch and two design notes.

**H3 — F3's three Meadows writers need an owner.** They are not Wave 6 work and
they are not in any lane roster I could find.

**H4 — the repair-cost settle is exercised only on the host/solo path here.**
`cloudreach_physical_runtime::_settle_interaction` runs out of
`_on_delta_applied` on a client, and that branch has no automated coverage: it
needs the Cloudreach net smoke of H1. The ordering it depends on
(`sets_world_flag(delta, completion)` checked before the local ticket) is the one
lane 3.B measured, and is asserted in the pickup path by
`smoke_net_pickup_race.gd`.

**H5 — `_pending_interactions` is not persisted.** A client that presses a repair
and quits before the delta lands loses the cost-spend (it keeps its materials and
the world keeps the repair). That is the safe direction — the player is not
charged for something they did not see finish — but it is a real asymmetry and it
is written down rather than hidden.
