# Lane 3.E — item trading and dropped items

Branch `claude/mp-3e-trading`, based on `main` @ `61518f6b`.
Godot 4.7-stable installed at `~/godot-bin/godot`; `--import` run twice on a
fresh container before anything else.

**The lane's claim:** two players can hand each other items and drop items into
the world, and no stack is ever duplicated or destroyed doing it. Held, on a
two-process run, on the first attempt.

---

## 1. Verdicts, one line each

| Item | Verdict |
|---|---|
| Direct offer/accept through `transfer_item` | **DONE** — offer is a two-message conversation, only its accepted outcome becomes an intent |
| Drop to world through `drop_item` + `scripts/world/dropped_item.gd` | **DONE** — committed `item_dropped` scene op, drawn on every peer off the same delta |
| Picking a dropped stack back up | **DONE** — a `claim_pickup` on `dropped:<txn_id>`; first writer wins, loser told `already_taken` |
| A disconnect mid-offer duplicates nothing and destroys nothing | **DONE by construction** — nothing is ever held in escrow; see §4 for the one residual window, which is not closable from the consumer side |
| Solo behaves exactly as today | **VERIFIED** — no session, `is_host()` true, satchel 8 → 5 on drop, 8 after pickup, replay refused `duplicate` |
| A transfer into a full satchel is refused with a sentence | **DONE** — checked by the receiver, the only process that can see that satchel; goes back to the giver as "Their satchel is full." |
| Inventory addressed by item identity, never slot number | **DONE** — and this is a deliberate behaviour change; see §5 |
| Every intent carries an explicit `realm` (D97) | **DONE** — read off the world the drop is happening in, never off `Game.current_realm`; see §3 |
| `pending` moves nothing locally | **DONE** — and the consumer moves nothing on `ok` either; see the finding in §2 |

---

## 2. Finding: the brief contradicts the code, and the code is right

The brief states:

> the honest consequence is that a client's own take must be applied locally when
> its delta arrives, exactly as `storage_container.gd::_settle()` does for a chest.

**This is false against the tree, and following it would have double-charged
every trade and every drop.** `scripts/net/ledger_rpc.gd::_apply_player_ops()`
already applies `item_grant` and `item_take` for every `player`-scope op
addressed to the local peer — on the host inside `_commit_here()`, and on a
client inside `_rpc_delta()`. `world_ledger.gd::_transfer_item`/`_drop_item`
emit exactly those ops, with `peers: [peer_id]`.

`storage_container.gd::_settle()` exists precisely because `storage_txn` is the
one intent that carries **no** player op — `storage_set` addresses the
container, never a satchel — so the chest's own consumer has to move the satchel
itself. Trading is the opposite case. CLAUDE.md: the codebase outranks a task
prompt. So no consumer in this lane writes an inventory, and every one of them
says so in a comment where a future reader would otherwise be tempted.

---

## 3. What was built

**New files**

- `scripts/world/dropped_item.gd` — a stack on the ground. Interact prompt,
  item-coloured prop under the shared `pickup_glow` (not a light of its own —
  `item_cache_pickup.gd`'s comment records why that does not scale). `pick_up()`
  submits a `claim_pickup` and returns `world_ledger.gd`'s verdict shape. A full
  satchel is refused **before** the intent is minted, because only this process
  can answer that question.
- `scripts/world/dropped_item_spawner.gd` — one per world, carrying that world's
  realm, turning a committed `item_dropped` op into a prop on every peer. Also
  the single place `realm_of()` and `drop_origin()` are answered from, so a
  caller with a `SceneTree` never reads a global to stamp a record.
- `scripts/ui/trade_offer.gd` — the offer conversation, mounted at
  `/root/Game/Session/TradeOffer` beside `LedgerRpc` and for the same reason
  (identical node path in every process, or the RPCs do not resolve).
- `scripts/ui/trade_offer_panel.gd` — the receiver's prompt. Deliberately does
  **not** pause the tree, unlike every other modal in this game: an offer
  arrives unasked, possibly mid-fight, and freezing somebody's game because a
  friend pressed Give would be a griefing tool. Built lazily on the first offer
  a process receives.

**Changed**

- `scripts/ui/tab_backpack.gd` — Drop is now a `drop_item` intent instead of
  `inventory.gd::drop_slot()`'s outright delete (that file's own comment asked
  for exactly this entity). The drop confirmation's row list became variable:
  **solo it is still exactly "Drop it" / "Cancel"**, and in a session it grows
  one `Give to <player>` row per other player. Rows are dispatched off a
  parallel `_confirm_actions` array rather than off the index, and are built
  once at the maximum and shown/hidden — a row freed while holding focus is the
  failure the neighbouring target panel was written to avoid. No new input
  action was invented; the pad has none spare (see `DROP_ACTION`'s own comment
  on what the last binding collision cost).
