# F35#3 four ultimates on one frame: recapture after the attacker-pose fix

Captured Sun 11 Oct 2026, finished about 3:14 PM CT, by the captures lane. This lane captures; it does not judge.

- **Source:** tb/ev-ultimates `e6fef6aad` (ultimates lane's CAPTURE-READY). The fix: re-showing the posed attackers had re-enabled their physics and they fell through the stage, and the smoke now fails if any attacker leaves its pose. Run in a detached worktree at that SHA; Low/Compatibility (llvmpipe), 1280x720, `--fixed-fps 30`.
- **Tool:** that commit's `tools/capture_f35_four_contact.gd` with `--batch=ultimates --simultaneous=ultimate_terrapup,ultimate_veridian,ultimate_fulgocobra,ultimate_solmane`. Beats (travel, contact, peak, late) are timed on game frames; the camera is elevated on the target's side.
- **Result:** 84 frames; all 4 effects arrived (contact at game 0.80 s); `failures: 0` (`results-four.json`). All four attackers stay posed and visible in every frame.
- **Limits:** stage presentation, not an earned four-player fight.
