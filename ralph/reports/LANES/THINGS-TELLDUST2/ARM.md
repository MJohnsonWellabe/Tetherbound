# THINGS-TELLDUST2: a lower dust band that stays off the creatures' legs (F38#3 / F38#28 close-out)

**Rows.** After TELLDUST: F38#3 High 7.51 / Medium 7.47 (0.03 short), F38#28 High 7.47 (0.03 short) / Medium 7.55. `G-things-telldust.md`, 3/3 ask for dust "that stays off the creatures' legs and heads"; the GPU lane saw the band cross in front of the boar's legs on grunt frame 03.

**Why it reaches the legs.** Each puff is a camera-facing sprite that grows through its life to about 1.45 times `dust_size_m` (`tell_style.gd _dust_walk`). At the shipped 0.8 m that is up to about 1.4 m tall where the outline passes in front of a creature.

**Change** (overlay only, over the shipped round 1): `dust_size_m` 0.8 to 0.5, `dust_spacing_m` 0.3 to 0.2, `dust_rise_m` 0.06 to 0.04, and `dust_max` 260 to 400 so the closer spacing still covers a long outline. Alpha and colour are round 1's. The largest puff is now about 0.85 m, roughly ankle to knee on these creatures, and each puff is still 2.5 times as wide as the gap to the next, so the band stays continuous and does not go back to beads.

**Not shown on CPU.**

**Risk.** A thinner band is a little easier to miss. If it loses, round 1 stays as it is.

**Ask.** Round 1 against this arm, High and Medium, camera-matched, with the F38#38 control. By eye first on grunt 03: the band should sit below the boar's body.
