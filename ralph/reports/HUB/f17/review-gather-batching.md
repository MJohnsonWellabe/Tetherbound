# Independent review: guest gather batching (tb/f17)

Commits reviewed: 81e045f0 (pickup spec registry), 48813e94 (batched guest gathers), 503483c9 (F32 receipt window).
Reviewer: independent agent, read-only except this file. Line numbers are HEAD of tb/f17 (4c4743ab).
The working tree has uncommitted, unreviewed receipt-window work (scripts/creatures/receipt_windows.gd and edits to f32_source_actions.gd and others). This review covers the committed state only.

**Verdict: 3 blocking findings** (B1, B2 in 48813e94; B3 in 81e045f0). Do not land 48813e94 until B1 and B2 are fixed.

## Blocking

### B1. The `replayed` max-mark prunes a row the owner-passive replay still needs; the guest's owner-passive stream then dies
- Files: `scripts/net/gather_batches.gd:118-136` (`marked` uses `maxi`, `prunable` prunes everything `<= min(acked, replayed)`), `scripts/net/ledger_rpc.gd:562` (`mark_gather_replayed`), `scripts/net/owner_passive_sync.gd:444-454`.
- The two marks are high-water marks. Batches settle out of seq order, so a high mark can jump past an accepted row that has not been replayed yet.
- Scenario (common, because a guest checks `has_room_for` without counting up to 8 in-flight hits):
  1. Batch 1 (new item, no free slot) reaches the guest. `REWARD_DELIVERY.apply` stages it as `grant_due` and does not settle it. The guest ACKs anyway (`_process_reward_delivery` always calls `_ack_reward_delivery`), so `acked=1`. No owner-passive input is recorded, because the slots did not change.
  2. Batch 2 (an item that stacks onto an existing stack) settles. The guest records `reward_delivery_applied(2)`. The host replays it, so `replayed=2`. The guest ACKs, so `acked=2`. The floor is now 2, which prunes row 1 (accepted) and row 2.
  3. The guest frees room. `reconcile_reward_deliveries` settles the escrow row 1 that is still `grant_due` and records `reward_delivery_applied(1)`.
  4. On the host, `owner_passive_sync._inputs_host` looks up `world.reward_deliveries[row1]`. The row is gone, so `REPLAY.apply_delivery` returns `unproved_delivery_input` and sets `stream.error`. That error is terminal: every later input and checkpoint for this character is denied (lines 392, 479, 516, 568). The host authority never gains batch 1.
- The same thing happens whenever pending rows are applied in non-seq order. `pending_for_character` walks dictionary order, which after a JSON reload is not seq order.
- Fix: never prune a row the replay has not credited. Track the replay per row (for example a `replayed` flag on the row, set by `mark_gather_replayed` for that exact id, and prune only rows that are both accepted and replayed), or make both marks contiguous (advance only when every lower seq has reached that state). Add a test for the grant_due-then-settled order.

### B2. The guest prunes escrow by seq floor alone, which removes the exactly-once guard; a lower batch can be paid twice
- File: `scripts/net/ledger_rpc.gd:584-603` (`_gather_guest_view`).
- The guest erases every *settled* escrow row whose source is `gather_batch:<seq>` with `seq <= min(acked, replayed)` of the current world.
  - It does not filter by `world_namespace`.
  - It does not check that the host's row for that id is gone or accepted.
- Escrow ids are `sha256(namespace, "gather_batch:<seq>", character)`. Escrow is the only thing that stops `REWARD_DELIVERY.apply` from granting again.
- Scenario A (same world, ACK hole):
  1. The guest settles batch 1. Its ACK fails: `_accept_reward_delivery` rolls back on a world-save failure or a busy fallback, and the retry is throttled to 3 s.
  2. Batch 2's ACK succeeds, so `acked=2`. Both replays land, so `replayed>=2`.
  3. The host prunes nothing for row 1, because it is still pending. The guest prunes escrow 1, because seq 1 <= floor 2.
  4. Within 0.5 s, `reconcile_reward_deliveries` sees row 1 still pending. `apply` finds no escrow row, creates `grant_due` and gives the items again. The duplicate reaches both the satchel and, through a second replay, the host authority.
