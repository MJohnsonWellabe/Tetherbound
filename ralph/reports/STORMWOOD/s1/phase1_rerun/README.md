# Card S1 Phase 1 re-run (tb/stormwood, after F09#3 landed)

Command (headless, Godot 4.7):

    godot --headless --path . --script tests/smoke_stormwood_continuous.gd -- --through-aftermath --witness-dir=user://swrun_s1 --checkpoint-dir=user://swcp_s1
    godot --headless --path . --script tests/smoke_stormwood_continuous.gd -- --witness-dir=user://swrun_s1 --verify-reload

| Run | Head | Result | Cause |
|---|---|---|---|
| 1 | b0c10d8c | FAIL at Officer Nysa (`run1_fail_nysa_midfight.txt`) | A wild engaged on the walk to Nysa; her answer was the mid-battle refusal (her "defeated" line) and the retry waited on a challenge that cannot open during a fight. Harness fix b4eed78d: fight out an engaged wild before retrying. |
| 2 | b4eed78d | FAIL at the Ashfoot Break wait (`run2_fail_break_wait_contention.txt`) | The 120 s wall-clock wait ran while three llvmpipe renders shared 4 cores. Infrastructure; one confirming re-run alone. |
| 3 | 28012b3a | FAIL at Officer Nysa (`run3_fail_nysa_tavi_press.txt`) | A wild engaged during the interact tap; the fight's trainer-aside step put the player 1.9 m from circuit Tavi and the same press opened Tavi. Second failure at this spot, so the approach changed: the press helper now recognises a press a starting fight displaced, closes the stray line, fights the wild and retries (0068c542). The game-side cause (interact is not gated on a starting fight) is a STATE finding for X03. |
| **4** | **0068c542** | **PASS, EXIT 0; reload EXIT 0** (`run4_pass.txt`, `run4_reload_pass.txt`) | The same Nysa race recurred ("the press landed on … Tavi … as a wild engaged (fighting=true)") and the retry handled it. Six witness steps PASS; safety total 1 trainer death, 1 satchel recovery, 5 strike hits over 92 warnings. |

Commits after 0068c542 on the landing branch change presentation only (combat HUD font floors, dimmed-cell contrast, the move grid kept under the miss line, the vitals chip alpha, the Day/time size) plus a `trainer_aside` tunable left at its original offsets; no route, flag, reward or fight rule.

Shortcuts disclosed: as `../README.md` (Cloudreach-boundary fixture start, L44 fresh five, granted tools, 8x clock with fights and presses at 1x, harness input and fights, helper routing B1-B8).