- `scripts/world/playground_world.gd`, `scripts/world/cloudreach_world.gd` —
  two lines each in `_ready()`, mounting the spawner and the offer transport.
  **Beyond the three files the brief named**, and unavoidable: both nodes must
  exist in *every* process before anyone presses anything, and the only file
  that mounts session-wide nodes today (`autoload/game_state.gd`) is on the
  forbidden list. Both `attach()`es are idempotent. Neither world root is owned
  by lanes 3.B, 3.C or 4.C.
- `tools/net/peer_runner.gd` — five arms (`trade_offer`, `trade_accept`,
  `trade_decline`, `item_drop`, `item_pickup`) and one probe (`trade`).
  `storage_grant` is reused to stock a satchel rather than adding a second way
  to put items in a bag. Expect a trivial additive conflict here with 3.B/3.C/4.C.
- `.github/workflows/ci.yml` — `verify-multiplayer-shard`: count floor 6 → 7,
  and `tests/smoke_net_trade.gd` added to the named-registration list.

---

## 4. Handovers

1. **Tool durability is lost through a drop.** `world_ledger.gd`'s
   `item_dropped` op is built field by field from an item id and a count with no
   passthrough, so a worn axe dropped and picked back up returns at **full
   durability** — a repair-by-drop exploit. Closing it needs a `durability`
   field on the op, which is `scripts/net/world_ledger.gd`, lane 3.A's file.
   Nothing here can work around it: the prop has no durability to carry.
2. **A dropped stack does not survive a reload and does not reach a joiner.**
   `item_dropped` is `scene` scope, is not in `WorldState`, and the handshake
   snapshot (D100) does not carry it. A peer joining after a drop sees bare
   ground. This **loses**, it never duplicates — the `dropped:<txn>` claim flag
   is an ordinary persisted world flag, so a stack cannot be claimed twice
   across a reload.
3. **`claim_pickup` writes one permanent world flag per dropped stack ever
   picked up.** Correct, and unbounded: a long campaign accumulates them in the
   save. A drop-specific intent that does not persist a receipt would be the
   fix, and it is lane 3.A's file.
4. **The one disconnect window that is not closed.** The receiver dropping in
   the milliseconds between sending its accept and the delta landing leaves the
   grant addressed to a peer that is gone: the stack is destroyed. It cannot be
   closed from the consumer side — the host would have to hold the stack, and
   holding it means seeing it, which is the thing `world_ledger.gd` cannot do.
   The giver re-checks the receiver is still connected immediately before
   submitting, which narrows it to one network hop. Every *other* mid-offer
   disconnect is safe by construction: nothing is ever escrowed, so an
   unanswered offer is only a message and the items never left the giver's bag.
5. **Lane 4.B shipped `tests/smoke_net_deploy_two_creatures.gd` without its
   `.uid`.** A fresh `--import` on this tree generates
   `tests/smoke_net_deploy_two_creatures.gd.uid` as an untracked file, so every
   agent who imports sees it as noise. Left untracked here rather than swept
   into this lane's diff — it is that lane's file and a one-line `git add` for
   whoever owns it next.
6. **`storage_container.gd::_panel` is process-global `static`.** Same latent
   split-screen hazard 3.D recorded; `trade_offer_panel.gd` is per-process too
   (mounted under the tree root), and would need to become per-player the day
   one process drives two local players. Not a defect today.

---

## 5. Deliberate behaviour change

Drop used to remove **the focused slot**. It now removes **`count` of that item
id**, and `inventory.gd::remove()` drains the smallest stacks of that id first.
The number of items leaving the satchel is identical; which slots end up empty
can differ when the player holds the same item in more than one stack.
CLAUDE.md makes identity addressing non-negotiable and the old slot-indexed
delete broke it, so this is the rule being applied, not a regression.

