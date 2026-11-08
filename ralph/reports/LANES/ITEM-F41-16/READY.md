STATUS: land
BRANCH: tb/item-f41-16  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, queue row 12 part (coordinator 8 Nov): F41#16 P2-110 Hollows fight loss result clarity. This is a stand fix only, with **no score claim and no judge round** (the coordinator said to skip it).

## The defect in the stand
- In `ralph/reports/VISUAL/item-scores/job.json`, both F41#16 "loss" frames (`stormwood__fight__hollows_long__hollows_alpha-i13`, `-99-after`) ran `tools/phase2_capture_stormwood_fights.gd --ids=hollows_alpha ... --seed=2042` with no party level. The tool's default is its **win** fixture (party level 80, pilot input), so the "loss" frames showed a win and no loss-card change could ever score.
- The tool already carries the loss case as a disclosed fixture, so no boundary-save generator profile is needed: `--party-level=42 --input-policy=idle-after-engage`, which its own docs call "the original loss fixture". Idle input requests no attacks or evasions; it does not force the outcome.

## Change
- `job.json`: the two F41#16 frames' `repro` gains `--party-level=42 --input-policy=idle-after-engage`. They were the only frames using that exact command; no other row changes. `quick_judge.py` and the GPU re-judge read this file, so both now shoot a real loss.
- `hud.json loss_card` is ON (code-blind PASS 12 Oct) and is unchanged.

## GPU re-baseline list (from this lane)
- **F41#16**: re-shoot on the corrected loss stand; live has loss_card ON.
- **F39#19** (Tidewake fight roster): the roster no longer fades on today's main, so the 28 Oct GPU 5.78 predates the live roster (`ralph/reports/LANES/ITEM-F39-19-ROSTER/READY.md` on tb/item-meshy-recheck-parked).
- **F38#30 / F38#24** (Warrens): score the re-seated walk_03 (`tb/item-f38-30-stands`).

## Pre-ready check
- JSON parse of `job.json`; a diff of 2 lines (the two repro strings). No test reads this file: `git grep item-scores` over tests/ and tools/visual_judge/tests found nothing.