- Scenario B (cross-world):
  1. In host A's world, the guest settles batch 5 and the host quits before the ACK lands, so row A:5 stays pending in A's file.
  2. In host B's world, the floor reaches 5 or more, so the guest erases A's escrow row (same source string, other namespace).
  3. The guest rejoins A. The pending A:5 row is applied again, which duplicates its items.
- Fix: prune only rows whose `world_namespace` matches the current world and whose id is absent from the guest's mirror of `world.reward_deliveries` (meaning the host pruned it). Also fix the host's max-mark hole (B1 fix) so the host never reports a floor over a pending row.

### B3. `pickup:` and `tm:` prefix inference lets a guest mint one of any item into the host's record (81e045f0)
- File: `scripts/net/pickup_spec_registry.gd:37-43`. Used at `world_ledger._claim_pickup` and `ledger_rpc.gd:406`.
- `lookup()` returns `{item: <flag suffix>, count: 1}` for any flag starting with `pickup:` or `tm:`, whether or not such a find exists.
- A modified guest sends `claim_pickup` with flag `pickup:<any item id>`, for example an evolution catalyst. The flag is unset and `guest_pickup_routed` accepts everything except `dropped:`, so the host journals a durable reward delivery of that item. Owner-passive replay then credits the host authority.
- One forged item per item id, per world, per prefix. It also writes the forged world flag, which can consume a real key pickup's flag for everyone.
- This contradicts the commit's claim that "a forged find cannot enter the host's record".
- Fix: register key and TM pickups in their own `setup()`, as caches do, and drop the prefix inference. At minimum, require `items.kind(suffix)` to be "key" or "tm" and the TM id to exist in tms.json.

## Should-fix

- **S1. An open batch survives a host restart but is never flushed** (`ledger_rpc.gd:519-555`). `_gather_open_since` is in memory only. If the world was autosaved with an open batch (accrue ops are not durable, but a periodic save captures them), then after a restart nothing flushes it: not on load, not on guest admission. The items wait until that character gathers again, or forever if it never does. Seed `_gather_open_since` from `redesign_world.gather_batches` on world load and on admission. Also flush on rejoin.
- **S2. Uncached config read every frame and on every hit** (`gather_batches.gd:26-40`). `DATA.json` is `FileAccess.get_file_as_string` plus `JSON.parse_string`, with no cache.
  - `_gather_poll` calls `flush_seconds()` every frame while any batch is open on the host, and every frame while a failing flush retries.
  - `enabled()`, `accrued()` (max_open_items), `max_hits()` and `_harvest` → `guest_batches` read the file on every gather, on the host and again on every peer applying the accrue op.
  - Cache the config in a static var. This matters on the ROG Ally.
- **S3. A synchronous full world save every ~1.5 s per gathering guest.** Every flush is a durable `save_world` before publication, triggered at 8 hits or 1.5 s after the first hit. Harvest nodes and Stormwood sites previously caused no save. The two-peer smoke proves correctness, not frame time. Measure host hitches on the Ally with 3 gathering guests. Consider a longer `flush_seconds` or a write that does not block.
- **S4. A batch can become permanently unflushable, silently swallowing every later gather.**
  - `accrued()` (`gather_batches.gd:83`) caps distinct items (24) but not hits or total stacks.
  - `flush_delivery` returns {} when the stacks exceed 24, or when one item needs more than SLOT_COUNT stacks. `_gather_flush` then refuses with "nothing_open" forever, while new accrues keep succeeding: the world flags are consumed and nothing is ever paid.
  - Reachable while saves keep failing (hits grow without bound), or with small-stack gatherables (heartstone and sunstone have stack 1).
  - Each failed attempt also snapshots `world.save_data()` in `_commit_here`.
  - Fix: make `accrued` refuse `batch_full` when the resulting `flush_delivery` would be empty, and cap hits.
