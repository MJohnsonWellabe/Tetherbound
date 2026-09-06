# MP-3C — Building and death satchels through the ledger

Stage B Wave 3, lane 3.C. Branch `claude/mp-3c-building`, based on `main` at
`61518f6b` (world ledger 3.A, session 2.A, per-peer rig 2.C, lanes 3.D and 4.B all
present).

---

## Verdicts, one line each

| # | Item | Verdict |
|---|------|---------|
| 1 | Placement goes through the ledger (`place_building` intent, delta plants) | **Done** |
| 2 | Dismantle goes through the ledger (`dismantle` intent, delta uproots) | **Done** |
| 3 | A CLIENT's structure survives the host's save and a late join | **Proven** — `smoke_net_shared_building`, all 21 checks green first run |
| 4 | `pending` plants nothing and spends nothing | **Done** — ticket queue; the smoke's own step detail shows the client's records at `0 -> 0` at press time |
| 5 | Death satchel gains an owner; only the owner may open it | **Done** |
| 6 | A non-owner sees the owner's name and is refused in one sentence | **Done** — prompt reads `<Name>'s Satchel`, press answers `That satchel is <Name>'s — only they can open it.` |
| 7 | Multiple satchels still persist | **Unchanged** — no code touched the per-death record/node split |
| 8 | Save-shape change for `owner` | **None needed** — lane 3.A already landed the field and the round trip |
| 9 | Building address: index vs stable id | **Index**, deliberately — see "The addressing decision" |
| 10 | `storage_container.gd::container_key()` re-pointed | **No** — follows from 9; the file is untouched |
| 11 | `build_placer.gd:902` `AllyCreature` → `deployed_creature` group | **Done** — the legacy alias has no consumers left |
| 12 | Judgement on `static var _panel` in `death_satchel.gd` | **Not a hazard now** — see finding F4 |
| 13 | Solo unchanged | **Proven** — `smoke_playground` and `smoke_gate_a_build_house` both green |

---

## Files

Owned and changed:

- `scripts/build/build_placer.gd` — the ledger conversation. `_place()` submits a
  `place_building` intent instead of writing a record; `dismantle_piece()` submits a
  `dismantle` intent after its local guards; `_on_delta_applied` plants and uproots on
  every peer; `_settle_placement`/`_settle_dismantle` spend and refund once, on the peer
  that pressed. Also the `deployed_creature` group fix in
  `_bodies_that_are_not_buildings()`.
- `scripts/world/player_death.gd` — stamps the dying player's character id and an
  explicit realm on the record and on the live node; hands the owner to `restore()` on
  load.
- `scripts/world/death_satchel.gd` — `owner_character_id`, `can_open()`, `owner_name()`,
  `refusal()`; the prompt names the owner and `_on_open` refuses a non-owner.

Also changed (not in the forbidden list, but shared — flagged for the merge):

- `tools/net/peer_runner.gd` — two arms (`build_place`, `save_world`) and three probes
  (`placed_building_rows`, `placed_building_nodes`, `saved_world_buildings`). The arms
  stand in for a player's materials and press only; the placer, the intent, the delta and
  the save are all shipping code.
- `tests/smoke_net_shared_building.gd` (new) + `.uid`.
- `.github/workflows/ci.yml` — `verify-multiplayer-shard`: count floor 6 → 7 and the
  named-registration list. Lane 3.B is adding a smoke to the same two places; the
  conflict is additive and my line is correct for my own smoke.

Not touched, as instructed: `autoload/game_state.gd`, `scripts/net/*`,
`autoload/world_state.gd`, `item_cache_pickup.gd`, `harvest_node.gd`, `vegetation.gd`,
`storage_*.gd`.

---

## The addressing decision: index, and why

**Decision: `dismantle` keeps addressing a structure by its index into
`placed_buildings`.** A stable per-record id is the better address and I did not land
one, for a reason that is structural rather than a preference:

Every file that would have to change to make a stable id *work* is on this lane's
forbidden list.

- Minting the id belongs in `WorldState.register_building()` — that is the one
  construction site for a record's shape, deliberately (`autoload/world_state.gd`,
  forbidden).
- Resolving id → record belongs in `world_ledger.gd::_dismantle()`, and applying it
  belongs in `WorldState._apply_op()`'s `building_remove` — both forbidden
  (`scripts/net/*`, `autoload/world_state.gd`).
- I cannot smuggle it through the intent either: `_place_building()` builds its op from a
  fixed key set (`id`, `position`, `yaw_deg`, `paid`) and drops anything else, so an id
  put on the intent never reaches the record.

What I *could* have done from inside my own files is mint an id in `build_placer.gd`'s
delta handler and stamp it onto the record after the fact — derived from `delta.seq` so
every peer derives the same one. I rejected it. It would give the world **two** address
schemes: `dismantle` would still travel by index (the ledger understands nothing else),
while `container_key()` travelled by id. A second address scheme that only half the
system understands is worse than one address scheme that works, and it would put a field
in the save that no reader validates and no migration covers.

