# Independent review r2: gather batching fixes and receipt windows (tb/f17)

Commits reviewed:
- 99886a5e "review blockers B1-B3 and should-fixes"
- 0af0fd27 "high-frequency receipt kinds stay bounded under the 4096 cap"

Prior review: `review-gather-batching.md`. Line numbers are HEAD of tb/f17 (99886a5e).
Every finding below comes from reading the code. No suite was run for this review.

**Verdict: 1 blocking finding (R1, in 0af0fd27).** 99886a5e closes B1, B2, B3, S1, S2, S4, S5, S6, S7 and N1 as claimed. It has no blocker. It has one unverified residual risk (G1).

## Blocking

### R1. Windowing `trainer_round` reopens every old retained round duty. Result: a permanent duty hold, or stale HP re-applied in a loop
Files:
- `data/config/receipt_windows.json` (`trainer_round: 1024`)
- `scripts/net/combat_round_reward.gd:202`
- `scripts/net/session.gd:918-925` and `:984-986`
- `scripts/net/foundation_retry_order.gd:11-30`
- `scripts/net/foundation_event.gd` (rows stay `status: "retained"` and are never erased; `reward_deliveries.erase` appears only in the gather code)

How a duty is recognised as settled today:
- Every `combat_round_reward` duty stays in `world.reward_deliveries` forever as a retained `foundation_event`.
- `_retry_foundation_events` runs once a second (`foundation_composition.gd:66-78`).
- It skips an old duty only when `latest.after.redesign_character.transaction_receipts.has(receipt)`. Here `latest` is the character's single training row in this world, and its `after` is the full current record.
- So "settled" means "the receipt is still in the record". Nothing else marks the duty done.

What the window changes:
- After 1024 newer trainer-round receipts, counted across all worlds, the oldest round receipt is dropped from the record.
- Its retained duty in this world stops being skipped and is staged again through `FOUNDATION_ACTIONS.commit`, then `combat_round_reward.stage`.
- `stage` no longer finds the decision receipt (`:170`), so it runs `settled_before` against the current party.

Two outcomes:
1. **Usual case.** The party's `max_hp` or bench HP no longer matches the frozen `settled_vitals`, so the stage denies `actual_terminal_round_required` with `resolved: false`.
   - `session.gd:984-986` notes a hold and sets `handled[character]`.
   - `ordered()` puts progression duties first once the latest row is accepted, so this stale duty comes first on every scan, permanently.
   - Every later duty for that character in that world is starved: combat mastery, research, bounty events, and the **current fight's round reward**. The fight's next round waits on that reward (`session.gd:978-983`), so trainer fights stall.
   - This also hits the host's own solo character, because the local peer goes through the same scan.
2. **Endgame case.** The party is at the level cap with unchanged `max_hp` and full HP, so `settled_before` passes. The old round pays again:
   - `actor_vitals_delivery.settled_card` writes the old round's HP and fainted state onto the current creatures.
   - The new receipt evicts the next-oldest round, which the next scan stages again.
   - The result is one journal row, one owner save and one stale-HP write per second, without end.

Scenario: a long save (the game is meant to be "fun to grind") passes 1024 trainer rounds, counting rematch rounds. From then on, in the home world where the early rounds happened, every foundation duty for that character holds, or the HP loop starts.

Not affected:
- `wild_defeat` and `shed_win`: their retry source is the in-memory `_retained_host_wild_source` of a live encounter (`session.gd:5210-5263`), so the recency argument holds.
- `bounty_event`: also a retained duty matched by the `bounty_decision` window, but a re-staged old event ends in `no_matching_bounty`, which the scan lets through. The cost is per-second re-staging of every evicted event: the full record is deep-copied once per event per scan. That is a performance nit.

Fix options:
- Drop `trainer_round` from the windows. The ESTIMATE puts it at 200-600 per clear.
- Or give retained duties a durable settled marker that does not depend on the receipt staying present. Either a world-side settled set keyed by the duty, or prune or mark the retained event once the latest row containing its receipt is accepted.

Add a test: 1025 accepted trainer rounds, then one `_retry_foundation_events` scan.

## Should-fix

