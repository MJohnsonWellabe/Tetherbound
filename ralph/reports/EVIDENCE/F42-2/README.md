# F42#2 (+F10#6) — fight HUD shows ultimate meter, command meter and move slots without clutter; 7-inch judge — CAPTURE-READY

systems-b, Sun 11 Oct 2026 (CT). Taken over from fights/ultimates.
Fixes found by the live capture:
- b22eb20f1: the F42 overlay was 0×0 (set_anchors_preset keeps the rect), and its move cluster was positioned from the top-left. In a live fight no move slots, ultimate ring or command lane drew, and the legacy grid was hidden.
- 00ce19bcf: the ultimate caption wrapped one letter per line and pushed the move diamond off-screen.
- New `tests/test_combat_system_overlay_layout.gd` fails before both fixes and passes after.
- Also c8fd78886: trainer fights no longer show the catch-aim prompt.
Capture (real path: production Stormwood scene, HUD and CombatManager; disclosed fixtures as in the tool header):
`xvfb-run … godot --rendering-driver opengl3 --resolution <W>x<H> --fixed-fps 20 --script res://tools/capture_named_fights_f10_6.gd -- --ids=hollows_alpha --seconds=12`, run at 1920×1080 (00ce19bcf) and 1280×800 (5651d8f23).
Judge inputs: `frames_1920x1080/hud-00..04.jpg` and `frames_1280x800/hud-00..04.jpg`, the same moments at each size (mid-fight intervals, a tell start and an impact). The 1280×800 set is the UX §8 handheld capture for the 7-inch device-profile judge.
Shown: RB ultimate ring and caption, the Y/X/B/A move diamond (× = not ready), the command lane (bar, ticks, 4 d-pad commands with costs, dimmed while unaffordable), the action hint, the enemy plate, the ally panel and the team strip.
Not claimed: the 4-player strip, the judge verdict, on-device readability.
