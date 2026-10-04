# F01#3 — Normal-controller NIGHT walk reaches every opening NPC, camp and gate

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3, 1280x720 (CI render.yml resolution for this tool)
- Command: `XDG_DATA_HOME=<fresh> xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 --script tests/capture_village_walk.gd -- --route=visits --time=night --from-title --capture-dir=<dir>`
- Replaces: ralph/reports/MEADOWS/f01-walks night evidence (night_7fe6e703 / code_blind_judge_verdict_night_d41ff2f0.md)

## Harness result: FAIL (exit 1)

`[village-walk] FAIL route=visits time=night: ended 9.32m from Mira (needs 3.0m) (captures=24)`
Visited Grandpa (1.11 m), Tam (1.08 m); Mira and all later targets not reached. Same stall as the day walk (F01-2: 9.29 m from Mira) — reproduced on two independent runs, so not a one-off; the separate day confirm re-run was cancelled.

## Code-blind judge (fresh agent; 24 frames, criterion, target list): FAIL

Defects (verbatim), most important first:
1. Ten of 12 targets are never reached. The walk fails after Tam (024).
2. The route stalls or turns back near the beam without ever reaching the camp or any gate (021–024).
3. Interiors are lit as daytime at night (002–005, 013–014): "Grandpa's room has bright white walls, sunlit window panes and hard daylight shadows. This contradicts the night exterior seen through the doorway in 005." The open arch beside Tam shows the same daylight-bright interior.
4. The start camera is blocked by a wall (001): wall fills the left ~45%; Team panel over the wall texture; a wall-mounted sign clips into the wall edge.
5. Foreground lamp posts obscure the view and the prompt (016, 022, 023).
Also: frame 021 path dark between light pools (still legible); quick-slot panel and button legend cover scene content (e.g. 014 doorway).

Positives noted: village road reads in moonlight; warm windows and amber pools at shop door and lamp posts; trainer readable; no clipping, floating objects or scale breaks.

## Verdict: FAIL
