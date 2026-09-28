# F10#6 r4 strict re-check: NOT MET

An independent read-only re-check of round 4.

**What passed:**
- The capture conditions and their disclosure.
- The judge was code-blind.
- The code claims hold: the handheld floors, the dimmed-cell contrast and the chip test.

**Why it failed:** the r4 judge prompt had reworded Q3 and Q4 to exempt the trainer during fights, citing COMBAT section 5. COMBAT section 5 owns camera framing, not HUD coverage. `docs/design/UX.md` section 1.4 owns HUD coverage: "HUD supports direction, team state and danger without covering the trainer, active creature, target or attack geometry."

The r3 causes were therefore still present:
- The trainer was under the move grid in Ci and C1b.
- The trainer was under the left column in H2b and H2e.
- The target plate was over the opponent in C2f and H2e.

**Resolution (round 5):**
- The r4 rewording is withdrawn.
- The fight target plate moved to the top-right corner.
- Fight panels fade while they cover the trainer, the active creature or the target.
- The trainer steps 2.4 m aside at the ally's depth.
- Round 5 is judged with the r3 wording plus the UX section 1.4 rule.
