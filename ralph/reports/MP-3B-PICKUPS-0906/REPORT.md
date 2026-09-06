# MP-3B — pickups and harvest through the ledger

Stage B Wave 3, lane 3.B. Branch `claude/mp-3b-pickups`, off `61518f6b`
(“Stage B Wave 3/4: a shared chest, creature ownership, and two ledger bugs
found by reading”).

**One sentence:** every pickup and every harvest now submits an intent to
`Game.ledger` and changes nothing locally until the committed delta says so, so
two players reaching for the same find produce exactly one grant.

---

## Per-item verdicts

| File | Verdict | What it does now |
|---|---|---|
| `scripts/world/item_cache_pickup.gd` | **converted** | `claim_pickup` intent (`realm`, `flag`, `item`, `count`); removal on `delta_applied`; refusal on `intent_refused` and on a synchronous host refusal, re-emitted as its own `claim_refused` signal |
| `scripts/world/key_pickup.gd` | **converted** | `claim_pickup`; `setup()` gained an optional `realm_id` (default `"meadows"`) |
| `scripts/world/tm_pickup.gd` | **converted** | `claim_pickup`; gained a static `flag_id()` (it only had `FLAG_PREFIX`); `setup()` gained an optional `realm_id` |
| `scripts/world/harvest_node.gd` | **converted** | `harvest` intent; tool gate, wrong-tool sentence and full-satchel sentence stay local; the “+N item”, the gather sounds, `home_materials_gathered` and the tool wear all moved into a `_settle()` that only runs when **this** peer’s claim commits |
| `scripts/world/vegetation_harvest_point.gd` | **converted** | `deplete_vegetation` intent (`realm`, `layer`, `index`); carries no item, because RG9 already moved the payout to the felled pile; the take-down is no longer this node’s call |
| `scripts/world/vegetation.gd` | **converted** | applies the `scene` half of the delta (`veg_deplete` → `fell()`), stamps its own `realm` onto the points and piles it spawns, and replays the durable world flags in `restore_from_game()` |
| `scripts/world/felled_resource.gd` | **converted** | `claim_pickup` against a new `felled:<realm>:<layer>#<index>` flag; `clear_felled()` and the “+N item” line moved onto the delta |
| `scripts/world/band_pickups.gd` | **no change needed** | it is a placer/dresser only: every band find it stands is an `item_cache_pickup.gd`, and it already reads `ITEM_CACHE_PICKUP.was_taken()`/`flag_id()` rather than writing anything. Converting the prop converted the band pickups. Verified by reading `place_all`/`place_one`/`flag_id` — there is no satchel write and no `set_flag` anywhere in the file. |

### Supporting files

| File | Why |
|---|---|
| `scripts/world/ledger_claim.gd` (new) | The three things all six consumers need — find `Game.ledger` and submit, read a verdict, recognise the committed delta — in one place instead of six. Holds no state; repeats no rule from `world_ledger.gd`. Modelled on `storage_container.gd`’s conversation (lane 3.D), not a second design. |
| `data/progression/flag_scopes.json` | Added the `vegetation:` and `felled:` prefixes to the **world** block. Both ids are minted at runtime by the ledger and land in `WorldState.flags` directly, so nothing routes them through `merged_progression.gd` today — but an unscoped id there is a `push_error`, and leaving two live prefixes off the table is a trap for the next reader. |
| `tools/net/peer_runner.gd` | Two arms (`pickup_stand`, `pickup_take`) and one probe (`pickup`) for the new net smoke. Everything they touch is shipping code: a real `item_cache_pickup.gd`, its own `Interactable.activated` signal, the real `Game.ledger`. |
| `tests/smoke_net_pickup_race.gd` (new) | The lane’s player-visible outcome, two processes. |
| `.github/workflows/ci.yml` | `verify-multiplayer-shard`: count floor 6 → 7, and `tests/smoke_net_pickup_race.gd` added to the named-registration list. |
| `tests/smoke_net_deploy_two_creatures.gd.uid` | Not this lane's file. Lane 4.B landed its smoke without the `.uid` every other `tests/smoke_net_*.gd` has, so the import mints it fresh on every checkout. Committed here because it fell out of this lane's own import; say so rather than leave a mystery file in the diff. |

---

## The shape, and why it is this shape

