# P0 combat_mastery duty backlog (coordinator, 8:04 AM CT 12 Oct)

## Claim vs. reproduction
Claim: older mastery duties are never recognised as accepted, so they never resolve, saves grow and frames crawl.
Reproduction used a real earned save with an undrained queue (`tests/fixtures/earned_saves/tidewake_07_human_late`: 232 retained events, 89 of them mastery). It was loaded through the production title and the production scans ran (`tools/probe_mastery_drain.gd`, output in `probe_tidewake_07.txt`):
- **Duties do resolve and retire.** All 89 drain by frame 89, and every event row retires on its accept through `world_state._settle_retained_duty` (ruling R2, wired in `autoload/world_state.gd`; recognition does not depend on the latest training row). Mastery uses on the cards go from 52 to 141, exactly +89, so no landed use is lost.
- Every real-play fixture's leftover mastery events are **not yet accepted**: none of their receipts are on the character (tidewake_07: 122, meadows_01: 21, tidewake_08_earned: 18). They were saved mid-drain; none is a stuck accepted duty.
- character.json is 2.8 MB at every checkpoint from Meadows 01 onward because of the fog-of-war maps (`realm_maps/*/visited_b64`, ~2.77 MB). That is constant, not growth from mastery.

## The real cost (measured; local timing instrumentation, reverted)
- **Drain:** one mastery duty per scan, with scans every 0.1 s while a backlog exists. Each duty costs ~260–390 ms (stage, then a world save of ~115–160 ms; the owner apply adds a character save of ~180–220 ms). Two to four admissions of ~60–75 ms each come on top. While a fight's queue drains, frames run 0.7–2.6 s. 89 hits took ~110 s of wall time.
- **Idle:** every 1 s scan re-attempts each retained `research_event` row (143 rows here) at ~560–680 ms per scan. That steady hitch hits every player after a long campaign.

## Landed (fix commit below)
- `session.gd`: a scan-scoped memo of `admitted_character_state`, dropped for a peer after any commit that may change it. It removes repeated full admissions inside one scan. `test_foundation_retry_admission`'s per-scan admission counts still hold.
- `test_combat_mastery_delivery.gd`: 60 landed hits through the real journal, stage, owner apply, host acknowledgement and owner settle. Each hit's event retires on accept, no event or settlement entry remains, and all 60 uses are on the card.
- `tools/probe_mastery_drain.gd`: the backlog-save proof above. It drains, keeps every use, and exits 1 otherwise.

## Not landed: needs a decision
1. **Idle research re-attempts.** A cross-scan no-progress memo (keyed by character and world revision) cut the warm idle scan from ~600 ms to ~85 ms. But `test_foundation_retry_admission` asserts "a new scan cannot reuse the previous no-progress observation" (each scan admits fresh), so it was reverted rather than loosening that assertion. Options: relax that contract to a revision-keyed memo, or retire research rows once their research is saturated (they are never retired today).
2. **Drain cost per hit.** Each landed hit is its own training decision with two multi-MB saves. Batching a fight's mastery into one decision (or throttling it in the background) changes the durable schema and needs a design call.

Broad batch (69 session/save/foundation/research/mastery/ledger/owner suites): 585 tests, 11873 assertions. Five failures were found, and the cross-scan memo revert cleared two of them. `test_cloudreach_route_ledger` (2) is a known sparse-checkout artifact (missing report.json). `test_meadows_named_location_ledger_0912` (1) is missing evidence manifests in this checkout, unrelated to code. After the revert, `test_foundation_retry_admission` + `test_combat_mastery_delivery` run 15 tests, 881 assertions, 0 failed.

## Round 2 (coordinator decisions, 9:1x AM CT): 3922d592c, d66a1af54, a5e24d779 and the budget commit
Same save (`tidewake_07_human_late`), same host, nothing else running, timed with temporary local instrumentation (reverted):

| | before (one-by-one) | after |
|---|---|---|
| idle foundation scan (warm) | 560–680 ms every 1 s | **5–10 ms** |
| retained world rows | 242 | **14** (saturated research retired) |
| mastery drain, 89 queued + 33 saturated | 177 s span, 125 slow scans, worst frame ~1.9 s | **123 s** span (~30% faster), worst scan 1.86 s |
| mastery uses on cards | 52 → 141 | 52 → 141 (identical) |

- **Research rows:** a no-progress research duty can never progress, because a species' research only grows. Each scan settles all such duties in one `retained_settle` world op with one world save, and their rows retire. Accepted research settles through R2 `after_accept`. The `test_foundation_retry_admission` assertions are unchanged; its fixture cannot settle, so its rows stay. A loaded old save retires its saturated backlog on its first scan.
- **Mastery batch:** the host's own queued duties run per scan through the exact one-by-one path, with disk writes deferred and peers' deltas held, then one character write followed by one world write. A refusal stops the batch with nothing half-applied. A refused write stays owed and blocks further foundation work.
  - Crash window: the character lands first, and a hit whose receipt the character already holds settles by receipt instead of holding forever.
- **Why the drain gain is only ~30%:** each hit still costs ~0.35 s of host CPU in record validation and projection (journal ~75 ms, owner apply 130–170 ms, accept 140–175 ms), against the ~0.43 s of disk writes the batch removes. An unbounded batch froze one frame for ~30 s, so a batch stops starting new hits after 500 ms (`foundation_mastery_batch_budget_ms`), and the next 0.1 s scan continues.
- **Follow-up recommended:** cut the per-hit validation cost. Each training row re-validates and re-projects the full before and after character several times per hit.

Tests: 33 tests, 1474 assertions, 0 failed across `test_combat_mastery_delivery` (batched == one-by-one for 60 hits; refusal at hit 30 stops both modes at the same place; refused-write retry lands the character before the world; already-held receipts settle; a spent budget continues next scan) and `test_foundation_retry_admission` (116-row saturated backlog retires in one write; a shared event waits for every participant; non-permanent actions can't settle), plus `test_receipt_windows` and `test_retained_settlement`.
Broad 69-suite batch: 591 tests, 12321 assertions. The only failures are the known evidence-file artifacts (`test_cloudreach_route_ledger` x2, `test_meadows_named_location_ledger_0912`) and `test_receipt_windows`'s pinned list, which was updated to the decided state with the windowed-kinds check kept.
