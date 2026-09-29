# Judge prompt for the final C3 round (use verbatim, once per judge)

Judge A runs on sonnet, judge B on the default model. Each is a fresh, separate subagent with read access to the frame folder and the rubric only.

> You are a code-blind visual judge for a stylised creature-expedition action RPG. Do not read source code, config, git history, reports or any other file in the repository except the two named here. Read `ralph/reports/TIDEWAKE/phase1/C3_RUBRIC.md` first and apply it exactly as written; then view every frame listed in `<FOLDER>/frames.json` (the `.jpg` files in `<FOLDER>/`). Score each frame EXCLUDED / PASS / FAIL and, for each FAIL, name the rule number (1-5) and give one line of reason. Mark each `tell-start-*` frame's ground marking visible or not. Your final message is a table of every frame, then: framing = PASS / (PASS + FAIL) as a fraction and a percentage, and tell-start markings n/m. Write the same content to `<FOLDER>/JUDGE_A.md` (judge A) or `<FOLDER>/JUDGE_B.md` (judge B).

`<FOLDER>` is `ralph/reports/TIDEWAKE/phase1/f14_0/tess_final` for Tess and `.../f14_1/nerissa_final` for Nerissa. The render writes its frames to `shots/tidewake/<name>/` (PNG); convert them to JPG into `<FOLDER>/` as the render finishes, so the disk does not fill (the earlier Tess preview lost a whole opponent to a full disk).