`storage_container.gd` was the precedent and was followed rather than
re-invented: submit, treat `pending` as “not yet”, settle on `delta_applied`,
surface the refusal.

1. **Solo is not a second path.** A solo player is a host with nobody to tell:
   `submit()` commits in-process and emits the delta **before it returns**, so a
   pickup is removed and an item granted in the same frame they always were.
   Every consumer here re-checks its own `_taken` after `submit()` for exactly
   that reason — the delta handler has already run by the time the call returns.
2. **Nothing local moves on `pending`.** No hide, no grant, no sound. A lost
   race then looks like the find simply staying put, which is the correct
   picture of what happened.
3. **Removal is driven by the delta, not the intent.** That single change is the
   race fix. Every consumer’s `_on_delta_applied` watches for the one world flag
   op that IS its claim.
4. **The satchel checks stay local, ahead of the intent.** `world_ledger.gd`’s
   own header says the host cannot see a client’s satchel. “Is there room”,
   “is the right tool in hand” and “does this swing reach” are the questions
   only the pressing peer can answer, so they still refuse visibly, locally,
   before anything is submitted.
5. **Every intent carries an explicit `realm` (D97).** Nothing added here reads
   `Game.current_realm`. `item_cache_pickup.gd` already had a `_realm_id`;
   `key_pickup`/`tm_pickup`/`harvest_node` gained an optional one defaulting to
   `"meadows"`, and `vegetation.gd` gained a settable `realm` it stamps onto
   every point and pile it spawns. See the handovers for what that default owes.

### The one two-part case

`deplete_vegetation` commits two ops. The durable half is an ordinary world flag
(`WorldLedger.vegetation_flag(realm, layer, index)`), applied by
`WorldState.apply_delta()` like anything else. The live half is a `scene` op,
because `_harvested` is a base64 bitset whose byte length
`vegetation.gd::restore_from_game()` checks against the running layer before it
will trust a byte of it — only that node knows the length, so a pure state object
writing it would hand every peer a bitset its own scatter then discards.
`vegetation.gd::_on_delta_applied()` is the consumer, via
`WorldLedger.scene_ops()`, and `restore_from_game()` now replays the flags too,
which is the half that survives a bitset this build cannot line up.

**The felled pile’s amount does not ride the op, and does not need to.**
`harvest_logic.gather()` returns either `0` — a refusal the chopper catches
before it ever submits — or `item_db.harvest_yield(item, base, true, false)`,
which returns `base` unchanged when the required tool is held. `base` is the
layer’s authored `harvest_amount`, which every peer already holds in
`_harvest_lookup`. So every peer stands the same pile the chopper would have,
derived rather than transmitted. This was checked in `autoload/item_db.gd:125`
rather than assumed.

---

## Commands run, and what they said

Godot **4.7-stable** installed to `~/godot-bin/godot`
(`4.7.stable.official.5b4e0cb0f`), `--import` run twice before anything else,
both clean.

| Command | Result |
|---|---|
| `godot --headless --path . --check-only --script <each changed .gd>` (10 files: the 7 converted, `ledger_claim.gd`, `peer_runner.gd`, `smoke_net_pickup_race.gd`) | clean, no output |
| `godot --headless --path . --script tests/run_tests.gd -- --only=harvest` | **52 tests, 1020896 assertions, 0 failed** |
| `godot --headless --path . --script tests/run_tests.gd -- --only=world_ledger` | **21 tests, 105 assertions, 0 failed** |
| `godot --headless --path . --script tests/smoke_playground.gd` | **`smoke: OK`** (exit 0) |
| `tools/net/run_net_smoke.sh pickup_race` | **ALL CHECKS PASSED**, exit 0 — see below |

Nothing green was re-run to confirm it. The net smoke was run four times because
the first three were RED and each red was a real defect in what the harness was
measuring, fixed between runs (F5, F6, F7). No full sweep was run, and the exit-time
`ObjectDB instances were leaked` / `resources still in use` notices were not
chased.

### `tools/net/run_net_smoke.sh pickup_race`

**ALL CHECKS PASSED**, exit 0. 22 checks. The two peers really host and join
(`peer 1 joined peer 0's world on port 34241 ... snapshot applied; 2 peer(s) in
registry`), both stand `cache:net_race_cache`, and both press at one shared
wall-clock instant:

