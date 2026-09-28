# C3 combat-readability judge answers (code-blind)

Sources opened: `judge_packet/JUDGE_PROMPT.txt`, the six `sheet-fight-*.jpg` sheets, and full-size tiles under `frames/<letter>/`. No other file was opened.

## Fight K (Voltarach, spider)

- (a) PASS. Every tell puts a saturated magenta lane and a ring at the spider's feet, with "! incoming — move" on the opponent card (tell1-a-start, tell1-b-mid, tell3-b-mid, tell4-a-start). This is unmistakable against the dark grass.
- (b) PASS. The lane runs from the spider toward the pilot, so the struck strip is plain and the escape is to step sideways off it. In tell3-d-strike Sparkit is visibly beside the lane as it releases.
- (c) PASS. Both creatures stay clear of the HUD and are uncropped. Sparkit often sits under the spider's front legs (tell1-b-mid, i07, tell4-e-impact), but its silhouette stays readable. The camera is never inside a body.
- (d) PASS. tell1-e-impact and tell4-e-impact show a hit burst on Sparkit. tell2-e-impact shows a clean avoidance: Sparkit is off the faded lane and "it missed you" appears.
- **C3 PASS**

## Fight V (Voltarach, spider, lightning-crack ground)

- (a) PASS. The magenta lane and ring with "incoming — move" (tell1-a-start, tell2-b-mid) still stand out over the yellow ground-lightning decals. The magenta hue does not compete with them.
- (b) PASS. The lane points straight at the pilot (tell1-b-mid, tell2-c-late). At tell2-d-strike Sparkit is only at the lane's near edge when "it missed you" registers, so the dodge margin is thin to the eye.
- (c) PASS. Both creatures are readable at scale. In tell2-e-impact the left panels go translucent while the trainer stands behind them, and Sparkit stays in open ground. There is no cropping or camera clipping.
- (d) PASS. tell1-e-impact shows a hit burst on Sparkit. tell2-f-recovery and i10 show "it missed you".
- **C3 PASS**

## Fight W (Voltarach, spider, open meadow)

- (a) PASS. The lane and ring are clear at every tell (tell1-a-start, tell2-a-start, tell3-a-start, tell4-a-start).
- (b) PASS, with a caveat. In tell3-c-late and tell3-d-strike Sparkit visibly runs off the side of the lane before release, which is the ideal read. In tell4-d-strike, however, Sparkit sits squarely inside the lane under the spider, yet tell4-e-impact reports "it missed you". The same happens in i10. The marked zone and the outcome disagree there.
- (c) PASS. The trainer overlaps the translucent pilot card (tell1-e-impact) and stands inside the lane (tell3-c-late), but both creatures stay readable and uncropped.
- (d) PASS. tell1-e-impact shows a hit burst on Sparkit. tell3-e-impact shows an avoidance: Sparkit is clear of the lane with "it missed you".
- **C3 PASS**

## Fight X (Tanglevolt, wolf)

- (a) PASS. The heavy tell reads distinctly as "!! HEAVY — get clear" in orange, separate from the ordinary yellow "incoming", on top of the magenta lane (tell2-b-mid, tell3-b-mid). In tell1-a-start the tell's start is partly masked by a hit burst on the wolf (see look defects).
- (b) PASS. The lane shows the lunge line. In tell3-d-strike and tell3-e-impact Sparkit is off to the side while the wolf lunges down the marked strip. The far end of that lane runs under the action panel (tell3-d-strike).
- (c) PASS. The wolf's lunge in tell3-e-impact is strongly foreshortened and touches the top of the action panel, but it is not hidden. Otherwise both bodies are clear and uncropped.
- (d) PASS. tell3-e-impact and tell2-f-recovery show "it missed you" with a visible dodge line. tell1-c-late shows a staggering hit on the wolf, and i04 shows a hit exchange.
- Note: the tell1 set has no d/e/f frames, and tell4 has only a-start. The complete tell2 and tell3 sets carry the verdict.
- **C3 PASS**

