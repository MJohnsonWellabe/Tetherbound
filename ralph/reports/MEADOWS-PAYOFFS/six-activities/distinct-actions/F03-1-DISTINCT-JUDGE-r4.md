# F03#1 distinct optional action: code-blind judge, round 4 (bram and doss)

Judge input: the 8 frames in `r4/` (bram_01..04.jpg, doss_01..04.jpg) plus the designed-action lines in the brief (bram, doss, and the reference actions for herd/juno/hall/vault). No code, data, config, tests or scripts were opened.

| activity | action shown | matches ledger | distinct from nearest | overall |
|---|---|---|---|---|
| bram | Talk to Old Bram in the woods, then fight his Meadowhart (Lv6) and then his Galecrest (Lv7) under an "Old Bram · LEVEL n" trainer header; "Old Bram defeated" with a trainer reward (60 Coin, 5 Greater Orb, 3 Small Potion) | PASS | PASS (nearest: juno's Team Tether patrol fight) | PASS |
| doss | Three dialogue boxes from Doss on a meadow: the bank perch buckled, one wood and one fiber will fix it, it's fixed now, 45 coin and a large potion paid out. No perch, payment or repair ever appears on screen | FAIL | PASS (nearest: herd, the other non-fight walk-up) | FAIL |

## Evidence

**bram**
- bram_01: a named NPC, Old Bram, in a hat and duster, with a portrait dialogue box ("Sit if you like. I've not got anywhere to be."). He reads as an older, settled figure. Nothing in these frames says he is a retired champion, though. That is a flavour gap, not a gate failure.
- bram_02/03: real-time direct piloting (Terrapup, the Pebble Toss/Stone Rush/Throw/Switch HUD). The enemy header names the owner, "Old Bram", with two different creatures in sequence: Meadowhart LEVEL 6 (Ground), then Galecrest LEVEL 7 (Air). That is a two-creature trainer fight. The telegraph ring and the "incoming, move" and "it's open, hit it" prompts show that combat is live.
- bram_04: the "Old Bram defeated" panel shows a trainer reward and XP for the whole team. Bram is still standing in the world next to a large companion.
- Distinct: juno's patrol is also a trainer-style fight, but Bram is a named, friendly, solo NPC encounter with a sequenced two-creature roster and no rescue or escort. It also differs from hall (one wild alpha) and vault (underground, Elder Trailpup, heartstone).

**doss**
- doss_01: Doss names the problem ("The bank perch buckled. Those loose boards..."). The river is visible only far off in the background valley. No buckled perch, loose boards or blocked bank is anywhere in frame.
- doss_02: Doss states the cost ("One wood and one fiber will brace and lash it"). No payment prompt, inventory panel or item-deduction feedback is shown.
- doss_03/04: Doss says the job is done ("Solid boards and tight lashings... a safe perch beside the river again") and names the reward (45 coin, large potion). Between frames the camera shifts slightly (a tree now occludes the background), but nothing rebuilt is visible. No coin or item toast appears.
- Result: it is correctly not a fight, and its content is unlike every other activity, so it passes distinctness. But the designed action (pay the wood/fiber repair once at a blocked river bank; clear or rebuild a bank perch) exists only as dialogue text. A player sees a four-line conversation on an open meadow, not a repair at a river bank. That fails "matches ledger" for a visible, performable action.
- Also seen: a dark vertical smear or column runs through the upper centre of every doss frame, and there is an unexplained orange cone behind Doss. Neither decides the verdict, but both hurt readability.

## Fixes

- **doss (most important):** stage the activity at a visibly buckled bank perch on the river's edge (broken boards blocking the bank), with Doss beside it. Show the one-time wood + fiber payment as an explicit confirm prompt with item-deduction feedback. Then show the same spot with the rebuilt perch, ideally with the player or a companion standing on it.
- bram (optional polish): add one line establishing that Bram is a retired champion.
