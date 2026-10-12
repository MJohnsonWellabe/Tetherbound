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

## r2 (after judge r1 FAIL, coordinator 11:30 PM CT) — CAPTURE-READY
Fixes: eb5d6be8f and 189f4cdb9.
- One F42 layout in every fight state. Before the first host sync (the "CHARGE" frame at fight start), a zero-valued placeholder replaces the legacy grid. The real snapshot's security contract is unchanged.
- Overlay text keeps the foreground fade floor.
- Command lane: always visible in a fight (muted when inactive), cost-ordered columns, bar track and fill, d-pad glyph art. It hides again after the fight.
- No "×" on move slots.
Recaptured at 189f4cdb9 (1920×1080) and 209748abd (1280×800; that change touches only reward code). Same fight, same moments:
- hud-00: fight start, CHARGE telegraph.
- hud-01, hud-02: mid-fight.
- hud-03: impact.
- hud-04: a later CHARGE.
- hud-05: after the fight (exploration HUD, no command lane).
Not observed: a frame where a command is affordable. Rally needs 50 and the meter peaked at 32–40; item throw needs a held item (0 held); tag-switch needs a combo window. Unavailable commands are shown muted.
