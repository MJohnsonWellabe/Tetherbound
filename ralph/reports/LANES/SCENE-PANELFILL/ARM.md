# SCENE-PANELFILL: Players and Quest Log fill their panels (F38#10 close-out)

Row: F38#10 Meadows menus. GPU 7.39 at High and at Medium (`G-closeout-f38-10-panels.md`, tb/judge 83d0819f; control 7.63, so that panel ran about 0.6 strict). Defect PARTIAL 3/3: "Players and Quest Log still leave the lower third to half of the panel empty below a few rows of text." Build alone reads 7.75: "well filled with three illustrated cards".

## Cause

Seen on the CPU capture of main (top row of the sheet), and in the layout code:
- **Players:** the roster is one short trainer row and three one-line "open seat" rows in a scroll box that takes all the remaining height. The rows are about 40 px each (at 960 wide), so the lower 40% of the panel is bare.
- **Quest Log:** one tracked step, an empty-section line and one bounty line, stacked from the top of a full-height scroll box. The same bare lower third.

## Arm

Overlay (`overlay.json`): `menu.json panel_fill_1113.enabled` true. Flag-off code on `tb/scene`:
- **Players:** the four seats stand side by side as tall cards that fill the panel, each with a large portrait over its name and status, the way Build shows its pieces. Open seats show the trainer silhouette. Same rows, labels and Remove buttons; nothing about the session changes.
- **Quest Log:** the tracked story section becomes a card: the realm's own banner art (`assets/ui/region_bands/<realm>.png`, cropped to a thumbnail) beside the steps, with a chapter progress strip under them ("0 of 28 steps" at the start). The other sections are unchanged.

Device-local presentation only. No new art.

## CPU

`phase2_capture_ui.gd --biome=meadows --tabs=players,quest_log --gamepad --seed=2042`. `_sheet_cpu_base_top_arm_bottom.jpg`. The Players "network port could not be opened" line comes from the capture machine.

## By-eye line for the GPU lane

`menu_players`: four cards in a row, the first with the trainer's portrait, the other three with dark silhouettes, filling the panel down to the one-line note. `menu_quest_log`: a painted meadow thumbnail at the left of the tracked step, with a thin progress strip under the step's text. If either panel still shows short rows over an empty lower half, hold it.

## Risks and no-loss frames

- Three "Open seat · joining is unavailable" cards repeat one message. On the judging PC that line appears only because its network port is closed; on a normal machine the cards read "Open seat".
- The progress strip shows the count of story steps in the chapter (28 in the Meadows). It names no future step. If showing the total is a spoiler concern, it is one line to drop.
- `menu_build` must be identical (not touched). Close in one batch with all three panels at both presets and the F38#38 control.
- Other realms' Quest Log uses that realm's band art; only Meadows was captured here.