## Fight Y (Staticub, bear)

- (a) PASS. A magenta cone and a ring under the bear appear with "incoming — move" (tell2-a-start, tell2-c-late, tell3-c-late). In tell1-b-mid the bear's head and wind-up are covered by a pale-gold burst.
- (b) PASS. The cone shape shows the frontal swipe arc, and the way out is to the flank (tell3-c-late, where Sparkit runs left out of the cone). At tell2-d-strike Sparkit is still near the cone's near edge when it misses, so that dodge reads weakly. The bear's pose barely changes between c-late and d-strike (tell3-c-late vs tell3-d-strike). The release is shown mostly by the cone vanishing and the text, not by a visible swipe.
- (c) PASS. Both creatures are uncropped and clear of the HUD. The trainer overlaps Sparkit's head in tell3-d-strike and sits under the translucent pilot card in i07. These are notes only.
- (d) PASS. tell1-d-strike shows a hit burst on Sparkit. tell2-d-strike, tell3-d-strike and i06 show "it missed you".
- **C3 PASS**

## Fight Z (Mosshock, moss toad, dark forest)

- (a) PASS. A magenta ring around the toad with "incoming — move" (tell1-c-late, tell2-c-late, tell3-a-start, i09). At tell1-a-start only the HUD text shows and the ground ring has not appeared yet. The ring is thinner than the lane/cone tells and is partly hidden by the toad's own body (tell2-c-late).
- (b) PASS, the weakest of the six. The ring tells you only to get away from the toad's body. It is readable, and Sparkit backing off beyond it avoids the hit (tell2-c-late, then tell2-d-strike). In tell1-d-strike, though, the hit lands on Sparkit standing at the ring's rim.
- (c) PASS, with a note. Both creatures are readable at scale at the tells. In i10 and i11, dark foreground foliage covers most of Sparkit's body and the toad is half behind a shrub. That is scenery occlusion in consecutive interval frames, not HUD and not at a tell. Camera clipping never occurs.
- (d) PASS. tell1-d-strike and tell3-e-impact show a hit burst on Sparkit, and tell3-d-strike shows the white hit flash. tell2-d-strike and i04 show "it missed you".
- **C3 PASS**

## Summary

| Fight | (a) | (b) | (c) | (d) | Overall |
|---|---|---|---|---|---|
| K | PASS | PASS | PASS | PASS | **C3 PASS** |
| V | PASS | PASS | PASS | PASS | **C3 PASS** |
| W | PASS | PASS | PASS | PASS | **C3 PASS** |
| X | PASS | PASS | PASS | PASS | **C3 PASS** |
| Y | PASS | PASS | PASS | PASS | **C3 PASS** |
| Z | PASS | PASS | PASS | PASS | **C3 PASS** |

## Remaining look defects (max three)

1. **The "it missed you" outcome contradicts the danger zone.** In W tell4-d-strike, Sparkit stands in the middle of the lane under the spider, and W tell4-e-impact says "it missed you". W i10 is the same. V tell2-d-strike and Y tell2-d-strike show the same thing more mildly, with Sparkit on the zone's near edge. No dodge motion or i-frame cue is visible. The player learns that standing in the marked area can be safe, which undermines the telegraph.
2. **The pale-gold impact starburst masks the opponent's wind-up.** In X tell1-a-start the wolf's heavy wind-up is buried under the burst and the wolf is washed translucent. Y tell1-b-mid covers the bear's head mid-tell, and Z tell3-b-mid does the same to the toad. The one moment the player must read the body is the moment it disappears.
3. **The warning text fades with the opponent card.** In W tell3-c-late, the spider behind the top-right card turns it translucent. At the late tell, "incoming — move" is barely legible. X tell3-d-strike and Y tell3-d-strike fade the card the same way. The ground marker still carries the tell, but the heavy/normal distinction lives only in that text.
