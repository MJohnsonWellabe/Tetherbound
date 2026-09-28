# F04#7 C3 half, "varied-size framing and the C3 blind fight-footage verdict": the pass bar for the final judge round

This bar is written before any frame of the final round is rendered or seen, and it does not change after that. It is given to both judges unchanged, together with `ralph/reports/TIDEWAKE/phase1/C3_RUBRIC.md`, before the frames. This is the criterion's one final round (coordinator, 2026-09-28 22:04). It is rendered on `main` after the Combat Spacing PR merges. If it fails, the remaining defects go into STATE and to the coordinator, and no further round is started.

The C2 half is already MET (Balance lane, ruling 12) and is not re-judged here.

## Sources
- **COMBAT (camera):** "Camera must show both combatants' facing and the actionable tell in 90% of active combat samples; no continuous actionable-tell occlusion longer than 0.25s."
- **ACCEPTANCE §6.1 F04:** "Varied-size framing and C2/C3 results pass."
- **C3_RUBRIC:**
  - the per-frame EXCLUDED, FAIL and PASS clauses;
  - two independent code-blind judges, one on sonnet and one on the default model;
  - a pass needs both at 90% or more, and every tell-start frame showing its marking.
- **CLAUDE_START_HERE §4, row 8:** the DIVER's 0.4 s tell has a harness exemption, which BOSSES allows with a long positional cue. A DIVER tell-start frame whose marking is visible passes clause 5 even though the tell is shorter than 0.8 s.

## Body sizes
The player's creature is each of the fixture starters that `capture_named_fight.gd --ally=` supports:
- **Terrapup:** the default and the largest body. It uses the F04#1/#2 final captures and the Warden and Dell captures.
- **One small starter per fight**, the same pairing as JUDGE_C3_small_257839f5:
  - **Galewisp** for the Warden, Halder and Vance;
  - **Ripplet** for Vess, Oreth and Dell.

## Frames
Rendered with render.yml at 1280x720 on main. Each capture runs `tools/art_pipeline/capture_named_fight.gd --trainer=<id> --attack --dodge --tell-frames --keep-alive`, with `--ally=<small starter>` for the small-body set. That is six fights × two sizes.

Per capture the judges see:
- the tell frames `tNN-*`;
- the in-fight frames `01`–`24`;
- `RUN.txt`.

The aftermath frames `a*` are not fight frames and are not scored.

## Scoring
Each judge scores every fight frame EXCLUDED, PASS or FAIL per C3_RUBRIC. The judges' verdicts are archived as `JUDGE_A.md` and `JUDGE_B.md` in this folder.

## Verdict
- **PASS:** for each of the 12 captures, both judges score it at 90% or more PASS among non-excluded frames, and every tell-start frame shows its marking.
- **FAIL:** any capture falls below that for either judge. The failing captures, frames and clauses are listed.
- The 0.25 s clause is reported as unverified.