```
peer 0 pickup: { "claimed": true, "flag": "cache:net_race_cache", "press": "submitted",
                 "refusals": [], "satchel": { "berries": 1.0 }, "standing": false }
peer 1 pickup: { "claimed": true, "flag": "cache:net_race_cache", "press": "submitted",
                 "refusals": [{ "code": "already_taken",
                                "reason": "Someone else got there first." }],
                 "satchel": {  }, "standing": false }

PASS: exactly one berries entered the world: 0 before, 1 after (peer 0: 0 -> 1, peer 1: 0 -> 0)
PASS: exactly one peer walked away with the find
PASS: peer 1 (the loser) was refused with `already_taken`
PASS: peer 1's refusal reads like something a player can act on: 'Someone else got there first.'
PASS: peer 0 (the winner) was not also refused
peer 1 lost by shape A: refused `already_taken` -- 'Someone else got there first.'
```

It went red three times before it went green, and every one of those was the
harness measuring the wrong thing rather than the lane's code misbehaving — the
invariant lines (`exactly one berries`, `exactly one peer`, both worlds
`claimed`, both props `standing: false`) passed on the very first run and on
every run since. F5, F6 and F7 below are what the three reds actually were.

---

## Findings

**F1 — `_restore_progression()` runs before `delta_applied` on a client, and
would have swallowed the winner’s own feedback.** `ledger_rpc.gd::_rpc_delta`
sweeps the `progression_restore` group *before* it emits `delta_applied`. Every
pickup here is in that group, so on a **client** the node is already deactivated
by its own flag by the time `_on_delta_applied` fires. A `_taken` guard placed
first — the obvious way to write it, and how the first draft of all four
consumers read — would therefore have skipped `harvest_node.gd`’s `_settle()`
on every client and only on clients: no “+3 Wood”, no gather sound, no tool
wear, for the peer that actually won. Found by reading `_rpc_delta`’s ordering
against the group registration, not by a test. Fixed by checking the flag first
and `_taken` last, in all four; the comment is in each file.

**F2 — the chop’s tool wear is spent win or lose, deliberately.**
`harvest_node.gd` holds its tool wear back until its claim commits, because the
node is still standing to be gathered again if the claim is refused.
`vegetation_harvest_point.gd` does the opposite and spends it at submit time.
The placement is on its way out on every peer regardless of who won, so there is
nothing to hold the wear back *for*, and a swing that connected with a tree
somebody else felled in the same second is still a swing. Solo is unaffected
either way — solo always wins.

**F3 — `felled:` needed a flag id that did not exist.** A felled pile is
contested (two peers can walk up to the same woodpile) but is not a world flag
today: it lives in `felled_vegetation`, a dictionary keyed by
`<layer>#<index>`. `claim_pickup` needs a flag, so `felled_resource.gd` mints
`felled:<realm>:<layer>#<index>` as a static `flag_id()`. It is a session-race
token more than a save fact — `clear_felled()` already removes the durable
record — but it is the only thing that can make the pile claimable exactly once.

**F4 — a two-peer race is not reproducible over the coordinator’s own
transport.** The coordinator talks to each peer over its own TCP socket and
awaits each verdict before sending the next, so two “press now” messages are
always a round trip apart — and a pickup, unlike a chest, is *removed* by the
winner’s delta, so the second peer would routinely find nothing left to press
and the smoke would assert nothing. `pickup_take` therefore takes an
`at_unix_ms` deadline: given one it arms the press and answers immediately, so
both peers can be armed and then press at the same instant off the wall clock
they share. Same problem lane 3.D solved by pinning the revision; same class of
answer. Everything about the press itself is the shipping path.


**F5 — a lost race has two legal shapes, and the smoke has to name which one it
got.** Because removal is driven by the DELTA, a losing peer whose press falls
more than a frame after the winner's never submits at all: the winner's delta
reaches it, takes the find down, and its press lands on nothing. That is not a
failure — it is the correct player experience, and it is what the brief itself
describes as the pickup simply staying put. The `already_taken` refusal is the
other shape: both intents in flight before either delta lands, which is the
interleaving the shared press deadline exists to create, and which the passing
run produced.