### R2. The cap is still reachable. The commit's goal ("never reach 4096") is not met
Files: `ralph/reports/HUB/f17/receipt-cap/ESTIMATE.md`, `data/config/receipt_windows.json`.
- **The windows already add up to the cap.** 256 (F32) + 256 (essence) + 3×1024 + 128 (groom) + 256 (station) + 128 (bounty) = **4096**.
  - That is before today's care receipts and before any once-ever or unwindowed receipt.
  - The ESTIMATE's bound ("256 + 1024×3 + 750") leaves out four of the windows.
- **Unwindowed kinds the ESTIMATE does not list:**

| Kind | Rate | Bound |
|---|---|---|
| `craft:combat_mastery_<sha>:<c>` (`foundation_actions.gd:91`) | One per landed hit while a move has fewer than 300 mastery uses (`encounter_host.gd:685-690`) | 5 creatures × about 4 moves × 300 is about 6000 per lineup, more as moves change. Over 1000 fights this alone passes 4096 in a normal clear. |
| `rematch:...:win:` (`rematch_rules.gd:157`) | Every rematch, the repeatable grind loop | Unbounded |
| `craft:<c>:den:` (den rests) | Repeatable | Unbounded |
| `craft:<c>:loadout_` (loadout edits) | Repeatable | Unbounded |
| `craft:<c>:camp:` and `camp_bed:` (camp actions) | Repeatable | Unbounded |
| Capture tokens | Repeatable after a release | Unbounded |

- combat_mastery cannot simply be windowed: its retained duties use the same settled check as R1.

### R3. The cap check runs before compaction, so windowed writers still refuse at the cap
- These writers test `size() >= maximum_transaction_receipts` on the uncompacted list:
  - `essence.gd:555` (defeat), `:260` (spend), `:909` (care)
  - `combat_round_reward.gd:171`
  - `bounty_board.gd:187`
- Compaction runs only afterwards. Once unwindowed growth (R2) brings the list to 4096, every windowed kind is refused `receipt_budget`, even though compacting would keep the size at 4096.
- `compose_wild_shed` and F32 compact first and then check. The others should do the same.
- The proof test uses 4095 receipts, so it never exercises this.

### R4. `compact_care` ignores the world namespace, so cross-world grooms rest on the 128-groom window alone
File: `receipt_windows.gd:74-83`.
- Care receipts are `care:<c>:<day>:...` with no namespace. Compaction drops every care receipt from a day below the current world's day.
- Scenario:
  1. Groom creature X in world A on day 50.
  2. Play in world C on day 60, which drops A's day-50 care receipts.
  3. Return to world A while its clock is still on day 50 (its host has not played).
- `stage_care` then finds no care receipt, and the daily cap resets. Only the groom shed receipt (`groom:` window 128, identity includes the world and day) still refuses the groom.
- After more than 128 grooms elsewhere, roughly 26 days at 5 a day, creature X can be groomed again on A's day 50: the care essence and the shed pay twice.
- Low likelihood. The documented claim "day-keyed kinds are guarded by the day" holds only per world.

### G1. Residual B1-class risk: owner-passive recovery may replay a delivery input after its row was pruned (unverified)
Files: `owner_passive_sync.gd:236-266`, `:319`, `:444-454`; `gather_batches.gd:156-168`.
- A row is pruned once it is accepted and in `replayed`. `replayed` is set when the in-memory host stream applies the input, not when an owner checkpoint that covers it is saved.
- If the guest departs after the replay but before that checkpoint, the recovery stream starts from the last prepared checkpoint (`_recovery_candidate(prepared.before/after)`).
- If the re-sent inputs include that `reward_delivery_applied`, the lookup at `:445` finds no row. That gives `unproved_delivery_input`, which is the terminal stream error B1 was about.
- I could not confirm from the code whether recovery re-sends inputs that precede the departure. Add a two-peer test for this sequence: gather, flush, settle, replay, ACK, prune, then disconnect before the checkpoint and reconnect. Alternatively, prune only after the checkpoint that covers the input has been saved.

## Nits

- **N-a.** `harvest_node.gd:151-156` reads `items` through `/root/Game` only when `is_inside_tree()`. A node set up in a detached shell registers `tool: ""`, so a guest gets the full `count` from a tool-gated node without the tool. Load `ITEM_DB` directly instead.
  - Also, the host tool gate (`world_ledger.gd:601-603`) checks that the tool id is present, not that the tool still works. A broken tool still passes, while the client's `HARVEST_LOGIC.tool_slot` refuses it.
