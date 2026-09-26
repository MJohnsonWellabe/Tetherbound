# F03#1 distinct optional action: code-blind judge, round 7 (doss, perch without the material retint)

Judge input: the 4 frames in `r7/` (`doss_01.jpg` .. `doss_04.jpg`) plus the designed/other action lines given in the brief. No code, data, config, tests or scripts were opened.

| activity | action shown | matches ledger | distinct from nearest | overall |
|---|---|---|---|---|
| doss | Talk to Doss by a collapsed pile of white planks, hand over 1 wood + 1 fiber once, and the pile becomes an upright two-rail plank structure; paid 45 coin + a large potion | PASS | PASS (nearest: herd) | PASS |

## Evidence (01 vs 04)

- **Same camera, same spot.** Hills, trees, Doss's and the trainer's positions, HUD layout and minimap (559 m) all match between 01 and 04. The only change in the world is the structure behind Doss.
- **01:** a jumbled, collapsed heap of white planks and rails lies on the ground, tilted every which way. Prompt: "E Help Doss repair the bank perch".
- **04:** at the same place stands one upright, level two-rail plank panel with posts. It is plainly the same pieces rebuilt. Prompt now reads "E Greet Doss", so the repair can't be offered again (one-time).
- **02:** Doss states the cost: "One wood and one fiber will brace and lash it", with coin and a large potion as the reward. A river running between banks shows behind her, which ties the spot to a river bank.
- **03:** Doss confirms: "Your help earned 45 coin and a large potion."
- **HUD delta 01 to 04:** quick slot 2 potion goes from x2 to x3 (the reward arrived). The other slots are unchanged. Food is 98% in both, and nothing on screen suggests combat.
- **Matches ledger:** a single material payment to repair a broken structure on the bank, with no fight and no fishing. That is the designed action.
- **Distinct:** herd is the nearest non-combat activity (approach and watch). Doss differs because it has a material cost, a persistent structure in the world that goes from broken to rebuilt, and an NPC reward. Bram, juno, hall and vault all centre on a fight, and this has none.

## Caveats (strict)

- The payment is only stated in dialogue. The quick bar has no wood or fiber slot, so no frame shows the 1 wood + 1 fiber leaving the inventory.
- The rebuilt object reads as a **fence panel**, not a "perch". There's no seat, platform or ledge, and no water is visible in 01/04. A player would describe the action as "repaired Doss's fence". That still matches "pay to rebuild a bank structure", but the word "perch" gets no visual support.
- The HUD clocks run out of order: 01 12:48, 02 12:37, 03 12:54, 04 13:25. Frame 02 was captured before frame 01, possibly in a separate pass. This doesn't change the verdict, but the sequence isn't one continuous take.

## Art issues (separate from the verdict)

- With the retint gone, the planks are flat, stark, unshaded white both before and after. They look like an untextured placeholder or ghost preview, not lashed wood. They don't sit in the warm nature/village prop family around them.
- A dark vertical smoke/haze column crosses frames 02 and 03 (and the top-left of 01/04), cutting through the dialogue framing.

## Fix

None required for PASS. Most valuable follow-up: give the rebuilt structure a readable perch silhouette (a plank platform or seat at the bank edge, with the river in frame 01/04) in a wood material, not bare white, so "bank perch" reads without the prompt text.