Which shape a run gets is frame phase between two processes; pinning it would
mean pinning the scheduler. `world_ledger.gd`'s own header already draws this
line — the deterministic interleavings are proven headlessly in
`tests/test_world_ledger_races.gd`, and "the net smokes only ever prove `no
duplication regardless of order`". So the smoke asserts both shapes by branch,
prints which one it saw, and lets neither be silence and neither pay the loser.

**F6 — `queue_free()` is deferred, so "is the prop still there" is the wrong
question to ask about a press.** The first version of the harness read
`is_instance_valid(_pickup_node)` and reported `submitted`. That was wrong in
the direction that hides a bug: a prop taken down by a delta earlier in the SAME
frame still passes `is_instance_valid`, the press reaches it, its own `_taken`
guard swallows it silently, and the harness reports a submission that never
happened. The runner now reads `item_cache_pickup.was_taken()` — the prop's own
public static over the same flag the delta carries — which is exactly the
question `_on_picked_up` is about to ask itself.

The shipping-code observation behind it, recorded rather than changed: inside
that one frame a press on an already-claimed find is silent. It is not reachable
by a player — the prompt is disabled and the node freed in the same frame — so
it was left alone rather than given a sentence nothing would ever show.

**F7 — a client's refusal outlives the prop it was about, and only the transport
sees it.** The `already_taken` verdict comes back a round trip after the client
submits, and by then the winner's delta has usually already reached that client
and freed the prop — taking `item_cache_pickup.gd`'s own `claim_refused`
connection with it. The player still gets the sentence, because
`ledger_rpc.gd::_rpc_verdict` pushes it to `Game` before it emits and that is
not a node connection; but a harness (or any future consumer) that listened only
on the prop would see silence and conclude the refusal never happened. The
runner now listens on **both**: the prop for the host's synchronous refusal, the
transport — an autoload child, which outlives any prop — for the client's. Worth
knowing for any consumer that wants to react to a refusal rather than merely
show it.

---

## Handovers

**H1 — the default realm on `key_pickup`, `tm_pickup`, `harvest_node` and
`vegetation`.** Their flags are not realm-qualified and never were
(`pickup:<item>`, `tm:<id>`, `harvest_node:order:<n>`), and only the Meadows
places any of them today, so `"meadows"` is correct now and is a plain
constructor default, not a read of `Game.current_realm`. A Cloudreach placer
that stands any of these must pass its own realm — and if two realms ever stand
the *same* pickup id, the flag itself has to become realm-qualified, the way
`item_cache_pickup.gd::flag_id()` already is. `vegetation.gd` exposes `realm` as
a settable property for the same reason; the Meadows is the only world that
builds a scatter today.

**H2 — `claim_refused` exists on `item_cache_pickup.gd` only.** It is the
prop-side twin of `storage_container.gd::storage_refused`, and it is what lets
the net smoke read a refusal on **both** paths (a host that loses is refused
synchronously inside `submit()`; a client hears `already_taken` a round trip
later on `intent_refused`). The other five consumers still surface a refusal the
way a player sees it — one sentence through `Game.push_world_message`, pushed by
`ledger_claim.gd::submit` on the host path and by `ledger_rpc.gd::_rpc_verdict`
on the client path. Add the signal to the others when something needs to branch
on the code rather than show the sentence; nothing does yet.

**H3 — `harvest_node.gd` re-reads the tool slot at settle time.** The slot is
read when the player presses and applied when the claim commits, which on a
client is a round trip later. The satchel can have been rearranged in between,
so `damage_tool(slot)` could in principle wear the wrong tool. It is guarded by
`slot >= 0` and nothing more. Addressing tools by identity rather than slot
across the round trip is the real fix and belongs with whoever owns
`inventory.damage_tool`; it is out of this lane’s file list.

**H4 — the pile amount is derived, not transmitted.** See “the one two-part
case”. It is exact *today* because `harvest_yield` returns `base` on every path
that reaches `fell()`. If a future yield rule makes the amount depend on the
chopper (a tool tier, a trait, a buff), the peers will diverge on pile size and
`veg_deplete` will need to carry the amount — which is `scripts/net/*`, not this
lane’s files.

**H5 — `smoke_playground`’s chop-then-gather number was not captured.** The run
printed `smoke: OK` and exited 0, which is the bar and which means the
chop-then-gather check passed. Its own `satchel total N -> M` line fell outside
the tail that was captured to the log, so the literal 12 → 14 is asserted by the
smoke rather than quoted here.
