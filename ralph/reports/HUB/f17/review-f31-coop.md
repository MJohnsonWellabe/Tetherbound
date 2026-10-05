# Independent review: F31 co-op commits on tb/f17

Reviewer: independent code-review agent (read-only except this file). Date: 2026-10-05.
Commits reviewed:

- `4071a284`: guest `claim_pickup` paid through a journaled reward delivery (`scripts/net/world_ledger.gd`, `scripts/net/ledger_rpc.gd`)
- `01c64ec0`: `homestead_action_completed` emitted on saved settlement (`scripts/net/session.gd`)
- `eabcadfb`: `station_rules.gd` `reason()` strings

**Verdict: nothing blocking.** I found no path where a guest's find is granted twice to either the local satchel or the host's CharacterAuthority record, and no regression in the host or solo pickup path. There are two should-fix gaps. First, the fix covers only `claim_pickup`. The main gathering verbs still give guests items that the host authority never gets. Second, a short disconnect window can leave a guest's authority record permanently out of step with the satchel, and the next rejoin is then refused. Details below.

---

## Answers to the asked questions

**Double grant (satchel or authority)?** I found none for an honest client.
- World side: the flag is checked first (`_flag_set`, world_ledger.gd:485). The delivery id is a deterministic receipt, `sha256(namespace, "claim_pickup:"+flag, character)`. It is checked against `world.reward_deliveries` (world_ledger.gd:504). `world_state` `reward_delivery_journal` also refuses an existing id (autoload/world_state.gd:535). A resent or replayed intent after reconnect therefore gets `already_taken` (covered by `test_a_second_claim_pays_nothing_and_the_receipt_is_stable`).
- Guest satchel: `REWARD_DELIVERY.apply` stages the delivery once in `satchel_escrow[id]` and returns `settled` with `changed=false` on every repeat (reward_delivery.gd:51-102). Reconcile, the 0.5 s `reconcile_reward_deliveries` poll and escrow replay therefore cannot pay twice.
- Host authority: `_process_reward_delivery` calls `_owner_passive_delivery_record` only when the satchel slots actually changed (ledger_rpc.gd:~1005). That happens once: either on first apply, or later when a full bag makes room for an escrowed row. The host credits only on that replayed `reward_delivery_applied` input.
- Rejoin keeps the host's existing record (`seed_admitted_character` returns `already_seeded`, character_authority.gd:73-76), so reconnecting re-grants nothing. This matches the smoke's new "the reconnect re-granted no find" check.

**Can a guest get an item locally that the host authority never gets?** Yes, in the cases listed under should-fix #1 and #2 below. The main one is that harvest, vegetation and Stormwood gathering still use a bare `item_grant`.

**Host/solo pickup path unchanged?** Yes. In `world_ledger._claim_pickup`, the new branch requires `peer_id != HOST_PEER`, so host and solo still append the same `_item_grant`. They then go through `_commit`, which now calls `_flag_gate` and then the identical `seq += 1` / `apply` / return body. In `ledger_rpc._commit_here`, `guest_pickup` requires `peer_id != _local_peer_id()`, so host and solo claims are not durable transactions. They keep the old "apply player ops, then emit, then rpc" ordering in the `else` branch (ledger_rpc.gd:496-501). Dropped stacks (`dropped:*`) and claims without an admitted character also keep the direct grant.

**Durable save, rollback and publish ordering?** Correct for this path.
- The `before_satchel` snapshot (world save_data, seq, world revision, storage revisions, seen txns) is taken before `ledger.commit`.
- On `save_world` failure, the code restores that snapshot and returns `journal_failed` with "The world could not save this find. Nothing was claimed." No delta has been emitted or rpc'd and no player op has been applied at that point, so nothing leaks to the guest. The guest's `item_cache_pickup` resets `_claiming` on `intent_refused`, and the find stays standing.
- After a successful save, the journal delta is emitted and rpc'd before `_apply_player_ops`, the same as `reward_grant`. On the host, `_apply_player_ops` is a no-op for a guest-addressed delivery, so the order is harmless.
- The `guest_pickup` predicate in ledger_rpc and the routing predicate in world_ledger use the same inputs: item non-empty, `guest_pickup_routed(flag)`, and a non-empty character from `_registered_character`, which `with_host_actor` passes in. On the host, `_local_peer_id() == HOST_PEER`. The two cannot disagree.
- Test gap: no test drives the ledger_rpc `save_world`-failure rollback for `claim_pickup`. The commit message says "unsaved world refused without effect", but that test (`test_a_guest_in_an_unsaved_world_is_refused_without_effect`) covers the world_ledger `world_not_ready` branch (empty namespace), not the durable rollback. (nit)

