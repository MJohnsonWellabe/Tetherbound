# F10#2 C3: the six Stormwood named fights on the current fight camera (Phase 1)

F10#2's criterion (ACCEPTANCE §6.1 F10; card S2) is that the named fights pass C2/C3. The C2 half is met: the Balance lane's starter parity (#413) ran `smoke_stormwood_b_named_c2c3 --seeds=24` with 18/18 rows passing and a worst single hit of 0.105 of HP. This folder closes the C3 half:
- tells ≥ 0.8 s and heavy tells ≥ 1.1 s;
- framing and readability pass at actual creature scale;
- a real hit or avoidance is visible,

all re-captured on the current fight camera and HUD, as `CLAUDE_START_HERE.md` §4 asks.

## Capture
- **Head:** tb/stormwood feba5de9, the S1 landing head, which includes main through #423. The Stormwood-B commits 07bc9cad, 45927814 and 85ba1c57 remain reverted: the footage did not need them.
- **Command:**

      XDG_DATA_HOME=<tmp> xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 10 --script res://ralph/reports/STORMWOOD/b/f10_2/capture_named_fights.gd -- --out=<raw> --seconds=12 --interval=1.0

- **Post-processing:** `ralph/reports/STORMWOOD/b/f10_2/make_sheets.py` turned the frames into 960x540 JPGs and per-fight sheets. They were renamed to neutral letters from a shuffled key, which was kept outside the packet while judging.
- **Logs:** `capture_log.json` (per-fight summary) and `capture_stdout.txt`.
- **Later change:** main's a8aafa0d (merged after this capture) rewords the CHARGER and DIVER wind-up text to "CHARGE — step off the lane" and "DIVE — step out of its line". The frames show the earlier "incoming — move" wording; fight camera, timing and AI are unchanged.
- **Independent strict re-check: MET.** It spot-checked five cited frames and matched the judge's hit and miss claims against the log.

## Tells and hits (from `capture_log.json`)
| Fight | Engaged by | Tells (authored -> measured s) | Enemy hits on ally | Enemy misses | Frames |
|---|---|---|---|---|---|
| hollows_alpha | Engage press | 0.8->0.85, 0.8->0.85, 0.8->0.80, 0.8->0.85 | 2 | 2 | 36 |
| capacitor_alpha | aggressive named wild initiated | 0.8->0.87, 0.8->0.87 | 1 | 1 | 24 |
| crown_guardian | Engage press | 0.85->0.90, 0.85->0.85, 0.85->0.90, 0.85->0.90 | 2 | 2 | 36 |
| old_rodfolk_hall_guardian | aggressive named wild initiated | 1.1->1.10, 1.1->1.10 | 0 | 2 | 28 |
| blackwater_elder | Engage press | 0.8->0.85, 0.8->0.85, 0.8->0.85, 0.8->0.80 | 2 | 2 | 33 |
| glass_field_alpha | aggressive named wild initiated | 0.8->0.85, 0.8->0.80, 0.8->0.80, 0.8->0.85 | 2 | 2 | 36 |

Capacitor Alpha's 0.8 s strike tell follows its 1.1 s route cue (BOSSES §7). This capture measures only the strike tell, not the route cue; the strike tell meets the 0.8 s floor on its own. Crown Guardian's 0.85 s at x1.5 power is authored explicitly in BOSSES §7. No measured tell is shorter than its authored value; the extra 0.05 s is frame quantisation at 10 fps.

## Code-blind judge (`JUDGE_ANSWERS.md`)
The judge could open only `judge_packet/` and `frames/<letter>/`. The prompt is `judge_packet/JUDGE_PROMPT.txt`: the C3 bar and questions (a)–(d) from the accepted `b/f10_2/c3_close/final` round, with the HUD description updated for the top-right target plate and the panel fade.

**Verdict: all six fights C3 PASS.**

| Letter | Fight | (a) tell visible | (b) where it hits / where to go | (c) both readable at scale | (d) hit or avoidance | C3 |
|---|---|---|---|---|---|---|
| K | glass_field_alpha | PASS | PASS | PASS | PASS | PASS |
| V | capacitor_alpha | PASS | PASS | PASS | PASS | PASS |
| W | hollows_alpha | PASS | PASS | PASS | PASS | PASS |
| X | old_rodfolk_hall_guardian | PASS | PASS | PASS | PASS | PASS |
| Y | crown_guardian | PASS | PASS | PASS | PASS | PASS |
| Z | blackwater_elder | PASS | PASS | PASS | PASS | PASS (the weakest) |

**Look defects the judge recorded** (not blocking; Phase 2 catalog or F10#6):
1. "It missed you" while Sparkit stands inside the marked lane (W tell4). The judge saw no dodge cue.
2. The pale-gold impact starburst veils the opponent's wind-up (X, Y, Z).
3. The warning text fades with the target plate while the opponent is behind it (W tell3-c-late). This is the F10#6 subject fade; the plate is being taken out of the fade.

## Disclosed shortcuts (relaxed proof, owner 2026-09-27)
- The party is five level-42 creatures, and Sparkit leads every fight.
- The player is debug-placed 4.5 m from each named body, and the gated regions are reached by placement.
- Other wilds within 25 m are hidden.
- The storm is pinned in Calm.
- Rendering runs at a fixed 10 fps.
- The ally is steered by harness stick input and quick taps, and backs out of the lane on two tells in three.
- Each fight is cut at the 12 s cap.
- The HUD is the real fight HUD.
