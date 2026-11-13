# BEINGS-STATICUB-COOL: a darker storm-brown Staticub with lit veins for the Stormwood world frames

**Status: CPU-ready, waiting for a GPU slot.**

**Row:** the Staticub world frames, scored 6.53 at both High and Medium in G-closeout-staticub. Its stage row, F36 (0) #19, is already closed. The same r10 bears stand behind the Stormwood cast in F41#8 and F41#18.

**Defect, quoted (3/3):** under Stormwood light the coat reads "orange / peach, almost plastic", and the veins are "barely visible in the scene".

## Cause
- **The coat is too light.** The shipped storm coat averages RGB 99,65,40, warm and light. In the world frames it renders far lighter than Stormursa's coat.
- **The glow map is off.** The r10 vein glow map (`creature_staticub_r10_glow_read.png`, matching the violet flecks in the albedo) is not lit in the game: its only flag, `remake_owner1101_glow_read`, is OFF. Only the eyes emit.

## Change
New flag `beings_staticub_cool_veins` in `data/config/creature_coat_flags.json`, OFF. It sits after `below6_staticub_storm_fur`, so its albedo wins when ON. It changes the r10 coat only:
- **albedo:** `creature_staticub_r10_Image_0_cool.png`, made by `make_cool_fur.py` from the shipped storm coat. The fur is multiplied by (0.62, 0.64, 0.70), about a third darker with red trimmed most; average 64,43,30. Arcs, eyes and muzzle keep their colour.
- **emission:** the model's own `glow_read.png` at strength 2.5.

Nothing is red, and Stormursa is untouched. There is no code change.

## Round 1, dropped (top two rows of the sheet)
Round 1 moved the coat toward Stormursa's average colour by pulling red down and pushing blue up (0.90, 0.95, 1.35). Under Stormwood's violet light that rendered pink, which is worse than orange. The world read is a brightness problem, not a hue problem.

## CPU sheet
`_sheet_r2.jpg` shows idle and fainted for three versions: base, round 1 (dropped) and the arm.
- Base: a peach-orange bear.
- Arm: a natural dark-brown bear, with the white-violet vein streaks on the back and shoulder now readable.

## By-eye line for the GPU lane
`stormwood__staticub__idle`: the bear is a dark natural brown, neither peach nor pink, and white-violet streaks show on its back. If it reads pink or mauve, hold.

## No-loss checks
The dialogue frames from G-below6-staticub-fur-dialogue (Nysa, and Maud and Bryn) have the r10 bears behind them. They must not lose.

## Risks
- Under the violet light the dark coat keeps a slight mauve cast on CPU.
- The faint end is still the belly-down "loaf" the judges named. That is a separate ask (roll onto the side with legs showing) and is not in this arm.