**Does `_flag_gate` keep every refusal code and order?** Yes. The loop body is moved verbatim: `typed_ripplet_claim`, then `not_your_character`, then `host_only`, per op, in the same order. It returns `{}` on pass. `_commit` still runs it first for every kind. On the guest path the gate runs early, on `[world flag]` only, before the new `world_not_ready` and `already_taken` checks. `_commit` then runs it again over ops whose added entries are not `op == "flag"`, so the outcome is identical. The new guest-only refusals come strictly after the gate.

**`homestead_action_completed`: double fire, wrong action, groom, listeners?** Groom is excluded explicitly. The action and intent come from the settled row itself, so a "wrong action" emission cannot happen. All five listeners filter by op plus their own pending intent (craft_panel.gd:593, tab_backpack.gd:2448, relic_power_panel.gd:141, crossing_hall.gd:603, plus test helpers), and they clear or disconnect after a terminal result, so repeats are ignored. The emission can repeat, though; see should-fix #3.

---

## Findings

### should-fix #1: the fix covers only `claim_pickup`; harvest, vegetation and Stormwood gathering still diverge the guest from the host authority
- `scripts/net/world_ledger.gd:572` (`_harvest`), `:591` (`_stormwood_harvest`), `:613` (`_deplete_vegetation`). All three still append `_item_grant(peer_id, …)` for a guest. `ledger_rpc._apply_player_ops` applies that only to the guest's local satchel.
- Scenario: a guest picks berries from a harvest node or a bush (`harvest` / `deplete_vegetation`) or gathers a Stormwood site, then tries to craft at the host's Kitchen. The guest's satchel shows the items, but the host's CharacterAuthority record (which station crafts read) never got them, so the craft is refused for missing materials. This is the same F31#5 symptom the commit set out to fix ("guests could not craft with what they gathered"). The new smoke passes only because it stands `pickup_stand` caches, which route through `claim_pickup`.
- It also feeds should-fix #2: any core-field inventory divergence makes the next rejoin's owner-passive admission refuse.
- Dropped stacks are deliberately excluded (world_ledger.gd:518-525), but drops cause the same problem in a different shape. A drop removes items from the guest's local satchel only, and the authority keeps them. Picking up someone else's drop adds items locally only. Both diverge the record. The exclusion is correct (routing a pickup of a drop would mint an item), but the underlying drop and pickup-of-drop divergence stays open and is not mentioned in STATE.

### should-fix #2: a disconnect between the guest's local save and the host replaying `reward_delivery_applied` leaves the authority short for good, and rejoin is then refused
- Path: on the guest, `ledger_rpc._process_reward_delivery` applies the delivery, saves the character, then calls `_owner_passive_delivery_record` → `owner_passive_sync.record_delivery` (owner_passive_sync.gd:121-125), which queues an input. The host credits the authority only when that input is replayed (owner_passive_sync.gd:444-448).
- Scenario: the guest grabs a cache and the process exits, crashes or drops the connection before the queued input reaches the host. The guest's save has the item and a `settled` escrow row, so reconcile never records it again. The host's record lacks the item. On rejoin, `seed_admitted_character` keeps the host's record (character_authority.gd:73-76), and `owner_passive_sync.admitted` compares `REPLAY._core` (which includes inventory) of the declared and host records. They differ, so the stream is refused with `owner_passive_admission_conflict` (owner_passive_sync.gd:178-186). The player then sees "Their care and Altar actions are paused until you rejoin" on every rejoin to that world.
- This path already existed for `reward_grant`. The commit makes it far more reachable by putting every guest cache, key, TM and felled-pile pickup on it.
- Fix options: have the host credit the authority at journal time, as it does for the world row, and let the owner mirror it. Or have rejoin reconcile `reward_delivery` rows that are settled in the declared escrow and `pending`/`accepted` in the host journal but not yet replayed.
- A related small window: `_owner_passive_delivery_ready()` returns true when `_owner_passive.local` is empty (session.gd:179-181), for example before the stream starts during admission. `_owner_passive_delivery_record` is then a no-op, so a delivery applied in that window never reaches the authority.

