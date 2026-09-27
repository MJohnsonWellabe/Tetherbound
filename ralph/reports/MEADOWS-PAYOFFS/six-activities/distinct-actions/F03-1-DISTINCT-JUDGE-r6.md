# F03#1 distinct optional action: code-blind judge, round 6 (doss)

Judge input: the four frames `r6/doss_01.jpg` .. `r6/doss_04.jpg` and the designed/other action lines given in the brief. No code, data, config, tests or scripts were opened.

| activity | action shown | matches ledger | distinct from nearest | overall |
|---|---|---|---|---|
| doss | Player prompts "Help Doss repair the bank perch" at a collapsed timber structure; Doss asks for one wood and one fiber ("brace and lash it") for coin and a large potion; afterwards the structure stands rebuilt and the prompt drops to "Greet Doss" | PASS | PASS (nearest: herd, a walk-and-watch; no other activity builds or repairs anything, and none is paid with materials) | PASS |

## Evidence (01 vs 04, same camera, same spot)

- **Structure:** in 01 the planks are collapsed: a rail frame tipped over at the left, loose boards lying flat and angled in the middle, a broken rail section leaning at the right. In 04 the same spot holds an upright, intact L-shaped rail fence (two posts and double rails along the front, a return section at the right). No loose boards remain.
- **Prompt:** 01 says "Help Doss repair the bank perch"; 04 says "Greet Doss". The repair offer is gone, which fits a one-time repair.
- **Reward:** quick slot 2 goes from x2 in 01 to x3 in 04. That matches the large potion Doss names in 02 and 03 ("Your help earned 45 coin and a large potion").
- **Cost:** 02 states the cost in dialogue (one wood, one fiber). The frames never show the materials being taken from the inventory. The cost is announced, but the payment itself is not visible.
- **Location:** 02 shows a river running close behind Doss, so the spot does sit on the river bank. In 01 and 04 the river is out of frame.
- **Not a fight, not fishing:** no enemy, combat HUD, rod or water interaction appears in any frame. Team HP and bond values are the same in 01 and 04.

## Caveats (not failing)

1. The rebuilt object reads as a **fence or pen corner**, not a "perch". Nothing about it suggests somewhere to sit, stand or watch from.
2. In 01 and 04 the "blocked bank" is not shown: the river is out of frame, so the debris does not visibly block anything.
3. The wood/fiber deduction is not shown on screen.

## Fix

No blocking fix is needed. The most useful polish is to make the rebuilt piece read clearly as a bank perch overlooking the water, for example a raised plank platform or lookout seat with the river in the same shot as the before/after frames, instead of a generic fence corner.