Index is sound for what it is asked to do today: ordered delta application keeps every
peer's `placed_buildings` in step, `_reindex_placed_nodes` moves the node metadata in the
same order on every peer, and the smoke shows host and client holding byte-identical
records at the same index. What index does **not** survive is the one-round-trip window
in F2 below.

**Consequences for lane 3.D, stated plainly:** `container_key()` stays
`storage:<realm>:<placed_index>` and stays exposed to the renumber it flagged. Dismantling
a structure below a chest shifts that chest's key, and the chest inherits the revision
counter of whatever key it moved onto — a spurious `stale_revision` on the next write.
That refusal is recoverable, not corrupting: lane 3.D's `adopt_storage_revision` path
takes the host's number and the player's second press lands. It is a real defect and it is
handover **H1**, not something this lane could close.

---

## Design, in one paragraph

A press builds a **ticket** — id, realm, spot, yaw, the cost as it stood at the press —
pushes it on `_pending_placements`, and submits `{"kind": "place_building", "realm", "id",
"position", "yaw_deg", "paid"}`. Nothing else happens. `_on_delta_applied` fires on every
peer, counts the `building_add` ops in the delta so the k-th add lands on record
`size - adds + k`, plants a node at that index through the same `_spawn_building` the save
restore uses, then looks for a ticket matching that id, realm and spot (within 5 cm) and,
if it finds one, spends the cost and rings the two sounds and the home flags. Solo and
host complete inside the `submit()` call, because `submit()` emits the delta before it
returns; a client completes a round trip later, or never, if `intent_refused` drops the
ticket first. Dismantle is the same shape with the local guards (chest not empty, bed
occupied, no room for the refund) kept in front of the submit, where they belong: none of
them is the host's question.

---

## Commands and counts

Godot **4.7-stable** installed to `~/godot-bin/godot` (`4.7.stable.official.5b4e0cb0f`);
`godot --headless --path . --import` run twice before anything else.

```
godot --headless --path . --check-only --script scripts/build/build_placer.gd     exit 0
godot --headless --path . --check-only --script scripts/world/player_death.gd     exit 0
godot --headless --path . --check-only --script scripts/world/death_satchel.gd    exit 0
godot --headless --path . --check-only --script tools/net/peer_runner.gd          exit 0
godot --headless --path . --check-only --script tests/smoke_net_shared_building.gd exit 0

godot --headless --path . --script tests/run_tests.gd -- --only=world_ledger
  21 tests, 105 assertions, 0 failed

godot --headless --path . --script tests/run_tests.gd -- --only=test_register_building.gd,
  test_build_placer_preview.gd,test_build_grid.gd,test_build_catalogue.gd,test_free_build.gd,
  test_gate_a_build_segment_contract.gd,test_save_format.gd,test_world_state.gd,
  test_realm_world_records.gd,test_satchel.gd,test_storage.gd
  167 tests, 926 assertions, 0 failed

godot --headless --path . --script tests/smoke_playground.gd            smoke: OK
godot --headless --path . --script tests/smoke_gate_a_build_house.gd    GATE A BUILD HOUSE SMOKE: PASS
godot --headless --path . --script tests/smoke_free_build.gd            free build smoke test passed

tools/net/run_net_smoke.sh shared_building                              ALL CHECKS PASSED (21 checks)
```

Every one of these is a first run. Nothing was retried, and nothing was re-run to confirm
a pass. Exit-time `ObjectDB instances were leaked` / `resources still in use` notices
appeared and were ignored as engine noise, per the lane brief.

`smoke_free_build.gd` is one command beyond the named list and is here on purpose: this
lane moved *when* a placement's cost is spent, and free build is the one mode where that
cost is empty. It was cheap and directly in scope, not a sweep.

---

## Findings

**F1 — the acceptance bar is met, and the proof is the save file, not the record.**
`smoke_net_shared_building` has the client place a `floor`. The host's
`placed_buildings` goes 0 → 1, the client's record comes back byte-identical at the same
index, a live node stands at that index on **both** peers, and the host's written save
contains that record. The last one is the assertion that separates "the record went
through the host" from "the client wrote its own copy" — a client-only record is in
nobody's save, and a late joiner rebuilds from exactly that file's shape
(`GameState.apply_world_snapshot` → `build_placer.restore_from_game`, already on `main`,
which is why late join needed no new code from me).

**F2 — index addressing has a one-round-trip window, and it is inherent, not a bug in
this file.** A client submits `dismantle` with index N. If a different peer's
`building_remove` at an index below N commits while that intent is in flight, the host
applies mine against a renumbered array and takes down the neighbour. The ledger's own
realm guard catches the cross-realm case; it cannot catch this one, because after the
renumber the index is *valid*, just wrong. A stable id closes it outright. Handover H1.

