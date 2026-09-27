# F03#0 lure judge, round 6 (code-blind)

Judge input: the 25 frames in `r6-judge/` plus the F03 lure criterion and the coordinator's ruling (visible from the road, then readable on approach). I opened no code, data, config, tests, scripts or other files.

| activity | visible from road | readable on approach | overall |
|---|---|---|---|
| herd | PASS (marginal) | PASS (marginal) | PASS (marginal) |
| bram | PASS | FAIL | FAIL |
| doss | FAIL | FAIL | FAIL |
| hall | PASS (marginal) | PASS | PASS |
| vault | PASS | PASS (marginal) | PASS (marginal) |
| juno | FAIL | FAIL | FAIL |

**Result: 3 of 6 PASS.**

## Per-activity notes

- **herd.** Road: in the first-seen frame the herd is not visible. The only cue is a tall cyan light beam at the upper left (about 60 px wide and running from the top of the frame to the treeline), which is noticeable but reads as a generic marker, not as grazing animals. Mossy boulder creatures sit at the far left edge. The herd first shows in the first-readable frame as two deer silhouettes about 40 px tall beside a rock on the right, close to the objective panel. Approach: at 30 m one deer stands at top centre, about 50 px tall, and reads clearly as a deer. At the prompt two deer are visible. Two animals barely read as a "herd", and they do not look large next to the trainer and companion. Marginal pass on both counts.
- **bram.** Road: a strong dark smoke column with a small fire at its base sits in the left third of the first-seen frame, clearly visible through the trees. Approach: in both the first-readable frame and the 30 m frame there is only the campfire and smoke. Old Bram is not visible in either. At the prompt he is almost entirely hidden behind the player character, with only his hat showing. You can tell a camp is there, but not who is at it or what it offers.
- **doss.** Road: in the first-seen frame the lure is a speck about 20 px wide at the far end of the road (a small creature or cart cluster), and no signal column is visible. The first-readable frame is unusable because the camera is inside tree canopy and the screen is solid green leaves. At 30 m a thin dark column is cut off by the top edge of the frame and Doss is a figure about 15 px tall on the horizon. He becomes readable only in the prompt frame, where he stands just ahead of the player on the river bank.
- **hall.** Road: the gold nameplate text "Alpha ..." floats large at the far end of the road, centred and noticeable. A tree trunk clips it, though, and the creature itself is not visible in the first-seen or first-readable frames. Those two frames are near-identical, so no readability was gained between them. Marginal pass. Approach: at 30 m the full "Alpha Galecrest" nameplate is legible and the blue winged creature is visible behind the companion. At the prompt a large bird-like alpha fills the frame. Clear.
- **vault.** Road: from 160 m, 110 m and 70 m a dark signal column rises over a hill mound with a rock face and cave openings. It is centred at 160 m and 110 m and on the right at 70 m, where it grows to about 230 px tall and stands clearly above the skyline. These road frames have no HUD and use a low camera, so they are not ordinary gameplay framing. No waylight light is visible from the road. Approach: at 30 m (dark, inside the Warrens) a stone arch opens onto a lit inner space with a thin cyan vertical waylight sliver above it. That reads as "a passage here", though the waylight is faint. At the prompt a lit guardian (Elder Trailpup) stands beside a pedestal holding a gold reward, which reads clearly. Marginal pass on approach.
- **juno.** Road: in the first-seen frame the only candidate is a pale blue-grey rock cluster about 50 px wide on the horizon. No camp, uniforms or red is readable. In the first-readable frame (night) there are some specks about 10 px tall on the far-left horizon, and the companion blocks the road. At 30 m a lone deer stands at top centre, overlapping the clock text, and there are no Tether figures or camp. At the prompt a dark-clad figure stands ahead and a deer is half-hidden behind the HUD. No oxblood uniform, tent or camp structure can be seen at any distance. Only the prompt text says it is a Tether Patrol.

## Fixes for each FAIL (single most important)

- **bram:** Put Old Bram at the fire, where he is lit and to one side of the approach path, so he is visible and recognisable as a trainer at 30 m and never hidden behind the player at the prompt.
- **doss:** Make Doss's signal column tall and high-contrast enough to show above the skyline in the first road view, like Bram's smoke or the vault column. Right now nothing marks the camp from the road. The canopy-clipping camera in the first-readable frame also needs fixing before re-judging.
- **juno:** Give the Tether Patrol camp a lit, road-visible oxblood identity at the road edge (banner, tents or brazier), so it reads as a Team Tether camp at night. Today the patrol is dark silhouettes and the stolen Meadowhart looks like a stray deer.