- **N-b.** The `replayed` list is capped at 64 (`gather_batches.gd:146`). If more than 64 rows are replayed but not yet accepted (the guest's ACKs keep failing), `gather_replayed` is refused and ignored. Those rows are never pruned, and the guest's escrow for them is never pruned either. The leak is bounded, but nothing logs it.
- **N-c.** `RECEIPT_WINDOWS.window()` re-reads and re-parses `receipt_windows.json` on every stage and every validator re-stage. `DATA.json` is uncached.
  - The owner-side validators (`foundation_delivery.valid:35-40`, `training_transition_valid`) re-run the stage, compaction included. Host and owner builds with different window configs would therefore reject each other's rows. Note this as a version-skew constraint.
- **N-d.** The `station_craft` pattern `craft:<c>:<32 hex>` also matches feast cooks (`breakthrough.gd:156`). That is safe: they are repeatable and their revision is checked. The comment should say so.
- **N-e.** Dev worlds saved with the pre-99886a5e batch shape (`acked`, integer `replayed`) now fail the schema and do not load. Those saves exist only on tb/f17, since 48813e94 never landed.

## Verification of the 99886a5e claims

| Finding | Closed? | Notes |
|---|---|---|
| B1 | Yes (see G1) | `pruned()` erases only rows that are both accepted and listed in `replayed`, per row. An earlier batch still in `grant_due` keeps its row until its own replay. `reward_delivery_accept` prunes rows already replayed. The order of replay and accept does not matter. Every peer applies the same steps. |
| B2 | Yes | The guest erases a settled escrow row only for this world's namespace, and only when the row is missing from its mirror of `world.reward_deliveries`, which `reconcile_reward_deliveries` already relies on. A pending row with a failed ACK stays. A row from another world stays. |
| B3 | Yes | No prefix inference remains. Key and TM pickups register in `setup()`. A forged `pickup:`/`tm:` flag falls back to the local-only grant. |
| S1 | Yes | A 2 s host scan seeds timers for open batches loaded from a save. A departed character's flush has no player op, and its row waits for rejoin. |
| S2 | Yes | Config is cached in a static. |
| S4 | Yes | `accrued` refuses when the batch would exceed 24 stacks or 4× `max_hits`. The world flag is not taken when refused. |
| S5 | Yes (see N-a) | The gate reads the tool from the admitted authority inventory. Bare-handed gathering of a tool-gated node yields 0 in `harvest_logic.gather` anyway, so this is no regression. |
| S6 | Yes | The pre-action flush is removed. |
| S7 | Yes | One-time finds are consumed on a successful claim. Non-renewable harvest nodes are freed for good, and renewable ones never register. |
| N1 | Yes | `batch()` returns {} for a corrupt row. Callers refuse it, and the scan skips it. |

## Answers on 0af0fd27, kind by kind

| Kind | Can an evicted receipt pay twice? |
|---|---|
| essence_spend | No. A resend carries its old envelope revision, which `session.gd:526` / `context.expected_revision` refuses, and `stale_level` refuses it too. A resend at the current revision is simply a new paid spend. |
| station_craft (and feast cook) | No, for the same revision reason. |
| wild_defeat, shed_win | No in practice. The retry source is an in-memory live encounter, and the latest-row duplicate path checks the latest row only. |
| trainer_round | **Yes, or the duty holds (R1).** |
| care | Only across worlds, and only after more than 128 grooms (R4). |
| groom | No. The groom identity includes the world and day, and today's care receipt is kept. |
| bounty_decision | No payout. Rotations grant nothing, and claims are guarded by the permanent `bounty_receipts`. Old events end in `no_matching_bounty`; the per-second re-stage cost is the perf nit in R1. |

- **Do owner or host checks expect `after == before + [receipt]`?**
  - None found. `foundation_delivery.valid` re-stages from `before` (deterministic, compaction included) and checks only `!before.has(r) && after.has(r)`.
  - `owner_plan`, `combat_round_reward.owner_plan` and `stage_training_owner` compare whole records with `_equivalent`.
  - `character_record_rules` has no receipt-list arithmetic.
  - Owner-passive replay never inspects receipts.
  - The only check that breaks is the session's retained-duty skip (R1).
- **Is a once-ever receipt ever matched by a window pattern?** No:
  - Boss receipts start `defeat:boss_`.
  - Gear, TM, relic, ending, homestead and altar builds have non-hex tails.
  - Starter, portal and the remaining once-ever kinds use other prefixes.
  - The only extra match is feast cooks (N-d), which are repeatable.
