# Stormwood and Water survey results — 2026-09-19

## Outcome

This evidence-reconciliation changes both inherited visual summaries without changing game content:

| Biome | Current visual ledger | Current content floor | Readiness |
|---|---:|---|---|
| Stormwood | **0 PASS / 5 POLISH / 7 FAIL / 0 unknown** (12) | **63 / >=160** dialogue conversations; **8 / 12** live recipes; **533** explicit replacement points | Does not clear the visual or content bar. |
| Water | **0 PASS / 2 POLISH / 22 FAIL / 0 unknown** (24) | **0 / 6** side chains; **12 / 28-32** main objectives; **0 / 3** accepted settlements | Fully surveyed, but does not clear the visual or content bar. |

The two important corrections are:

1. Stormwood's previously invalid Crown Arch row now has valid ordinary-camera day/night evidence and independent rejection. It is **FAIL**, not invalid/unknown.
2. Water's 22 supposedly unknown destinations were already covered by a complete corrected-camera 48/48 day/night catalogue and independent location-by-location review. They are **surveyed FAIL**, not unknown. First Shore Welcome Beacon and First Shore Horizon Stones were subsequently promoted to **POLISH** by accepted September 11 production receipts.

Detailed ledgers and census provenance are in:

- `ralph/reports/STORMWOOD-PROGRESS/STATUS-SURVEY-2026-09-19.md`
- `ralph/reports/WATER-PROGRESS/STATUS-SURVEY-2026-09-19.md`

## Method and grade rule

- Read all reports under `STORMWOOD-PROGRESS` and `WATER-PROGRESS`, the later relevant `FOUR-BIOME-BUILD` material, and later Water/Stormwood receipts under `BROAD-VISUAL-0910` and `FOUR-BIOME-CONTINUATION-0910`.
- Recounted the requested content floors from current `origin/main` data in this worktree rather than carrying the handoff figures forward.
- A row is promoted only by valid production evidence with an accepted independent disposition. A narrow material preference, held candidate, test pass, or gameplay traversal receipt does not promote a whole named location.
- A complete valid survey with a negative independent presentation finding is `FAIL`, not `unknown`.
- `unknown` is reserved for a genuinely absent or invalid visual verdict. There are none left in these two ledgers.

## Capture decision and render lock

No new screenshots were captured. The committed evidence already contains:

- Stormwood: 24/24 corrected-camera production frames, plus later Crown Arch and other targeted receipts.
- Water: 48/48 corrected-camera production frames, complete manifests and per-location independent findings, plus later targeted material/location receipts and the two September 11 First Shore promotions.

A new broad capture would have duplicated valid evidence without changing the conservative ledger rule. Because no screenshot capture was attempted, this lane did not claim or modify `D:\tetherbound\RENDER_LOCK.json`.

## Evidence lineage

| Claim | Primary committed evidence | Commit / PR note |
|---|---|---|
| Stormwood corrected full catalogue | `FOUR-BIOME-BUILD/audit-resume/STORMWOOD-CAMERA-RESURVEY.md` | `1a357d3e`; no PR number is encoded in the local report/commit metadata. |
| Stormwood independent full review | `FOUR-BIOME-BUILD/audit-resume/JUDGE-STORMWOOD.md`, `REJUDGE-STORMWOOD.md` | review history includes `2f41763a`; no recoverable PR mapping locally. |
| Crown Arch valid evidence and rejection | `FOUR-BIOME-BUILD/STORMWOOD-CROWN-ARCH-0909.md` | `e42ff4a1`; held, A No / B No. |
| Stormwood retained palette direction | `BROAD-VISUAL-0910/STORMWOOD-PALETTE01-RETAINED.md` | `44473241`; retained improvement, not a location promotion. |
| Deepwood Circuit connected path | `BROAD-VISUAL-0910/STORMWOOD-DEEPWOOD-CIRCUIT01.md` | `4e150c65`; one connected side chain, not part of the requested Stormwood floor. |
| Remaining five Stormwood side chains incomplete | `BROAD-VISUAL-0910/STORMWOOD-SIDE-CHAIN-REMAINDER.md` | `5a3f6c56`; no PR mapping in local metadata. |
| Water corrected full catalogue | `FOUR-BIOME-BUILD/audit-resume/WATER-CAMERA-RESURVEY.md` | `bffd531a`; no PR mapping in local metadata. |
| Water independent 48-frame review | `FOUR-BIOME-BUILD/audit-resume/JUDGE-WATER.md`, `REJUDGE-WATER.md` | rejudge at `2f41763a`; all 24 locations covered. |
| Water terrain/material refinement | `BROAD-VISUAL-0910/WATER-MATERIAL-01.md` | `ce6f5ccc`; modest retained improvement, commercial-quality No. |
| Water horizon correction | `BROAD-VISUAL-0910/WATER-HORIZON01-CANDIDATE.md` | `8c1b0edc`; narrow defect correction, not location acceptance. |
| Two First Shore POLISH promotions | `FOUR-BIOME-CONTINUATION-0910/.../FIRST-SHORE-HORIZON-STONES-R2/REPORT.md` and `.../FIRST-SHORE-WELCOME-BEACON-R3/REPORT.md` | `f2c972be`; no PR number encoded locally. |
| Water objective text/current 12-row file | `data/config/water_objectives.json` | `65267c4b`, explicitly associated with PR #89 in the commit subject. |

Where a report names a branch or candidate but local history does not preserve a PR number, this report cites the landed commit and marks the PR mapping unavailable instead of guessing.

## Final disposition

Neither biome clears the bar. Stormwood has five locations at POLISH but no PASS locations, seven FAIL locations, and large dialogue/recipe gaps. Water has complete survey coverage but only two POLISH locations, 22 FAIL locations, no side-chain implementation, only 12 main objectives, and no accepted settlement. This lane made no implementation changes; sequencing any future production work remains an owner decision.
