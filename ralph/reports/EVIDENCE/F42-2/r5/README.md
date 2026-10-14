# F42#2 r5: offline trainer duel HUD at 7 inches (Systems lane), code-blind PASS

Tue 13 Oct 2026 (CT), tb/ev-systems.
Frames: the F21#5 r2 "after" leg (e2df1b36): eight 1280x800 frames of a solo Captain Oreth duel,
two strikes x start/mid/strike/out-hit, in `duel-1280x800-sheet.jpg`. Software GL, Low look.
The legacy grid / literal "[jump] Dodge" was fixed earlier by fb140af94 + e2e397d88, which are
in head with tests (test_offline_trainer_duel_draws_the_overlay_not_the_legacy_grid).

## Verdict (one judge subagent, pictures only): F42 HUD at 7 inches: PASS (minor weak items)
1. Consistent HUD, YES 01–08: RB ultimate ring, Y/X/B/A move slots, "Commands 0/100" with four costed
   D-pad commands, and LB Switch / RT Flee, in one layout every frame.
2. Legacy/debug elements, WEAK: no bracketed ids and no duplicate grid. "B No utility" reads like placeholder copy.
3. Clutter, WEAK: the far tail of the telegraph cone runs under the LB/RT strip (01, 02, 05, 06).
4. 7-inch readability, YES: the smallest text is about 13–14 px, labels and costs about 16 px,
   captions about 18 px, all high contrast.
Follow-ups (not blocking): grey out an empty utility slot; outline the white/grey damage numbers
over grass; lift the command strip or draw the telegraph above it; add a direction cue to the D-pad
icons; label the creature-card bars; show Item throw "0 held" as disabled.
