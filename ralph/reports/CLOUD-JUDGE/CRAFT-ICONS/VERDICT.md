# CRAFT-ICONS (P2-095): cloud yardstick verdict, 1 Nov 2026

GPU capture: tb/gpu-frames-1101 8ebb96dd4, `craft/{main,cand}/meadows__system__crafting.jpg`, High 1920x1080. The candidate is main 2f2901db + tb/world-craft-icons 8ed4a7ca, with `craft_presentation.json` `readable_r3` and `rendered_item_icons` ON.
Judging: `tools/visual_judge/JUDGE_PROMPT.md` v1, three fresh code-blind agent judges, 3 anchor pairs (craft, f36_0_gap, f36_0_npc), `calibrate.py`.

| Arm | Judges (raw) | Mapped mean |
|---|---|---|
| Candidate (icons + r3 ON) | 7.2 / 7.2 / 7.0 | **7.36** |
| Main | 6.8 / 6.6 / 6.4 | 6.80 |

- Gain +0.56. The candidate is over 7. It is under 7.5, so it is not MET under the owner's 7.5 bar, and no Medium run.
- Recorded defect (clipped recipe lines): FIXED 3/3 on both sides.
- Judges' next asks: controller face-button glyphs in a footer, denser rows (5+ visible), higher-contrast "Missing" tags and button, and a warmer meadow backdrop.
- The flags land ON.