---

## 6. Exact commands, and what they printed

Every one of these was run once. Nothing below is a retry, and nothing was
re-run to confirm a pass.

```
godot --headless --path . --import          # twice, fresh container, exit 0
```

**`--check-only` on every changed `.gd` — 9 files, all clean, no errors or warnings**

```
scripts/ui/tab_backpack.gd              clean
scripts/ui/trade_offer.gd               clean
scripts/ui/trade_offer_panel.gd         clean
scripts/world/dropped_item.gd           clean
scripts/world/dropped_item_spawner.gd   clean
scripts/world/playground_world.gd       clean
scripts/world/cloudreach_world.gd       clean
tools/net/peer_runner.gd                clean
tests/smoke_net_trade.gd                clean
```

**Unit — the ledger, and the inventory tests by name**

```
godot --headless --path . --script tests/run_tests.gd -- --only=world_ledger
  21 tests, 105 assertions, 0 failed

godot --headless --path . --script tests/run_tests.gd -- --only=test_inventory.gd
  43 tests, 287 assertions, 0 failed

godot --headless --path . --script tests/run_tests.gd -- --only=test_characterize_party_and_inventory.gd
  18 tests, 50 assertions, 0 failed
```

**Smoke**

```
godot --headless --path . --script tests/smoke_playground.gd
  smoke: OK

godot --headless --path . --script tests/smoke_backpack_pad_target.gd
  backpack target picker answers a controller: OK      (3 checks)
```

`smoke_backpack_pad_target` is not on the brief's list; it is here because it is
the only existing test that drives the confirm/target panels this lane
restructured, and restructuring them without running it would have been a claim
rather than evidence.

**The net smoke — `tools/net/run_net_smoke.sh trade`, 32 checks, ALL CHECKS PASSED, first attempt**

Run `net-20260906T052122Z-3382`. Both peers exited cleanly
(`unexpected_exit=false`). The numbers that matter:

```
the wood in the world before anybody trades: 20
nothing moved while the offer was merely OUT: 20 before, 20 now
peer 0 still carries all 10 wood while its offer is unanswered (has 10)
the giver paid exactly once:   peer 0 has 6 wood
the receiver was paid exactly once: peer 1 has 14 wood
the wood is conserved across the trade: 20 before, 20 after
peer 1 dropped 3 wood            (client submit: ok=false pending=true)
peer 0 draws the dropped stack on the ground: 3 wood
peer 1 draws the dropped stack on the ground: 3 wood
the wood is conserved across the drop: 20 before, 20 after
the finder was paid exactly once:   peer 0 has 9 wood
the dropper was not re-paid:        peer 1 has 11 wood
the wood is conserved end to end: 20 before everything, 20 after everything
```

The client's drop returning `pending` and still settling correctly is the case
worth naming: peer 1 submitted, moved nothing locally, and its satchel went
14 → 11 only when the delta landed. Peer 0 lost nothing.

Conservation is asserted at **every** stage, not once at the end: an overall
total can hide a stack destroyed in one step and minted in another.

Against the brief's warning about tests that pass while asserting less than they
should: `_satchel()` and `_ground()` assert `has()` before `get()` and return
`-1` rather than 0 on a missing key, and `_snapshot()` fails a check rather than
returning a null probe — so a probe that lost a key fails the smoke instead of
comparing 0 against 0.

**Solo — a throwaway probe, not committed**

The net smoke only exercises host + client, so solo was checked directly against
a real booted Meadows:

```
session active: false        is_host (solo): true      realm from spawner: meadows
submit ok=true pending=false
satchel wood 8 -> 5          dropped props in world: 1   (wood x3 at (1.0, 2.25, 3.0))
pickup ok=true               satchel now 8               props after pickup: 0
replay of the same txn_id: refused=true code='duplicate' satchel still 8
```

Solo is the host path, commits in-process, and a replayed transaction is refused
without crediting anybody twice.

---

## 7. Not done

- No test was skipped, disabled or quarantined.
- No full sweep was run, and no passing run was re-run.
- Exit-time `ObjectDB instances were leaked` notices were not chased; they are
  engine noise at exit.
