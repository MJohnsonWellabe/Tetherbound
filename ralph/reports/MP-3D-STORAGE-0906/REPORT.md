# Lane 3.D — shared storage through the ledger

Branch `claude/mp-3d-storage`, based on `claude/tetherbound-roadmap-next-jrcjs8` @ `fbc2a8b1`.
Contract: D103. Godot 4.7-stable installed into `~/godot-bin/godot` in this container
(`4.7.stable.official.5b4e0cb0f`); `--import` run twice before anything else, clean both times.

**Deliverable: two players share a chest, and neither can silently overwrite the other.** Done.

---

## Verdicts, one line per item

| # | Item | Verdict |
|---|---|---|
| 1 | Deposits/withdrawals stop writing container state directly and submit a `storage_txn` intent | **PASS** — `storage_container.gd::_submit()`; `storage_panel.gd` no longer calls `state.deposit()`/`state.withdraw()` at all |
| 2 | Every intent carries an `expected_revision` | **PASS** — read with `WorldLedger.storage_revision(container)` and quoted back |
| 3 | Revisions are session-scoped, read not invented, never persisted | **PASS** — no counter of my own anywhere; `_storage_revision()` reads the live `WorldLedger` and returns 0 when the transport has no ledger yet, which is the same thing a fresh ledger says |
| 4 | A stale write is refused with `stale_revision` and one actionable sentence | **PASS** — net smoke prints the host's refusal verbatim: `Someone else changed that container -- close it and look again.` |
| 5 | The refusal is shown in the storage panel, not swallowed | **PASS** — new message row under the panel title, fed by `storage_refused` (client) and by the synchronous verdict (host/solo) |
| 6 | Solo behaves exactly as it does today; no second code path | **PASS** — solo *is* the host: one `_submit()`, one `submit()`, one apply. Evidence below |
| 7 | On `{"ok": false, "pending": true}` nothing changes locally | **PASS** — `_pending` is recorded and nothing else happens; the panel shows "Waiting for the world to accept that…" and no moved items |
| 8 | The panel never shows a deposit that has not committed | **PASS** — rows are redrawn only from `storage_changed` (a delta) or from an `ok` verdict |
| 9 | Inventory addressed by item identity, never slot number | **PASS** — every path is `count`/`add`/`remove`/`stack_at(i).id`; `set_slot` is used only to *copy* an inventory slot-for-slot, which is `save_data()`'s existing contract |
| 10 | Explicit `realm` (D97); `Game.current_realm` never read | **PASS** — `realm()` reads the node's own `realm` metadata, which `build_placer.gd` stamps from the record |
| 11 | One new net smoke, registered in CI | **PASS** — `tests/smoke_net_storage_concurrency.gd`, ALL CHECKS PASSED first run |
| 12 | Judgement on `static var _panel` | **Not a hazard now** — see finding F4 |

---

## Files

Owned and changed:

- `scripts/world/storage_state.gd` — added `preview_deposit()` / `preview_withdraw()`: what the chest *would* hold, computed on throwaway copies, changing neither side. `deposit()`/`withdraw()` are untouched (`death_satchel.gd` and `tests/test_storage.gd` still use them).
- `scripts/build/storage_container.gd` — owns the ledger conversation: `submit_deposit`/`submit_withdraw`, `container_key()`, the `delta_applied`/`intent_refused` handlers, and two signals (`storage_changed`, `storage_refused`) for the panel.
- `scripts/ui/storage_panel.gd` — draws; no longer writes. Message row for refusals.

Also changed (not in the forbidden list, but shared — flagged for the merge):

- `tools/net/peer_runner.gd` — four harness arms (`storage_place`, `storage_bind`, `storage_grant`, `storage_transfer`) and two probes (`storage`, `placed_building_count`). They stand in for the panel's presses only; the ledger, the intent, the container and the delta are all shipping code.
- `tests/smoke_net_storage_concurrency.gd` (new) + `.uid`
- `tests/test_storage.gd` — four unit tests for the new preview functions.
- `.github/workflows/ci.yml` — `verify-multiplayer-shard`.

Not touched, as instructed: `autoload/game_state.gd`, `scripts/net/*`, `autoload/world_state.gd`,
`build_placer.gd`, `player_death.gd`, `death_satchel.gd`, `item_cache_pickup.gd`,
`harvest_node.gd`, `vegetation.gd`.

---

## Design, in one paragraph

