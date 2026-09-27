# F03#1 distinct optional action: code-blind judge, earned save, set B (doss)

Judge input: the 4 frames in `distinct-b/` (doss_01.jpg .. doss_04.jpg) plus the designed-action and other-activity lines in the brief. No code, data, config or other files were opened.

| activity | action shown | matches ledger | distinct from nearest | overall |
|---|---|---|---|---|
| doss | Gather a plant (01), then at Doss's collapsed wooden perch press "Help Doss repair the bank perch" (02); Doss confirms "Solid boards and tight lashings... a safe perch beside the river again" (03); the perch stands rebuilt (04) | PASS | PASS (nearest: herd, the other non-combat activity; herd is walk-up-and-watch with no build, cost or world change) | PASS |

## Evidence: 02 vs 04 (same camera, same spot, Day 10 16:11 vs 16:49)

- **Deck:** in 02 the planks are dark, tilted and caved in, with loose boards angled up at left. In 04 there is a level, lighter-wood plank deck.
- **Rails:** in 02 the rail posts lean at broken angles, with a crossed or fallen section at the right rear. In 04 they are upright, a squared railing on the back and right sides with straight horizontal rails.
- **Prompt:** "Help Doss repair the bank perch" (02) becomes "Greet Doss" (04). The repair is consumed and cannot be repeated from this prompt, which fits a one-time repair.
- **Unchanged:** the player position, Doss's position (foreground, back to camera), the team panel, the tool bar (30/40, 31/40, 23/40, 40/40, x5), health and food 88%. The only thing that changes in the world is the perch.
- This is not a fight (no enemy, no combat HUD) and not fishing (no rod, no water interaction).

## Gaps (strict; they do not overturn the action verdict)

- **The wood/fiber payment is never shown.** No frame shows a cost, a material requirement or a deduction. The quick bar holds tools, not materials, and it is identical in 02 and 04. Frame 01 shows gathering, but nothing ties that fiber to the repair. From these images alone, "pay once" is only inferred.
- **The river bank is not visible.** No water appears in 02 or 04. The river is established only by Doss's line in 03.
- **No repair in progress.** The frames show only before and after. Nothing shows the work happening (no animation, no construction state).

## Art issues (separate from the verdict)

- In 02 and 04, Doss stands in the lower centre foreground with her back to the camera and blocks part of the perch.
- The quick bar and control-hint panels cover the right third of the scene, next to the perch.
- The rebuilt perch is small and plain: a pen-like fence on a bare dirt patch, with no water, moorings or anything that reads as a riverside perch.
- In 03 a large creature head fills the right edge of the frame, the player's hair fills the left edge, and Doss's face is flat and stiff.
- The team panel lists two Mudsnout and two Bramblebun entries, with two KO.

## Fix

Not required for this PASS. The most important improvement is to show the transaction. Put the wood/fiber cost on the repair prompt or in a confirm line, and show the materials leaving (a toast or satchel delta) when the player pays. Framing the perch against visible river water would also help it read as a bank perch.
