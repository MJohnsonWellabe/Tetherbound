# v1/b24: Cindercub value lift and the existing Voltarach/Brooktail dark lift ship ON

**Arms in `creature_coat_flags.json`:**
- **`creatures_ralph_cindercub_value_lift` (new):** the live owner1101 albedo, midtone gamma 0.78 and saturation x1.12.
- **`remake_owner1101_dark_lift`:** the CAUSE-REMAKES lane's lift for Voltarach and Brooktail, built 1 Nov and never judged until now. It lifts dark, low-saturation texels, feathered, and keeps the eyes, mouth and saturated spots.

**Frames:** `capture_f36_poses.gd --species=voltarach,brooktail,cindercub --whole-body --context`, base (both OFF) and candidate (both ON) from one run (`q_lift4.sh`). Each species is its own stage set (hit 50/100, faint 50/100). CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py` (linear, slope 1.43, intercept -2.12, r 0.93).

| Species | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand |
|---|---|---|---|---|
| Cindercub | 6.52 | **7.38** | +0.86 | 5.7 6.4 6.0 / 6.4 6.9 6.6 |
| Voltarach | 5.28 | **6.04** | +0.76 | 4.9 5.6 5.0 / 5.5 6.0 5.6 |
| Brooktail | 6.18 | **6.28** | +0.10 | 5.5 6.2 5.7 / 5.5 6.4 5.7 |

**Verdict:** all three gain, so both flags ship ON.

**Tests:**
- `test_remake_owner1101_finish`: `remake_owner1101_dark_lift` moves from its held-OFF finish list into `JUDGED_ON` (score in `_why`).
- `test_dark_value_lift_flags`: adds Cindercub.

**What the judges still name:**
- **Voltarach:** a gilt-like gold lattice over the whole shell, and a face that does not read.
- **Brooktail:** only its spots carry the read, the face is lost in faint, and it barely clears the trainer.
- **Cindercub:** a heavy all-over ember-crack lattice.