A press calls `preview_*` on the chest — no mutation — and submits
`{"kind": "storage_txn", "realm", "container", "index", "expected_revision", "state"}`.
`container` is `storage:<realm>:<placed_index>`, derived on every peer from the same
`placed_buildings` record, so two processes name the chest identically without exchanging an
id. The committed contents come back as a `storage_set` op and are loaded onto the live chest
by `_on_delta_applied` — on the host and on every client, through the same lines. The
player's own satchel half is applied by `_settle()`, because `storage_txn` deliberately
carries no player ops (the host cannot see a client's satchel): synchronously on the host,
and on a client only when the delta that matches its pending write lands.

---

## Commands run, and their counts

Godot install and import (twice, as instructed):

```
curl … Godot_v4.7-stable_linux.x86_64.zip  →  ~/godot-bin/godot   (4.7.stable.official.5b4e0cb0f)
godot --headless --path . --import          ×2, no SCRIPT ERROR / Parse Error / Failed to load
```

`--check-only`, every changed `.gd` — all clean:

```
godot --headless --path . --check-only --script scripts/world/storage_state.gd            clean
godot --headless --path . --check-only --script scripts/build/storage_container.gd        clean
godot --headless --path . --check-only --script scripts/ui/storage_panel.gd               clean
godot --headless --path . --check-only --script tools/net/peer_runner.gd                  clean
godot --headless --path . --check-only --script tests/smoke_net_storage_concurrency.gd    clean
godot --headless --path . --check-only --script tests/test_storage.gd                     clean
```

"Clean" was itself checked rather than assumed: the same command on a deliberately broken
throwaway script printed `SCRIPT ERROR: Parse Error: …`, so silence means silence.

Unit tests:

```
godot --headless --path . --script tests/run_tests.gd -- --only=world_ledger
    19 tests, 87 assertions, 0 failed      (baseline before any change: identical)
godot --headless --path . --script tests/run_tests.gd -- --only=storage
    15 tests, 112 assertions, 0 failed     (was 11 tests / 98 assertions; +4 preview tests)
```

Smokes:

```
godot --headless --path . --script tests/smoke_playground.gd
    smoke: OK
godot --headless --path . --script tests/smoke_station_panels_hide_world_hud.gd
    PASS: every station panel hides both world HUD layers and gives them back
    (the existing storage smoke by name — it opens storage_panel.gd)
tools/net/run_net_smoke.sh storage_concurrency --out=/tmp/net-local
    ALL CHECKS PASSED   (45 checks, 2 peers, no unexpected peer exit)
```

The panel smoke failed once on the way here and was right to: it opens `storage_panel.gd`
against a bare stand-in node, and the first version of `_connect_chest()` called
`is_connected` on a node with no such signal. Fixed with a `has_signal` guard rather than by
changing the smoke.

No full sweep, no re-run of a pass, no chasing of exit-time `ObjectDB instances were leaked`
notices.

### What the net smoke actually proved

Two peers, one host, one joiner, both standing a real chest on record `storage:meadows:0`,
both holding 10 wood, both pressing "store 5" **from revision 0**:

```
peer 1 pressed store (deposit 5 wood: ok=false pending=true  code='pending')
peer 0 pressed store (deposit 5 wood: ok=false pending=false code='stale_revision')
peer 0 storage: chest {wood: 5} record {wood: 5} satchel {wood: 10} revision 1
                last: stale_revision "Someone else changed that container -- close it and look again."
peer 1 storage: chest {wood: 5} record {wood: 5} satchel {wood:  5} revision 1
```

- exactly one commit (chest 5, not 10; revision 1, not 2), on both peers and in the world record;
- the loser was told, in a sentence, with the `stale_revision` code;
- 20 wood before, 20 wood after — nothing duplicated, nothing destroyed;
- the loser then pressed again with a live revision read and it landed (chest 10, satchel 5),
  so a refusal is a "look again", not a lockout.

The client won this run. Which peer wins is genuinely packet order and the smoke asserts the
invariant, not the winner.

**Why the revision is pinned in the smoke.** `storage_transfer` takes the revision the presser
was looking at, exactly as the panel hands the container the row the player pressed. Left to
wire timing the race cannot be constructed at all: the coordinator's TCP round trip is slower
than the loopback ENet hop, so whichever peer is told to press second has already seen the
first one's delta, both writes serialise, and the smoke would pass without asserting anything.
Pinning both peers to revision 0 reproduces the interleaving two players hit by pressing within
one round trip of each other. That is why `submit_deposit`/`submit_withdraw` take an optional
`expected_revision` (default `-1` = read it now, which is what the panel and every solo press
use): quoting the revision you actually saw is the correct optimistic-concurrency contract, not
a test hook bolted on.

### Evidence that solo is unchanged

There is no solo branch to regress: `submit()` on a host commits in-process and emits the
delta before it returns, and `Game.is_host()` is true solo (`game_state.gd`: no session ⇒
host). The host half of that path is exercised end to end by the net smoke's retry
(`ok=true`, chest 5→10, satchel 10→5, world record in step). `tests/smoke_playground.gd`
still prints `smoke: OK`, and `test_storage.gd`'s original eleven tests are untouched and
green.

---

## Findings

**F1 — a `storage_set` delta carries no submitter, so a client cannot always tell "my write
committed" from "an identical write committed".** `world_ledger.gd::_storage_txn` builds the
op from `{op, scope, realm, container, index, state, revision}` — no `txn_id`, no `by`. A
client's `submit()` returns only `pending`, and the host sends a verdict *only* on refusal, so
the sole positive signal a client has is the arriving delta. `_resolve_pending()` matches it
by `revision == expected + 1` **and** identical committed contents. That is exact unless two
peers deposit the same item and the same count from the same revision, when the two candidate
states are byte-identical and the loser would settle as if it had won — its items would simply
cease to exist.

*Mitigated here, not left open:* the host still sends the loser a refusal, which is
unambiguous and peer-targeted. A `storage_txn` refusal that arrives on an already-settled
write now puts the satchel back (`_on_intent_refused`, `_settled`). Both arrival orders are
therefore correct: refusal-then-delta drops the pending write untouched, delta-then-refusal
settles and then undoes.

*Handover to lane 3.A — the clean fix is two lines in a file I must not touch:* pass
`intent.txn_id` through into the `storage_set` op. `WorldLedger.apply()` already records
op-level `txn_id`s in `_seen_txns`, so this also buys `storage_txn` the replay guard
`transfer_item`/`drop_item` have. A client could then match its own commit exactly and the undo
window would not need to exist.

**F2 — a joiner is locked out of any chest that was written before it joined.** *(Found by
reading `scripts/net/world_ledger.gd` + `scripts/net/session.gd`; not covered by the smoke,
which places its chest after the handshake.)* `_storage_revisions` is session-scoped and
deliberately not persisted — correct — but it is also not in the join snapshot, and it is
only ever advanced by `apply()` seeing a `storage_set` op. So a peer that joins a session
where the host has already written a chest reads revision **0** while the host holds **N**.
Its first write is refused as `stale_revision`, and the refusal produces no delta, so its local
revision stays 0: it will be refused again, and again, until some *other* peer writes that
container. The player's experience is a chest that says "someone else changed that container"
forever.

*Handover to lane 3.A.* Either seed the joiner's `_storage_revisions` from the world snapshot
(a map of container → revision alongside `placed_buildings`), or carry the current revision in
the `stale_revision` verdict so the loser can re-quote it. The second is smaller and also
turns every ordinary lost race into a single silent retry instead of a message. I did not
attempt either: `scripts/net/*` is lane 3.A's, and nothing in my files can recover a number
this peer has never been told.

**F3 — the container key inherits `placed_buildings` index instability.** `container_key()` is
`storage:<realm>:<placed_index>`, and `build_placer.gd` renumbers `placed_index` on every peer
after a dismantle. Two chests can therefore trade revision counters. It is harmless for
correctness as long as every peer renumbers identically (the counter is only a change detector,
and a shared one still detects change), but a chest whose panel is open across a dismantle
would resolve its pending write against the wrong key. *Handover to lane 3.C:* `world_ledger.gd`'s
own `_dismantle` comment already says a stable per-record id is 3.C's call and a save-format
change; when it lands, `container_key()` should be derived from it. I did not invent one —
CLAUDE.md forbids inventing a major decision, and a save-format change is one.

**F4 — `static var _panel` in `storage_container.gd`: not a hazard today.** `static` is
process-global, and Stage B still gives one process exactly one local player with one screen;
a second peer is a second *process* with its own static, which is precisely what the net smoke
demonstrates (two peers, two panels' worth of state, no interference). The panel is re-pointed
at whichever chest opened it, which is correct when only one chest can be open. It becomes a
real hazard the day one process drives two local players (split-screen), where it would have
to become per-player. Left as it is, with that reasoning written into the file.

**F5 — one behaviour change worth knowing about outside multiplayer.** A chest's live contents
are now loaded from the committed delta rather than mutated in place. `build_placer.gd::
sync_state_to_game` still writes the live node's contents into the record at save time, and
`WorldState.apply_delta` writes the same contents into the same record on commit, so the two
agree; the net smoke asserts `record == chest` on both peers. Nothing else reads a chest's
inventory.

---

## Handovers

- **Lane 3.A** — F1 (`txn_id` through `_storage_txn`) and F2 (joiner revision seeding, or the
  revision on the refusal). F2 is the one that blocks shipping.
- **Lane 3.C** — F3: when `placed_buildings` records get a stable id, `container_key()` should
  use it instead of the index.
- **Orchestrator / merge** — I touched two shared files outside my owned three:
  `tools/net/peer_runner.gd` (new arms appended at named seams: the `_execute_step` match, the
  `_execute_probe` match, and one member block) and `.github/workflows/ci.yml` (the
  `verify-multiplayer-shard` discovery step, where I added a named-registration loop over the
  five `# peers: 2` smokes on top of the existing count guard). Both are likely conflict sites
  with 3.B/3.C/3.E; both conflicts are additive and trivial to resolve by keeping every lane's
  lines.
