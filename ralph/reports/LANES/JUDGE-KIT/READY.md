# JUDGE-KIT lane: READY

**State (4 Nov 2026, ~01:00 UTC): the kit is usable. Timings and the parity check are still open.**

**Delivered on `tb/judge-kit-1104`:**
- `tools/visual_judge/quick_judge.py` (`plan` / `run` / `capture` / `packet` / `finish` / `revert`), with `tools/visual_judge/README.md` and a TECHNICAL §8.1 pointer.
- `tools/visual_judge/tests/test_quick_judge.py`: **13 tests, OK** (`python3 tools/visual_judge/tests/test_quick_judge.py`). It covers:
  - the stand lookup (F39#23, P2-114 → F39#23; every job.json frame maps to exactly one launch; creature boots merged);
  - the overlay apply/revert, byte-identical on oddly formatted JSON. This includes a failing capture, a bad overlay mid-apply, a crash recovered with `revert`, a refused second overlay and a refused already-ON flag;
  - judge-reply parsing and A/B assembly.
- An end-to-end check without Godot: synthetic frames → `packet` (3 anchor pairs incl. craft, filled prompt, hard-linked `reference/`) → fake replies → `finish` (calibrate.py, VERDICT.md, `_sheet` under 1.5 MB). All steps ran clean.

**Where the hour went, and what the kit removes:**
- Whole-biome launch groups. The kit captures only the item's own stands. F39#23 is 1 boot per side. F38#1+F38#2 drop from 3 creature boots to 1 (`--only` merged, `--poses` narrowed).
- A fresh base every round. The base is cached per tree, so a second arm on the same head captures only the candidate.
- Hand-built sheets, prompts and batches. One command builds the packet, and one `finish` produces the verdict.
- The judges. Three run in one message, in parallel.

**Open:**
1. **Measured timings, before and after.** This container has no disk to install or import Godot: about 100 MB free, with a 21 GB `.git` pack. Re-cloning shallow needs owner or coordinator OK. In a lane with an imported tree, run `quick_judge.py run F39#23 --overlay '{"data/config/capture_readout_visual.json": {"readout_side_enabled": true, "contrast_r2": true}}'`. `round.json` → `timing` records the base, candidate and wall seconds.
   - Note: F39#23's two flags shipped ON on creatures-ralph. On a head that has them, invert the overlay (set both `false`) to reproduce v1/b5's A/B.
2. **Parity:** re-score F39#23 the quick way against v1/b5 (CPU 6.02 → 6.91 mapped, RMSE 0.50). It passes if the result is within the anchor RMSE.
