# F03#1 distinct optional action: code-blind judge, round 3

Judge input: the 24 frames in `r3/` (`<activity>_01..04.jpg` for herd, bram, doss, juno, hall, vault) plus the ledger action lines supplied with the request. No code or data was opened.

| activity | action shown | matches ledger | distinct from nearest | overall |
|---|---|---|---|---|
| herd | Player walks up to two Meadowharts with Terrapup beside them, presses "Watch the Meadowhart herd", and gets a line about studying their tracks; no fight | PASS | PASS (nearest: doss) | PASS |
| bram | "Challenge Old Bram" prompt in a forest clearing, then a distant wide shot, then an "Old Bram defeated" reward panel with one downed blue creature | FAIL | FAIL (nearest: juno) | FAIL |
| doss | "Help Doss repair the bank perch" prompt, then Doss says "Solid boards and tight lashings…", then a "Greet Doss" prompt | FAIL | PASS (nearest: herd) | FAIL |
| juno | "Tether Patrol defeated" panel with a "Lead the Meadowhart home" prompt, the patrol conceding, the Meadowhart following the player through the woods, and Juno's reunion line "You're home." | PASS | PASS (nearest: bram) | PASS |
| hall | "Engage Alpha Galecrest" (Lv 19 boss bar), fight with Ripple, then "Your creature is out of the fight" while the alpha is still standing | FAIL | PASS, weak (nearest: vault) | FAIL |
| vault | Underground chamber with a pedestal, "Engage Elder Trailpup", fight with Tup, Trailpup downed, "Take the heartstone" | PASS | PASS (nearest: hall) | PASS |

Evidence:

- **herd:** Frames 01–04 show the player close to the real herd with a companion out. The interaction is observation only: the companion stays put, no combat HUD appears, and the herd moves naturally in 04. This is the only activity built on watching. Minor visual note: in 04 the left Meadowhart's body looks stretched.
- **bram:** No fight is shown, so the frames never show Bram's two creatures. Frame 02 has no combat HUD, no opposing creature and no player companion. Frame 03 shows only one downed opponent. The setting is a dense forest, not the eastern fields, and Bram is never close enough on screen to read as a retired champion. The only thing on screen that is unique to Bram is the same "Challenge X" prompt followed by the same gold "X defeated / reward / XP list" panel that opens juno_01. Take away the escort and Juno's reunion, and bram and juno's fight half are the same encounter with different names.
- **doss:** Nothing on screen shows the bank blocked, the wood or fiber being paid, or a perch being cleared or built. The river is far in the background, and 01 and 04 show the same field before and after. The only change is a small bare-dirt patch beside the companion in 04. The designed action is only stated in text (prompt and dialogue). It is not a fight, so it is clearly distinct from the combat activities.
- **juno:** The fight itself appears only as a result panel. After it, the escort (03) and the handover to Juno (04) are visible and unique beats, and the player plainly does not keep the creature. This reads as a different activity from bram because of those beats. The frame order is odd: the patrol's concession line (02) comes after the "defeated" panel (01).
- **hall:** It is a real wild alpha fight, with a Lv 19 Alpha Galecrest, a boss bar and a telegraph ring. But the capture ends with the player's creature knocked out and the alpha standing, so neither a catch nor a defeat is shown. Frames 02–04 are also next to a dirt road and Tether pylons, which is not clearly off-road. It uses the same Engage prompt, boss bar and pink ring as vault. What sets it apart (overworld, rarer and bigger creature) is real but thin, because its own payoff never appears. The HUD also calls the companion "Ripple" in one place and "Ripplet" in another.
- **vault:** The player is in an underground branch chamber, and the Elder Trailpup fight has a visible resolution (downed in 04) plus a unique pedestal reward ("Take the heartstone"). That setting and reward set it apart from hall even though the combat HUD is the same. Visual defect: the downed Trailpup renders as a flat, smeared mesh.

**Result: 3 of 6 pass.**

## Fixes (one per FAIL)

- **bram:** Capture the fight itself in the eastern fields, with Bram close enough to read and both of his creatures on screen one after the other (for example, a second-creature send-out beat and the combat HUD showing his roster). Something that is only Bram's has to be visible, not just the generic "defeated" panel juno also uses.
- **doss:** Show the change in the world and the cost: the blocked bank or debris before, the wood/fiber deduction at the moment of repair, and the rebuilt perch standing at the river's edge afterward, framed so before and after can be compared.
- **hall:** Capture a successful outcome, with the Alpha Galecrest either caught (orb throw and catch confirmation) or defeated, somewhere visibly off the road.