**F3 — `intent_refused` cannot name which of two in-flight tickets it refused.** The
signal carries `kind`, `code`, `reason` and the verdict, and the verdict carries no
submitter and no `txn_id` for `place_building`/`dismantle`. With two placements in flight
inside one round trip, a refusal pops the front ticket rather than the refused one, so the
surviving ticket is charged when the *other* structure lands. Same player, same materials,
so nothing is created or destroyed and no other peer can see it; but the wrong press pays.
This is the same shape as lane 3.D's F-note on `storage_set` carrying no `txn_id`, and it
has the same fix in the same file I may not touch. Handover H2. In practice one Place edge
is one ticket and `_place_blocked` bars a second press on the arming frame, so hitting it
takes two deliberate presses inside one RTT.

**F4 — `static var _panel` in `death_satchel.gd`: not a hazard today.** I read lane 3.D's
F4 on the identical pattern in `storage_container.gd` before writing this, and I reach the
same verdict for the same reason. `static` is process-global; Stage B still gives one
process exactly one local player with one screen, and a second peer is a second *process*
with its own static — the net smokes are two processes and demonstrate exactly that. One
reason of my own on top: a satchel now refuses anyone but its owner, and the only player
who can reach `_on_open` in this process is the local one, so the field cannot become a
route into somebody else's bag even if a second local player existed. It becomes a real
hazard the day one process drives two local players (split-screen), where two screens
would fight over one panel and it has to become per-player. Left as it is, with that
reasoning written into the file.

**F5 — the `owner` field needed no save-format work.** Lane 3.A had already added
`owner` to `WorldState.register_death_satchel`, `GameState.register_death_satchel` and the
world save, and `tests/test_world_state.gd` already round-trips it. What was missing was
anybody filling it in. A record written before this lane has no `owner`, reads as `""`,
and an unowned satchel opens for whoever finds it — which is precisely how it behaved when
it was written. That is the whole migration, and it is why there is no version bump.

**F6 — one behaviour change worth knowing about outside multiplayer.** A placement's cost
is now spent *after* the record commits, not before the node spawns. Solo that is the same
frame and the same call (`submit()` commits in-process and emits the delta before it
returns), which `smoke_gate_a_build_house` and `smoke_free_build` both confirm. It is
visible only as an ordering: `_can_afford` still gates the press, and a refusal now leaves
the satchel untouched instead of having to put materials back.

**F7 — satchel drops are not ledger-mediated, and this lane did not make them so.**
`world_ledger.gd` has no `drop_satchel` intent kind, and adding one is `scripts/net/*`. A
death on a client therefore still writes its satchel record into that client's own world
copy, exactly as before this lane; ownership is stamped correctly, but the record does not
reach the host. This is out of the lane's stated scope (part (b) asked for an owner) and is
flagged rather than half-built. Handover H3.

---

## Handovers

**H1 — a stable per-record id for `placed_buildings`.** For whichever lane owns
`autoload/world_state.gd` and `scripts/net/world_ledger.gd`. Mint it in
`register_building()`, accept it in `_dismantle()` and `building_remove` (index kept as a
fallback for one release), migrate existing records by minting on load, and re-point
`storage_container.gd::container_key()` at it. Closes F2 and the renumber/revision
collision lane 3.D flagged. Everything in `build_placer.gd` that would have to move is
`PLACED_INDEX_META` and the two `_take_*_ticket` helpers.

**H2 — a `txn_id` on `place_building`/`dismantle`, echoed on the delta op and on the
refusal verdict.** Same file, same request lane 3.D already filed for `storage_set`. It
turns `_take_placement_ticket`'s position match and `_on_intent_refused`'s
pop-the-front into exact answers, and closes F3.

**H3 — route the death-satchel drop through the ledger.** Needs a `drop_satchel` intent
kind and a `satchel_add` op (`scripts/net/*`, `autoload/world_state.gd`). The consumer
side is ready: `player_death.gd::_drop_satchel` is already a single call site that
computes position, owner and realm before it registers anything, and
`restore_from_game` already rebuilds from the record. The `owner` field this lane fills in
is what a shared satchel would need to be worth sharing.

**H4 — `_place()` is called directly by the net smoke's `build_place` arm, not through an
injected press.** A press only plants when the ghost is green, and where a peer spawns in
the Meadows decides that; a smoke whose subject is "did a client's record reach the host"
must not be able to go red because of the terrain under a spawn point. Everything
downstream of the press is untouched shipping code, and the arm reports `_ghost_ok` in its
detail (it was `true` on this run). If a later lane gives the harness a reliable
teleport-to-flat-ground step, that arm should become a real `build_place` press.