- **S5. Host-side yield and reach checks are weak, and now they credit the authority.**
  - `legal_amount` (`pickup_spec_registry.gd:30`) never checks that the guest holds the required tool. The registered `alt` equals `count` anyway (`harvest_yield(...,true,...)` returns base), so the tool tier is unenforced: a guest without the tool gets full yield on tool-gated nodes.
  - The static registry is never unregistered when nodes free or realms unload, and `_harvest`/`_claim_pickup` have no realm or proximity check against the host's view of the guest. A modified guest can take every registered find remotely, once per regrowth.
  - Before this change such forgeries reached only the guest's own file; now they reach the host's authority. Use `_water_actor_context`-style actor checks and the authority inventory's tool slot.
- **S6. The flush before a station action invites an authority race (unverified).**
  - `session.gd:404` flushes inside `_foundation_handle`, so a delivery leaves just before the foundation action mutates the host authority.
  - `character_authority.apply_owner_reward_delivery` (`character_authority.gd:272`) requires authority state == stream base. If the station commit lands between, the replay fails with `owner_passive_delivery_authority_changed`, which is terminal.
  - The flush gives the action no benefit: the guest built its request from a satchel without the batch, and the authority gains the items only after the replay. No dup or loss of items otherwise; a craft simply cannot use items still in flight.
  - Needs a two-peer proof: gather, then craft at once. Otherwise drop the pre-action flush.
- **S7. Registry cap with no eviction** (`pickup_spec_registry.gd:13,23`). Keyed felled piles register on every felled tree and never leave. After 8192 entries in a process lifetime, new finds are silently unregistered. A guest's claim on one then falls back to the local-only `item_grant`, so the guest satchel and host authority diverge. Evict felled entries on claim or free, or exempt them from the cap.
- **S8. The F32 refine eviction-safety claim rests on a guard with no producer** (`f32_source_actions.gd:189`). No production code sets `completed_present_channel` or `completed_action_id`, so `refine` is unreachable today and the "forge completed-channel ticket" argument is unproven. When it is wired, the ticket must be single-use (consumed in the same commit). Otherwise an action evicted after 256 newer F32 receipts can replay while the ticket is still live. Add that as an acceptance check on the wiring.
- **S9. "Gathering never stops at the receipt cap" holds only for F32 receipts.** Wild-win shed receipts (`compose_wild_shed`), combat mastery receipts, care and others still share the 4096 budget in the committed state, and F32 `stage` still denies `receipt_budget` once they fill it. The uncommitted `receipt_windows.gd` work appears to address this but is outside this review.

## Nits

- **N1.** `GATHER_BATCHES.batch()` silently returns `empty_batch()` (next_seq=1) for a row that passes the schema but fails `batch_valid`, for example `hits=0` with a non-empty `open`. Seq ids would then be reused. If the old row still exists, every flush is refused (`reward_deliveries.has(id)`). If it was pruned, the guest's escrow treats the new batch as already settled, so it is lost. Only a corrupted or hand-edited save reaches this. Prefer refusing the load.
- **N2.** A guest-sent `gather_flush` intent enters the durable path (`ledger_rpc.gd:410`), and `world.save_data()` is snapshotted before world_ledger refuses it as host_only. A cheap amplification for a spamming guest. Exclude non-host peers before the snapshot.
- **N3.** The guest sees "+N on its way" at the hit. If the host crashes before the flush is saved, nothing arrives. The world stays consistent (the node returns), but the message overstates the guarantee.
- **N4.** An older build refuses a world containing `gather_batches` (`additionalProperties: false`). Downgrade is not required, but note it in the migration line.
- **N5.** Batch rows for departed characters stay forever. This is bounded per character and is fine.

## Answers to the specific questions

### Can a guest's gathered items be duplicated or lost?

