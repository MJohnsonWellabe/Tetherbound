# JUDGE-KIT lane: READY

**State (4 Nov 2026, ~03:00 UTC): the kit works on a real item. Timings were measured and F39#23 parity passes.**

**Tool:** `tools/visual_judge/quick_judge.py` (`plan` / `run` / `capture` / `packet` / `finish` / `revert`). Usage is in `tools/visual_judge/README.md`, with a pointer in TECHNICAL §8.1. The test, `tools/visual_judge/tests/test_quick_judge.py`, has **14 tests, OK**. It covers the stand lookup, the byte-identical overlay apply/revert, crash recovery, the render-only base key and reply parsing.

## Measured timings: F39#23 on CPU llvmpipe, Compatibility, 4 vCPU

| Step | Old flow (creatures-ralph `lane_bin`) | `quick_judge.py` |
|---|---|---|
| Base capture (one `phase2_capture_catch.gd` boot) | 533 s, every round | 443 s once; **0 s on later rounds** (cached per render tree) |
| Candidate capture (one boot) | 478 s | 943 s / 1050 s (after the container restart; see host note) |
| Sheets, anchors, filled prompt | separate scripts by hand | **< 1 s** (`run` prints LAUNCH_JUDGES.md) |
| Three judges, one message | sequential hand-off | **79 s / 125 s** wall |
| Batch, calibrate, VERDICT, sheet | `assemble.py` + `calibrate.py` by hand | **< 1 s** (`finish`) |
| **One A/B round, base cached** | ≈ 17 min of capture plus manual steps (about 1 h per round in the lane, with queues) | **one candidate boot + ~2 min** |

**Host note:** the same single catch boot measured 443–533 s before the container restart and 754 s after it, measured by a `lane_bin` re-run of the same command at 03:16 UTC. So capture time depends on the host: the 943–1050 s candidates ran on the slower post-restart container, not slower for any reason in the kit; on the pre-restart host a cached-base round is about 8 + 2 = **10 min**.

**Speed comes only from plumbing:**
- one boot per tool, with the subsets merged;
- creature `--only` merged and `--poses` narrowed;
- UI `--tabs` narrowed where the tool keeps its framing;
- no import;
- a base cached per render-relevant tree;
- parallel judges;
- scripted packet and finish.

JUDGE_PROMPT.md, the anchors, calibrate.py, the cameras and the resolution are unchanged.

## Parity check: F39#23 re-scored the quick way vs v1/b5 (slow way, tb/creatures-ralph)

Main now ships both readout flags ON, so the base is the shipped look (b5's ON arm). The overlay switches `readout_side_enabled` and `contrast_r2` OFF, which reproduces b5's base.

| Batch | Anchors | Fit | Shipped ON (b5 6.91) | Flags OFF (b5 6.02) | Gain (b5 +0.89) | Defect call |
|---|---|---|---|---|---|---|
| b5 anchor set | craft, f10_2_r3_capacitor, f04_6_r22 (as b5) | linear 1.40, r 0.81, RMSE 0.68 | **6.79** (Δ 0.12) | **5.57** (Δ 0.45) | +1.22 | PRESENT → FIXED 3/3 |
| Default draw | craft, f36_0_gap, f36_0_npc | linear 1.31, r 0.88, RMSE 0.40 | 6.38 (Δ 0.53) | 5.11 (Δ 0.91) | +1.27 | PRESENT → FIXED 3/3 |

- **Verdict: parity passes with b5's own anchor set.** Both arms are within the batch's anchor RMSE (0.68), and within b5's (0.50). The default draw keeps the gain within RMSE (Δ 0.38) but sits about 0.5–0.9 lower, so different anchor draws move the absolute level.
- **The anchors are now pinned by default** (`PINNED_ANCHORS` = craft, f10_2_r3_capacitor, f04_6_r22), so every quick round is comparable with b5's level. Override with `packet --include`.
- **Verdicts:** `qj/parity-f39-23-b5anchors/`, `qj/parity-f39-23-default-anchors/`.

## Lane notes

- **Catch frames have a spawn confound.** With `--seed=2042`, `phase2_capture_catch.gd` still spawns a different wild creature per boot: the judges saw a shell creature on one arm and a frog on the other. That affects every A/B of catch frames, slow or quick. Note it in the verdict, and judge the HUD subject.
- **Long chains must run as tracked background Bash.** A `nohup`/`setsid` chain dies when the container is reclaimed. A restart mid-candidate left the overlay applied; `quick_judge.py revert` restored it byte-identically (sha256 = HEAD blob), and the cached base was reused.
- **Blob-less clone:** `git commit` lazily fetches blobs. Use `write-tree --missing-ok`, `commit-tree` and `update-ref`, and push with `-c pack.window=0` (TECHNICAL §8.1).

## Open candidates

- Per-tool narrowing for more tools; only tools whose filter keeps the framing qualify.
- A two-arm single-boot mode, if a capture tool can re-read config between passes.
