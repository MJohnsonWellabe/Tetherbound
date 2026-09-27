# F03#0 lure judge, round 7 (code-blind; juno and doss only)

Judge input: the 9 frames in `r7-judge/` (juno_01..04, doss_01..05) plus the F03 lure criterion and ruling ("visible from the road, then readable on approach"). No code, data, config or other files were opened.

| activity | visible from road | readable on approach | overall |
|---|---|---|---|
| juno | FAIL | PASS (marginal) | FAIL |
| doss | PASS (marginal) | PASS (marginal) | PASS (marginal) |

## juno (Tether patrol holding a stolen Meadowhart)

- **Visible from road: FAIL.** In `juno_01_lure-first-seen` (on the road, labelled as the first sighting) I cannot find anything that reads as a patrol, an oxblood standard or a deer. The only candidates are a few pale grey specks on the far ridge around frame centre (roughly x 600-660, y 220-255), a handful of pixels, and Tup covers the right third of the view. In `juno_02_lure-first-readable` there is still no oxblood and no deer I can pick out. The two Burrowbacks near the road and the "Engage Burrowback" prompt take all the attention, and anything at the top-right edge sits under the minimap. A player walking the road would not notice a reason to leave it.
- **Readable on approach: PASS (marginal).** In `juno_03_approach-30m` the Meadowhart stands as a clear silhouette on the hill crest (centre-top, about 50 px tall), with two dark-red banners either side of it (about x 550 and 750). That reads as "a creature being held at a Tether post". The minimap shows the road off to the lower-left, though, so the player has already left the road here. In `juno_04_prompt-offered` the two oxblood banners on white posts, a campfire, a dark-clothed grunt and the large Meadowhart make the scene clear, and the prompt is "Challenge Tether Patrol". It is marginal for two reasons. The grunt reads as black, not oxblood. And nothing shows the Meadowhart is stolen or restrained (no tether, pen or leash), so it looks like it is just standing with them.
- **Most important fix:** make the post read from the road. Put a tall oxblood standard or banner pair, taller than the tree line and silhouetted against the sky, on the side of the ridge facing the road. It should also sit clear of the screen corner where the minimap and quest panel go, so a player walking past sees red on the skyline before the Burrowback encounter takes over.

## doss (ranger at a blocked river bank, signal smoke)

- **Visible from road: PASS (marginal).** In `doss_01_cue-160m_road` a dark vertical smoke column stands clearly above the tree line right of the road (around x 1040-1075, y 195-310). It is plainly not a cloud and is the most eye-catching unusual shape in the frame, which is a good lure. The sighting does not hold, though. In `doss_02_cue-110m_road` the road runs into dense forest and the canopy hides all the sky; in `doss_03_cue-070m_road` the open sky toward the mountains shows no smoke at all. So the lure is seen once at 160 m and then lost for the rest of the road approach.
- **Readable on approach: PASS (marginal).** In `doss_04_approach-30m` the smoke column rises from the crest at top centre, and at its base is a tiny standing figure (about 20 px, around x 640, y 80). That reads as "someone camped at the smoke", but only just at this size. In `doss_05_prompt-offered` the green-haired ranger stands by a small fire under the column, with the river behind, and the prompt is "Help Doss repair the bank perch". Who is there is clear. What the problem is (the blocked or broken bank) is not visible: the river bank behind him looks intact and unobstructed.
- **Most important fix (to firm up the marginal pass):** keep the smoke on screen along the road. Make the column taller or place the camp so the smoke stays visible through the 110 m forest stretch and the 70 m opening. Also add a visible blockage or broken perch at the bank beside Doss, so the approach shows the job and not just the person.
