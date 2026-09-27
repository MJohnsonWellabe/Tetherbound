# F03#1 distinct optional action: code-blind judge, round 5 (doss)

Judge input: the 4 frames in `r5/` (doss_01.jpg .. doss_04.jpg) plus the designed-action lines in the brief (doss and the five other activities). No code, data, config, tests or scripts were opened.

| activity | action shown | matches ledger | distinct from nearest | overall |
|---|---|---|---|---|
| doss | Talk to Doss on a grassy rise, accept "one wood and one fiber" repair, receive 45 coin + large potion; a flat white slab on the ground changes shape | FAIL | PASS | FAIL |

## Evidence

- **01 (before):** Player and Doss stand on an open grassy hillside. Behind them is a flat, untextured, bright-white tilted quad (about 2 m across) with a small orange/yellow flame-like or twig mark at its upper-right edge and a thin yellow stick below it. The prompt reads "Help Doss repair the bank perch". No water, bank edge or debris is visible in this frame. The hotbar shows slot 2 at x2.
- **02 (request):** Doss says "One wood and one fiber will brace and lash it. I've coin and a large potion for whoever helps." The river is visible far in the background, well away from where the characters stand. An orange cone-shaped marker stands beside Doss.
- **03 ("repair" line):** Doss says "Your help earned 45 coin and a large potion. Keep your team ready for the road ahead." This is a reward line. No bracing, lashing or placing of anything is shown, and the text does not say the perch was repaired. A companion creature stands behind the player.
- **04 (after):** Same camera and spot. The white quad is now larger, flatter and more rectangular (it spans about x540–740 instead of about x575–720). The orange/yellow marks and the yellow stick are gone. It is still a featureless white plane with no wood, planks, posts or lashing. The prompt now reads "Greet Doss". Slot 2 went from x2 to x3 (the potion reward). No wood/fiber deduction is visible on the HUD.
- **Net change 01 to 04:** One white placeholder-looking plane swaps for a slightly different white plane, a few small orange/yellow bits disappear, and the prompt text changes. Without the prompt text, no viewer would read this as a "blocked river bank" becoming a "rebuilt bank perch". The spot is not visibly at a bank, the blockage is not legible, and the result looks like a missing-texture decal, not a structure.
- **Distinctness:** The interaction is a dialogue plus a resource payment, with no combat, no fishing, no herd-watching and no escort. By its form it is distinct from herd, bram, juno, hall and vault. That distinctness comes from the dialogue and prompt text, not from anything visible in the world.

## Single most important fix

Replace the white placeholder planes with a readable perch prop from the installed nature/village prop family, placed visibly at the river's edge. **Before:** a clearly blocked/broken bank (for example fallen logs, snapped planks or a debris pile across the spot). **After:** a braced, lashed wooden perch or platform standing where the debris was. Also make frame 03 show or state the repair itself (for example "Braced and lashed. The perch holds."), and show the wood/fiber leaving the inventory.
