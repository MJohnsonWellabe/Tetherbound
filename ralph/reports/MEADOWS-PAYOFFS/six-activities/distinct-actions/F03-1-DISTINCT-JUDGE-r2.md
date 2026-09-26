# F03#1 distinct optional action: code-blind judge, round 2

This round has a fresh judge and the same prompt. Bram's and Juno's frames are replaced with the fight-end frames (`r2/`), which show "Old Bram defeated" and "Tether Patrol defeated". The other four activities keep the round-1 frames.

| activity | matches ledger | distinct from nearest | overall |
|---|---|---|---|
| herd | PASS | PASS (vs doss) | **PASS** |
| bram | FAIL (the win is shown; the two-creature fight is not; woods, not fields) | FAIL (vs juno) | FAIL |
| doss | FAIL (repair not performed on screen) | PASS | FAIL |
| juno | FAIL (the rescue outcome is not shown) | FAIL (vs bram) | FAIL |
| hall | FAIL (a loss; road-adjacent) | PASS (vs vault) | FAIL |
| vault | PASS | PASS | **PASS** |

**Result: 4 of 6 distinct; 2 of 6 pass.** F03#1 is **not met**.

**The finding that matters: Bram and Juno read as one encounter re-skinned.** They share:
- the prompt verb, "Challenge <human>";
- a human trainer on grass;
- the same "X defeated / X's reward" banner and XP list.

Juno's distinct action is the rescue: the escort, then the reunion with Juno. The `--act` escort capture (x03-act-juno-b at 749729bd) is still rendering.

**If the escort frames still don't make Juno distinct,** that is a presentation question for the owning lane, not a capture gap. It needs a different aftermath for the patrol win, for example the freed Meadowhart and the "Lead the Meadowhart home" beat in place of, or beside, the generic trainer banner.

**Still open:**
- **doss:** the repair press is rendering (x03-act-doss2).
- **hall:** the only saves available leave a Lv12 team against the Lv19 alpha, so the capture shows a loss.
- **bram:** the fight frames show one opponent at a time; his second creature appears only in the second fight-end frame (`bram_16`, not sheeted).
