# Shared transaction_receipts cap (4096): growth over a 25 h clear

Assumptions (from config and typical play): day_length_seconds 600 → ~150 host days in 25 h;
a wild fight roughly every 1–2 min in active play → ~750–1500 fights; party of five.

| Kind (receipt) | Writer | Rate | 25 h estimate | Replay guard if evicted | Treatment |
|---|---|---|---|---|---|
| F32 gather `craft:<c>:f32:` | f32_source_actions | every gather | 1500–4000+ | stock/plot revision, forge ticket | window 256 (503483c9) |
| Wild defeat `defeat:<c>:` | essence.stage_defeat | per wild win | 750–1500 | host duty settles once; window = recency margin | window 1024 |
| Shed win `craft:<c>:shed_win:` | f32 compose_wild_shed | per wild win | 750–1500 | same as defeat | window 1024 |
| Trainer round `defeat:trainer_round_*:<c>` | combat_round_reward | per trainer round | 200–600 | host duty | window 1024 |
| Care `care:<c>:<day>:` | essence.stage_care | per creature per day | up to 750 | keyed by host day | keep current day |
| Groom `groom:` | f32 groom | per creature per day | up to 750 | day-keyed care receipt | window 128 |
| Essence spend `essence_spend:<c>:` | essence.stage_core_spend | per Altar level | 250–400 | stale character revision | window 256 |
| Station craft `craft:<c>:<32hex>` | station_actions | per craft | 200–600 | stale character revision | window 256 |
| Bounty decision `bounty:clock_/event_` | bounty_board | 1 rotation/day + claims | 300–600 | anchor day; permanent bounty_receipts | window 128 |
| Once-ever (research, master recipe, starter, relic, portal, ending, release, trait teach, feast feed, home key, waystone, tm, gear, homestead build) | various | bounded by content | < 600 | permanent | never compacted |

Sum without windows: roughly 5,000–11,000 in a full clear, so normal play reaches 4096 and every
foundation action then refuses `receipt_budget`. With windows the steady-state bound is about
256 + 1024×3 + 750 (care, per day ≤ 5) → well under 4096 even with all once-ever receipts.

Proof: tests/test_receipt_windows.gd (every kind bounded, once-ever untouched, station-craft
pattern exact, care by day, and a real ESSENCE.stage_defeat past 4096 receipts: without the
window the defeat after the cap is refused `receipt_budget`, with it all pay and defeats stay
at 1024); tests/test_f32_receipt_window.gd for F32.

## Re-review corrections (review-gather-batching-r2.md)

- **R1 (blocking, fixed):** trainer rounds are retained world duties that count as settled only while
  their receipt exists, so windowing them re-staged old rounds (stalling later duties, or paying again
  at the cap). `trainer_round` is no longer windowed.
- **R3 (fixed):** the budget checks in the windowed writers now count the compacted receipts, so a
  character exactly at 4096 is paid (test starts at 4096).
- **R4 (fixed):** care is no longer compacted: its receipt carries no world namespace, so pruning by
  day could let a return to another world's earlier day pay again.
- **R2 (open, needs a design decision):** the cap is still reachable. `craft:combat_mastery_*` (one per
  landed hit until a move reaches 300 uses, ~6000 per five-creature lineup) and trainer rounds cannot
  be windowed for the same reason as R1, and care (~750) stays. Bounding them needs retained duties to
  carry a durable per-character settled marker in the world row (or be retired once every recipient
  settles), after which their receipts can be windowed.
