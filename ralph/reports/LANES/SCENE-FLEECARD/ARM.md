# SCENE-FLEECARD: the flee verdict as a framed result card (F41#16)

Row: F41#16 Hollows fight-loss result clarity. GPU High 1108 rescore 6.37 (5.5, 5.5, 5.7), PARTIAL 3/3: "the loss result is not clear". Not in TRIED_AND_FAILED.

## Cause (confirmed on the judged frames)

The frame judged for this row is not a loss. `capture_named_fights_f10_6.gd` ends the Hollows fight with `combat_manager._begin_resolve("fled")` and saves `99-after` as soon as the fight stops. The level-42 party never actually loses Voltarach inside the capture window: in `G-rescore-stale-ext-stormwood/F41-16/main/High`, `i12` is still mid-fight with 5/5 healthy and the foe's bar full.

So `combat_hud.gd _on_exited("fled")` is what judges see. It draws one default-size line, "You backed off.", in the outcome band at screen centre, over the foe's body. The director's "Put Sparkit away" recall line sits below it. The shipped `loss_card` and `result_focus` never apply: the loss card handles only `lost`. `result_focus` does stand the roster and quickbar down, which leaves the screen empty apart from the tiny line.

## Arm

Overlay: `hud.json flee_card_1114.enabled` true. Flag-off code on `tb/scene`:

- `combat_hud.gd _apply_flee_card` draws the flee verdict in the same framed family as the catch card. The card is an opaque plate with a soft teal edge (no red). It shows a 44 px headline "YOU BACKED OFF" over "<creature> got clear. Regroup and try again.", placed in the upper third, clear of the creature, and held 3 s.
- While the card holds, the director's "Call out / Put away" recall line stands down, the same rule as a story hold.
- The flee, its timing and every rule after it are unchanged.
- Test: `tests/test_flee_card_flag.gd`. It checks three things: the flag ships off with the old line; the card is framed, sized and placed from config, then restored after; the creature is named.

## CPU

Overlay on, `--ids=hollows_alpha --seconds=3 --interval=10`, frame `99-after`. Round 1 at 720p showed the card readable over the forest, but it covered the Day/time line and the detail wrapped to three lines. Round 2 moved it down 40 px and made it 160 px wider.

## By-eye line for the GPU lane

Hollows `99-after` at High: a dark framed card in the upper third reading "YOU BACKED OFF / Sparkit got clear. Regroup and try again." in large type. There must be no small "You backed off." over the spider and no "Put Sparkit away" line. If the small line is still there, the overlay did not apply: hold it.

## Risks and no-loss frames

- `i12` (mid-fight HUD) must be identical, since only the flee outcome is touched.
- F41#21 `hollows_win 99-after` must be identical, since a win never takes this path.
- The row's name says "loss". The coordinator may still want the GPU job to reach a real loss (the job's "party 42, idle" setup does not lose inside the window). If it does, the shipped `loss_card` draws, and this arm is neutral there.