### should-fix #3: on the host, `homestead_action_completed` likely re-fires every 0.5 s for the latest accepted foundation action
- `scripts/net/session.gd:4503-4510`, reached from `scripts/net/ledger_rpc.gd:1252-1255` and `:1311-1313`.
- Path: `reconcile_reward_deliveries` runs every 0.5 s from `_process` (ledger_rpc.gd:187). It calls `_process_creature_training` for every one of the character's creature_training rows. For an `accepted` row on the host, that calls `_accept_creature_training(…, local)`, then `host_ack_creature_training`, which returns true once the receipt is in the host's record (character_authority.gd:953-954). It then calls `_deliver_training_decision(local, row)`. `_settle_owner_training_accepted` has no one-shot state: it returns true whenever the row is the current owner row (session.gd:4714-4732). The new code therefore emits again on every poll until a newer row replaces it.
- The existing `altar_essence_spend_completed` emission next to it is one-shot because it is gated on `_altar_spend_request`. The new emission has no such gate.
- On the guest, every extra `_rpc_creature_training_ack` the host receives after acceptance sends another `_rpc_training_decision`, which emits again (bounded, a few per action).
- Impact today is low: every listener filters on its own pending nonce-bearing intent (craft_panel adds `craft_id`/`action_id`, craft_panel.gd:489). It is still a 2 Hz signal, with a `_foundation_decision` computation, for as long as the session lives. Any future listener that is not intent-gated, such as a toast or a sound, will repeat.
- Fix: emit only on the transition. One way is a one-shot keyed by `row.receipt`, mirroring `_altar_spend_request`. The other is to emit only when the row was the pending one this session submitted (`_foundation_requests` correlation).
- I inferred this from the code; I did not run it. A counter on the signal in `smoke_f31_station_paid_path` would confirm it.

### should-fix #4 (exposure widened): guest-chosen item and count now mint into the host authority record
- `scripts/net/world_ledger.gd:486-511`. `item` and `count` come from the guest's intent, and the flag can be any unused string that is not `dropped:` or `cache:ripplet:`.
- Scenario: a modified client sends `claim_pickup {flag:"x:1", item:"<any item>", count:<up to 40 stacks>}`. Before this commit, that grant reached only the guest's own satchel. Now the host journals it and the authority record gains it, which bypasses the guarded `reward_grant` path (`client_grant_refusal` / `_reward_actor`).
- Severity is moderated because admission already trusts the guest's portable file on first visit (`seed_admitted_character`), so this is not a new class of trust. It is a new in-session minting door into an existing record, though.
- Fix: validate against host data. Accept only flags whose consumer is standing in the host scene, with the item and count taken from that node or from config, as `_stormwood_harvest` already does ("Identity, yield and availability come from host data, never the request").

### should-fix #5: every guest pickup now costs a full host world save, and its journal row is kept forever
- `ledger_rpc.gd:403-405, 465-466`: each guest pickup now runs a full `world.save_data()` snapshot plus a synchronous `save_world`. The guest also saves the character on each one (`_persist_reward_character`). Felled piles and caches are frequent. On the ROG Ally this is a possible hitch on the host for every guest pickup.
- `autoload/world_state.gd:504-539`: accepted rows are marked `accepted` and never pruned, so each guest pickup adds a permanent `reward_deliveries` row (sha ids, stacks) to the world file and to every join snapshot. The guest's `satchel_escrow` likewise keeps a settled row for each pickup. Over a 15–25 h co-op run that grows without bound.
- Fix: a retention policy for settled `claim_pickup:` rows, keeping the receipt id only, or batching the saves.

### nit #1: the guest's authority replay does no per-delivery dedupe
- `scripts/net/owner_passive_replay.gd:70-90` (`apply_delivery`) checks that the row exists, the character and the stacks hash, but not that the `delivery_id` was not already applied in this stream. Duplicates are prevented only by sequence numbering and the honest client recording once.
- Scenario: a modified client repeats `reward_delivery_applied` for one id, and the host credits the stacks again. This existed before the commit, but the commit raises its frequency of use.

### nit #2: the "already_taken" text for an existing delivery id is misleading
- `world_ledger.gd:504-505`: if the flag is unset but the receipt exists, the guest is told "Someone else got there first." Currently unreachable because nothing clears pickup flags, but it would mislead if a future respawning find reused a flag. Consider a distinct code such as `already_delivered`.

### nit #3: `station_ground` text
- `scripts/build/station_rules.gd:291`. `station_ground` fires when the ground probe is non-finite or too far from the placement height (build_placer.gd:128), for example over water or off a ledge. "The ground here is uneven" is acceptable. The strings are distinct keys with no duplicates in the literal, so there is no parse risk, and no test asserted the old fallback string for these codes.
- The Altar keeps its own text in `build_placer.gd:1261-1263`, so Altar and other stations word these refusals differently (for example "Something is already here" vs "Something is in the way"). Cosmetic only.

---

## CI-relevant notes
- No parse risks spotted. `FOUNDATION_ACTIONS` is preloaded in session.gd:5, `DROPPED_FLAG_PREFIX` is defined, and `guest_pickup_routed` and `guest_pickup_delivery` are static and called statically from ledger_rpc via `WORLD_LEDGER`.
- `smoke_net_pickup_race` (guest winner): the satchel is now paid through the delivery, so the guest's item depends on `_owner_passive_delivery_ready()` / `_owner_training_blocks_character_write`. If those hold, it arrives on the 0.5 s reconcile poll, which is well within `SETTLE_FRAMES = 300`. Worth watching in the next engine CI run.