| Case | Result |
|---|---|
| Flush timing | Correct |
| World save fails during flush | Correct: `world.load_data(before)` restores world, seq, storage revisions and seen txns; the batch stays open and retries 1.5 s later. Unbounded growth while it keeps failing is S4. |
| Disconnect mid-batch | Correct. `_on_peer_disconnected` flushes while the registry row still exists; the target is the departed peer, which is harmless. The pending row reaches the rejoined peer through `reconcile_reward_deliveries` (every 0.5 s), and the escrow id keeps it exactly-once. |
| Reconnect | Correct, subject to B2 |
| Host crash between accrue and flush | Unsaved: consistent rollback (node back, nothing paid). Autosaved: S1 (stuck until next gather). |
| Guest prunes escrow rows | **Can duplicate** (B2) |
| Host prunes world rows before the owner-passive replay | **Breaks the replay** (B1) |
| Host prunes world rows after the replay | Fine |
| Guest crafts before the flush lands | No dup or loss; the craft cannot use items in flight. Possible authority race (S6). |

### Is the host/solo path unchanged?

Yes. Every batching branch is gated on `peer_id != HOST_PEER` and an admitted character. The host's own `claim_pickup`, harvest and Stormwood paths keep the immediate grant. The only additions on the host/solo path are:
- registry writes in node `setup()`;
- an early-return `_gather_poll` each frame;
- a scan of delta ops in `_gather_after_commit`;
- a gather_mark appended to `accept_reward_delivery` only for `gather_batch:` sources.

### Is world state deterministic on every peer?

Yes. Ops carry the full delivery, and every peer re-derives it with `flush_delivery` and checks it with `_equivalent`. `batch()` normalises JSON floats to ints, and the schema `integer` type accepts integral floats.

### Can a malicious guest abuse gather_flush/gather_mark or forge items/amounts?

- `gather_flush` and `gather_mark` are host-only in world_ledger. The acked mark is reached only through `_accept_reward_delivery`, which checks that the registry character matches the row.
- Amounts and items for batched gathers come from host data.
- Forging is still possible through B3 (key/TM prefixes) and S5 (tool and reach).

### Does the optional schema field load a v28 world cleanly and round-trip?

Yes. `gather_batches` is optional (not in `required`), so a v28 world without it validates and reads as empty, and the row shape round-trips. No key-set test breaks:
- `test_world_state.gd:101` checks top-level world keys, and the new key is nested in `redesign_world`;
- `test_split_key_coverage_equals_v22` checks only `STATE_KEYS`;
- the `test_session_snapshot` carrier compare is unaffected;
- `data/schema/world_state.json` defaults are unchanged;
- the flag_scopes entry is present.

### Is the F32 receipt window safe?

| Op | Evicted receipt replayable? |
|---|---|
| node | No: stale `expected_stock_revision` gives `stale_stock` |
| farm | No: plot revision |
| groom | No: guarded by the `groom` shed receipt (different prefix, not compacted by this commit) and F27's care receipt |
| refine | Unproven (S8); unreachable today |

- Compaction is a pure function of `current`, so host staging and owner_plan agree.
- A late resend of an evicted action gets `stale_*` instead of `existing_transaction_replay_required`. Harmless.
- No other receipt user filters on the `craft:<char>:f32:` prefix.

### Performance

- S2: an uncached JSON config read every frame while batches are open, and on every hit on every peer.
- S3: a full synchronous world save about every 1.5 s per gathering guest.
- `prunable` is O(reward_deliveries) per mark, and F32 compaction is O(receipts ≤ 4096) per F32 action. Both are fine.

## Test gaps worth adding with the fixes

- A grant_due batch followed by a settled later batch, with the replay of the earlier one after the prune (B1).
- An ACK failure on batch N with batch N+1's ACK succeeding; also prune in world B, then rejoin world A with a pending row (B2).
- A forged `pickup:<item>` and `tm:<item>` claim from a guest (B3).
- A host restart with an open batch saved (S1).
- A batch exceeding 24 stacks (S4).
- Gather then immediately craft, two-peer (S6).
